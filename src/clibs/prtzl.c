
#include <stdlib.h>
#include <stdio.h>

#include "prtzl.h"


struct graph* init_graph(){

	struct graph* ret = (struct graph*) malloc(sizeof(struct graph));
	ret->vertices = map_init();

	return ret;

}

struct node* insert_vertex(struct graph* g, char* label){

	struct node* new_vert = (struct node*) malloc(sizeof(struct node));

	new_vert->properties = map_init();
	put_node_property(new_vert, "label", label);

	map_put(g->vertices, label, new_vert);

	return new_vert;

}

struct node* query_vertex(struct graph* g, char* label){

	return map_get(g->vertices, label);

}

int delete_vertex(struct graph* g, char* label){

	return map_del(g->vertices, label);

}

void put_node_property(struct node* v, char* key, void* val){

	map_put(v->properties, key, val);

}

void* get_node_property(struct node* v, char* key){

	return map_get(v->properties, key);

}

int main(){

	struct graph* g = init_graph();

	struct node* omaha = insert_vertex(g, "omaha");

	struct node* queried = query_vertex(g, "omaha");

	printf("%p %s %p %s\n",
		omaha, (char*) get_node_property(omaha, "label"),
		queried, (char*) get_node_property(queried, "label"));

	int res = delete_vertex(g, "omaha");

	printf("%d\n", res);

	return 0;

}

