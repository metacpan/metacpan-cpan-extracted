package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Meta;

diag 'Modules required for author testing';

note 'This list is just the optional modules, and needs filling out.';

require_ok $_ for My::Module::Meta->optional_modules();

done_testing;

1;

# ex: set textwidth=72 :
