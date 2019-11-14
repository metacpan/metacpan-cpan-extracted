use lib '.';

# set up tests to do
use Test::More tests => 3 + ( 4 * 3 ) + ( 2 * 4 ) + 1;

# strict and verbose as possible
use strict;
use warnings;

# does it compile?
BEGIN { use_ok( 'persona' ) }

# set up source to check
my $module = 'Foo';
my $source = <<"SRC";
package $module;

use strict;
use warnings;

print "all in Foo\$/";
#PERSONA one
print "one only\$/";
#PERSONA one two
print "one and two\$/";
#PERSONA !one
print "not one\$/";
#PERSONA !( zero || one )
print "not zero or one\$/";
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
my $filename = "$module.pm";
open( my $out, '>', $filename ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# ok string if there is no interference
my $postfix = "-Ilib -M$module -e1 2>&1 |";
my $all = <<"ALL";
all in Foo
one only
one and two
not one
not zero or one
all in Foo again
ALL

# no interference from persona whatsoever
foreach ( '', 'zero', 'one', 'two' ) {
    local $ENV{PERSONA} = $_;

    my $prefix .= "$^X -I.";
    open( $out, "$prefix $postfix" );
    is( readline($out), $all, "$prefix no interference" );
    open( $out, "$prefix -Mpersona $postfix" );
    is( readline($out), $all, "$prefix no module selected, no interference" );
    open( $out, "$prefix -Mpersona=only_for,Bar $postfix" );
    is( readline($out), $all, "$prefix Bar module selected, no interference" );
}

# interference
foreach my $only_for ( qw( Foo * ) ) {
    local $ENV{PERSONA};

    my $command = "$^X -I. -Mpersona=only_for,$only_for $postfix";

    open( $out, $command );
    is( readline($out), $all, "$only_for module selected, no PERSONA" );

    $ENV{PERSONA} = 'zero';
    open( $out, $command );
    is( readline($out), <<'OK', "Foo module selected, PERSONA zero" );
all in Foo
not one
all in Foo again
OK

    $ENV{PERSONA} = 'one';
    open( $out, $command );
    is( readline($out), <<'OK', "Foo module selected, PERSONA one" );
all in Foo
one only
one and two
all in Foo again
OK

    $ENV{PERSONA} = 'two';
    open( $out, $command );
    is( readline($out), <<'OK', "Foo module selected, PERSONA two" );
all in Foo
one and two
not one
not zero or one
all in Foo again
OK
}

# we're done
ok( unlink($filename), 'remove module' );
