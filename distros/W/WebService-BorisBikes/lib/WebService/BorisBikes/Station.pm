package WebService::BorisBikes::Station;

use strict;
use warnings;

use base qw(Class::Accessor);

our @station_fields = ( 
     qw/id 
        name 
        terminalName 
        lat 
        long 
        installed 
        locked 
        installDate 
        temporary 
        nbBikes 
        nbEmptyDocks 
        nbDocks/ 
);

WebService::BorisBikes::Station->follow_best_practice;
WebService::BorisBikes::Station->mk_accessors(@station_fields);

1;
