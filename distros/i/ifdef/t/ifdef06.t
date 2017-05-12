
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ('../lib','.');
    }
}

use Test::More tests => 6;
use strict;
use warnings;
use overload; # just need any core modules that's not loaded already

ok( open( my $handle,'>testfile' ),"Failed creating testfile: $!" );
print $handle <<'EOD';
use overload;
print $INC[0]->( 'overload.pm' );
EOD
ok( close( $handle ),"Check if flushing testfile ok" );

ok( open( $handle,"$^X -Ilib -Mifdef testfile |" ),"Failed creating pipe: $!" );
is( scalar( <$handle> ),$INC{'overload.pm'},"Check if same file found" );
ok( close( $handle ),"Check if flushing pipe ok" );

ok( unlink( 'testfile' ),"Check if cleanup ok" );
1 while unlink 'testfile';
