## no critic: Modules::ProhibitAutomaticExportation

package Text::sprintfn;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(sprintfn printfn);

our $VERSION = '0.090'; # VERSION

our $distance  = 10;

my  $re1   = qr/[^)]+/s;
my  $re2   = qr{(?<fmt>
                    %
                       (?<pi> \d+\$ | \((?<npi>$re1)\)\$?)?
                       (?<flags> [ +0#-]+)?
                       (?<vflag> \*?[v])?
                       (?<width> -?\d+ |
                           \*\d+\$? |
                           \((?<nwidth>$re1)\))?
                       (?<dot>\.?)
                       (?<prec>
                           (?: \d+ | \* |
                           \((?<nprec>$re1)\) ) ) ?
                       (?<conv> [%csduoxefgXEGbBpniDUOF])
                   )}x;
our $regex = qr{($re2|%|[^%]+)}s;

# faster version, without using named capture
if (1) {
    $regex = qr{( #all=1
                    ( #fmt=2
                        %
                        (#pi=3
                            \d+\$ | \(
                            (#npi=4
                                [^)]+)\)\$?)?
                        (#flags=5
                            [ +0#-]+)?
                        (#vflag=6
                            \*?[v])?
                        (#width=7
                            -?\d+ |
                            \*\d+\$? |
                            \((#nwidth=8
                                [^)]+)\))?
                        (#dot=9
                            \.?)
                        (#prec=10
                            (?: \d+ | \* |
                                \((#nprec=11
                                    [^)]+)\) ) ) ?
                        (#conv=12
                            [%csduoxefgXEGbBpniDUOF])
                    ) | % | [^%]+
                )}xs;
}

sub sprintfn {
    my ($format, @args) = @_;

    my $hash;
    if (ref($args[0]) eq 'HASH') {
        $hash = shift(@args);
    }
    return sprintf($format, @args) if !$hash;

    my %indexes; # key = $hash key, value = index for @args
    push @args, (undef) x $distance;

    $format =~ s{$regex}{
        my ($all, $fmt, $pi, $npi, $flags,
            $vflag, $width, $nwidth, $dot, $prec,
            $nprec, $conv) =
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12);

        my $res;
        if ($fmt) {

            if (defined $npi) {
                my $i = $indexes{$npi};
                if (!$i) {
                    $i = @args + 1;
                    push @args, $hash->{$npi};
                    $indexes{$npi} = $i;
                }
                $pi = "${i}\$";
            }

            if (defined $nwidth) {
                $width = $hash->{$nwidth};
            }

            if (defined $nprec) {
                $prec = $hash->{$nprec};
            }

            $res = join("",
                grep {defined} (
                    "%",
                    $pi, $flags, $vflag,
                    $width, $dot, $prec, $conv)
                );
        } else {
            my $i = @args + 1;
            push @args, $all;
            $res = "\%${i}\$s";
        }
        $res;
    }xego;

    # DEBUG
    #use Data::Dump; dd [$format, @args];

    sprintf $format, @args;
}

sub printfn {
    print sprintfn @_;
}

1;
# ABSTRACT: Drop-in replacement for sprintf(), with named parameter support

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::sprintfn - Drop-in replacement for sprintf(), with named parameter support

=head1 VERSION

This document describes version 0.090 of Text::sprintfn (from Perl distribution Text-sprintfn), released on 2019-11-19.

=head1 SYNOPSIS

 use Text::sprintfn; # by default exports sprintfn() and printfn()

 # with no hash, behaves just like printf
 printfn '<%04d>', 1, 2; # <0001>

 # named parameter
 printfn '<%(v1)-4d>', {v1=>-2}; # <-2  >

 # mixed named and positional
 printfn '<%d> <%(v1)d> <%d>', {v1=>1}, 2, 3; # <2> <1> <3>

 # named width
 printfn "<%(v1)(v2).1f>", {v1=>3, v2=>4}; # <   3>

 # named precision
 printfn "<%(v1)(v2).(v2)f>", {v1=>3, v2=>4}; # <3.0000>

=head1 DESCRIPTION

This module provides sprintfn() and printfn(), which are like sprintf() and
printf(), with the exception that they support named parameters from a hash.

=head1 RATIONALE

There exist other CPAN modules for string formatting with named parameter
support. Two of such modules are L<String::Formatter> and
L<Text::Sprintf::Named>. This module is far simpler to use and retains all of
the features of Perl's sprintf() (which we like, or perhaps hate, but
nevertheless are familiar with).

String::Formatter requires you to create a new formatter function first.
Text::Sprintf::Named also accordingly requires you to instantiate an object
first. There is currently no way to mix named and positional parameters. And you
don't get the full features of sprintf().

=head1 HOW IT WORKS

Text::sprintfn works by converting the format string into sprintf format, i.e.
replacing the named parameters like C<%(foo)s> to something like C<%11$s>.

=head1 DOWNSIDES

Currently the main downside is speed. C<sprintfn()> is about 2-3 orders of
magnitude slower than C<sprintf()>. See L<Bencher::Scenario::Textsprintfn> for
benchmarks.

=head1 TIPS AND TRICKS

=head2 Common mistake 1

Writing

 %(var)

instead of

 %(var)s

=head2 Common mistake 2 (a bit more newbish)

Writing

 sprintfn $format, %hash, ...;

instead of

 sprintfn $format, \%hash, ...;

=head2 Alternative hashes

You have several hashes (%h1, %h2, %h3) which should be consulted for values.
You can either merge the hash first:

 %h = (%h1, %h2, %h3); # or use some hash merging module
 printfn $format, \%h, ...;

or create a tied hash which can consult hashes for you:

 tie %h, 'Your::Module', \%h1, \%h2, \%h3;
 printfn $format, \%h, ...;

=head1 FUNCTIONS

=head2 sprintfn $fmt, \%hash, ...

If first argument after format is not a hash, sprintfn() will behave exactly
like sprintf().

If hash is given, sprintfn() will look for named parameters in argument and
supply the values from the hash. Named parameters are surrounded with
parentheses, i.e. "(NAME)". They can occur in format parameter index:

 %2$d        # sprintf version, take argument at index 2
 %(two)d     # $ is optional
 %(two)$d    # same

or in width:

 %-10d       # sprintf version, use (minimum) width of 10
 %-(width)d  # like sprintf, but use width from hash key 'width'
 %(var)-(width)d  # format hash key 'var' with width from hash key 'width'

or in precision:

 %6.2f       # sprintf version, use precision of 2 decimals
 %6.(prec)f  # like sprintf, but use precision from hash key 'prec'
 %(width).(prec)f
 %(var)(width).(prec)f

The existence of formats using hash keys will not affect indexes of the rest of
the argument, example:

 sprintfn "<%(v1)s> <%2$d> <%d>", {v1=>10}, 0, 1, 2; # "<10> <2> <0>"

Like sprintf(), if format is unknown/erroneous, it will be printed as-is.

There is currently no way to escape ")" in named parameter, e.g.:

 %(var containing ))s

=head2 printfn $fmt, ...

Equivalent to: print sprintfn($fmt, ...).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-sprintfn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-sprintfn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-sprintfn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

sprintf() section on L<perlfunc>

L<String::Formatter>

L<Text::Sprintf::Named>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
