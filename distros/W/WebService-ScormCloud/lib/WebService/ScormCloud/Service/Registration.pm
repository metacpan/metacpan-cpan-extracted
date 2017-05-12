package WebService::ScormCloud::Service::Registration;

use Moose::Role;

with 'WebService::ScormCloud::Service';

=head1 NAME

WebService::ScormCloud::Service::Registration - ScormCloud API "registration" namespace

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

    my $registration_list = $ScormCloud->getRegistrationList;

=head1 DESCRIPTION

This module defines L<WebService::ScormCloud> API methods in the "registration"
namespace.  See L<WebService::ScormCloud> for more info.

=cut

use Carp;

requires 'process_request';

=head1 METHODS

=head2 createRegistration ( I<course_id>, I<registration_id>, I<first_name>, I<last_name>, I<learner_id> [ , I<options_hashref> ] )

Creates a new registration.

Required arguments are:

=over 4

=item B<course_id>

=item B<registration_id>

=item B<first_name>

=item B<last_name>

=item B<learner_id>

=back

Valid options include:

=over 4

=item B<email>

=item B<postbackurl>

=item B<authtype>

=item B<urlname>

=item B<urlpass>

=item B<resultsformat>

=item B<disableTracking>

=back

=cut

sub createRegistration ## no critic (NamingConventions::Capitalization, Subroutines::ProhibitManyArgs)
{
    my ($self, $course_id, $registration_id, $first_name, $last_name,
        $learner_id, $opts)
      = @_;

    croak 'Missing course_id' unless defined $course_id && length $course_id;
    croak 'Missing registration_id'
      unless defined $registration_id && length $registration_id;
    croak 'Missing first_name' unless defined $first_name && length $first_name;
    croak 'Missing last_name'  unless defined $last_name  && length $last_name;
    croak 'Missing learner_id' unless defined $learner_id && length $learner_id;

    $opts ||= {};

    my %params = (
                  method    => 'registration.createRegistration',
                  courseid  => $course_id,
                  regid     => $registration_id,
                  fname     => $first_name,
                  lname     => $last_name,
                  learnerid => $learner_id,
                 );

    foreach my $opt (
                     qw(email postbackurl authtype urlname urlpass
                     resultsformat disableTracking)
                    )
    {
        $params{$opt} = $opts->{$opt} if exists $opts->{$opt};
    }

    return $self->process_request(
        \%params,
        sub {
            my ($response) = @_;

            return exists $response->{success} ? 1 : 0;
        },
    );
}

=head2 deleteRegistration ( I<registration_id> )

Given a registration ID, delete the corresponding registration.

=cut

sub deleteRegistration    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $registration_id) = @_;

    croak 'Missing registration_id' unless $registration_id;

    return $self->process_request(
        {
         method => 'registration.deleteRegistration',
         regid  => $registration_id,
        },
        sub {
            my ($response) = @_;

            return exists $response->{success} ? 1 : 0;
        },
    );
}

=head2 resetRegistration ( I<registration_id> )

Given a registration ID, reset the corresponding registration.

=cut

sub resetRegistration    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $registration_id) = @_;

    croak 'Missing registration_id' unless $registration_id;

    return $self->process_request(
        {
         method => 'registration.resetRegistration',
         regid  => $registration_id,
        },
        sub {
            my ($response) = @_;

            return exists $response->{success} ? 1 : 0;
        },
    );
}

=head2 getRegistrationList ( [ I<filters> ] )

Returns an arrayref containing a list of registrations.
The returned list might be empty.

The optional I<filters> hashref can contain any of these entries
to filter the returned list of registrations:

=over 4

=item B<filter>

A regular expression for matching the registration ID

=item B<coursefilter>

A regular expression for matching the course ID

=back

Note that any filter regular expressions must match the B<entire>
string.  (There seems to be an implied C<^...$> around the supplied
pattern.)  So to match e.g. any courses that begin with "ABC":

    {coursefilter => '^ABC'}    # THIS WILL NOT WORK

    {coursefilter => 'ABC.*'}   # This will work

=cut

