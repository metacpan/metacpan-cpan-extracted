package t::lib::Car;

use strict;
use warnings;

use YAWF::Object::MongoDB (collection => 'Y_O_M_Test_Cars',
				 keys => ['color','brand','model','price']);

our @ISA = ('YAWF::Object::MongoDB');

1;
