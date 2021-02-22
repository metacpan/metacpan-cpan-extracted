package Text::BibTeX::Validate;

use strict;
use warnings;

# ABSTRACT: validator for BibTeX format
our $VERSION = '0.3.0'; # VERSION

use Algorithm::CheckDigits;
use Data::Validate::Email qw( is_email_rfc822 );
use Data::Validate::URI qw( is_uri );
use Scalar::Util qw( blessed );
use Text::BibTeX::Validate::Warning;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    clean_BibTeX
    shorten_DOI
    validate_BibTeX
);

my @months = qw(
    january
    february
    march
    april
    may
    june
    july
    august
    september
    october
    november
    december
);

=head1 NAME

Text::BibTeX::Validate - validator for BibTeX format

=head1 SYNOPSIS

    use Text::BibTeX;
    use Text::BibTeX::Validate qw( validate_BibTeX );

    my $bibfile = Text::BibTeX::File->new( 'bibliography.bib' );
    while( my $entry = Text::BibTeX::Entry->new( $bibfile ) ) {
        for my $warning (validate_BibTeX( $entry )) {
            print STDERR "$warning\n";
        }
    }

=head1 DESCRIPTION

Text::BibTeX::Validate checks the standard fields of BibTeX entries for
their compliance with their format. In particular, value of C<email> is
checked against RFC 822 mandated email address syntax, value of C<doi>
is checked to start with C<10.> and contain at least one C</> and so on.
Some nonstandard fields as C<isbn>, C<issn> and C<url> are also checked.
Failures of checks are returned as instances of
L<Text::BibTeX::Validate::Warning|Text::BibTeX::Validate::Warning>.

=head1 METHODS

=cut

sub shorten_DOI($);

=head2 validate_BibTeX( $what )

Takes plain Perl hash reference containing BibTeX fields and their
values, as well as L<Text::BibTeX::Entry|Text::BibTeX::Entry> instances
and returns an array of validation messages as instances of
L<Text::BibTeX::Validate::Warning|Text::BibTeX::Validate::Warning>.

=cut

sub validate_BibTeX
{
    my( $what ) = @_;
    my $entry = _convert( $what );

    my @warnings;

    # Report and remove empty keys
    for my $key (sort keys %$entry) {
        next if defined $entry->{$key};
        push @warnings,
             _warn_value( 'undefined value', $entry, $key );
        delete $entry->{$key};
    }

    if( exists $entry->{email} &&
        !defined is_email_rfc822 $entry->{email} ) {
        push @warnings,
             _warn_value( 'value \'%(value)s\' does not look like valid ' .
                          'email address',
                          $entry,
                          'email' );
    }

    if( exists $entry->{doi} ) {
        my $doi = $entry->{doi};
        my $doi_now = shorten_DOI $doi;

        if( $doi_now !~ m|^10\.[^/]+/| ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' does not look like valid DOI',
                              $entry,
                              'doi' );
        } elsif( $doi ne $doi_now ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' is better written as \'%(suggestion)s\'',
                              $entry,
                              'doi',
                              { suggestion => $doi_now } );
        }
    }

    # Validated according to BibTeX recommendations
    if( exists $entry->{month} ) {
        if( $entry->{month} =~ /^0?[1-9]|1[12]$/ ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' is better written as \'%(suggestion)s\'',
                              $entry,
                              'month',
                              { suggestion => ucfirst substr( $months[$entry->{month}-1], 0, 3 ) } );
        } elsif( grep { lc $entry->{month} eq $_ && length $_ > 3 } @months ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' is better written as \'%(suggestion)s\'',
                              $entry,
                              'month',
                              { suggestion => ucfirst substr( $entry->{month}, 0, 3 ) } );
        } elsif( !(grep { lc $entry->{month} eq substr( $_, 0, 3 ) ||
                          lc $entry->{month} eq substr( $_, 0, 3 ) . '.' } @months) ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' does not look like valid month',
                              $entry,
                              'month' );
        }
    }

    if( exists $entry->{year} ) {
        # Sometimes bibliographies list the next year to show that they
        # are going to be published soon.
        my @localtime = localtime;
        if( $entry->{year} !~ /^[0-9]{4}$/ ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' does not look like valid year',
                              $entry,
                              'year' );
        } elsif( $entry->{year} > $localtime[5] + 1901 ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' is too far in the future',
                              $entry,
                              'year' );
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
        push @warnings,
             _warn_value( 'value \'%(value)s\' does not look like valid %(FIELD)s',
                          $entry,
                          $key,
                          { FIELD => uc $key } );
    }

    # Both keys are nonstandard
    for my $key ('eprint', 'url') {
        next if !exists $entry->{$key};
        next if defined is_uri $entry->{$key};

        if( $entry->{$key} =~ /^(.*)\n$/ && defined is_uri $1 ) {
            # BibTeX converted from YAML (i.e., Debian::DEP12) might
            # have trailing newline character attached.
            push @warnings,
                 _warn_value( 'URL has trailing newline character',
                              $entry,
                              $key,
                              { suggestion => $1 } );
            next;
        }

        push @warnings,
             _warn_value( 'value \'%(value)s\' does not look like valid URL',
                          $entry,
                          $key );
    }

    # Nonstandard
    if( exists $entry->{pmid} ) {
        if( $entry->{pmid} =~ /^PMC[0-9]{7}$/ ) {
            push @warnings,
                 _warn_value( 'PMCID \'%(value)s\' is provided instead of PMID',
                              $entry,
                              'pmid' );
        } elsif( $entry->{pmid} !~ /^[1-9][0-9]*$/ ) {
            push @warnings,
                 _warn_value( 'value \'%(value)s\' does not look like valid PMID',
                              $entry,
                              'pmid' );
        }
    }

    return @warnings;
}

=head2 clean_BibTeX( $what )

Takes the same input as C<validate_BibTeX> and attempts to reconcile
trivial issues like dropping the resolver URL part of DOIs (see
C<shorten_DOI> method) and converting month numbers into three-letter
abbreviations.

=cut

sub clean_BibTeX
{
    my( $what ) = @_;
    my $entry = _convert( $what );

    # Deleting undefined values prior to the validation
    for (keys %$entry) {
        delete $entry->{$_} if !defined $entry->{$_};
    }

    my @warnings = validate_BibTeX( $entry );
    my @suggestions = grep { $_->{suggestion} } @warnings;

    for my $suggestion (@suggestions) {
        $entry->{$suggestion->{field}} = $suggestion->{suggestion};
    }

    return $entry;
}

=head2 shorten_DOI( $doi )

Remove the resolver URL part, as well as C<doi:> prefixes, from DOIs.

=cut

sub shorten_DOI($)
{
    my( $doi ) = @_;

    return $doi if $doi =~ s|^https?://(dx\.)?doi\.org/||;
    return $doi if $doi =~ s|^doi:||;
    return $doi;
}

sub _convert
{
    my( $what ) = @_;

    if( blessed $what && $what->isa( 'Text::BibTeX::Entry' ) ) {
        $what = { map { $_ => $what->get($_) } $what->fieldlist };
    }

    # TODO: check for duplicated keys
    return { map { lc $_ => $what->{$_} } keys %$what };
}

sub _warn_value
{
    my( $message, $entry, $field, $extra ) = @_;
    $extra = {} unless $extra;
    return Text::BibTeX::Validate::Warning->new(
            $message,
            { field => $field,
              value => $entry->{$field},
              %$extra } );
}

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
