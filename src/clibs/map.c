
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "map.h"

int hash(char* key){
	return (strlen(key) * 17) % MAP_BUCKETS;
}

struct map* map_init(){

	struct map* ret = (struct map*) malloc(sizeof(struct map));

	ret->size = 0;

	ret->buckets = (struct map_entry**) malloc(sizeof(struct map_entry**) * MAP_BUCKETS);

	int i;
	for(i=0; i<MAP_BUCKETS; i++){
		ret->buckets[i] = NULL;
	}

	return ret;

}

void map_put(struct map* m, char* key, void* value){

	//remove existing key first
	map_del(m, key);

	int hashd = hash(key);

	struct map_entry* new_entry = (struct map_entry*) malloc(sizeof(struct map_entry));

	new_entry->key = key;
	new_entry->value = value;
	new_entry->next = NULL;

	struct map_entry* ptr = m->buckets[hashd];

	//empty bucket
	if(ptr == NULL){

		m->buckets[hashd] = new_entry;
		
	}

	else{

		while(ptr->next != NULL){
			ptr = ptr-> next;
		}

		ptr->next = new_entry;

	}

	(m->size)++;

}

void* map_get(struct map* m, char* key){

	int hashd = hash(key);

	struct map_entry* ptr = m->buckets[hashd];

	struct map_entry* ret = NULL;

	// key is not in the map, as key's bucket is empty
	if(ptr == NULL){

		return NULL;
	}
	//iterate bucket, try to find key
	else{

		do{

			// keys are same
			if(strcmp(key, ptr->key) == 0){
				ret = ptr;
				break;
			}

			ptr = ptr->next;

		} while(ptr != NULL);
	}

	return (ret == NULL) ? NULL : ret->value;

}

int map_del(struct map* m, char* key){

	int ret = 0;

	int hashd = hash(key);

	struct map_entry* ptr = m->buckets[hashd], *last = NULL;

	//iterate bucket, try to find key
	if(ptr != NULL){

		do{

			// keys are same
			if(strcmp(key, ptr->key) == 0){
				
				//perform the break;
				if(last != NULL){
					last->next = ptr->next;
				}
				//this is list head, need to update map struct
				else{
					m->buckets[hashd] = ptr->next;
				}

				free(ptr);

				m-> size--;

				ret = 1;

				break;
			}

			last = ptr;
			ptr = ptr->next;

		} while(ptr != NULL);
	}

	return ret;

}

void map_destroy(struct map* m){

	int i;
	for(i=0; i<MAP_BUCKETS; i++){

		struct map_entry* ptr = m->buckets[i], *tmp;

		if(ptr != NULL){

			do{
				tmp = ptr->next;
				free(ptr);
				ptr = tmp;

			} while(ptr->next != NULL);
		}
	}

	free(m);
}


// int main(){

// 	struct map* mymap = map_init();

// 	int thing = 7;
// 	map_get(mymap, "candy");
// 	map_put(mymap, "candy", &thing);
// 	map_put(mymap, "a", &thing);
// 	map_put(mymap, "b", &thing);
// 	map_put(mymap, "c", &thing);
// 	printf("size %d\n", mymap->size);

// 	int* myval = (int*) map_get(mymap, "candy");
// 	printf("get %d\n", *myval);

// 	int other = 8;
// 	map_put(mymap, "candy", &other);
// 	printf("size %d\n", mymap->size);
// 	myval = (int*) map_get(mymap, "candy");
// 	printf("get %d\n", *myval);


// 	int del = map_del(mymap, "candy");
// 	int del2 = map_del(mymap, "candy");
// 	printf("size %d %d %d\n", mymap->size, del, del2);
// 	printf("contains candy? %d\n", map_get(mymap, "candy") != NULL);

// 	map_destroy(mymap);

// 	printf("destroyed\n");

// 	return 0;
// }