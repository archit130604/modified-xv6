#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
extern struct mlfq mlfq1;
struct spinlock tickslock;
// extern struct proc* prev_proc1;
uint ticks;
int runnable_processes(struct queue *q)
{
    int count = 0;
    // struct proc *p;
    while (q != 0)
    {
        if (q->proc1->state == RUNNABLE)
        {
            count++;
        }
        q = q->next;
    }
    return count;
}
extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
    initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void usertrap(void)
{
    int which_dev = 0;

    if ((r_sstatus() & SSTATUS_SPP) != 0)
        panic("usertrap: not from user mode");

    // send interrupts and exceptions to kerneltrap(),
    // since we're now in the kernel.
    w_stvec((uint64)kernelvec);

    struct proc *p = myproc();

    // save user program counter.
    p->trapframe->epc = r_sepc();

    if (r_scause() == 8)
    {
        // system call

        if (killed(p))
            exit(-1);

        // sepc points to the ecall instruction,
        // but we want to return to the next instruction.
        p->trapframe->epc += 4;

        // an interrupt will change sepc, scause, and sstatus,
        // so enable only now that we're done with those registers.
        intr_on();

        syscall();
    }
    else if ((which_dev = devintr()) != 0)
    {
        // ok
    }
    else
    {
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
        setkilled(p);
    }

    if (killed(p))
        exit(-1);

    // give up the CPU if this is a timer interrupt.
    if (which_dev == 2)
    {
        if (p != 0)
        {
            p->alarm_ticks_passed++;
            // p->ticks_used_MLFQ++;
            if ((p->alarm_called == 1) && (p->alarm_interval > 0))
            {
                if ((p->alarm_ticks_passed == p->alarm_interval))
                {
                    p->alarm_ticks_passed = 0;
                    p->alarm_called = 0;
                    *(p->backup_trapframe) = *(p->trapframe);
                    p->trapframe->epc = p->handler1;
                }
            }
        }
#ifdef RR
        yield();
#endif

#ifdef MLFQ
        if (p != 0)
        {
            p->ticks_used_MLFQ++;
        }
        struct proc *temp_temp;
        for (temp_temp = proc; temp_temp < &proc[NPROC]; temp_temp++)
        {
            if (temp_temp->state == RUNNABLE)
            {
                // temp_temp->wait_ticks++;
                if ((temp_temp) && (temp_temp != p) && ((ticks - temp_temp->wait_ticks) >= 30))
                {
                    temp_temp->wait_ticks = ticks;
                    temp_temp->ticks_used_MLFQ = 0;
                    decrease_priority(temp_temp);
                }
            }
        }

        if (p && (p->priority == 0))
        {
            p->priority++;
            // pop(&mlfq1.queue0);
            // prev_proc1 = 0;
            p->ticks_used_MLFQ = 0;
            remove_from_middle(&mlfq1.queue0, p);
            push(&mlfq1.queue1, p);
            // prev_proc1=p;
            p->wait_ticks = ticks;
            yield();
        }
        else if (p && (p->priority == 1))
        {
            if (p->ticks_used_MLFQ == 3)
            {
                p->priority++;
                p->ticks_used_MLFQ = 0;
                p->wait_ticks = ticks;
                remove_from_middle(&mlfq1.queue1, p);
                push(&mlfq1.queue2, p);
                // p->wait_ticks = 0;
                yield();
            }
            else if (runnable_processes(mlfq1.queue0) > 0)
            {
                p->wait_ticks = ticks;
                // remove_from_middle(&mlfq1.queue1, p);
                // push(&mlfq1.queue1, p);
                yield();
            }
        }
        else if (p && (p->priority == 2))
        {
            if (p->ticks_used_MLFQ == 9)
            {
                p->priority++;

                p->ticks_used_MLFQ = 0;
                // p->wait_ticks = 0;
                remove_from_middle(&mlfq1.queue2, p);
                push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue0) > 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue2, p);
                // push(&mlfq1.queue2, p);
                p->wait_ticks = ticks;
                yield();
            }

            if (runnable_processes(mlfq1.queue1) > 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue2, p);
                // push(&mlfq1.queue2, p);
                p->wait_ticks = ticks;
                yield();
            }
        }
        if (p && (p->priority == 3))
        {
            if (p->ticks_used_MLFQ == 15)
            {
                // p->priority++;
                remove_from_middle(&mlfq1.queue3, p);
                push(&mlfq1.queue3, p);
                p->ticks_used_MLFQ = 0;
                yield();
            }
            if (runnable_processes(mlfq1.queue0) != 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue1) != 0)
            {
                /* code */
                // p->ticks_used_MLFQ = 0;
                // prev_proc1 = p;
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue2) != 0)
            {
                // p->ticks_used_MLFQ = 0;
                // prev_proc1 = p;
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
        }
        if (p == 0)
        {
            yield();
        }

