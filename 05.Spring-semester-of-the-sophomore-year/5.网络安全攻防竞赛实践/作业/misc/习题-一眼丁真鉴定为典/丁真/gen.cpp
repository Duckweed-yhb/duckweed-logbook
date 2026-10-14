#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>
// #include<random>
#define ALPHABET_SIZE 40

char dic[48] = "abcdefghijklmnopqrstuvwxyz{}_!1234567890";
char flag[48]="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";

int getIndex(char x){
    for(int i=0;i<40;i++){
        if(dic[i]==x){
            return i;
        }
    }
    return -1;
}

typedef struct TrieNode {
    bool is_word; 
    struct TrieNode* children[ALPHABET_SIZE]; 
} TrieNode;
 

TrieNode* createTrieNode() {
    TrieNode* node = (TrieNode*)malloc(sizeof(TrieNode));
    if (node) {
        node->is_word = false;
        for (int i = 0; i < ALPHABET_SIZE; i++) {
            node->children[i] = NULL;
        }
    }
    return node;
}
 

TrieNode* initTrie() {
    return createTrieNode();
}
 

void insertToTrie(TrieNode* root, const char* word) {
    TrieNode* current = root;
    for (int i = 0; word[i] != '\0'; i++) {
        int index = getIndex(word[i]); 
        if (current->children[index] == NULL) {
            current->children[index] = createTrieNode();
        }
        current = current->children[index];
    }
    current->is_word = true; 
}
 

bool searchInTrie(TrieNode* root, const char* word) {
    TrieNode* current = root;
    for (int i = 0; word[i] != '\0'; i++) {
        int index =getIndex(word[i]);
        if (current->children[index] == NULL) {
            return false; 
        }
        current = current->children[index];
    }
    return current->is_word; 
}
 

void genWord(char data[48],int start){
    srand(rand());
    for(int i=start;i<42;i++){
        int a = (rand()&0xff)%ALPHABET_SIZE;
        data[i] = dic[a];
    }
}
void printTree(TrieNode* root){
    if(root->is_word==true){
        printf("#");
    }else{
        for(int i=0;i<ALPHABET_SIZE;i++){
            if(root->children[i]!=NULL){
                printf("%c",dic[i]);
                printTree(root->children[i]);
            }
        }
    }
}

int main() {
    flag[42]='\0';
    TrieNode* trie = initTrie();
    insertToTrie(trie,flag);
    srand(time(0));
    char data[48];
    memccpy(data,flag,0,5);
    data[42]='\0';

    for(int i=0;i<1000;i++){
        genWord(data,5);
        insertToTrie(trie,data);
    }
    memccpy(data,flag,0,20);
    for(int i=0;i<1000;i++){
        genWord(data,20);
        insertToTrie(trie,data);
    }
    for(int i=0;i<1000;i++){
        genWord(data,0);

        insertToTrie(trie,data);
    }
    printTree(trie);// >output.txt
    return 0;
}