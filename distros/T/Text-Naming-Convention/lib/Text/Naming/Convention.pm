package Text::Naming::Convention;

use warnings;
use strict;
use Carp;

use base qw/Exporter/;
our @EXPORT_OK = qw/naming renaming default_convention default_keep_uppers/;

our $VERSION = '0.07';

my @_valid_conventions = ( '_', '-', 'UpperCamelCase', 'lowerCamelCase' );
my $_default_convention = '_';

# keep the upper case for word like 'RFC', but not 'bAr', that only take
# effect for CamelCase conventions, and not the first word if it's
# lowerCamelCase.
my $_default_keep_uppers = 1;

=head1 NAME

Text::Naming::Convention - Naming or Renaming( for identifiers, mostly )


=head1 VERSION

This document describes Text::Naming::Convention version 0.06


=head1 SYNOPSIS

    use Text::Naming::Convention qw/naming renaming/;
    my $name = naming( 'foo', 'bar', 'baz' ) # got foo_bar_baz
    $name = naming( 'foo', 'bar', 'baz',
            { convention => 'UpperCamelCase'} ); # got FooBarBaz
    my $new_name = renaming( 'FooBarBaz' ); # got foo_bar_baz
    $new_name = renaming( 'FooBarBaz',
            { convention => 'lowerCamelCase' } ); # got fooBarBaz


=head1 DESCRIPTION

This's a simple module for naming and renaming, mostly for identifiers or something like that.

I'm tired of writing renaming sub, so I chose to create this module, wish it can help you too :)

=head2 default_convention

get or set default convention, default is '_'.
valid values are ( '_', '-', 'UpperCamelCase', 'lowerCamelCase' ).
return the default convention.

=cut

sub default_convention {
    my $convention = shift;
    return $_default_convention unless $convention;

    if ( grep { $_ eq $convention } @_valid_conventions ) {
        $_default_convention = $convention;
    }
    else {
        carp "invalid convention: $convention";
    }
    return $_default_convention;
}

=head2 default_keep_uppers

keep words of uppers or not, here uppers means all uppers like 'BAR', not 'bAr'.
default value is true

=cut

sub default_keep_uppers {
    if (@_) {
        $_default_keep_uppers = shift;
    }
    return $_default_keep_uppers;

}

=head2 naming

given a list of words, return the named string
the last arg can be hashref that supplies option like:
{ convention => 'UpperCamelCase' }

=cut

sub naming {
    my @words       = @_;
    my $convention  = $_default_convention;
    my $keep_uppers = $_default_keep_uppers;

    if ( ref $words[-1] eq 'HASH' ) {
        my $option = pop @words;

        # the last element is option
        if ( _is_valid_convention( $option->{convention} ) ) {
            $convention = $option->{convention};
        }
        else {
            carp "invlid convention: $option->{convention}";
        }

        if ( exists $option->{keep_uppers} ) {
            $keep_uppers = $option->{keep_uppers};
        }
    }

    for my $word (@words) {
        next if $keep_uppers && $word =~ /^[A-Z]+$/ && $convention =~ /Camel/;
        $word = lc $word;
    }

    if ( $convention eq '_' ) {
        return join '_', @words;
    }
    elsif ( $convention eq '-' ) {
        return join '-', @words;
    }
    elsif ( $convention eq 'UpperCamelCase' ) {
        return join '', map { ucfirst } @words;
    }
    elsif ( $convention eq 'lowerCamelCase' ) {
        my $first = shift @words;
        $first = lc $first;
        return $first . join '', map { ucfirst } @words;
    }
    else {
        carp "invalid $convention: $convention";
    }
}

sub _is_valid_convention {
    my $convention = shift;
    return unless $convention;
    return grep { $_ eq $convention } @_valid_conventions;
}

=head2 renaming

given a name, renaming it with another convention.
the last arg can be hashref that supplies option like:
{ convention => 'UpperCamelCase' }

return the renamed one.

if the convention is the same as the name, just return the name.

if without arguments and $_ is defined and it's not a reference, renaming $_


=cut

sub renaming {

    my ($name, $option);
    if ( scalar @_ ) {
        $name        = shift;
        $option      = shift;
    }
    elsif ( defined $_ && ! ref $_ ) {
        $name = $_;
    }
    else {
        return
    }

    my $convention  = $_default_convention;

    if ( $option && ref $option eq 'HASH' ) {

        # the last element is option
        if ( _is_valid_convention( $option->{convention} ) ) {
            $convention = $option->{convention};
        }
        else {
            carp "invlid convention: $option->{convention}";
        }

    }

    if ( $name =~ /(_)/ || $name =~ /(-)/ ) {
        my $from = $1;
        return $name if $convention eq $from;

        if ( ( $convention eq '_' || $convention eq '-' ) )
        {
            $name =~ s/$from/$convention/g;
            return $name;
        }
        else {
            $name =~ s/$from(.)/uc $1/ge;
            return ucfirst $name if $convention eq 'UpperCamelCase';
            return $name;
        }
    }
    else {
        if ( $convention eq '_' || $convention eq '-' ) {
            # massage the first word, FOOBar => fooBar
            $name =~ s/^([A-Z])([^A-Z])/lc( $1 ) . $2/e;
            $name =~ s/^([A-Z]+)(?![a-z])/lc $1/e;

            # massage the last word, FooBAR => FooBar
            $name =~ s/(?<=[A-Z])([A-Z]+(\d+)?)$/lc( $1 )/e;

            # e.g. fooBARBaz => foo_bar_baz
            # first step: fooBARBaz => fooBarBaz
            # second step: fooBarBaz => foo_bar_baz
            $name =~ s/([A-Z]+)([A-Z])/(ucfirst lc $1 ) . $2/ge;
            $name =~ s/([^A-Z])([A-Z])/$1 . $convention . lc $2/ge;
            # tr all the weirdly left [A-Z]
            $name =~ tr/A-Z/a-z/;
        }
        else {
            my $from = 'UpperCamelCase';
            $from = 'lowerCamelCase' if $name =~ /^[^A-Z]/;
            if ( $convention eq 'UpperCamelCase' && $convention ne $from ) {
                return ucfirst $name;
            }
            elsif ( $convention eq 'lowerCamelCase' && $convention ne $from ) {
                $name =~ s/^([A-Z])([^A-Z])/lc( $1 ) . $2/e;
                $name =~ s/^([A-Z]+)(?![a-z])/lc $1/e;
                return $name;
            }
        }
    }
    return $name;
}

1;

__END__

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

