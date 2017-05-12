#! perl

use warnings;
use strict;
use WiX3::XML::CreateFolder;

print WiX3::XML::CreateFolder->new()->as_string();
