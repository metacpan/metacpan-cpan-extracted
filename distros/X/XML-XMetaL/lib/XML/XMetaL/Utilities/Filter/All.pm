package XML::XMetaL::Utilities::Filter::All;

use base 'XML::XMetaL::Utilities::Filter::Base';

use strict;
use warnings;

use Carp;

use XML::XMetaL::Utilities qw(:dom_node_types);

use constant TRUE  => 1;
use constant FALSE => 0;

# Constructor is in super class

sub accept {TRUE;}

1;