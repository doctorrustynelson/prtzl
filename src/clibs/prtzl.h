
#include "map.h"

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
int delete_vertex(struct graph*, char*);

void put_node_property(struct node*, char*, void*);

void* get_node_property(struct node*, char*);

int link(struct node*, struct node*, double weight);

int bi_link(struct node*, struct node*, double weight);

