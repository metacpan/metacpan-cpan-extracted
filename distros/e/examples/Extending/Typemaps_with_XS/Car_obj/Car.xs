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
    Car *car = malloc(sizeof(Car));
    car->id = ++global_car_id;
    printf ("Car %d created\n", car->id);
    return car;
}

void 
drive(Car *car) {
    printf ("Car %d driven\n", car->id);
}

void
delete_car (Car *car) {
    printf ("Car %d junked\n", car->id);
    free(car);
}

MODULE = Car PACKAGE = Car


Car *
new (CLASS)
    char *CLASS
   CODE:
     RETVAL = new_car();
   OUTPUT:
     RETVAL

void
drive (car)
    Car*   car

void
DESTROY(car)
    Car *car
  CODE:
    delete_car(car); /* deallocate that object */
