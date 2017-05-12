use warnings;
use strict;

use Inline (
    C => 'DATA', 
    libs => '-lpthread', 
    CLEAN_AFTER_BUILD => 0
);

my $x = 20;

create_thread('blah');

print "after callback, $x\n";

sub blah {
    print "perl callback\n";
}

__DATA__
__C__

#include <stdio.h>
#include <pthread.h>
#include <unistd.h>

PerlInterpreter *saved;

void *wrapper(void *sub_name_ptr){
    char *sub_name = (char *)sub_name_ptr;

    printf("threaded ok, sub: %s\n", sub_name);
    
    PERL_SET_CONTEXT(saved);
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;

        int i;
        for (i=0; i<3; i++){
            // if (access("lock", F_OK) != -1){
            if (access("lock", F_OK) == -1){
                call_pv(sub_name, G_DISCARD|G_NOARGS);
            }
            else {
                printf("no trigger\n");
            }
            sleep(2);
        }
        FREETMPS;
        LEAVE;
    }
}

int create_thread(char *subname){   
    saved = Perl_get_context();
    pthread_t sub_thread;
   
    if(pthread_create(&sub_thread, NULL, wrapper, subname)) {
        fprintf(stderr, "Error creating thread\n");
        return 1;
    }
    
    if(pthread_join(sub_thread, NULL)) {
        fprintf(stderr, "Error joining thread\n");
        return 2;
    }

    return 0;
}
