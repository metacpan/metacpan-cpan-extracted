#! perl

use warnings;
use strict;
use WiX3::XML::Fragment;

print WiX3::XML::Fragment->new(id => 'TestID')->as_string();
