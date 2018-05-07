#!/usr/bin/env perl

use strict;
use warnings;

use Test::Fatal qw(exception);
use Test::More tests => 60;

sub INTEGER::inc { $_[0] + 1 }
sub FLOAT::inc { $_[0] + 1 }
sub STRING::inc { my $string = shift; ++$string }
sub NUMBER::inc { $_[0] + 1 }
sub SCALAR::inc { my $scalar = shift; ++$scalar }

my $integer = 42;
my $float = 3.1415927;
my $string = 'Hello';
my $einc = qr{^Can't (call|locate object) method "inc" (without a|via) package\b};
my $einc2 = qr{^Can't locate object method "inc" via package "Hello"};

{
    use autobox INTEGER => 'INTEGER';

    is(42->inc, 43, '42->inc');
    is($integer->inc, 43, '$integer->inc');

    # make sure it doesn't work for other scalars
    like(exception { 42.0->inc }, $einc, '42.0->inc');
    like(exception { $float->inc }, $einc, '$float->inc');
    like(exception { "Hello"->inc }, $einc2, '"Hello"->inc');
    like(exception { $string->inc }, $einc2, '$string->inc');
}

{
    use autobox FLOAT => 'FLOAT';

    is(3.1415927->inc, 4.1415927, '3.1415927->inc');
    is($float->inc, 4.1415927, '$float->inc');

    like(exception { 42->inc }, $einc, '42->inc');
    like(exception { $integer->inc }, $einc, '$integer->inc');
    like(exception { "Hello"->inc }, $einc2, '"Hello"->inc');
    like(exception { $string->inc }, $einc2, '$string->inc');
}

{
    use autobox STRING => 'STRING';

    is("Hello"->inc, "Hellp", '"Hello"->inc');
    is($string->inc, "Hellp", '$string->inc');

    like(exception { 42->inc }, $einc, '42->inc');
    like(exception { $integer->inc }, $einc, '$integer->inc');
    like(exception { 42.0->inc }, $einc, '42.0->inc');
    like(exception { $float->inc }, $einc, '$float->inc');
}

{
    use autobox NUMBER => 'NUMBER';

    is(42->inc, 43, '42->inc');
    is($integer->inc, 43, '$integer->inc');
    is(3.1415927->inc, 4.1415927, '3.1415927->inc');
    is($float->inc, 4.1415927, '$float->inc');

    like(exception { "Hello"->inc }, $einc2, '"Hello"->inc');
    like(exception { $string->inc }, $einc2, '$string->inc');
}

{
    use autobox SCALAR => 'SCALAR';

    is(42->inc, 43, '42->inc');
    is($integer->inc, 43, '$integer->inc');
    is(3.1415927->inc, 4.1415927, '3.1415927->inc');
    is($float->inc, 4.1415927, '$float->inc');
    is("Hello"->inc, "Hellp", '"Hello"->inc');
    is($string->inc, "Hellp", '$string->inc');
}

# unimport should delete subtypes added automatically

{
    use autobox SCALAR => 'SCALAR';
    no autobox qw(INTEGER);

    like(exception { 42->inc }, $einc, '42->inc');
    like(exception { $integer->inc }, $einc, '$integer->inc');

    is(3.1415927->inc, 4.1415927, '3.1415927->inc');
    is($float->inc, 4.1415927, '$float->inc');
    is("Hello"->inc, "Hellp", '"Hello"->inc');
    is($string->inc, "Hellp", '$string->inc');
}

{
    use autobox SCALAR => 'SCALAR';
    no autobox qw(FLOAT);

    like(exception { 42.0->inc }, $einc, '42.0->inc');
    like(exception { $float->inc }, $einc, '$float->inc');

    is(42->inc, 43, '42->inc');
    is($integer->inc, 43, '$integer->inc');
    is("Hello"->inc, "Hellp", '"Hello"->inc');
    is($string->inc, "Hellp", '$string->inc');
}

{
    use autobox SCALAR => 'SCALAR';
    no autobox qw(STRING);

    like(exception { "Hello"->inc }, $einc2, '"Hello"->inc');
    like(exception { $string->inc }, $einc2, '$string->inc');

    is(42->inc, 43, '42->inc');
    is($integer->inc, 43, '$integer->inc');
    is(3.1415927->inc, 4.1415927, '3.1415927->inc');
    is($float->inc, 4.1415927, '$float->inc');
}

{
    use autobox SCALAR => 'SCALAR';
    no autobox qw(NUMBER);

    like(exception { 42->inc }, $einc, '42->inc');
    like(exception { $integer->inc }, $einc, '$integer->inc');
    like(exception { 42.0->inc }, $einc, '42.0->inc');
    like(exception { $float->inc }, $einc, '$float->inc');

    is("Hello"->inc, "Hellp", '"Hello"->inc');
    is($string->inc, "Hellp", '$string->inc');
}

{
    use autobox SCALAR => 'SCALAR';
    no autobox qw(SCALAR);

    like(exception { 42->inc }, $einc, '42->inc');
    like(exception { $integer->inc }, $einc, '$integer->inc');
    like(exception { 42.0->inc }, $einc, '42.0->inc');
    like(exception { $float->inc }, $einc, '$float->inc');
    like(exception { "Hello"->inc }, $einc2, '"Hello"->inc');
    like(exception { $string->inc }, $einc2, '$string->inc');
}
