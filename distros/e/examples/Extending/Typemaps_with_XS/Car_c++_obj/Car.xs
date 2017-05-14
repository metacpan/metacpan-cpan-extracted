extern "C" {
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include  <memory.h>
#include <stdio.h>
}
static int global_car_id = 0;

class Car {
public:
   int id;
   Car () {id = ++global_car_id;}
   void  drive() {
      printf ("Car %d driven\n", id);
   }
};

MODULE = Car PACKAGE = Car

Car*
Car::new ()

void
Car::drive()

void
Car::DESTROY()