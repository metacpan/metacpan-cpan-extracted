use lib '.';

# set up tests to do
use Test::More tests => 2 + 4 + 1;

# strict and verbose as possible
use strict;
use warnings;

# set up source to check
my $source = <<"SRC";
use strict;
use warnings;

use persona;

print "all in Foo\$/";
#PERSONA one
print "one only\$/";
#PERSONA one two
print "one and two\$/";
#PERSONA !one
print "not one\$/";
#PERSONA
print "all in Foo again\$/";
1;
__END__
#PERSONA one
print "one should never show\$/";
#PERSONA
print "all should never show\$/";
SRC

# make sure we have it as a file
my $filename = "lib/foo";
open( my $out, '>', $filename ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# no interference
my $prefix  = "$^X -I. -Ilib";
my $postfix = "$filename 2>&1 |";
open( $out, "$prefix $postfix" );
is( readline($out), <<'OK', 'no PERSONA, no interference' );
all in Foo
one only
one and two
not one
all in Foo again
OK

# interference
{
    local $ENV{PERSONA} = 'zero'; # use perl to pass ENV to child process
    open( $out, "$prefix $postfix" );
    is( readline($out), <<'OK', 'PERSONA zero' );
all in Foo
not one
all in Foo again
OK
}

open( $out, "$prefix -Mpersona=one $postfix" );
is( readline($out), <<'OK', 'PERSONA one' );
all in Foo
one only
one and two
all in Foo again
OK
open( $out, "$prefix -Mpersona=two $postfix" );
is( readline($out), <<'OK', 'PERSONA two' );
all in Foo
one and two
not one
all in Foo again
OK

# we're done
ok( unlink($filename), 'remove file' );
