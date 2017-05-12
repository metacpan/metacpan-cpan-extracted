package WebService::CIA::Source::Web;

require 5.005_62;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use Crypt::SSLeay;
use WebService::CIA;
use WebService::CIA::Parser;
use WebService::CIA::Source;

@WebService::CIA::Source::Web::ISA = ("WebService::CIA::Source");

our $VERSION = '1.4';

# Preloaded methods go here.

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $args = shift || {};
    if ( ! ref $args || ref $args ne "HASH" ) {
        croak "Arguments to new() must be a hashref";
    }
    my $self = {};
    $self->{CACHED} = "";
    $self->{CACHE} = {};
    $self->{PARSER} = WebService::CIA::Parser->new;
    bless ($self, $class);
    if ( exists $args->{ user_agent } ) {
        $self->ua( $args->{ user_agent } );
    }
    return $self;

}

sub value {

    my $self = shift;
    my ($cc, $f) = @_;

    unless ($self->cached eq $cc) {
        unless ($self->get($cc)) {
            return;
        }
    }

    if (exists $self->cache->{$f}) {
        return $self->cache->{$f};
    } else {
        return;
    }

}

sub all {

    my $self = shift;
    my $cc = shift;

    unless ($self->cached eq $cc) {
        unless ($self->get($cc)) {
            return {};
        }
    }

    return $self->cache;

}

sub get {

    my $self = shift;
    my $cc = shift;
    my $response = $self->ua->get($WebService::CIA::base_url . "print/$cc.html");
    $self->last_response( $response );
    if ($response->is_success) {
        my $data = $self->parser->parse($cc, $response->content);
        $self->cache($data);
        $self->cached($cc);
        return 1;
    } else {
        return 0;
    }

}

sub ua {

    my ( $self, $ua ) = @_;
    if ( defined $ua ) {
        $self->{ UA } = $ua;
    }
    if ( ! defined $self->{ UA } ) {
        $self->{ UA } = LWP::UserAgent->new;
        $self->{ UA }->env_proxy;
    }
    return $self->{UA};

}

sub parser {

    my $self = shift;
    return $self->{PARSER};

}

sub cached {

    my $self = shift;
    if (@_) {
        $self->{CACHED} = shift;
    }
    return $self->{CACHED};

}

sub cache {

    my $self = shift;
    if (@_) {
        $self->{CACHE} = shift;
    }
    return $self->{CACHE};

}

sub last_response {
    my ( $self, $response ) = @_;
    if ( defined $response ) {
        $self->{ LAST_RESPONSE } = $response;
    }
    return $self->{ LAST_RESPONSE };
}

1;

__END__


=head1 NAME

WebService::CIA::Source::Web - An interface to the online CIA World Factbook


=head1 SYNOPSIS

  use WebService::CIA::Source::Web;
  my $source = WebService::CIA::Source::DBM->new();


=head1 DESCRIPTION

WebService::CIA::Source::Web is an interface to the live, online version of the CIA
World Factbook.

It's a very slow way of doing things, but requires no pre-compiled DBM. It's
more likely to be useful for proving concepts or testing.


=head1 METHODS

Apart from C<new>, these methods are normally accessed via a WebService::CIA object.

=over 4

=item C<new( \%opts )>

    my $source = WebService::CIA::Source::Web->new();
    $source = WebService::CIA::Source::Web->new( { user_agent => $ua } );


This method creates a new WebService::CIA::Source::Web object. It takes an optional hashref of arguments.

=over 4

=item C<user_agent>

A user agent object to use. This must implement the same user interface
as C<LWP::UserAgent> (or, at least, a C<get()> method).

=back

=item C<value($country_code, $field)>

Retrieve a value from the web.

C<$country_code> should be the FIPS 10-4 country code as defined in
L<https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html>.

C<$field> should be the name of the field whose value you want to
retrieve, as defined in
L<https://www.cia.gov/library/publications/the-world-factbook/docs/notesanddefs.html>.
(WebService::CIA::Parser also creates four extra fields: "URL", "URL - Print",
"URL - Flag", and "URL - Map" which are the URLs of the country's Factbook
page, the printable version of that page, a GIF map of the country, and a
GIF flag of the country respectively.)

C<value> will return C<undef> if the country or field cannot be found, or if
there is an error GETing the page. This isn't ideal, but I can't think of the
best way around it right now.

=item C<all($country_code)>

Returns a hashref of field-value pairs for C<$country_code> or an empty
hashref if C<$country_code> isn't available from the Factbook.

=item C<get($country_code)>

Retrieve and cache the data for a country.

Returns 1 if successful, 0 if not.

=item C<cached($country_code)>

Get/set the country code whose data is cached.

=item C<cache($hashref)>

Get/set a hashref of data for the current country.

=item C<parser()>

Returns a reference to the WebService::CIA::Parser object being used.

=item C<ua( $userAgent )>

Returns a reference to the user agent object being used. By default
this is an C<LWP::UserAgent> object, but you can pass a different object
in if you wish.

=item C<last_response()>

Returns the C<HTTP::Response> object from the last request.

=back

=head1 CACHING

In order to make some small improvement in efficiency, WebService::CIA::Source::Web
keeps a copy of the data for the last country downloaded in memory.


=head1 TO DO

=over 4

=item File system based caching of pages.

=item User-definable stack of cached countries, rather than just one.

=item Caching of last-modified headers; conditional GET.


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

WebService::CIA, WebService::CIA::Parser, WebService::CIA::Source::DBM

=cut
