package Webservice::GAMSTOP;
# ABSTRACT: GAMSTOP API Client Implementation

use strict;
use warnings;

use Moo;
use Email::Valid;
use Mojo::UserAgent;

use Webservice::GAMSTOP::Response;

our $VERSION = '0.003';

=head1 NAME

Webservice::GAMSTOP - GAMSTOP API Client Implementation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Webservice::GAMSTOP;
    my $instance = Webservice::GAMSTOP->new(
        api_url => 'gamstop_api_url',
        api_key => 'gamstop_api_key',
        # optional (defaults to 5 seconds)
        timeout => 10,
    );

    $instance->get_exclusion_for(
        first_name    => 'Harry',
        last_name     => 'Potter',
        email         => 'harry.potter@example.com',
        date_of_birth => '1970-01-01',
        postcode      => 'hp11aa',
    );

=head1 DESCRIPTION

This module implements a programmatic interface to
[GAMSTOP](https://www.gamstop.co.uk/) API.

=head1 PRE-REQUISITE

Before you can use this module, you'll need to obtain your
own "Unique API Key" from [GAMSTOP](https://www.gamstop.co.uk/).

=cut

=head1 ATTRIBUTES

L<Webservice::GAMSTOP> implements the following attributes

=head2 api_url

GAMSTOP API endpoint url (REQUIRED)

=cut

has api_url => (
    is       => 'ro',
    required => 1,
);

=head2 api_key

GAMSTOP API unique key for operator (REQUIRED)

=cut

has api_key => (
    is       => 'ro',
    required => 1,
);

=head2 timeout

Maximum amount of time in seconds establishing a
connection may take before getting canceled
(OPTIONAL - DEFAULT 5 seconds)

=cut

has timeout => (
    is      => 'ro',
    default => 5,
);

has _ua => (
    is => 'lazy',
);

sub _build__ua {
    return Mojo::UserAgent->new->connect_timeout(shift->timeout);
}

=head1 METHODS

=head2 get_exclusion_for

Given user details return L<Webservice::GAMSTOP::Response> object
Note: it dies if an error occur connecting to GAMSTOP API endpoint

=head3 Required parameters

=over 4

=item * first_name   : First name of person, only 20 characters are significant

=item * last_name    : Last name of person, only 20 characters are significant

=item * date_of_birth: Date of birth in ISO format (yyyy-mm-dd)

=item * email        : Email address

=item * postcode     : Postcode (spaces not significant)

=back

=head3  Optional parameters

=over 4

x_trace_id: A freeform field that is put into audit log that can be used
by the caller to identify a request. This might be something to indicate
the person being checked, a unique request ID, GUID, or a trace ID from
a system such as zipkin.

=back

=head3 Return value

=over 4

A L<Webservice::GAMSTOP::Response> object

=back

=cut

sub get_exclusion_for {
    my ($self, %args) = @_;

    die "Missing required parameter: first_name."    unless (exists $args{first_name});
    die "Missing required parameter: last_name."     unless (exists $args{last_name});
    die "Missing required parameter: date_of_birth." unless (exists $args{date_of_birth});
    die "Missing required parameter: email."         unless (exists $args{email});
    die "Missing required parameter: postcode."      unless (exists $args{postcode});

    # validate args
    die 'Invalid date of birth. Date of birth should be in ISO format (yyyy-mm-dd)'
        unless $args{'date_of_birth'} =~ /^(?:\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))$/;
    die 'Invalid email.' unless Email::Valid->address($args{email});
    die 'Invalid postcode.' unless $args{postcode} =~ /^[^+]{0,20}$/;

    # required parameters
    my $form_params = {
        firstName   => $args{first_name},
        lastName    => $args{last_name},
        dateOfBirth => $args{date_of_birth},
        email       => $args{email},
        postcode    => $args{postcode},
    };

    # optional parameters
    $form_params->{'X-Trace-Id'} = $args{x_trace_id} if $args{x_trace_id};

    my $ua = $self->_ua;
    $ua->on(
        start => sub {
            my ($useragent, $tx) = @_;
            $tx->req->headers->header('X-API-Key' => $self->api_key);
        });

    my $tx = $ua->post($self->api_url => form => $form_params);

    if (my $err = $tx->error) {
        die 'Error - ' . $err->{code} . ' response: ' . $err->{message} if $err->{code};
        die 'Error - Connection error: ' . $err->{message};
    }

    my $headers = $tx->success->headers;
    return Webservice::GAMSTOP::Response->new(
        exclusion => $headers->header('x-exclusion'),
        date      => $headers->header('date'),
        unique_id => $headers->header('x-unique-id'),
    );
}

1;
__END__

=head1 AUTHOR

binary.com <cpan@binary.com>

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
