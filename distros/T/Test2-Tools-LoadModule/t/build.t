package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Test2::Tools::LoadModule';
BEGIN {
    # The above loaded our module but did not import
    CLASS->import( ':private' );
}

use constant R => { require => 1 };

is __build_load_eval( 'Fubar' ),
    'use Fubar;',
    'Module name only, use() semantics';

is __build_load_eval( Smart => 86 ),
    'use Smart 86;',
    'Module and version, use() semantics';

is __build_load_eval( Nemo => undef, [] ),
    'use Nemo ();',
    'Module and empty import list, use() semantics';

is __build_load_eval( Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp };',
    'Module and explicit import list, use() semantics';

is __build_load_eval( Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur };',
    'Module, version, and explicit export list, use() semantics';

is __build_load_eval( R, 'Fubar' ),
    'use Fubar ();',
    'Module name only, require() semantics';

is __build_load_eval( R, Smart => 86 ),
    'use Smart 86 ();',
    'Module and version, require() semantics';

is __build_load_eval( R, Nemo => undef, [] ),
    'use Nemo;',
    'Module and empty import list, require() semantics';

is __build_load_eval( R,
	Howard => undef, [ qw{ larry moe shemp } ] ),
    'use Howard qw{ larry moe shemp };',
    'Module and explicit import list, require() semantics';

is __build_load_eval( R,
	Dent => 42, [ qw{ Arthur } ] ),
    'use Dent 42 qw{ Arthur };',
    'Module, version, and explicit export list, require() semantics';

done_testing;

1;

# ex: set textwidth=72 :
