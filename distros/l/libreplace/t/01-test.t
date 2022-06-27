use Test::More tests => 1;

BEGIN { $ENV{PERL5LIB} = 'foo:bar:baz' }

use libreplace;

is_deeply( \@INC, [qw/foo bar baz/], 'lib set properly' );
