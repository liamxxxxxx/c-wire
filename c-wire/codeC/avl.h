// Structure for a station
typedef struct Station {
    int id;
    long long capacity;
    long long consumption;
    int height;
} Station;

// AVL Node structure
typedef struct Node {
    Station station;
    struct Node *left;
    struct Node *right;
} Node;

// Function to get the height of a node
int height(Node *N) {
    if (N == NULL)
        return 0;
    return N->station.height;
}

// Function to get maximum of two integers
int max(int a, int b) {
    return (a > b) ? a : b;
}

// Function to create a new AVL node
Node *newNode(int id, long long capacity) {
    Node *node = (Node *)malloc(sizeof(Node));
    if (!node) {
        perror("Memory allocation failed");
        exit(1);
    }
    node->station.id = id;
    node->station.capacity = capacity;
    node->station.consumption = 0;
    node->station.height = 1; // New node is initially at height 1
    node->left = NULL;
    node->right = NULL;
    return (node);
}

// Right rotate subtree rooted with y
Node *rightRotate(Node *y) {
    Node *x = y->left;
    Node *T2 = x->right;

    // Perform rotation
    x->right = y;
    y->left = T2;

    // Update heights
    y->station.height = max(height(y->left), height(y->right)) + 1;
    x->station.height = max(height(x->left), height(x->right)) + 1;

    // Return new root
    return x;
}

// Left rotate subtree rooted with x
Node *leftRotate(Node *x) {
    Node *y = x->right;
    Node *T2 = y->left;

    // Perform rotation
    y->left = x;
    x->right = T2;

    // Update heights
    x->station.height = max(height(x->left), height(x->right)) + 1;
    y->station.height = max(height(y->left), height(y->right)) + 1;

    // Return new root
    return y;
}

// Get Balance factor of node N
int getBalance(Node *N) {
    if (N == NULL)
        return 0;
    return height(N->left) - height(N->right);
}


// AVL insert function
Node *insert(Node *node, int id, long long capacity) {
    if (node == NULL)
        return (newNode(id, capacity));

    if (id < node->station.id)
        node->left = insert(node->left, id, capacity);
    else if (id > node->station.id)
        node->right = insert(node->right, id, capacity);
    else
        return node;

    node->station.height = 1 + max(height(node->left), height(node->right));
	
    int balance = getBalance(node);

    // Left Left Case
    if (balance > 1 && id < node->left->station.id)
        return rightRotate(node);

    // Right Right Case
    if (balance < -1 && id > node->right->station.id)
        return leftRotate(node);

    // Left Right Case
    if (balance > 1 && id > node->left->station.id) {
        node->left = leftRotate(node->left);
        return rightRotate(node);
    }

    // Right Left Case
    if (balance < -1 && id < node->right->station.id) {
        node->right = rightRotate(node->right);
        return leftRotate(node);
    }

    /* return the (unchanged) node pointer */
    return node;
}

Node* search(Node* root, int id) {
    if (root == NULL || root->station.id == id)
        return root;

    if (id < root->station.id)
        return search(root->left, id);

    return search(root->right, id);
}

void inorder(Node *root, FILE *outfile, const char stationType, const char* consumerType) {
    if (root != NULL) {
        inorder(root->left, outfile, stationType, consumerType);
        fprintf(outfile, "%d:%lld:%lld\n", root->station.id, root->station.capacity, root->station.consumption);
        inorder(root->right, outfile, stationType, consumerType);
    }
}

void freeAVLTree(Node* node) {
    if (node == NULL) return;
    freeAVLTree(node->left);
    freeAVLTree(node->right);
    free(node);
}