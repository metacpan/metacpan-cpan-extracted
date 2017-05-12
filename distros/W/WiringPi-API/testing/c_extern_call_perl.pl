use warnings;
use strict;

use Inline ('C' => 'DATA', libs => '-lwiringPi');

init();
setInterrupt(27, 3);

# direct call

callback();

# on() triggers the external function and sends
# it the callback

on(27);

sub p_callback {
    print "in perl callback\n";
}

__DATA__
__C__

#include <stdlib.h>
#include <stdio.h>
#include <wiringPi.h>

void init();
void on(int pin);
void off(int pin);
void setInterrupt(int pin, int edge);
void callback();

void init(){
    printf("in init\n");
    wiringPiSetup();
}
void on(int pin){
    pinMode(pin, 1);
    digitalWrite(pin, 1);
}

void off(int pin){
    digitalWrite(pin, 0);
    pinMode(pin, 0);
}

void callback(){
    int a = 10;
    int b = 20;
    dSP;

/*    
    ENTER;

    SAVETMPS;

    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newSViv(a)));
    XPUSHs(sv_2mortal(newSViv(b)));
    PUTBACK;
    call_pv("p_callback", G_DISCARD|G_NOARGS);

    SPAGAIN;

    printf("%d to the %dth power is %d.\n", a, b, POPi);

    PUTBACK;
    FREETMPS;
    LEAVE;
*/
}

//void callback(){
//    dSP;
//    PUSHMARK(SP);
//    PUTBACK;
//    FREETMPS;                       /* free that return value        */
//    LEAVE;         
//
//    call_pv("p_callback", G_DISCARD|G_NOARGS);
//}

void setInterrupt(int pin, int edge){
    wiringPiISR(pin, edge, &callback);
}
