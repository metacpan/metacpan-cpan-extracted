# $Id: classes.t 147 2008-03-08 16:04:33Z rmuhle $

# unit tests are in the order the code appears in classes.pm
# without any particular organization beyond that, seemed easiest
# approach to get full test coverage

no strict;
no warnings;

use Test::More tests => 14;
use_ok 'classes';

can_ok 'classes', 'classes';
can_ok 'classes', 'import';
can_ok 'classes', 'define';

can_ok 'classes', 'new_only';
can_ok 'classes', 'new_init';
can_ok 'classes', 'new_fast';
can_ok 'classes', 'init_args';
can_ok 'classes', 'clone';
can_ok 'classes', 'load';
can_ok 'classes', 'dump';
can_ok 'classes', 'set';
can_ok 'classes', 'get';

like classes::PERL_VERSION(), qr/\d/o,
    'classes::PERL_VERSION = '.classes::PERL_VERSION();
