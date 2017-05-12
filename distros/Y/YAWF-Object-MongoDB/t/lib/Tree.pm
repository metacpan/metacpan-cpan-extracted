package t::lib::Tree;

use strict;
use warnings;

use YAWF::Object::MongoDB (collection => 'Y_O_M_Test_Forest',
				 keys => {color => 1,
				          root => ['branch','twig']});

our @ISA = ('YAWF::Object::MongoDB');

1;
