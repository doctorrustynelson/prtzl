

#define MAP_BUCKETS 8

struct map{
	int size;
	struct map_entry** buckets;
};

struct map_entry{
	char* key;
	void* value;
	struct map_entry* next;
};

struct map* map_init();

void map_put(struct map*, char*, void* );

void* map_get(struct map*, char*);

int map_del(struct map*, char*);

void map_destroy(struct map*);