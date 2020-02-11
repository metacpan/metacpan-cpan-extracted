use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Text::Wrap';	# TODO insert your module name
use Test2::Plugin::BailOnFail;	# Abort entire test run on first failure
use Test2::Tools::LoadModule;

# TODO modify or remove import list as appropriate.
load_module_ok CLASS, undef, [ qw{ wrap fill $columns $huge } ];

# TODO modify to suit, or remove if nothing exported.
imported_ok qw{ wrap fill $columns $huge };

# TODO below here is specific to the module or package being tested.
# Modify to suit.

# NOTE the $columns export is not available at compile time, so we have
# to use the fully-qualified variable name. To make it available at
# compile time, wrap use_module_ok() in a BEGIN { } block.
$Text::Wrap::columns = 16;

# NOTE that the wrap() export is usable PROVIDED we do not need its
# attributes or prototype at compile time.
is wrap( '', '    ', 'There was a young lady from Munich' ),
"There was a
    young lady
    from Munich",
    'Wrap some text';

done_testing;

# ex: set textwidth=72 :
