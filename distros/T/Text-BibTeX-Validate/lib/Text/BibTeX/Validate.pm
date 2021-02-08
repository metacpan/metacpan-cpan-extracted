package Text::BibTeX::Validate;

use strict;
use warnings;

# ABSTRACT: validator for BibTeX format
our $VERSION = '0.1.1'; # VERSION

use Algorithm::CheckDigits;
use Data::Validate::Email qw( is_email_rfc822 );
use Data::Validate::URI qw( is_uri );
use Scalar::Util qw( blessed );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    validate_BibTeX
);

sub validate_BibTeX
{
    my( $what ) = @_;

    if( blessed $what && $what->isa( 'Text::BibTeX::Entry' ) ) {
        $what = { map { $_ => $what->get($_) } $what->fieldlist };
    }

    # TODO: check for duplicated keys
    my $entry = { map { lc $_ => $what->{$_} } keys %$what };

    if( exists $entry->{email} &&
        !defined is_email_rfc822 $entry->{email} ) {
        warn sprintf 'email: value \'%s\' does not look like valid ' .
                     'email address' . "\n",
                     $entry->{email};
    }

    if( exists $entry->{doi} ) {
        my $doi = $entry->{doi};
        if( $entry->{doi} =~ m|^https?://doi\.org/(10\.[^/]+/.*)$| ) {
            warn sprintf 'doi: value \'%s\' is better written as \'%s\'' . "\n",
                         $entry->{doi},
                         $1;
        } elsif( $entry->{doi} !~ m|^(doi:)?10\.[^/]+/.*| ) {
            warn sprintf 'doi: value \'%s\' does not look like valid DOI' . "\n",
                         $entry->{doi};
        }
    }

    # Validated according to BibTeX recommendations
    if( exists $entry->{month} &&
        $entry->{month} !~ /^(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\.?$/i ) {
        warn sprintf 'month: value \'%s\' does not look like valid month' . "\n",
                     $entry->{month};
    }

    if( exists $entry->{year} ) {
        # Sometimes bibliographies list the next year to show that they
        # are going to be published soon.
        my @localtime = localtime;
        if( $entry->{year} !~ /^[0-9]{4}$/ ) {
            warn sprintf 'year: value \'%s\' does not look like valid year' . "\n",
                         $entry->{year};
        } elsif( $entry->{year} > $localtime[5] + 1901 ) {
            warn sprintf 'year: value \'%s\' is too far in the future' . "\n",
                         $entry->{year};
        }
    }

    # Both keys are nonstandard
    for my $key ('isbn', 'issn') {
        next if !exists $entry->{$key};
        my $check = CheckDigits( $key );
        if( $key eq 'isbn' ) {
            my $value = $entry->{$key};
            $value =~ s/-//g;
            if( length $value == 13 ) {
                $check = CheckDigits( 'isbn13' );
            }
        }
        next if $check->is_valid( $entry->{$key} );
        warn sprintf '%s: value \'%s\' does not look like valid %s' . "\n",
                     $key,
                     $entry->{$key},
                     uc $key;
    }

    # Both keys are nonstandard
    for my $key ('eprint', 'url') {
        next if !exists $entry->{$key};
        next if defined is_uri $entry->{$key};
        warn sprintf '%s: value \'%s\' does not look like valid URL' . "\n",
                     $key,
                     $entry->{$key};
    }

    # Nonstandard
    if( exists $entry->{pmid} ) {
        if( $entry->{pmid} !~ /^[1-9][0-9]*$/ ) {
            warn sprintf 'pmid: value \'%s\' does not look like valid PMID' . "\n",
                         $entry->{pmid};
        }
    }
}

1;

__END__

=pod

=head1 NAME

Text::BibTeX::Validate - validator for BibTeX format

=head1 SYNOPSIS

    use Text::BibTeX;
    use Text::BibTeX::Validate qw( validate_BibTeX );

    my $bibfile = Text::BibTeX::File->new( 'bibliography.bib' );
    while( my $entry = Text::BibTeX::Entry->new( $bibfile ) ) {
        validate_BibTeX( $entry );
    }

=head1 DESCRIPTION

Text::BibTeX::Validate checks the standard fields of BibTeX entries for
their compliance with their format. In particular, value of C<email> is
checked against RFC 822 mandated email address syntax, value of C<doi>
is checked to start with C<10.> and contain at least one C</> and so on.
Some nonstandard fields as C<isbn>, C<issn> and C<url> are also checked.
Failures of checks are raised as Perl warnings.

Subroutine C<validate_BibTeX> currently accepts plain Perl hash
references containing BibTeX fields and their values, as well as
L<Text::BibTeX::Entry|Text::BibTeX::Entry> objects.

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut
