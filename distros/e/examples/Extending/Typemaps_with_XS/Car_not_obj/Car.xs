#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include  <memory.h>
#include <stdio.h>

static int global_car_id = 0;

typedef struct {
   int id;
} Car;

Car*  
new_car() 
{
    Car *c = malloc(sizeof(Car));
    c->id = ++global_car_id;
    printf ("Car %d created\n", c->id);
    return c;
}

void  drive(Car *c) {
    printf ("Car %d driven\n", c->id);
}

MODULE = Car PACKAGE = Car

Car *
new_car ()

void
drive (car)
    Car*   car
