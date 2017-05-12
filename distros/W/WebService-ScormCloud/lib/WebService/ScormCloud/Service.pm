package WebService::ScormCloud::Service;

use Moose::Role;

=head1 NAME

WebService::ScormCloud::Service - ScormCloud API base class

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use WebService::ScormCloud;

    my $ScormCloud = WebService::ScormCloud->new(
                        app_id      => '12345678',
                        secret_key  => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    );

    print "Service is alive\n" if $ScormCloud->ping;

    print "Auth is valid\n"    if $ScormCloud->authPing;

=head1 DESCRIPTION

This module defines L<WebService::ScormCloud> shared API methods.
See L<WebService::ScormCloud> for more info.

=cut

use Carp;
use Data::Dump 'dump';
use Digest::MD5 qw(md5_hex);
use HTTP::Request::Common;
use POSIX qw(strftime);
use Try::Tiny;
use XML::Simple;

use Readonly;
Readonly::Scalar my $DUMP_WIDTH => 40;

=head1 METHODS

=head2 request_uri ( I<params> )

Returns a URI object that would be used to make a ScormCloud API
request.

Note that you would not typically call this method directly - use
the API methods defined in the L</API CLASSES> instead.

The params hashref should contain all query params and values used
in building the request query string.  At minimum it must include a
value for "method".

=cut

sub request_uri
{
    my ($self, $params) = @_;

    $params ||= {};

    croak 'No method' unless $params->{method};

    my $top_level_namespace = $self->top_level_namespace;
    unless ($params->{method} =~ /^$top_level_namespace[.]/xsm)
    {
        $params->{method} = $top_level_namespace . q{.} . $params->{method};
    }

    $params->{appid} ||= $self->app_id;

    $params->{ts} ||= strftime '%Y%m%d%H%M%S', gmtime;

    my $sig = join q{}, map { $_ . $params->{$_} } sort keys %{$params};
    $params->{sig} = md5_hex($self->secret_key . $sig);

    my $uri = $self->service_url->clone;
    $uri->query_form($params);

    $self->_dump_data($uri . q{}) if $self->dump_request_url;

    return $uri;
}

=head2 request ( I<params> [ , I<args> ] )

Make an API request:

    my $parsed_response_data =
      $ScormCloud->request(method => 'rustici.debug.authPing');

Note that you would not typically call this method directly - use
the API methods defined in the L</API CLASSES> instead.

=cut

sub request
{
    my ($self, $params, $args) = @_;

    my $uri = $self->request_uri($params);

    $args                    ||= {};
    $args->{request_method}  ||= 'GET';
    $args->{request_headers} ||= {};
    $args->{xml_parser}      ||= {};

    my %request_args = %{$args->{request_headers}};

    # If set, "request_content" should be a listref.  E.g. for a
    # file upload:
    #
    #     $args->{request_content} = [file => ['/path/to/file']];
    #
    if ($args->{request_content})
    {
        $args->{request_method}     = 'POST';
        $request_args{Content_Type} = 'form-data';
        $request_args{Content}      = $args->{request_content};
    }

    my $http_request;
    {
        no strict 'refs';   ## no critic (TestingAndDebugging::ProhibitNoStrict)
        $http_request = $args->{request_method}->($uri, %request_args);
    }

    return $self->_make_http_request($http_request, $args);
}

sub _make_http_request
{
    my ($self, $http_request, $args) = @_;

    my $response = $self->lwp_user_agent->request($http_request);

    $self->last_error_data([]);

    my $response_data = undef;

    if ($response->is_success)
    {
        try
        {
            $self->_dump_data($response->content) if $self->dump_response_xml;

            # Add some extra handling in case we get an error response:
            #
            my $force_array = delete $args->{xml_parser}->{ForceArray} || [];
            my $group_tags  = delete $args->{xml_parser}->{GroupTags}  || {};
            push @{$force_array}, 'err', 'tracetext';
            $group_tags->{stacktrace} = 'tracetext';

            $response_data =
              XML::Simple->new->XMLin(
                                      $response->content,
                                      KeyAttr       => [],
                                      SuppressEmpty => q{},
                                      ForceArray    => $force_array,
                                      GroupTags     => $group_tags,
                                      %{$args->{xml_parser}}
                                     ) || {};

            # Response data should always include "stat".  Make sure it
            # exists, so callers can safely assume it is always there:
            #
            $response_data->{stat} ||= 'fail';
        }
        catch
        {
            $response_data = {
                              stat => 'fail',
                              err  => [
                                      {
                                       code => 999,
                                       msg  => 'XML PARSE FAILURE: ' . $_
                                      }
                                     ]
                             };
        };
    }
    else
    {
        $response_data = {
                      stat => 'fail',
                      err  => [
                          {
                           code => 999,
                           msg => 'BAD HTTP RESPONSE: ' . $response->status_line
                          }
                      ]
        };
    }

    if ($response_data->{stat} eq 'fail')
    {
        $response_data->{err} ||= [{code => 999, msg => 'FAIL BUT NO ERR'}];

        $self->last_error_data($response_data->{err});

        croak "Invalid API response data:\n" . dump($response_data)
          if $self->die_on_bad_response;
    }

    $self->_dump_data($response_data) if $self->dump_response_data;

    return $response_data;
}

sub _dump_data
{
    my ($self, $data) = @_;

    print q{=} x $DUMP_WIDTH, "\n", dump($data), "\n", q{=} x $DUMP_WIDTH, "\n";

    return;
}

=head2 process_request ( I<params>, I<callback> )

Make an API request, and return desired data out of the response.

Input arguments are:

=over 4

=item B<params>

A hashref of API request params.  At minimum must include "method".

=item B<callback>

A callback function that extracts and returns the desired data from
the response data.  The callback should expect a single argument
"response" which is the parsed XML response data.

=item B<args>

An optional hashref of arguments to modify the request.

=back

=cut

sub process_request
{
    my ($self, $params, $callback, $args) = @_;

    croak 'Missing request params' unless $params;
    croak 'Missing callback'       unless $callback;

    my $response_data = $self->request($params, $args);

    my $data = undef;

    if ($response_data->{stat} eq 'ok')
    {
        try
        {
            $data = $callback->($response_data);
        };
    }

    unless (defined $data)
    {
        croak "Invalid API response data:\n" . dump($response_data)
          if $self->die_on_bad_response;
    }

    $self->_dump_data($data) if $self->dump_api_results;

    return $data;
}

1;

__END__

=head1 SEE ALSO

L<WebService::ScormCloud>

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scormcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ScormCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Patches more than welcome, especially via GitHub:
L<https://github.com/larryl/ScormCloud>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ScormCloud::Service

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/larryl/ScormCloud>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ScormCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ScormCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ScormCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ScormCloud/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Larry Leszczynski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

