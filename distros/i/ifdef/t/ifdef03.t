
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ('../lib','.');
    }
}

use Test::More tests => 55;
use strict;
use warnings;

ok( open( my $handle,'>script' ),"Create script: $!" );
print $handle <<'EOD';

my $foo = 'foo';
print "before sections: $foo\n";

=foo DEBUGGING

This is foo documentation

=begin DEBUGGING

my $foo = 'bar';
print "within debugging: $foo\n";

=begin VERBOSE

my $foo = 'baz';
print "within verbose: $foo\n";

=end

More foo documentation

=cut
print "after sections: $foo\n";
EOD
ok( close( $handle ),"Close script: $! " );

#**********************************
do_tests();
#**********************************

ok( open( $handle,'>script' ),"Create script: $!" );
print $handle <<'EOD';
use Foo;
EOD
ok( close( $handle ),"Close script: $! " );

ok( open( $handle,'>Foo.pm' ),"Create module: $!" );
print $handle <<'EOD';
package Foo;

my $foo = 'foo';
print "before sections: $foo\n";

=foo DEBUGGING

This is foo documentation

=begin DEBUGGING

my $foo = 'bar';
print "within debugging: $foo\n";

=begin VERBOSE

my $foo = 'baz';
print "within verbose: $foo\n";

=end

More foo documentation

=cut
print "after sections: $foo\n";
EOD
ok( close( $handle ),"Close module: $! " );

#**********************************
do_tests();
#**********************************

is( unlink( qw(script Foo.pm) ),'2',"Check unlinking of temp files" );
1 while unlink qw(script Foo.pm); # multi-versioned file systems

#-------------------------------------------------------------------------
sub do_tests {

    local $/;
    ok( open( $handle,"$^X -I$INC[-1] script |" ),
     "Open pipe: $! " );
    is( <$handle>,<<EOD,"Check pipe output" );
before sections: foo
after sections: foo
EOD
    ok( close( $handle ),"Verify closing of pipe: $!" );

    foreach ('DEBUGGING','DEBUGGING,WHOOPI','WHOOPI,DEBUGGING') {
        ok( open( $handle,"$^X -I$INC[-1] -Mifdef=DEBUGGING script |" ),
         "Open pipe: $! " );
        is( <$handle>,<<EOD,"Check pipe output" );
before sections: foo
within debugging: bar
after sections: foo
EOD
        ok( close( $handle ),"Verify closing of pipe: $!" );
    }

    foreach ('DEBUGGING,VERBOSE','VERBOSE,DEBUGGING','all') {
        ok( open( $handle,"$^X -I$INC[-1] -Mifdef=$_ script |" ),
         "Open pipe: $! " );
        is( <$handle>,<<EOD,"Check pipe output" );
before sections: foo
within debugging: bar
within verbose: baz
after sections: foo
EOD
        ok( close( $handle ),"Verify closing of pipe: $!" );
    }

    $ENV{'VERBOSE'} = 1;
    ok( open( $handle,"$^X -I$INC[-1] -Mifdef script |" ),
     "Open pipe: $! " );
    is( <$handle>,<<EOD,"Check pipe output" );
before sections: foo
within verbose: baz
after sections: foo
EOD
    ok( close( $handle ),"Verify closing of pipe: $!" );
    $ENV{'VERBOSE'} = 0;
}
