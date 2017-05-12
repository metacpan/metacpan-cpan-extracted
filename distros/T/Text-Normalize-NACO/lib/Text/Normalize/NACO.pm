package Text::Normalize::NACO;

=head1 NAME

Text::Normalize::NACO - Normalize text based on the NACO rules

=head1 SYNOPSIS

    # exported method
    use Text::Normalize::NACO qw( naco_normalize );
    
    $normalized = naco_normalize( $original );
    
    # as an object
    $naco       = Text::Normalize::NACO->new;
    $normalized = $naco->normalize( $original );

    # normalize to lowercase
    $naco->case( 'lower' );
    $normalized = $naco->normalize( $original );

=head1 DESCRIPTION

In general, normalization is defined as:

    To make (a text or language) regular and consistent, especially with respect to spelling or style.

It is commonly used for comparative purposes. These particular normalization rules have been set out by the
Name Authority Cooperative. The rules are described in detail at: http://www.loc.gov/catdir/pcc/naco/normrule.html

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=cut

use base qw( Exporter );

use strict;
use warnings;

use Text::Unidecode;

our $VERSION = '0.13';

our @EXPORT_OK = qw( naco_normalize );

=head1 METHODS

=head2 new( %options )

Creates a new Text::Normalize::NACO object. You explicitly request
strings to be normalized in upper or lower-case by setting
the "case" option (defaults to "upper").

    my $naco = Text::Normalize::NACO->new( case => 'lower' );

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    my $self    = bless {}, $class;

    $self->case( $options{ case } || 'upper' );

    return $self;
}

=head2 case( $case )

Accessor/Mutator for the case in which the string should be returned.

    # lower-case
    $naco->case( 'lower' );

    # upper-case
    $naco->case( 'upper' );

=cut

sub case {
    my $self = shift;
    my ( $case ) = @_;

    $self->{ _CASE } = $case if @_;

    return $self->{ _CASE };
}

=head2 naco_normalize( $text, { %options } )

Exported version of C<normalize>. You can specify any extra
options by passing a hashref after the string to be normalized.

    my $normalized = naco_normalize( $original, { case => 'lower' } );

=cut

sub naco_normalize {
    my $text    = shift;
    my $options = shift;
    my $case    = $options->{ case } || 'upper';

    my $normalized = normalize( undef, $text );

    if ( $case eq 'lower' ) {
        $normalized =~ tr/A-Z/a-z/;
    }
    else {
        $normalized =~ tr/a-z/A-Z/;
    }

    return $normalized;
}

=head2 normalize( $text )

Normalizes $text and returns the new string.

    my $normalized = $naco->normalize( $original );

=cut

sub normalize {
    my $self = shift;
    my $data = shift;

    # Rules taken from NACO Normalization
    # http://lcweb.loc.gov/catdir/pcc/naco/normrule.html

    # Remove diacritical marks and convert special chars
    unidecode( $data );

    # Convert special chars to spaces
    $data =~ s/[\Q!(){}<>-;:.?,\/\\@*%=\$^_~\E]/ /g;

    # Delete special chars
    $data =~ s/[\Q'[]|\E]//g;

    # Convert lowercase to uppercase or vice-versa.
    if ( $self ) {
        if ( $self->case eq 'lower' ) {
            $data =~ tr/A-Z/a-z/;
        }
        else {
            $data =~ tr/a-z/A-Z/;
        }
    }

    # Remove leading and trailing spaces
    $data =~ s/^\s+|\s+$//g;

    # Condense multiple spaces
    $data =~ s/\s+/ /g;

    return $data;
}

=head1 SEE ALSO

=over 4

=item * http://www.loc.gov/catdir/pcc/naco/normrule.html

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
