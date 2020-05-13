use Test::More tests => 1;
use Type::Tiny;

use strict;
use warnings;

diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '    Type::Tiny XS backends...' );
diag( '' );
diag( '    use XS    ? ', &Type::Tiny::_USE_XS    ? 'YES': 'NO');
diag( '    use Mouse ? ', &Type::Tiny::_USE_MOUSE ? 'YES': 'NO');
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );
diag( '' );

pass( "Hopefully we will get to know" );

done_testing;
