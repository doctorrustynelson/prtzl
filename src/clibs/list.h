
// linked list data structure
struct list{

	int size;
	struct list_entry* head;
	struct list_entry* tail;
};

// entry of the linked list
struct list_entry{

	void* data;
	struct list_entry* next;
};

struct list* list_init();

// add to end of list
void list_add(struct list*, void*);

// get specified index
// boundaries checked
// returns NULL if out of bounds
void* list_get(struct list*, double);

// sets specified index
// boundaries checked
// returns 1 if successful
int list_set(struct list*, void*, double);

// attempt to remove index
// return 1 if successful
int list_remove(struct list*, double);

// get the list length
int list_length(struct list*);

// destroy the list
void list_destroy(struct list*);
