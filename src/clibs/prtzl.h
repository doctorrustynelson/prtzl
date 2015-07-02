
#include "map.h"
#include "list.h"

// graph data type
struct graph{
	struct map* vertices;
};

// used to represent vertices and edges
// vertices and nodes have different built in properties
// that differentiate them
struct node{
	struct map* properties;
};

struct graph* init_graph();

/* <+ "key" +> */
// add a vertex to the graph with the given label
struct node* insert_vertex(struct graph*, char*);

/* <? "key" ?> */
// check if a vertex specified by the given label exists in the graph
// if not, returns NULL
struct node* query_vertex(struct graph*, char*);

/* <_ "key" _> */
// deletes a vertex from the graph
double delete_vertex(struct graph*, char*);

// attach a property to the node's property map
void put_node_property(struct node*, char*, void*);

// read a property from the node's property map
// if the property doesn't exist, returns NULL
void* get_node_property(struct node*, char*);

// links 2 vertices from first to second node with given weight
double link(struct node*, struct node*, double weight);

// creates a bidirectional link between 2 vertices with given weight
double bi_link(struct node*, struct node*, double weight);

// prints the given number to stdout
void print_number(double);

// prints the given string to stdout
void print_string(char*);

// prints a summary of the given vertex to stdout
void print_vertex(struct node*);

// prints a summary of the given edge to stdout
void print_edge(struct node*);

// concatenate 2 new strings in a new buffer
char* cat(char*, char*);

// compare 2 strings, returns 1 if they match
double cmp(char*, char*);
