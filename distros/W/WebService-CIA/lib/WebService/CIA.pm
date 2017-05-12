package WebService::CIA;

require 5.005_62;
use strict;
use warnings;
use Carp;

our $VERSION = '1.4';

$WebService::CIA::base_url = "https://www.cia.gov/library/publications/the-world-factbook/";

sub new {

    my $proto = shift;
    my $opts = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    unless (exists $opts->{Source}) {
        croak("WebService::CIA: No source object specified");
    }
    $self->{SOURCE} = $opts->{Source};

    bless ($self, $class);
    return $self;

}

sub get {

    my $self = shift;
    my ($cc, $f) = @_;
    my $value = $self->source->value($cc, $f);
    return $value;

}

sub get_all_hashref {

    my $self = shift;
    my $country = shift;
    my $data = {};
    foreach my $cc (@$country) {
        $data->{$cc} = $self->source->all($cc);
    }
    return $data;

}

sub get_hashref {

    my $self = shift;
    my ($country, $field) = @_;
    my $data = {};
    foreach my $cc (@$country) {
         $data->{$cc} = {};
         foreach my $f (@$field) {
             $data->{$cc}->{$f} = $self->source->value($cc, $f);
         }
    }
    return $data;

}

sub source {

    my $self = shift;
    return $self->{SOURCE};

}

1;

__END__

=head1 NAME

WebService::CIA - Get information from the CIA World Factbook.


=head1 SYNOPSIS

  use WebService::CIA;
  use WebService::CIA::Source::DBM;
  use WebService::CIA::Source::Web;

  # Get data from a pre-compiled DBM file

  my $source = WebService::CIA::Source::DBM->new({ DBM => "factbook.dbm" });
  my $cia = WebService::CIA->new({ Source => $source });
  $fact = $cia->get("uk", "Population");
  print $fact;

  # Get data direct from the CIA World Factbook

  my $source = WebService::CIA::Source::Web->new();
  my $cia = WebService::CIA->new({ Source => $source });
  $fact = $cia->get("uk", "Population");
  print $fact;


=head1 DESCRIPTION

A module which gets information from the CIA World Factbook.


=head1 Crypt::SSLeay

The most recent version of the CIA World Factbook uses HTTPS to access its
web pages. As such, WebService::CIA requires Crypt::SSLeay which suffers from
the usual cryptographic export restriction mumbo jumbo. Sorry about that.

Users of ActiveState's ActivePerl should see L<http://aspn.activestate.com/ASPN/Downloads/ActivePerl/PPM/Repository>
for instructions on downloading a PPM of Crypt::SSLeay.


=head1 METHODS

=over 4

=item C<new(\%opts)>

Creates a new WebService::CIA object. Takes a hashref, which must contain a "Source"
key whose value is a WebService::CIA::Storage object.


=item C<get($country_code, $field)>

This method retrieves information from the store.

It takes two arguments: a country code (as defined in FIPS 10-4 on
L<https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html>,
e.g. "uk", "us") and a field name (as defined in
L<https://www.cia.gov/library/publications/the-world-factbook/docs/notesanddefs.html>,
e.g. "Population", "Agriculture - products"). (WebService::CIA::Parser also
creates four extra fields: "URL", "URL - Print", "URL - Flag", and "URL -
Map" which are the URLs of the country's Factbook page, the printable
version of that page, a GIF map of the country, and a GIF flag of the
country respectively.)

The field name is very case and punctuation sensitive.

It returns the value of the field, or C<undef> if the field or country isn't
in the store.

Note that when using WebService::CIA::Store::Web, C<get> will also return C<undef> if
there is an error getting the page.


=item C<get_hashref(\@countries, \@fields)>

This method takes two arguments: an arrayref of country codes and an arrayref
of field names.

It returns a hashref of the form

  {
   'country1' => {
                  'field1' => 'value',
                  'field2' => 'value'
                 },
   'country2' => {
                  'field1' => 'value',
                  'field2' => 'value'
                 }
  }

=item C<get_all_hashref(\@countries)>

Get all the fields available for countries.

It takes one argument, an arrayref of country codes.

It returns a hashref similar to the one from C<get_hashref> above,
containing all the fields available for each country.

=item C<source()>

Get a reference to the WebService::CIA::Source object in use.

=back


=head1 CONFIGURATION VARIABLES

=over 4

=item C<$WebService::CIA::base_url>

Sets the base URL for the Factbook (currently 
"https://www.cia.gov/library/publications/the-world-factbook/"). If the
Factbook changes location, this can be changed to point to the new location
(assuming the relative structure of the Factbook is unchanged).

=back


=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2003-2007, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The CIA World Factbook's copyright information page
(L<https://www.cia.gov/library/publications/the-world-factbook/docs/contributor_copyright.html>)
states:

  The Factbook is in the public domain. Accordingly, it may be copied
  freely without permission of the Central Intelligence Agency (CIA).


=head1 SEE ALSO

WebService::CIA::Parser, WebService::CIA::Source::DBM, WebService::CIA::Source::Web


=cut
