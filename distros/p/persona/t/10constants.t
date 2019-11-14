use lib '.';

# set up tests to do
use Test::More tests => 2 + 3 + ( 2 * 4 ) + 1;

# strict and verbose as possible
use strict;
use warnings;

# set up source to check
my $module = 'Foo';
my $source = <<"SRC";
package $module;

use strict;
use warnings;

use persona;

print "all in Foo\$/";
print "one only\$/"    if !PERSONA or PERSONA eq 'one';
print "one and two\$/" if !PERSONA or PERSONA eq 'one' or PERSONA eq 'two';
print "not one\$/"     if !PERSONA or PERSONA ne 'one';
print "all in Foo again\$/";
1;
__DATA__
print "one should never show\$/" if !PERSONA or PERSONA eq 'one';
print "all should never show\$/";
SRC

# make sure we have it as a file
my $filename = "lib/$module.pm";
open( my $out, '>', "$filename" ) or die "Could not open $filename: $!";
my $written = print $out $source;
ok( $written, "could write file $filename" );
ok( close($out), "flushed ok to disk" );

# always slurp
$/ = undef;

# ok string if there is no interference
my $postfix = "-e 'use $module' 2>&1 |";
my $all = <<"ALL";
all in Foo
one only
one and two
not one
all in Foo again
ALL

# no interference from persona whatsoever
my $prefix = "$^X -Ilib";
open( $out, "$prefix $postfix" );
is( readline($out), $all, "no interference" );
open( $out, "$prefix -Mpersona $postfix" );
is( readline($out), $all, "no module selected, no interference" );
open( $out, "$prefix -Mpersona=only_for,Bar $postfix" );
is( readline($out), $all, "Bar module selected, no interference" );


# interference
foreach my $only_for ( qw( Foo * ) ) {
    my $command = "$prefix -Mpersona=only_for,$only_for $postfix";

    open( $out, $command );
    is( readline($out), $all, "$only_for module selected, no PERSONA" );

    open( $out, "PERSONA=zero $command" );
    is( readline($out), <<'OK', "$only_for module selected, PERSONA zero" );
all in Foo
not one
all in Foo again
OK

    open( $out, "PERSONA=one $command" );
    is( readline($out), <<'OK', "$only_for module selected, PERSONA one" );
all in Foo
one only
one and two
all in Foo again
OK

    open( $out, "PERSONA=two $command" );
    is( readline($out), <<'OK', "$only_for module selected, PERSONA two" );
all in Foo
one and two
not one
all in Foo again
OK
}

# we're done
ok( unlink("$filename"), 'remove module' );
