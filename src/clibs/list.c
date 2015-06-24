
#include <stdlib.h>
#include <stdio.h>

#include "list.h"



struct list* list_init(){

	struct list* ret = (struct list*) malloc(sizeof(struct list));
	ret->size = 0;
	ret->head = NULL;
	ret->tail = NULL;

	return ret;
}

void list_add(struct list* l, void* data){

	struct list_entry* new_ent =
		(struct list_entry*) malloc(sizeof(struct list_entry));

	new_ent->data = data;
	new_ent->next = NULL;

	// empty list
	if(l->size == 0){
		l->head = new_ent;
		l->tail = new_ent;
	}

	// list has things
	else{
		l->tail->next = new_ent;

		l->tail = new_ent;
	}

	(l->size)++;

}

int check_boundaries(struct list* l, int i){
	return i >= 0 && i < l->size;
}

void* list_get(struct list* l, double index){

	int i = (int) index;

	if(!check_boundaries(l, i)){
		return NULL;
	}

	struct list_entry* ptr = l->head;

	void* ret = NULL;

	int j;
	for(j=0; j<i; j++){
		ptr = ptr->next;
	}

	return ptr->data;

}

int list_set(struct list* l, void* data, double index){

	int i = (int) index;

	if(!check_boundaries(l, i)){
		return 0;
	}

	struct list_entry* ptr = l->head;

	int j;
	for(j=0; j<i; j++){
		ptr = ptr->next;
	}

	ptr->data = data;

	return 1;

}

int list_remove(struct list* l, double index){

	int i = (int) index;

	if(!check_boundaries(l, i)){
		return 0;
	}

	struct list_entry* ptr = l->head, *prev;

	int j;
	for(j=0; j<i; j++){
		prev = ptr;
		ptr = ptr->next;
	}

	if(l->size == 1){

		l->head = NULL;
		l->tail = NULL;
		free(ptr);
	}

	else if(ptr == l->head){

		l->head = ptr->next;

		free(ptr);
	}

	else if(ptr == l->tail){

		l->tail = prev;
		prev->next = NULL;

		free(ptr);
	}

	else{

		prev->next = ptr->next;

		free(ptr);
	}

	(l->size)--;

	return 1;
}

int list_length(struct list* l){

	return l->size;
}

void list_destroy(struct list* l){

	while(l->size > 0){
		list_remove(l, 0);
	}

	free(l);
}

// int main(){

// 	struct list* mylist = list_init();

// 	int thing = 8;
// 	list_add(mylist, &thing);

// 	int thing2 = 9;
// 	list_add(mylist, &thing2);

// 	int thinggetted = *((int*) list_get(mylist, 0));

// 	printf("%d %d\n", thinggetted, list_length(mylist));

// 	int thing3 = 42;
// 	list_add(mylist, &thing3);

// 	printf("%d\n", list_length(mylist));

// 	list_remove(mylist, 1);

// 	int thinggetted2 = *((int*) list_get(mylist, 1));	

// 	printf("%d %d\n", thinggetted2, list_length(mylist));

// 	list_destroy(mylist);

// 	printf("list destroyed\n");

// 	return 0;
// }

