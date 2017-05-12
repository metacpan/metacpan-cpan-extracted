# WebService::UWO::Directory::Student
#  Retrieve student information from the Western Student Directory
#
# $Id: Student.pm 10608 2009-12-23 16:06:17Z FREQUENCY@cpan.org $

package WebService::UWO::Directory::Student;

use strict;
use warnings;
use Carp ();

use LWP::UserAgent;
use HTML::Entities ();

=head1 NAME

WebService::UWO::Directory::Student - Perl module for searching the UWO
student directory

=head1 VERSION

Version 1.004 ($Id: Student.pm 10608 2009-12-23 16:06:17Z FREQUENCY@cpan.org $)

=cut

our $VERSION = '1.004';
$VERSION = eval $VERSION;

=head1 DESCRIPTION

This module provides a Perl interface to the public directory search system
which lists current students at the University of Western Ontario. For more
information, see the web interface at L<http://uwo.ca/westerndir/>.

=head1 SYNOPSIS

Example code:

    use WebService::UWO::Directory::Student;

    # Create Perl interface to API
    my $dir = WebService::UWO::Directory::Student->new;

    # Look up a student by name
    my $results = $dir->lookup({
      first => 'John',
      last  => 'S'
    });

    # Go through results
    foreach my $stu (@{$results}) {
      print 'email: ' . $stu->email . "\n";
    }

    # Reverse a lookup (use e-mail to find record)
    my $reverse = $dir->lookup({
      email => 'jsmith@uwo.ca'
    });

    if (defined $reverse) {
      print "Found: $reverse\n";
    }

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 METHODS

=head2 new

  WebService::UWO::Directory::Student->new( \%params )

Creates a C<UWO::Directory::Student> search object, which uses a given web page
and server. Being that this module is developed to target UWO's in-house
system, the defaults should suffice.

The parameters available are:

    my $dir = UWO::Directory::Student->new({
      url    => 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
      server => 'localhost',
    });

Which instantiates a C<UWO::Directory::Student> instance using C<url> as the
frontend and C<server> as the "black-box" backend.

=cut

sub new {
  my ($class, $params) = @_;

  my $self = {
    url       => $params->{url} || 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
    server    => $params->{server} || 'localhost',
  };

  return bless($self, $class);
}

=head2 lookup

  $dir->lookup( \%params )

Uses a C<WebService::UWO::Directory::Student> search object to locate a given
person based on either their name (C<first> and/or C<last>) or their e-mail
address (C<email>).

The module uses the following procedure to locate users:

=over

=item 1

If an e-mail address is provided:

=over

=item 1

The address is deconstructed into a first initial and the portion of the last
name. (According to the regular expression C<^(\w)([^\d]+)([\d]*)$>)

=item 2

The partial name is looked up in the directory.

=item 3

The resulting records are tested against the e-mail address. If the e-mail
address matches a given record, an anonymous hash containing user information
is returned. The lookup returns a false value (0) upon failure.

=back

=item 2

If first and/or last names are provided:

=over

=item 1

The name is searched using the normal interface (using the query
C<last_name,first_name>) and the results are returned as an array reference.
If there are no results, the method returns a false value (0).

=back

=back

Example code:

    # Look up "John S" in the student directory
    my $results = $dir->lookup({
      first => 'John',
      last  => 'S'
    });

    # Look up jsmith@uwo.ca
    my $reverse = $dir->lookup({
      email => 'jsmith@uwo.ca'
    });

This method is not guaranteed to return results. Keep in mind that if no
results are found, the return code will be 0, so make sure to check return
codes before attempting to dereference the expected array/hash.

=head3 Record Format

Each returned record will be a hash with the following fields:

=over

=item *

last_name,

=item *

given_name (which may contain middle names)

=item *

email (the registered @uwo.ca e-mail address)

=item *

faculty

=back

You may explore this using C<Data::Dumper>.

=cut

sub lookup {
  my ($self, $params) = @_;

  Carp::croak('You must call this method as an object')
    unless ref $self;

  Carp::croak('Parameter not a hash reference')
    unless ref($params) eq 'HASH';

  Carp::croak('No search parameters provided')
    unless(
      exists($params->{first}) ||
      exists($params->{last})  ||
      exists($params->{email})
    );

  $params->{first} = '' unless defined($params->{first});
  $params->{last} = ''  unless defined($params->{last});

  # Don't do anything in void context
  unless (defined wantarray) {
    Carp::carp('Output from function discarded');
    return;
  }

  if (exists $params->{email}) {
    my $query;
    if ($params->{email} =~ /^(\w+)(\@uwo\.ca)?$/s) {
      $query = $1;

      # no domain provided, assume @uwo.ca for matching
      if (!defined($2)) {
        # This is intentionally not interpolated
        ## no critic(RequireInterpolationOfMetachars)
        $params->{email} .= '@uwo.ca';
      }
    }
    else {
      Carp::croak('Only UWO usernames and addresses can be searched');
    }

    # Discover query by deconstructing the username
    #  jdoe32
    #   First name: j
    #   Last name:  doe
    #   E-mail:     jdoe32@uwo.ca
    if ($query =~ /^(\w)([^\d]+)([\d]*)$/s) {
      my $result = $self->lookup({
        first   => $1,
        last    => $2,
      });
      foreach my $stu (@{$result}) {
        return $stu if ($stu->{email} eq $params->{email});
      }
    }
    else {
      Carp::croak('Given username does not match UWO username pattern');
    }
  }
  else {
    my $query;

    # If both first and last are given
    if (length $params->{first} && length $params->{last}) {
      $query = $params->{last} . ',' . $params->{first};
    }
    # First name only
    elsif (length $params->{first}) {
      $query = $params->{first} . '.';
    }
    # Last name only
    else {
      $query = $params->{last} . ',';
    }

    return _parse($self->_query($query));
  }
  return 0;
}

