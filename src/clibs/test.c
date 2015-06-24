
// build with
//  gcc test.c prtzl.c map.c list.c

// we want to include at least these headers in all our compiled programs
#include <stdio.h> //printf

#include "prtzl.h" //prtzl lib

int main(){

	//implicit graph construction
	struct graph* g = init_graph();

	printf("graph init\n");

	// Vertex omaha = <+ "omaha" +>;
	struct node* omaha = insert_vertex(g, "omaha");

	printf("omaha inserted\n");

	// Vertex queried = <? "omaha" ?>;
	struct node* queried = query_vertex(g, "omaha");

	printf("%p %s %p %s\n",
		omaha, (char*) get_node_property(omaha, "label"),
		queried, (char*) get_node_property(queried, "label"));

	// Number deg = omaha.out_degree;
	double deg = *((double*) get_node_property(omaha, "out_degree"));
	printf("%lf degree\n", deg);

	// Vertex kansas_city = <+ "kansas city" +>;
	struct node* kansas_city = insert_vertex(g, "kansas city");

	printf("kansas city added\n");

	// weighted_bi_link(omaha, kansas_city, 302.1);
	bi_link(omaha, kansas_city, 302.1);

	printf("linked\n");

	// deg = omaha.out_degree;
	deg = *((double*) get_node_property(omaha, "out_degree"));
	printf("%lf degree\n", deg);	

	// get the edge from neighbor list
	// follow it to get the dest
	// Vertex dest = omaha.out[0].dest;
	struct list* omlist = get_node_property(omaha, "out");
	struct node* edge = list_get(omlist, 0);
	struct node* dest = get_node_property(edge, "dest");

	// get the label property from dest
	// dest.label
	printf("%s\n", (char*)
		get_node_property(dest, "label"));

	int res = delete_vertex(g, "omaha");

	printf("%d\n", res);

	return 0;

}