#endif
    }
    usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
    struct proc *p = myproc();

    // we're about to switch the destination of traps from
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    p->trapframe->kernel_trap = (uint64)usertrap;
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
    int which_dev = 0;
    uint64 sepc = r_sepc();
    uint64 sstatus = r_sstatus();
    uint64 scause = r_scause();

    if ((sstatus & SSTATUS_SPP) == 0)
        panic("kerneltrap: not from supervisor mode");
    if (intr_get() != 0)
        panic("kerneltrap: interrupts enabled");

    if ((which_dev = devintr()) == 0)
    {
        printf("scause %p\n", scause);
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
        panic("kerneltrap");
    }

    // give up the CPU if this is a timer interrupt.
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    {
#ifdef RR
        yield();
#endif
#ifdef MLFQ
        struct proc *p = myproc();
        if (p != 0)
        {
            p->ticks_used_MLFQ++;
        }
        struct proc *temp_temp;
        for (temp_temp = proc; temp_temp < &proc[NPROC]; temp_temp++)
        {
            if (temp_temp->state == RUNNABLE)
            {
                // temp_temp->wait_ticks++;
                if ((temp_temp) &&(temp_temp != p) && ((ticks-temp_temp->wait_ticks) >= 30))
                {
                    temp_temp->wait_ticks = ticks;
                    temp_temp->ticks_used_MLFQ = 0;
                    decrease_priority(temp_temp);
                }
            }
        }

        if (p && (p->priority == 0))
        {
            p->priority++;
            // pop(&mlfq1.queue0);
            // prev_proc1 = 0;
            p->ticks_used_MLFQ = 0;
            remove_from_middle(&mlfq1.queue0, p);
            push(&mlfq1.queue1, p);
            // prev_proc1=p;
            p->wait_ticks = ticks;
            yield();
        }
        else if (p && (p->priority == 1))
        {
            if (p->ticks_used_MLFQ == 3)
            {
                p->priority++;
                p->ticks_used_MLFQ = 0;
                p->wait_ticks = ticks;
                remove_from_middle(&mlfq1.queue1, p);
                push(&mlfq1.queue2, p);
                // p->wait_ticks = 0;
                yield();
            }
            else if (runnable_processes(mlfq1.queue0) > 0)
            {
                p->wait_ticks = ticks;
                // remove_from_middle(&mlfq1.queue1, p);
                // push(&mlfq1.queue1, p);
                yield();
            }
        }
        else if (p && (p->priority == 2))
        {
            if (p->ticks_used_MLFQ == 9)
            {
                p->priority++;

                p->ticks_used_MLFQ = 0;
                // p->wait_ticks = 0;
                remove_from_middle(&mlfq1.queue2, p);
                push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue0) > 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue2, p);
                // push(&mlfq1.queue2, p);
                p->wait_ticks = ticks;
                yield();
            }

            if (runnable_processes(mlfq1.queue1) > 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue2, p);
                // push(&mlfq1.queue2, p);
                p->wait_ticks = ticks;
                yield();
            }
        }
        if (p && (p->priority == 3))
        {
            if (p->ticks_used_MLFQ == 15)
            {
                // p->priority++;
                remove_from_middle(&mlfq1.queue3, p);
                push(&mlfq1.queue3, p);
                p->ticks_used_MLFQ = 0;
                yield();
            }
            if (runnable_processes(mlfq1.queue0) != 0)
            {
                /* code */
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue1) != 0)
            {
                /* code */
                // p->ticks_used_MLFQ = 0;
                // prev_proc1 = p;
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
            if (runnable_processes(mlfq1.queue2) != 0)
            {
                // p->ticks_used_MLFQ = 0;
                // prev_proc1 = p;
                // remove_from_middle(&mlfq1.queue3, p);
                // push(&mlfq1.queue3, p);
                p->wait_ticks = ticks;
                yield();
            }
        }
        if (p == 0)
        {
            yield();
        }
#endif
    }
    // the yield() may have caused some traps to occur,
    // so restore trap registers for use by kernelvec.S's sepc instruction.
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    acquire(&tickslock);
    ticks++;
    update_time();
    // for (struct proc *p = proc; p < &proc[NPROC]; p++)
    // {
    //   acquire(&p->lock);
    //   if (p->state == RUNNING)
    //   {
    //     printf("here");
    //     p->rtime++;
    //   }
    //   // if (p->state == SLEEPING)
    //   // {
    //   //   p->wtime++;
    //   // }
    //   release(&p->lock);
    // }
    wakeup(&ticks);
    release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    uint64 scause = r_scause();

    if ((scause & 0x8000000000000000L) &&
        (scause & 0xff) == 9)
    {
        // this is a supervisor external interrupt, via PLIC.

        // irq indicates which device interrupted.
        int irq = plic_claim();

        if (irq == UART0_IRQ)
        {
            uartintr();
        }
        else if (irq == VIRTIO0_IRQ)
        {
            virtio_disk_intr();
        }
        else if (irq)
        {
            printf("unexpected interrupt irq=%d\n", irq);
        }

        // the PLIC allows each device to raise at most one
        // interrupt at a time; tell the PLIC the device is
        // now allowed to interrupt again.
        if (irq)
            plic_complete(irq);

        return 1;
    }
    else if (scause == 0x8000000000000001L)
    {
        // software interrupt from a machine-mode timer interrupt,
        // forwarded by timervec in kernelvec.S.

        if (cpuid() == 0)
        {
            clockintr();
        }

        // acknowledge the software interrupt by clearing
        // the SSIP bit in sip.
        w_sip(r_sip() & ~2);

        return 2;
    }
    else
    {
        return 0;
    }
}
