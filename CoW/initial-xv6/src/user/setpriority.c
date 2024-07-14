#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// Reference: https://cs631.cs.usfca.edu/guides/adding-a-syscall-to-xv6

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Usage: setpriority pid priority\n");
        exit(1);
    }
    int pid = atoi(argv[1]);
    int priority = atoi(argv[2]);
    int old_priority = set_priority(pid, priority);
    if (old_priority == -1)
    {
        printf("Invalid priority\nIt Should be between 0 and 100\n");
    }
    else if (old_priority == -2)
    {
        printf("Invalid pid\n");
    }
    else
    {
        printf("Old priority of process with pid %d is %d\n", pid, old_priority);
    }
    exit(0);
}