sub getRegistrationList    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $filters) = @_;

    $filters ||= {};

    my %params = (method => 'registration.getRegistrationList');

    foreach my $key (qw(filter coursefilter))
    {
        $params{$key} = $filters->{$key} if $filters->{$key};
    }

    return $self->process_request(
        \%params,
        sub {
            my ($response) = @_;

            die "bad\n" unless exists $response->{registrationlist};
            if ($response->{registrationlist})
            {
                return $response->{registrationlist};
            }
            else
            {
                return [];    # empty list
            }
        },
        {
         xml_parser => {
                        ForceArray => ['registration', 'instance'],
                        GroupTags  => {
                                      'registrationlist' => 'registration',
                                      'instances'        => 'instance',
                                     },
                       }
        }
    );
}

=head2 getRegistrationResult ( I<registration_id> [ , I<results_format> ] )

Given a registration ID, returns registration results.

Optional C<results_format> can be "course" (the default),
"activity", or "full".

=cut

sub getRegistrationResult    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $registration_id, $results_format) = @_;

    croak 'Missing registration_id' unless $registration_id;

    my %params = (
                  method => 'registration.getRegistrationResult',
                  regid  => $registration_id
                 );
    $params{resultsformat} = $results_format if $results_format;

    return $self->process_request(
        \%params,
        sub {
            my ($response) = @_;

            return
              ref($response->{registrationreport}) eq 'HASH'
              ? $response->{registrationreport}
              : undef;
        },
        {
         xml_parser => {
                        ForceArray =>
                          [qw(activity comment response interaction objective)],
                        GroupTags => {
                                      'children'              => 'activity',
                                      'comments_from_learner' => 'comment',
                                      'comments_from_lms'     => 'comment',
                                      'correct_responses'     => 'response',
                                      'interactions'          => 'interaction',
                                      'objectives'            => 'objective',
                                     },
                       }
        }
    );
}

=head2 getRegistrationListResults ( )

Effectively, runs getRegistrationList to get all the registrations,
and then runs getRegistrationResult on each of them.

Not implemented yet.

=cut

sub getRegistrationListResults  ## no critic (NamingConventions::Capitalization)
{
    croak 'Not implemented yet.';
}

=head2 launchURL ( I<registration_id> , I<$redirect_url> [ , I<options_hashref> ] )

Given a registration ID and redirect URL, returns a URL that can be
used in the browser to launch the test at cloud.scorm.com.

Valid options include:

=over 4

=item B<cssurl>

=item B<learnerTags>

=item B<courseTags>

=item B<registrationTags>

=item B<disableTracking>

=back

=cut

sub launchURL    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $registration_id, $redirect_url, $opts) = @_;

    croak 'Missing registration_id' unless $registration_id;
    croak 'Missing redirect_url'    unless $redirect_url;

    $opts ||= {};

    my %params = (
                  method      => 'registration.launch',
                  regid       => $registration_id,
                  redirecturl => $redirect_url,
                 );

    foreach my $opt (
             qw(cssurl learnerTags courseTags registrationTags disableTracking))
    {
        $params{$opt} = $opts->{$opt} if exists $opts->{$opt};
    }

    return $self->request_uri(\%params);
}

=head2 resetGlobalObjectives ( I<registration_id> )

Given a registration ID, reset any global objectives associated with
the corresponding registration.

=cut

sub resetGlobalObjectives    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $registration_id) = @_;

    croak 'Missing registration_id' unless $registration_id;

    return $self->process_request(
        {
         method => 'registration.resetGlobalObjectives',
         regid  => $registration_id,
        },
        sub {
            my ($response) = @_;

            return exists $response->{success} ? 1 : 0;
        },
    );
}

=head2 updateLearnerInfo ( I<learner_id>, I<fname>, I<lname> [ , I<new_id> ] )

Reset learner info previously given during registration creation.

Not implemented yet.

=cut

sub updateLearnerInfo    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $learner_id, $first_name, $last_name, $new_id) = @_;

    croak 'Missing learner_id' unless $learner_id;
    croak 'Missing first_name' unless $first_name;
    croak 'Missing last_name'  unless $last_name;

    croak 'Not implemented yet.';
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

    perldoc WebService::ScormCloud::Service::Registration

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

