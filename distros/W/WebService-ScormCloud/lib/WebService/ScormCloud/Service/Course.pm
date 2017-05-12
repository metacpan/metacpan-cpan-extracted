package WebService::ScormCloud::Service::Course;

use Moose::Role;

with 'WebService::ScormCloud::Service';

=head1 NAME

WebService::ScormCloud::Service::Course - ScormCloud API "course" namespace

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

    print "Found a course\n" if $ScormCloud->courseExists('123');

    my $course_list = $ScormCloud->getCourseList;

=head1 DESCRIPTION

This module defines L<WebService::ScormCloud> API methods in the "course"
namespace.  See L<WebService::ScormCloud> for more info.

=cut

use Carp;

requires 'process_request';

=head1 METHODS

=head2 courseExists ( I<course_id> )

Given a course ID, returns true if that course exists.

=cut

sub courseExists    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $course_id) = @_;

    croak 'Missing course_id' unless $course_id;

    return $self->process_request(
        {method => 'course.exists', courseid => $course_id},
        sub {
            my ($response) = @_;

            return $response->{result} eq 'true' ? 1 : 0;
        }
    );
}

=head2 getMetadata ( I<course_id> )

Given a course ID, returns course metadata.

=cut

sub getMetadata    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $course_id) = @_;

    croak 'Missing course_id' unless $course_id;

    return $self->process_request(
        {method => 'course.getMetadata', courseid => $course_id},
        sub {
            my ($response) = @_;

            return ref($response->{package}) eq 'HASH'
              ? $response->{package}
              : undef;
        }
    );
}

=head2 getCourseList ( [ I<filters> ] )

Returns an arrayref containing a list of courses.
The returned list might be empty.

The optional I<filters> hashref can contain any of these entries
to filter the returned list of registrations:

=over 4

=item B<filter>

A regular expression for matching the course ID

=back

Note that any filter regular expressions must match the B<entire>
string.  (There seems to be an implied C<^...$> around the supplied
pattern.)  So to match e.g. any courses that begin with "ABC":

    {filter => '^ABC'}    # THIS WILL NOT WORK

    {filter => 'ABC.*'}   # This will work

=cut

sub getCourseList    ## no critic (NamingConventions::Capitalization)
{
    my ($self, $filters) = @_;

    $filters ||= {};

    my %params = (method => 'course.getCourseList');
    $params{filter} = $filters->{filter} if $filters->{filter};

    return $self->process_request(
        \%params,
        sub {
            my ($response) = @_;

            die "bad\n" unless exists $response->{courselist};
            if ($response->{courselist})
            {
                return $response->{courselist};
            }
            else
            {
                return [];    # empty list
            }
        },
        {
         xml_parser => {
                        ForceArray => ['course'],
                        GroupTags  => {'courselist' => 'course'},
                       }
        }
    );
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

    perldoc WebService::ScormCloud::Service::Course

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

