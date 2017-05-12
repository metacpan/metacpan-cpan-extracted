#!perl

use 5.10.0;
use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use WebService::UINames;


my $uinames = WebService::UINames->new;
#say Dumper $uinames->get_name;

say Dumper $uinames->get_name( 
  gender => 'female', region => 'brazil' 
);

