package Text::Roman;
# ABSTRACT: Allows conversion between Roman and Arabic algarisms.


use strict;
use warnings qw(all);

use Carp qw(carp);
use Exporter;

## no critic (ProhibitAutomaticExportation, ProhibitExplicitISA)
our @ISA            = qw(Exporter);
our %EXPORT_TAGS    = (all => [qw(roman int2roman roman2int isroman mroman2int milhar2int ismroman ismilhar)]);
our @EXPORT_OK      = @{$EXPORT_TAGS{all}};

our $VERSION = '3.5'; # VERSION

our @RSN = qw/I V X L C D M/;                           # Roman Simple Numerals
our @RCN = qw/IV IX XL XC CD CM/;                       # Roman Complex Numerals
our %R2A;
@R2A{@RSN, @RCN} = qw/
    1 5 10 50 100 500 1000 4 9 40 90 400 900
/;                                                      # numeric values
our %A2R = reverse %R2A;                                # reverse for convenience


## no critic (RequireArgUnpacking)
sub isroman {
    local $_ = uc(@_ ? shift : $_);

    return if !/^[@RSN]+$/x;
    return if /([IXCM])\1{3,}|([VLD])\2+/x;             # tests repeatability
    my @re = qw/IXI|XCX|CMC/;
    for (1 .. $#RSN) {
        push @re, "$RSN[$_ - 1]$RSN[$_]$RSN[$_ - 1]";   # tests IVI
        push @re, "$RSN[$_]$RSN[$_ - 1]$RSN[$_]";       # and VIV conditions
    }
    my $re = join "|", @re;
    return !/$re/x;
}


sub int2roman {
    my $n = @_ ? shift : $_;
    return
        if not $n =~ /^[0-9]+$/x
        or $n <= 0
        or $n >= 4000;

    my $ret = '';
    for (reverse sort { $a <=> $b } values %R2A) {
        $ret .= $A2R{$_} x int($n / $_);
        $n %= $_;
    }

    return defined(wantarray)
        ? $ret
        : $_ = $ret;
}


sub roman2int {
    my $ret = 0;
    do {
        local $_ = uc(@_ ? shift : $_);

        return unless isroman();

        my ($r, $_ret) = ($_, 0);
        while ($r) {
            $r =~ s/^$_//x and ($ret += $R2A{$_}, last) for @RCN, @RSN;
            return if $ret <= $_ret;
            $_ret = $ret;
        }
    };

    return defined(wantarray)
        ? $ret
        : $_ = $ret;
}


sub ismilhar {
    local $_ = uc(@_ ? shift : $_);
    return unless /^[_@RSN]+$/x;

    my @r = split /_/;
    isroman() || return for @r;
    return 1;
}


sub milhar2int {
    my $ret;
    do {
        local $_ = uc(@_ ? shift : $_);

        return unless ismilhar();

        my @r = split /_/;
        $ret = roman2int(pop @r);
        $ret += 1000 * roman2int() for @r;
    };

    return defined(wantarray)
        ? $ret
        : $_ = $ret;
}


my %deprecated = (
    ismroman    => [ ismilhar   => \&ismilhar   ],
    mroman2int  => [ milhar2int => \&milhar2int ],
    roman       => [ int2roman  => \&int2roman  ],
);

for my $aliased (keys %deprecated) {
    ## no critic (ProhibitNoStrict)
    no strict 'refs';
    *{'Text::Roman::' . $aliased} = sub {
        carp sprintf(
            '%s() deprecated, use %s() instead',
            $aliased, $deprecated{$aliased}->[0]
        );
        goto $deprecated{$aliased}->[1];
    };
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Text::Roman - Allows conversion between Roman and Arabic algarisms.

=head1 VERSION

version 3.5

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Text::Roman qw(:all);

    print int2roman(123), "\n";

    my $roman = "XXXV";
    print roman2int($roman), "\n" if isroman($roman);

    my $milhar = 'L_X_XXIII'; # = 60,023
    print milhar2int($milhar), "\n" if ismilhar($milhar);

=head1 DESCRIPTION

This package supports both conventional Roman algarisms (which range from I<1> to I<3999>) and Milhar Romans, a variation which uses a bar across the algarism to indicate multiplication by I<1_000>.
For the purposes of this module, acceptable syntax consists of an underscore suffixed to the algarism e.g. IV_V = I<4_005>.
The term Milhar apparently derives from the Portuguese word for "thousands" and the range of this notation extends the range of Roman numbers to I<3999 * 1000 + 3999 = 4_002_999>.

Note: the functions in this package treat Roman algarisms in a case-insensitive manner such that "VI" == "vI" == "Vi" == "vi".

The following functions may be imported into the caller package by name:

=head1 FUNCTIONS

=head2 isroman

Tests a string to be a valid Roman algarism.
Returns a boolean value.

=head2 int2roman

Converts an integer expressed in Arabic numerals, to its corresponding Roman algarism.
If the integer provided is out of the range expressible in Roman notation, an I<undef> is returned.

=head2 roman2int

Does the converse of L</int2roman>, converting a Roman algarism to its integer value.

=head2 ismilhar

Determines whether a string qualifies as a Milhar Roman algarism.

=head2 milhar2int

Converts a Milhar Roman algarism to an integer.

=head2 ismroman/mroman2int/roman

These functions belong to the module's old interface and are considered deprecated.
Do not use them in new code and they will eventually be discontinued; they map as follows:

=over 4

=item *

ismroman      => B<ismilhar>

=item *

mroman2int    => B<milhar2int>

=item *

roman         => B<int2roman>

=back

=head1 CHANGES

Some changes worth noting from this module's previous incarnation:

=over

=item I<namespace imports>

The call to B<use> must now explicitly request function names imported into it's namespace.

=item I<argument defaults/void context>

All functions now will operate on B<$_> when no arguments are passed, and will set B<$_> when called in a void context.
This allows for writing code like:

    @x = qw/V III XI IV/;
    roman2int() for @x;
    print join("-", @x);

instead of the uglier:

    @x = qw/V III XI IV/;
    $_ = roman2int($_) for @x;
    print join("-", @x);

=back

=head1 SPECIFICATION

Roman algarisms may be described using the following BNF-like formula:

    a   = I{1,3}
    b   = V\a?|IV|\a
    e   = X{1,3}\b?|X{0,3}IX|\b
    ee  = IX|\b
    f   = L\e?|XL\ee?|\e
    g   = C{1,3}\f?|C{0,3}XC\ee?|\f
    gg  = XC\ee?|\f
    h   = D\g?|CD\gg?|\g
    j   = M{1,3}\h?|M{0,3}CM\gg?|\h

=head1 REFERENCES

For a description of the Roman numeral system see: L<http://www.novaroma.org/via_romana/numbers.html>.
A reference to Milhar Roman alagarisms (in Portuguese) may be found at: L<http://web.archive.org/web/20020819094718/http://www.estado.com.br/redac/norn-nro.html>.

=head1 ACKNOWLEDGEMENTS

This module was originally written by Peter de Padua Krauss and submitted to CPAN by L<Stanislaw Pusep|https://metacpan.org/author/SYP> who has relinquished control to L<Erick Calder|https://metacpan.org/author/ECALDER> since the original author has never maintained it and can no longer be reached.

Erick have completely rewritten the module, implementing simpler algorithms to perform the same functionality, adding a test suite, a Changes file, etc. and providing more comprehensive documentation.

Ten years later, Stanislaw returned as a maintainer.

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Erick Calder <ecalder@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
