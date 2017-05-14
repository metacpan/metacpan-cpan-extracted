#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

int
func_2_args(int a, char *b)
{
    printf("func_2_args received ... \'%d\', \"%s\"\n\n", a, b);
    return 1;
}

int test (int a, char *b, double c) 
{
    /* Called from func_with_keywords */
    printf("func_with_keywords called test \n");
    return 1;
}

MODULE = Test PACKAGE = Test

int
func_2_args(a, b)
   int    a
   char*  b


int
func_with_keywords(a, b)
    int    a
    char*  b
  PREINIT:
    double c;
  INIT:
    c = a * 20.3;
  CODE:
    if (c > 50) {
        RETVAL = test(a,b,c);
    }
  OUTPUT:
    RETVAL
   
         
     

