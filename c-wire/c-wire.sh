#!/bin/bash

TMP_DIR="tmp"
GRAPH_DIR="graphs"
FILTERED_FILE="$TMP_DIR/filtered_csv.dat"

display_help() {
    echo "Usage: $0 <data file path> <plant type> <consumer type> [plant ID] [-h]"
    echo "Options:"
    echo "  <data file path>     Path to the input CSV file (mandatory)"
    echo "  <plant type>         Type of plant to treat (mandatory)"
    echo "                       Possible values: hvb, hva, lv"
    echo "  <consumer type>      Type of consumer to treat (mandatory)"
    echo "                       Possible values: comp, indiv, all"
    echo "                       Note: 'hvb indiv', 'hvb all', 'hva indiv', 'hva all' are invalid"
    echo "  [plant ID]           Optional plant ID for filtering results (1 to 5)"
    echo "  -h                   Display this help and exit (priority)"
}

validate_params() {
    local plant_type=$1
    local consumer_type=$2

    if [[ "$plant_type" =~ ^(hvb|hva)$ && "$consumer_type" =~ ^(indiv|all)$ ]]; then
        echo "Error: Invalid combination of plant type and consumer type"
        display_help
        exit 1
    fi
}

sort_output_file() {
    local output_file="$1"
    local temp_sorted_file="$output_file.sorted"

    (head -n 1 "$output_file" && tail -n +2 "$output_file" | sort -t':' -k2,2n) > "$temp_sorted_file"
	
    mv "$temp_sorted_file" "$output_file"
}

if [[ " $@ " =~ " -h " ]]; then
    display_help
    exit 0
fi

if [[ $# -lt 3 ]]; then
    echo "Error: Insufficient arguments"
    display_help
    exit 1
fi

DATA_FILE=$1
PLANT_TYPE=$2
CONSUMER_TYPE=$3
PLANT_ID=$4

if [[ ! -f "$DATA_FILE" ]]; then
    echo "Error: Data file '$DATA_FILE' not found"
    display_help
    exit 1
fi

validate_params "$PLANT_TYPE" "$CONSUMER_TYPE"

if [[ ! -d "$TMP_DIR" ]]; then
    mkdir "$TMP_DIR"
else
    rm -rf "$TMP_DIR/*"
fi

if [[ ! -d "$GRAPH_DIR" ]]; then
    mkdir "$GRAPH_DIR"
fi

C_PROGRAM="codeC/process_data"
if [[ ! -f "$C_PROGRAM" ]]; then
    echo "C program not found, attempting to compile..."
    make -C codeC/
    if [[ $? -ne 0 ]]; then
        echo "Error: Compilation failed"
        exit 1
    fi
fi

START_TIME=$(date +%s)

if [[ -n "$PLANT_ID" ]]; then
	
	if [[ -f "$FILTERED_FILE" ]]; then
		
		rm -f "$FILTERED_FILE"
	
	fi
    
    awk -F';' -v id="$PLANT_ID" '
        NR == 1 || $1 == id {
            print
        }
    ' "$DATA_FILE" > "$FILTERED_FILE"

    if [[ ! -s "$FILTERED_FILE" ]]; then
        echo "Error: No rows found for Plant ID $PLANT_ID"
        exit 1
    fi

    DATA_FILE="$FILTERED_FILE"
fi

if [[ -z "$PLANT_ID" ]]; then
    ./"$C_PROGRAM" "$DATA_FILE" "$PLANT_TYPE" "$CONSUMER_TYPE"
else
    ./"$C_PROGRAM" "$DATA_FILE" "$PLANT_TYPE" "$CONSUMER_TYPE" "$PLANT_ID"
fi
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "Error: Data processing failed"
    echo "Processing time: 0.0sec"
    exit 1
fi

OUTPUT_FILE="tests/${PLANT_TYPE}_${CONSUMER_TYPE}"

if [[ -n "$PLANT_ID" ]]; then
    OUTPUT_FILE="${OUTPUT_FILE}_${PLANT_ID}"
fi
OUTPUT_FILE="${OUTPUT_FILE}.csv"

if [[ -f "$OUTPUT_FILE" ]]; then
    echo "Sorting output file by Capacity column..."
    sort_output_file "$OUTPUT_FILE"
    echo "Sorting completed: $OUTPUT_FILE"
else
    echo "Error: Output file $OUTPUT_FILE not found"
    exit 1
fi


END_TIME=$(date +%s)
PROCESS_TIME=$(echo "$END_TIME - $START_TIME" | bc)

echo "Processing time: ${PROCESS_TIME}sec"

exit 0
