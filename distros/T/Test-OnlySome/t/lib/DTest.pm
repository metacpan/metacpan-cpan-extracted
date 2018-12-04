# DTest.pm: test kit for Test::OnlySome

package DTest;
use feature qw(:5.12);
use strict;
use warnings;

use parent 'Exporter';
use Import::Into;

use Test::More;
use Test::OnlySome::PathCapsule;
use Carp qw(carp croak);
use constant { true => !!1, false => !!0 };

our @EXPORT = qw(int2ascii alen tokencopy contains_string true false localpath);

sub contains_string($$;$) {   # Adapted from Test::LongString {{{1
    my ($str,$sub,$name) = @_;

    my $ok;
    if (!defined $str) {
        ok(0, $name);
        diag("String to look in is undef");
    } elsif (!defined $sub) {
        ok(0, $name);
        diag("String to look for is undef");
    } else {
        $str = '' . $str;
        $sub = '' . $sub;
        my $index = index($str, $sub);
        diag("Looking for $sub in $str: $index");
        ok($index >= 0, $name);
    }
} # }}}1

sub int2ascii { # The Perl port of the numout instruction from ngb.c {{{1
    my $val = shift;
    croak unless defined $val;
    $val = +$val;
    croak "Negatives not supported" if $val<0;

    my $retval = '';
    my $first = 1;

    # Generate LSB to MSB
    while(1) {
        use integer;
        my $digit = chr( ($val % 26) + ord($first ? 'A' : 'a') );
            # last char is uppercase
        $retval = "${digit}${retval}";
        $first = false;
    } continue {
        use integer;
        $val /= 26;
        last unless $val>0;
    }

    return $retval;
} #int2ascii }}}1

sub alen { # Strlen, but returns the result in numout (_A_SCII) form  {{{1
    my $token = shift or croak;
    return int2ascii(length($token));
} #alen }}}1

sub tokencopy { # Return the string we expect as a copy of the input. {{{1
    my $token = shift or croak;
    return alen($token) . $token;
} #tokencopy }}}1

sub localpath { # Return the path to a file in the same directory as the caller {{{1
    my $newfn = shift or croak 'Need a filename';
    my ($package, $filename) = caller;

    $filename = 'dummy' unless $filename && $filename ne '-e';
        # Dummy filename assumed to be in cwd, if we're running from -e
        # or are otherwise without a caller.

    my $path = Test::OnlySome::PathCapsule->new($filename);
        # Assume the code up to this point hasn't changed cwd

    $path->file($newfn);
    return $path->abs;
} #}}}1

sub import { # {{{1
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    DTest->export_to_level(1, @_);

    # Re-export pragmas
    constant->import::into($target, {true => !!1, false => !!0});
    feature->import::into($target, qw(:5.12));
    foreach my $pragma (qw(strict warnings)) {
        ${pragma}->import::into($target);
    };

    # Re-export packages
    foreach my $pkg (qw(Test::More)) {
        ${pkg}->import::into($target);
    }

    Carp->import::into($target, qw(carp croak));
} # }}}1

1;

# vi: set fdm=marker: #
