#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
// #include "proc.h"
#include "spinlock.h"
// int scheduler_type=0;
// struct queue
// {
//     struct proc *proc;
//     struct queue *next;
// };
// struct mlfq1
// {
//     struct queue *q0;
//     struct queue *q1;
//     struct queue *q2;
//     struct queue *q3;
// };
// void enqueue(struct proc *p, struct queue **q)
// {
//     struct queue *new = (struct queue *)kalloc();
//     new->proc = p;
//     new->next = 0;
//     if (*q == 0)
//     {
//         *q = new;
//     }
//     else
//     {
//         struct queue *temp = *q;
//         while (temp->next != 0)
//         {
//             temp = temp->next;
//         }
//         temp->next = new;
//     }
// }
// struct proc *dequeue(struct queue **q)
// {
//     if (*q == 0)
//     {
//         return 0;
//     }
//     else
//     {
//         struct proc *p = (*q)->proc;
//         *q = (*q)->next;
//         return p;
//     }
// }
// struct mlfq1 mlfq;
volatile static int started = 0;
int count_to_read=0;
struct mlfq mlfq1;
// struct mlfq mlfq_arr1;
// count_to_read = 0;
// start() jumps here in supervisor mode on all CPUs.
// struct mlfq mlfq1;
void
main()
{
    mlfq1.queue0=0;
    mlfq1.queue1=0;
    mlfq1.queue2=0;
    mlfq1.queue3=0;
    // mlfq_arr1.queue0.max_size=NPROC;
    // mlfq_arr1.queue0.curr_size=0;
    // mlfq_arr1.queue0.front=0;
    // mlfq_arr1.queue0.rear=-1;
    // mlfq_arr1.queue1.max_size=NPROC;
    // mlfq_arr1.queue1.curr_size=0;
    // mlfq_arr1.queue1.front=0;
    // mlfq_arr1.queue1.rear=-1;
    // mlfq_arr1.queue2.max_size=NPROC;
    // mlfq_arr1.queue2.curr_size=0;
    // mlfq_arr1.queue2.front=0;
    // mlfq_arr1.queue2.rear=-1;
    // mlfq_arr1.queue3.max_size=NPROC;
    // mlfq_arr1.queue3.curr_size=0;
    // mlfq_arr1.queue3.front=0;
    // mlfq_arr1.queue3.rear=-1;
  if(cpuid() == 0){
    consoleinit();
    printfinit();
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("\n");
    kinit();         // physical page allocator
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging
    procinit();      // process table
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    binit();         // buffer cache
    iinit();         // inode table
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
      ;
    __sync_synchronize();
    printf("hart %d starting\n", cpuid());
    kvminithart();    // turn on paging
    trapinithart();   // install kernel trap vector
    plicinithart();   // ask PLIC for device interrupts
  }

  scheduler();        
}
