use strict;
use warnings;
use Test::More skip_all => "Can't test all without all modules";

use Module::Find;

my @fields = Module::Find::findsubmod Form::Processor::Field;

plan tests => @fields + 1;

use_ok( 'Form::Processor' );

use_ok( $_ ) for @fields;
