

#define MAP_BUCKETS 8

// hash map data structure
struct map{
	int size;
	struct map_entry** buckets;
};

// contains a key value entry in the map
struct map_entry{
	char* key;
	void* value;
	struct map_entry* next;
};

// initializes an empty map
struct map* map_init();

// add a key to the map, if the key exists, the current value
// is overwritten
void map_put(struct map*, char*, void* );

// gets a key from the map, if the key does not exists returns NULL
void* map_get(struct map*, char*);

// delete a key from the map, returns 1 if successful
int map_del(struct map*, char*);

// destroys the map
// using the map after destroy is undefined behavior
void map_destroy(struct map*);