=head1 UNSUPPORTED API

C<WebService::UWO::Directory::Student> provides access to some internal
methods used to retrieve and process raw data from the directory server. Its
behaviour is subject to change and may be finalized later as the need arises.

=head2 _query

  $dir->_query( $query, $ua )

This method performs an HTTP lookup using C<LWP::UserAgent> and returns a
SCALAR reference to the returned page content. A C<LWP::UserAgent> object may
optionally be passed, which is particularly useful if a proxy is required to
access the Internet.

Please note that if a C<LWP::UserAgent> is passed, the User-Agent string will
not be modified. In normal operation, this module reports its user agent as
C<'WebService::UWO::Directory::Student/' . $VERSION>.

=cut

sub _query {
  my ($self, $query, $ua) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  if (!defined $ua) {
    $ua = LWP::UserAgent->new;
    $ua->agent(__PACKAGE__ . '/' . $VERSION);
  }

  my $r = $ua->post($self->{'url'},
  {
    server => $self->{'server'},
    query  => $query,
  });

  Carp::croak('Error reading response: ' . $r->status_line)
    unless $r->is_success;

  return \$r->content;
}

=head2 _parse

  WebService::UWO::Directory::Student::_parse( $response )

This method processes the HTML content retrieved by _query method and returns
an ARRAY reference containing HASH references to the result set. This is most
likely only useful for testing purposes.

=cut

sub _parse {
  my ($data) = @_;

  Carp::croak('Expecting a scalar reference') unless ref($data) eq 'SCALAR';

  HTML::Entities::decode_entities(${$data});

  # Record format from the directory server:
  #    Full Name: Last,First Middle
  #       E-mail: e-mail@uwo.ca
  # Registered In: Faculty Name

  # 4 fields captured

  # We don't want the \n swallowed in .+
  ## no critic(RequireDotMatchAnything)
  my @matches = (
    ${$data} =~ m{
      [ ]{4}Full\ Name:\ ([^,]+),(.+)\n
      [ ]{7}E-mail:.*\>(.+)\</A\>\n
            Registered\ In:\ (.+)\n
    }xg
  );

  my $res;
  # Requires an irregular count - in steps of 4
  ## no critic (ProhibitCStyleForLoops)

  # Copy the fields four at a time based on the above regular expression
  for (my $i = 0; $i < scalar(@matches); $i += 4) {
    my $stu = {
      last_name   => $matches[$i],
      given_name  => $matches[$i+1],
      email       => $matches[$i+2],
      faculty     => $matches[$i+3],
    };
    push(@{$res}, $stu);
  }

  return $res;
}

=head1 AUTHOR

Jonathan Yu E<lt>jawnsy@cpan.orgE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::UWO::Directory::Student

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-UWO-Directory-Student>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-UWO-Directory-Student>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-UWO-Directory-Student>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-UWO-Directory-Student>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/WebService-UWO-Directory-Student>

=item * CPAN Testers Platform Compatibility Matrix

L<http://www.cpantesters.org/show/WebService-UWO-Directory-Student.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/WebService-UWO-Directory-Student>

If you are a CPAN developer and would like to make modifications to the code
base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the repository
administrator. I only ask that you contact me first to discuss the changes you
wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your bug
report in the form of failing unit tests, you are B<strongly> encouraged to do
so.

=head1 SEE ALSO

L<http://uwo.ca/westerndir/index-student.html>, the site this module uses
to query the database

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

This module is only able to access partial student records since students must
give consent for their contact information to be published on the web. For
more, see L<http://www3.registrar.uwo.ca/InfoServices/DirectoryRemoval.cfm>.

=item *

Some students change their name (for example, a marriage), while retainining
the same email address. This means their email addresses cannot be effectively
reverse-searched.

=item *

This module has not been very thoroughly tested for memory consumption. It
does a lot of copying that should be optimized, however, it is probably not
necessary for most uses.

=back

=head1 LICENSE

In a perfect world, I could just say that this package and all of the code
it contains is Public Domain. It's a bit more complicated than that; you'll
have to read the included F<LICENSE> file to get the full details.

=head1 DISCLAIMER OF WARRANTY

The software is provided "AS IS", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising from,
out of or in connection with the software or the use or other dealings in
the software.

=cut

1;
