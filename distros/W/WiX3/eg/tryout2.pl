#! perl

use warnings;
use strict;
use WiX3::XML::Fragment;
use WiX3::XML::CreateFolder;

my $cf = WiX3::XML::CreateFolder->new();
my $frag = WiX3::XML::Fragment->new(id => 'TestID');
$frag->add_child_tag($cf);
print $frag->as_string();
