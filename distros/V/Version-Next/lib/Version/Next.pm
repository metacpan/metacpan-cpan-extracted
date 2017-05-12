use strict;
use warnings;

package Version::Next;
# ABSTRACT: increment module version numbers simply and correctly

our $VERSION = '1.000';

# Dependencies
use version 0.81 ();
use Carp ();

# Exporting
use Sub::Exporter 0 ( -setup => { exports => ['next_version'] } );

# lax versions are too lax
sub _cleanup {
    my $version = shift;

    # treat 'undef' as 0
    if ( $version eq 'undef' ) {
        return "0";
    }

    # fix leading dots
    if ( $version =~ /^\./ ) {
        my $num_dots =()= $version =~ /(\.)/g;
        return $num_dots > 1 ? "v0$version" : "0$version";
    }

    # fix trailing dots
    if ( $version =~ /\.$/ ) {
        # is_lax already prevents dotted-decimal with trailing dot
        return "${version}0";
    }

    # otherwise, it should be fine
    return $version;
}

sub next_version {
    my $version = shift;
    return "0" unless defined $version;

    Carp::croak("Doesn't look like a version number: '$version'")
      unless version::is_lax($version);

    $version = _cleanup($version);

    my $new_ver;
    my $num_dots =()= $version =~ /(\.)/g;
    my $has_v    = $version =~ /^v/;
    my $is_alpha = $version =~ /\A[^_]+_\d+\z/;

    if ( $has_v || $num_dots > 1 ) { # vstring
        $version =~ s{^v}{} if $has_v;
        my @parts = split /\./, $version;
        if ($is_alpha) {             # vstring with alpha
            Carp::croak( _vstring_alpha_unsupported_msg($version) );
        }
        my @new_ver;
        while (@parts) {
            my $p = pop @parts;
            if ( $p < 999 || !@parts ) {
                unshift @new_ver, $p + 1;
                last;
            }
            else {
                unshift @new_ver, 0;
            }
        }
        $new_ver = $has_v ? 'v' : '';
        $new_ver .= join( ".", map { 0+ $_ } @parts, @new_ver );
    }
    else { # decimal fraction
        my $alpha_neg_offset;
        if ($is_alpha) {
            $alpha_neg_offset = index( $version, "_" ) + 1 - length($version);
            $version =~ s{_}{};
        }
        my ($fraction) = $version =~ m{\.(\d+)$};
        my $n = defined $fraction ? length($fraction) : 0;
        $new_ver = sprintf( "%.${n}f", $version + ( 10**-$n ) );
        if ($is_alpha) {
            substr( $new_ver, $alpha_neg_offset, 0, "_" );
        }
    }
    return $new_ver;

}

sub _vstring_alpha_unsupported_msg {
    my $v   = shift;
    my $msg = <<"HERE";
Can't determine next version number for '$v'.

Due to changes in the interpretation of dotted-decimal version numbers with
alpha elements in version.pm 0.9913 and later, the notion of the 'next'
dotted-decimal alpha is ill-defined.  Version::Next no longer supports
dotted-decimals with alpha elements.

Aborting
HERE
    chomp $msg;
    return $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Version::Next - increment module version numbers simply and correctly

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use Version::Next qw/next_version/;

  my $new_version = next_version( $old_version );

=head1 DESCRIPTION

This module provides a simple, correct way to increment a Perl module version
number.  It does not attempt to guess what the original version number author
intended, it simply increments in the smallest possible fashion.  Decimals are
incremented like an odometer.  Dotted decimals are incremented piecewise and
presented in a standardized way.

If more complex version manipulation is necessary, you may wish to consider
L<Perl::Version>.

=head1 USAGE

This module uses L<Sub::Exporter> for optional exporting.  Nothing is exported
by default.

=head2 C<next_version>

  my $new_version = next_version( $old_version );

Given a string, this function make the smallest logical increment and
returns it.  The input string must be a "lax" version numbers as defined by
the L<version> module.  The string "undef" is treated as C<0> and
incremented to C<1>.  Leading or trailing periods have a C<0> (or C<v0>)
prepended or appended as appropriate.  For legacy reasons, given no
argument or a literal C<undef> (not the string "undef"), the function
returns C<0>.

Decimal versions are incremented like an odometer, preserving the original
number of decimal places.  If an underscore is present (indicating an "alpha"
version), its relative position is preserved.  Examples:

  0.001    ->   0.002
  0.999    ->   1.000
  0.1229   ->   0.1230
  0.12_34  ->   0.12_35
  0.12_99  ->   0.13_00

Dotted-decimal versions have the least significant element incremented by one.
If the result exceeds C<999>, the element resets to C<0> and the next
most significant element is incremented, and so on.  Any leading zero padding
is removed.  Examples:

 v1.2.3     ->  v1.2.4
 v1.2.999   ->  v1.3.0
 v1.999.999 ->  v2.0.0

B<NOTE>: Due to changes in the interpretation of dotted-decimal version
numbers with alpha elements in L<version> 0.9913 and later, the notion of
the 'next' dotted-decimal alpha is ill-defined.  Version::Next no longer
supports dotted-decimals with alpha elements and a fatal exception will be
thrown if one is provided to C<next_version>.

=head1 SEE ALSO

=over 4

=item *

L<version>

=item *

L<Perl::Version>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Version-Next/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Version-Next>

  git clone https://github.com/dagolden/Version-Next.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Grzegorz Rożniecki

Grzegorz Rożniecki <xaerxess@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
