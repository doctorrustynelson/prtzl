
#include "map.h"
#include "list.h"

struct graph{
	struct map* vertices;
};

struct node{
	struct map* properties;
};

struct graph* init_graph();

/* <+ "key" +> */
struct node* insert_vertex(struct graph*, char*);

/* <? "key" ?> */
struct node* query_vertex(struct graph*, char*);

/* <_ "key" _> */
double delete_vertex(struct graph*, char*);

void put_node_property(struct node*, char*, void*);

void* get_node_property(struct node*, char*);

double link(struct node*, struct node*, double weight);

double bi_link(struct node*, struct node*, double weight);

void print_number(double);

void print_string(char*);

void print_vertex(struct node*);

void print_edge(struct node*);

char* cat(char*, char*);
