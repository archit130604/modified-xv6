// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
    struct run *next;
};

struct
{
    struct spinlock lock;
    struct run *freelist;
} kmem;
struct spinlock lock_for_the_arr_of_ref;
int arr_of_ref[PGROUNDUP(PHYSTOP) >> PGSHIFT];
void kinit()
{
    initlock(&kmem.lock, "kmem");
    initlock(&lock_for_the_arr_of_ref, "arr_of_ref");
    acquire(&lock_for_the_arr_of_ref);
    for (int i = 0; i < (PGROUNDUP(PHYSTOP) >> PGSHIFT); i++)
    {

        arr_of_ref[i] = 0;
    }
    release(&lock_for_the_arr_of_ref);
    freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
    char *p;
    p = (char *)PGROUNDUP((uint64)pa_start);
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
        acquire(&lock_for_the_arr_of_ref);
        arr_of_ref[(uint64)p >> PGSHIFT]++;
        release(&lock_for_the_arr_of_ref);
        kfree(p);
    }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree");
    int flag1=0;
    acquire(&lock_for_the_arr_of_ref);
    arr_of_ref[(uint64)pa >> PGSHIFT]--;
    if (arr_of_ref[(uint64)pa >> PGSHIFT] < 0)
    {
        panic("kfree in ref_cont");
    }
    flag1=arr_of_ref[(uint64)pa >> PGSHIFT];
    release(&lock_for_the_arr_of_ref);
    // Fill with junk to catch dangling refs.
    if (flag1)
    {
        return;
    }
    
    memset(pa, 1, PGSIZE);

    r = (struct run *)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    struct run *r;

    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r)
        kmem.freelist = r->next;
    release(&kmem.lock);

    if (r)
    {
        memset((char *)r, 5, PGSIZE); // fill with junk
        acquire(&lock_for_the_arr_of_ref);
        arr_of_ref[(uint64)r >> PGSHIFT]++;
        release(&lock_for_the_arr_of_ref);
    }
    return (void *)r;
}
