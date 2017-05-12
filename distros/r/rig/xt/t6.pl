package rig::task::bmoose;
sub rig_run { 
    { bmoose => [ 'Moose' ] }
}

package Joo;
#use sugar ":base";
use rig ':bmoose';

has 'aa' => is=>'rw', isa=>'Str';


1;

