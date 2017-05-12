# $Id: 00-env.t 245 2008-12-04 13:00:40Z aff $

use strict;
use warnings;

use Config;
use Test::More;
use File::Spec::Functions;
use lib catdir qw ( blib lib );

plan tests => 1;
use_ok( 'Test::MockDBI' );
diag( "Testing Test::MockDBI $Test::MockDBI::VERSION, Perl $], $^X, archname=$Config{archname}, byteorder=$Config{byteorder}" );

__END__
