package WebService::ScormCloud;

use Moose;

=head1 NAME

WebService::ScormCloud - Interface to cloud.scorm.com

=head1 DESCRIPTION

This module provides an API interface to cloud.scorm.com, which is a
web service provided by Rustici Software (L<http://www.scorm.com/>).

API docs can be found at
L<http://cloud.scorm.com/EngineWebServices/doc/SCORMCloudAPI.html>.

The author of this module has no affiliation with Rustici Software
other than as a user of the interface.

Registered trademarks are property of their respective owners.

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

=cut

use WebService::ScormCloud::Types;

=head1 API CLASSES

Each portion of the API is defined in its own class:

L<WebService::ScormCloud::Service::Course>

L<WebService::ScormCloud::Service::Debug>

L<WebService::ScormCloud::Service::Registration>

L<WebService::ScormCloud::Service::Reporting>

L<WebService::ScormCloud::Service::Upload>

=cut

with
  'WebService::ScormCloud::Service::Course',
  'WebService::ScormCloud::Service::Debug',
  'WebService::ScormCloud::Service::Registration',
  'WebService::ScormCloud::Service::Reporting',
  'WebService::ScormCloud::Service::Upload',
  ;

=head1 USAGE

=head2 new( I<%args> )

Construct a C<WebService::ScormCloud> object to communicate with the API.

B<Note:> Any of the following constructor parameters can also be
called post-construction as object set/get methods.

=over 4

=item B<app_id>

B<Required.>  An application ID generated for your login at
L<http://cloud.scorm.com/>.

=cut

has 'app_id' => (
                 is       => 'rw',
                 required => 1,
                 isa      => 'Str',
                );

=item B<secret_key>

B<Required.>  A secret key that corresponds to the application ID,
used for hashing parameters in the API request URLs.  Generated at
L<http://cloud.scorm.com/>.

=cut

has 'secret_key' => (
                     is       => 'rw',
                     required => 1,
                     isa      => 'Str',
                    );

=item B<service_url>

The API service URL.  Defaults to "http://cloud.scorm.com/api".

=cut

has 'service_url' => (
                      is       => 'rw',
                      required => 1,
                      isa      => 'WebService::ScormCloud::Types::URI',
                      coerce   => 1,
                      default  => 'http://cloud.scorm.com/api',
                     );

=item B<last_error_data>

Returns a listref representing the raw response data for the
error(s) returned by the most recent ScormCloud service API call.

The data will look like:

    [
        {
         code => 100.
         msg  => 'A general security error has occured',
        }
        ...
    ]

Useful if e.g. "die_on_bad_response" is set to false, and a service
API call returns undef instead of the expected object.

=cut

has 'last_error_data' => (
                          is      => 'rw',
                          isa     => 'ArrayRef',
                          default => sub { return [] },
                         );

=item B<last_error_msg>

Return a error message representing the error(s) returned by the
most recent ScormCloud service API call.

Useful if e.g. "die_on_bad_response" is set to false, and a service
API call returns undef instead of the expected object.

=cut

my %error_codes = ();

sub last_error_msg
{
    my ($self) = @_;

    my @msg = ();

    foreach my $error (@{$self->last_error_data})
    {
        my $msg = $error->{msg};
        $msg =~ s/^\s+//msx;
        $msg =~ s/\s+$//msx;
        $msg =~ s/\s+/ /msx;
        $msg =~ s/ associated with appid \[.*?\]//gmsx;

        push @msg, $msg;
    }

    return join("\n", @msg);
}

=item B<lwp_user_agent>

Set the user agent string used in API requests.  Defaults to "MyApp/1.0".

=cut

has 'lwp_user_agent' => (
                         is       => 'rw',
                         required => 1,
                         isa => 'WebService::ScormCloud::Types::LWP::UserAgent',
                         coerce  => 1,
                         default => 'MyApp/1.0',
                        );

=item B<top_level_namespace>

Top-level namespace for API methods.  Defaults to "rustici".

=cut

has 'top_level_namespace' => (
                              is       => 'rw',
                              required => 1,
                              isa      => 'Str',
                              default  => 'rustici',
                             );

=item B<dump_request_url>

Set to true to dump request URLs to STDOUT.  Default is false.

=cut

has 'dump_request_url' => (
                           is      => 'rw',
                           isa     => 'Bool',
                           default => 0,
                          );

=item B<dump_response_xml>

Set to true to dump raw response XML to STDOUT.  Default is false.

=cut

has 'dump_response_xml' => (
                            is      => 'rw',
                            isa     => 'Bool',
                            default => 0,
                           );

=item B<dump_response_data>

Set to true to dump data from parsed response XML to STDOUT.
Default is false.

Parsing is currently done with L<XML::Simple>.

=cut

has 'dump_response_data' => (
                             is      => 'rw',
                             isa     => 'Bool',
                             default => 0,
                            );

=item B<dump_api_results>

Set to true to dump results grabbed from response data by each API
call.  Default is false.

Parsing is currently done with L<XML::Simple>.

=cut

has 'dump_api_results' => (
                           is      => 'rw',
                           isa     => 'Bool',
                           default => 0,
                          );

=item B<die_on_bad_response>

Set to true to die if the API response data is malformed or invalid
for the given API method being called (mainly useful for testing).
Default is false.

=cut

has 'die_on_bad_response' => (
                              is      => 'rw',
                              isa     => 'Bool',
                              default => 0,
                             );

=back

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SEE ALSO

L<http://www.scorm.com/>

L<WebService::ScormCloud::Service::Course>

L<WebService::ScormCloud::Service::Debug>

L<WebService::ScormCloud::Service::Registration>

L<WebService::ScormCloud::Service::Reporting>

L<WebService::ScormCloud::Service::Upload>

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-scormcloud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ScormCloud>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

Patches more than welcome, especially via GitHub:
L<https://github.com/larryl/ScormCloud>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ScormCloud

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

