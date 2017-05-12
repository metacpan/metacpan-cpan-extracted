package Video::DVDRip::CPAN::Scanf;
use Locale::TextDomain qw (video.dvdrip);

# This is the unmodified String::Scanf module from Jarkko Hietaniemi
# which is just included into this distribution to keep the dependencies
# low. According credits are noted in the COPYRIGHT file.

use strict;

use vars qw($VERSION @ISA @EXPORT);

$VERSION = '2.0';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(sscanf);

=pod

=head1 NAME

String::Scanf - emulate sscanf() of the C library

=head1 SYNOPSIS

    use String::Scanf; # imports sscanf()

    ($a, $b, $c, $d) = sscanf("%d+%d %f-%s", $input);
    ($e, $f, $g, $h) = sscanf("%x %o %s:%3c"); # input defaults to $_

    $r = String::Scanf::format_to_re($f);

or

    # works only for Perl 5.005
    use String::Scanf qw(); # import nothing

    my $s1 = String::Scanf->new("%d+%d %f-%s");
    my $s2 = String::Scanf->new("%x %o %s:%3c");

    ($a, $b, $c, $d) = $s1->sscanf($input);
    ($e, $f, $g, $h) = $s2->sscanf(); # input defaults to $_

=head1 DESCRIPTION

String::Scanf supports scanning strings for data using formats
similar to the libc/stdio sscanf().

The supported sscanf() formats are as follows:

=over 4

=item %d

Decimal integer, with optional plus or minus sign.

=item %u

Decimal unsigned integer, with optional plus sign.

=item %x

Hexadecimal unsigned integer, with optional "0x" or "0x" in front.

=item %o

Octal unsigned integer.

=item %e %f %g

(The [efg] work identically.)

Decimal floating point number, with optional plus or minus sign,
in any of these formats:

    1
    1.
    1.23
    .23
    1e45
    1.e45
    1.23e45
    .23e45

The exponent has an optional plus or minus sign, and the C<e> may also be C<E>.

The various borderline cases like C<Inf> and C<Nan> are not recognized.

=item %s

A non-whitespace string.

=item %c

A string of characters.  An array reference is returned containing
the numerical values of the characters.

=item %%

A literal C<%>.

=back

The sscanf() formats [pnSC] are not supported.

The C<%s> and C<%c> have an optional maximum width, e.g. C<%4s>,
in which case at most so many characters are consumed (but fewer
characters are also accecpted).

The numeric formats may also have such a width but it is ignored.

The numeric formats may have C<[hl> before the main option, e.g. C<%hd>,
but since such widths have no meaning in Perl, they are ignored.

Non-format parts of the parameter string are matched literally
(e.g. C<:> matches as C<:>),
expect that any whitespace is matched as any whitespace
(e.g. C< > matches as C<\s+>).

=head1 WARNING

The numeric formats match only something that looks like a number,
they do not care whether it fits into the numbers of Perl.  In other
words, C<123e456789> is valid for C<sscanf()>, but quite probably it
won't fit into your Perl's numbers.  Consider using the various
Math::* modules instead.

=head1 AUTHOR, COPYRIGHT AND LICENSE

Jarkko Hietaniemi <jhi@iki.fi>

Copyright (c) 2002 Jarkko Hietaniemi.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Carp;

sub _format_to_re {
    my $format = shift;

    my $re = '';
    my $ix = 0;
    my @fmt;
    my @reo;
    my $dx = '\d+(?:_\d+)*';

    while ($format =~
	   /(%(?:(?:(\d+)\$)?(\d*)([hl]?[diuoxefg]|[pnsScC%]))|%(\d*)(\[.+?\])|(.+?))/g) {
	if (defined $2) { # Reordering.
	    $reo[$ix] = $2 - 1;
	} else {
	    $reo[$ix] = $ix;
	}
	if (defined $1) {
	    if (defined $4) {
		my $e;
		my ($w, $f) = ($3, $4);
		$f =~ s/^[hl]//;
		if ($f =~ /^[pnSC]$/) {
		    croak __x("'{function}' not supported", function => $f);
		} elsif ($f =~ /^[di]$/) {
		    $e = "[-+]?$dx";
		} elsif ($f eq 'x') {
		    $e = '(?:0[xX])?[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*';
		} elsif ($f eq 'o') {
		    $e = '[0-7]+(?:_[0-7]+)*';
		} elsif ($f =~ /^[efg]$/) {
		    $e = "[-+]?(?:(?:$dx(?:\\.(?:$dx)?)?|\\.$dx)(?:[eE][-+]?$dx)?)";
		} elsif ($f eq 'u') {
		    $e = "\\+?$dx";
		} elsif ($f eq 's') {
		    $e = $w ? "\\S{0,$w}" : "\\S*";
		} elsif ($f eq 'c') {
		    $e = $w ? ".{0,$w}" : ".*";
		}
		if ($f !~ /^[cC%]$/) {
		    $re .= '\s*';
		}
		$re .= "($e)";
		$fmt[$ix++] = $f;
	    } elsif (defined $6) { # [...]
		$re .= $5 ? "(${6}{0,$5})" : "($6+)";
		$fmt[$ix++] = '[';
	    } elsif (defined $7) { # Literal.
		my $lit = $7;
		if ($lit =~ /^\s+$/) {
		    $re .= '\s+';
		} else {
		    $lit =~ s/(.)/\\$1/g;
		    $re .= $lit;
		}
	    }
	}
    }

    $re =~ s/\\s\*\\s\+/\\s+/g;
    $re =~ s/\\s\+\\s\*/\\s+/g;

    return ($re, \@fmt, \@reo);
}

sub format_to_re {
    my ($re) = _format_to_re $_[0];
    return $re;
}

sub _match {
    my ($format, $re, $fmt, $reo, $data) = @_;
    my @matches = ($data =~ /$re/);

    my $ix;
    for ($ix = 0; $ix < @matches; $ix++) {
	if ($fmt->[$ix] eq 'c') {
	    $matches[$ix] = [ map { ord } split //, $matches[$ix] ];
	} elsif ($fmt->[$ix] =~ /^[diuoxefg]$/) {
	    $matches[$ix] =~ tr/_//d;
	}
	if ($fmt->[$ix] eq 'x') {
	    $matches[$ix] =~ s/^0[xX]//;
	    $matches[$ix] = hex $matches[$ix];
	} elsif ($fmt->[$ix] eq 'o') {
	    $matches[$ix] = oct $matches[$ix];
	}
    }
    @matches = @matches[@$reo];

    return @matches;
}

sub new {
    require 5.005; sub qr {}
    my ($class, $format) = @_;
    my ($re, $fmt, $reo) = _format_to_re $format;
    bless [ $format, qr/$re/, $fmt, $reo ], $class;
}

sub format {
    $_[0]->[0];
}

sub sscanf {
    my $self = shift;
    my $data = @_ ? shift : $_;
    if (ref $self) {
	return _match(@{ $self }, $data);
    }
    _match($self, _format_to_re($self), $data);
}

1;
