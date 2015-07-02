
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "prtzl.h"


struct graph* init_graph(){

	struct graph* ret = (struct graph*) malloc(sizeof(struct graph));
	ret->vertices = map_init();

	return ret;

}

struct node* _init_vertex(char* label){

	struct node* ret = (struct node*) malloc(sizeof(struct node));

	ret->properties = map_init();
	put_node_property(ret, "label", label);

	struct list* in = list_init();
	struct list* out = list_init();

	double* in_degree = (double*) malloc(sizeof(double));
	*in_degree = 0;

	double* out_degree = (double*) malloc(sizeof(double));
	*out_degree = 0;

	put_node_property(ret, "in", in);
	put_node_property(ret, "out", out);
	put_node_property(ret, "in_degree", in_degree);
	put_node_property(ret, "out_degree", out_degree);

	return ret;
}

struct node* insert_vertex(struct graph* g, char* label){

	struct node* new_vert = _init_vertex(label);

	map_put(g->vertices, label, new_vert);

	return new_vert;

}

struct node* query_vertex(struct graph* g, char* label){

	return map_get(g->vertices, label);

}

struct node* _destroy_vertex(){
	//TODO fix big memory leaks from node property map
}

double delete_vertex(struct graph* g, char* label){

	return (double) map_del(g->vertices, label);

}

void put_node_property(struct node* v, char* key, void* val){

	map_put(v->properties, key, val);

}

void* get_node_property(struct node* v, char* key){

	return map_get(v->properties, key);

}

struct node* _init_edge(struct node* src, struct node* dest, double weight){

	struct node* ret = (struct node*) malloc(sizeof(struct node));
	ret->properties = map_init();

	put_node_property(ret, "src", src);
	put_node_property(ret, "dest", dest);

	double* w = (double*) malloc(sizeof(double));
	*w = weight;
	put_node_property(ret, "weight", w);

	return ret;

}

double link(struct node* src, struct node* dest, double weight){

	struct node* new_edge = _init_edge(src, dest, weight);

	struct list* src_out = get_node_property(src, "out");
	list_add(src_out, new_edge);

	double* src_out_deg = get_node_property(src, "out_degree");
	(*src_out_deg)++;

	struct list* dest_in = get_node_property(dest, "in");
	list_add(dest_in, new_edge);

	double* dest_in_deg = get_node_property(dest, "in_degree");
	(*dest_in_deg)++;

	return 1;

}

double bi_link(struct node* src, struct node* dest, double weight){

	link(src, dest, weight);
	link(dest, src, weight);

	return 1;

}

void print_number(double n){

	printf("%lf\n", n);
}

void print_string(char* s){

	printf("%s\n", s);
}

void print_vertex(struct node* v){

	printf("%s: %.0lf edge(s) in %.0lf edge(s) out\n",
		(char*) get_node_property(v, "label"),
		*((double*) get_node_property(v, "in_degree")),
		*((double*) get_node_property(v, "out_degree")));

}

void print_edge(struct node* e){

	printf("src: %s dest: %s weight: %lf\n",
		(char*) get_node_property(get_node_property(e, "src"), "label"),
		(char*) get_node_property(get_node_property(e, "dest"), "label"),
		*((double*) get_node_property(e, "weight")));

}

char* cat(char* a, char* b){

	int len = strlen(a) + strlen(b) + 2;
	char* ret = (char*) malloc(sizeof(char) * len);
	sprintf(ret,"%s%s", a, b);

	return ret;
}

double cmp(char* a, char* b){

	if(a == NULL || b == NULL){
		return 0;
	}

	int res = strcmp(a, b);

	if(res == 0){
		return 1;
	}
	else{
		return 0;
	}

}
