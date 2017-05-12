
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ('../lib','.');
    }
}

use Test::More tests => 6 * 5;
use strict;
use warnings;

$ENV{OGD_DEBUG} = 1;

# Globals destroyed at global destruction

verify( <<'EOD1',<<'EOD2' );
if (1) {
    push @bar,bless \$_,'Bar' foreach 0..4;
}
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
+1
+1
+1
+1
+1
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
Bar 4 (1)
Bar 3 (1)
Bar 2 (1)
Bar 1 (1)
Bar 0 (1)
!10
xBar(5) Foo(5)
EOD2

# Lexicals destroyed at end of file scope

verify( <<'EOD1',<<'EOD2',sub { $_[0] =~ s#Bar \d \(\)#Bar x ()#sg } );
my @bar;
push @bar,bless \$_,'Bar' foreach 0..4;
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
+1
+1
+1
+1
+1
Bar x ()
Bar x ()
Bar x ()
Bar x ()
Bar x ()
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
!5
xFoo(5)
EOD2

# Lexicals destroyed at end of lexical scope

verify( <<'EOD1',<<'EOD2',sub { $_[0] =~ s#Bar \d \(\)#Bar x ()#sg } );
if (1) {
    my @bar;
    push @bar,bless \$_,'Bar' foreach 0..4;
}
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
Bar x ()
Bar x ()
Bar x ()
Bar x ()
Bar x ()
+1
+1
+1
+1
+1
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
!5
xFoo(5)
EOD2

$ENV{OGD_CLEANUP} = 2;

# Globals destroyed at global destruction, with cleanup every 4 objects

verify( <<'EOD1',<<'EOD2' );
if (1) {
    push @bar,bless \$_,'Bar' foreach 0..4;
}
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
+1
+1
+1
+1
+1
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
Bar 4 (1)
Bar 3 (1)
Bar 2 (1)
Bar 1 (1)
Bar 0 (1)
!10
xBar(5) Foo(5)
EOD2

# Lexicals destroyed at end of file scope, with cleanup every 4 objects

verify( <<'EOD1',<<'EOD2',sub { $_[0] =~ s#Bar \d \(\)#Bar x ()#sg } );
my @bar;
push @bar,bless \$_,'Bar' foreach 0..4;
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
+1
+1
+1
+1
+1
Bar x ()
Bar x ()
Bar x ()
Bar x ()
Bar x ()
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
!5
xFoo(5)
EOD2

# Lexicals destroyed at end of lexical scope, with cleanup every 4 objects

verify( <<'EOD1',<<'EOD2',sub { $_[0] =~ s#Bar \d \(\)#Bar x ()#sg } );
if (1) {
    my @bar;
    push @bar,bless \$_,'Bar' foreach 0..4;
}
push @foo,bless \$_,'Foo' foreach 5..9;
EOD1
+1
+1
+1
+1
+1
Bar x ()
Bar x ()
Bar x ()
Bar x ()
Bar x ()
+1
+1
+1
-8->3
+1
+1
*
Foo 9 (1)
Foo 8 (1)
Foo 7 (1)
Foo 6 (1)
Foo 5 (1)
!5
xFoo(5)
EOD2

1 while unlink qw(script stderr); # multi-versioned file systems

#---------------------------------------------------------------------

sub verify {
    my ($input,$output,$code) = @_;
    ok( open( my $handle,'>script' ),"Create script: $!" );
    print $handle $input,<<'EOD';

sub Foo::DESTROY { print STDERR "Foo ${$_[0]} ($_[1])\n" }
sub Bar::DESTROY { print STDERR "Bar ${$_[0]} ($_[1])\n" }
EOD
    ok( close( $handle ),"Close script: $! " );

    local $/;
    ok( open( $handle,"$^X -I$INC[-1] -mogd script 2>&1 |" ),"Open pipe: $! " );
    my $found = <$handle>;
    $code->( $found ) if $code;
    is( $found,$output,"Check pipe output" );
    ok( close( $handle ),"Verify closing of pipe: $!" );
}
