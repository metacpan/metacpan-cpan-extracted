package WebService::Blogger;
our $VERSION = '0.23';
use warnings;
use strict;

use Moose;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use File::stat;
use Data::Dumper;
use Encode ();

use WebService::Blogger::Blog;

# Authentication credentials. Cannot be changed after object is created.
has login_id        => ( is => 'ro', isa => 'Str');
has password        => ( is => 'ro', isa => 'Str');

# Blogs belonging to the account.
has blogs => (
    is            => 'ro',
    isa           => 'ArrayRef[WebService::Blogger::Blog]',
    lazy_build    => 1,
    auto_deref    => 1,
);

# LWP:::UserAgent instance for all requests during the session.
has ua => (
    lazy_build => 1,
    is         => 'ro',
);

# Speed Moose up.
__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Loads credentials from credentials file.
    my $class = shift;
    my %attrs = @_;

    return \%attrs if defined $attrs{login_id} && defined $attrs{password};

    # See if there's a file with login credentials and return if there isn't.
    my $creds_file_name
        = $attrs{creds_file_name}
          || $ENV{WEBSERVICE_BLOGGER_CONFIG}
          || "$ENV{HOME}/.www_blogger_rc";

    return \%attrs unless -s $creds_file_name;

    die "Credentials file \"$creds_file_name\" is accessible by others. "
        . 'Please make it readable by the owner only, for security reasons.'
        if stat($creds_file_name)->mode & 07777 != 0600;

    # Read file contents into a string.
    open my $creds_fh, '<', $creds_file_name
        or die "Unable to read login credentials from $creds_file_name: $!";
    my $creds_file_contents = join '', <$creds_fh>;
    close $creds_fh;

    # Parse and return available credentials to be set as object attributes.
    my %parsed_creds = $creds_file_contents =~ /^(\S+)\s*=\s*(\S+)/gm;
    $attrs{login_id} = $parsed_creds{username} if !defined $attrs{login_id}
                                                  && defined $parsed_creds{username};
    $attrs{password} = $parsed_creds{password} if !defined $attrs{password}
                                                  && defined $parsed_creds{password};
    return \%attrs;
}


sub BUILD {
    ## Authenticates with Blogger.
    my ($self,$creds) = @_;

    # Submit request for authentiaction token.
    my $response = $self->{'ua'}->post('https://accounts.google.com/o/oauth2/auth',
          { basic_authentication => $self->{'base64'},
        	Content_Type         => 'application/x-www-form-urlencoded',
        	grant_type           => 'client_credentials',
        	client_id            => $self->{'key'},
        	client_secret        => $self->{'secret'},
          }
        );

print Dumper($response);
exit(0);

#There are 4 grant types defined in the OAuth spec.
#	Authorization code
#	Implicit
#	Resource owner password credentials
#	Client credentials




#    my $response = $self->ua->post('https://www.google.co.uk/accounts/ClientLogin',
#        {
#            Email       => $self->login_id,
#            Passwd      => $self->password,
#            service     => 'blogger',
#        }
#    );

    # Check success, parsing Google error message, if available.
    unless ($response->is_success) {
        my $error_msg = ($response->content =~ /\bError=(.+)/)[0] || 'Google error message unavailable';
        die 'HTTP error when trying to authenticate: ' . $response->status_line . " ($error_msg)";
    }

    # Parse authentication token and set it as default header for user agent object.
    my ($auth_token) = $response->content =~ /\bAuth=(.+)/
        or die 'Authentication token not found in the response: ' . $response->content;
    $self->ua->default_header(Authorization => "GoogleLogin auth=$auth_token");

    # Set default content type for all requests.
    $self->ua->default_header(Content_Type => 'application/atom+xml');
}


sub creds_file_name {
    ## Class method. Returns name of optional file with login credentials.
    my $self = shift;

    # Use the same name and format as WWW::Blogger::XML::API, for compatibility.
    return "$ENV{HOME}/.www_blogger_rc";
}


sub _build_ua {
    ## Populares 'ua' property.
    my $self = shift;

    return LWP::UserAgent->new;
}


sub _build_blogs {
    ## Populates 'blogs' property with list of instances of WebService::Blogger::Blog.
    my $self = shift;

    # Get list of blogs.
    my $response = $self->http_get('http://www.blogger.com/feeds/default/blogs');
    my $response_tree = XML::Simple::XMLin($response->content, ForceArray => 1);

    # Populate the accessor with blog objects generated from the list.
    return [
        map WebService::Blogger::Blog->new(
                source_xml_tree => $_,
                blogger         => $self,
            ),
            @{ $response_tree->{entry} }
   ];
}


sub http_put {
    ## Executes a PUT request to the service.
    my $self = shift;
    my ($url, $content) = @_;

    my $request = HTTP::Request->new(PUT => $url, $self->ua->default_headers,
                                     Encode::encode_utf8($content));
    return $self->ua->request($request);
}


sub http_get {
    ## Executes a GET request to the service.
    my $self = shift;
    my @req_args = @_;

    return $self->ua->get(@req_args);
}


sub http_post {
    ## Executes a POST request to the service.
    my $self = shift;
    my @args = @_;

    return $self->ua->request(HTTP::Request::Common::POST(@args));
}


1;


__END__

=head1 NAME

WebService::Blogger - (DEPRECATED) Interface to Google's Blogger service

=cut

=head1 SYNOPSIS

B<DEPRECATION NOTICE.> This module no longer works and is deprecated. In fact,
as of this writing (2020-10-21), none of the CPAN modules for Blogger currently
work.

This module provides interface to the Blogger service now run by
Google. It's built in object-oriented fashion with L<Moose>, which makes
it easy to use and extend. It also utilizes newer style GData API for
better compatibility. You can retrieve list of blogs for an account,
add, update or delete entries.

 use WebService::Blogger;

 my $blogger = WebService::Blogger->new(
     login_id   => 'myemail@gmail.com',
     password   => 'mypassword',
 );

 my @blogs = $blogger->blogs;
 foreach my $blog (@blogs) {
     print join ', ', $blog->id, $blog->title, $blog->public_url, "\n";
 }

 my $blog = $blogs[1];
 my @entries = $blog->entries;

 my ($entry) = @entries;
 print $entry->title, "\n", $entry->content;

 $entry->title('Updated Title');
 $entry->content('Updated content');
 $entry->categories([ qw/category1 category2/ ]);
 $entry->save;

 my $new_entry = WebService::Blogger::Blog->add_entry(
     title   => 'New entry',
     content => 'New content',
     blog    => $blog,
 );
 $new_entry->delete;


=head1 METHODS

=head2 new

 my $blogger = WebService::Blogger->new(
     login_id   => 'myemail@gmail.com',
     password   => 'mypassword',
 );

Connects to Blogger, authenticates and returns object representing
Blogger account. The credentials can be given in named parameters or
read from a configuration file which has contents like this:

 username = someone@gmail.com
 password = somepassword

The file is first searched for as $ENV{WEBSERVICE_BLOGGER_CONFIG} then
as "$ENV{HOME}/.www_blogger_rc". On Windows, please use the first format.

The file must not be accessible by anyone but the owner. Module will
die with an error if it is. Authentication token received will be
stored privately and used in all subsequent requests.

=cut

=head2 blogs

Returns list of blogs for the account, as either array or array
reference, depending on the context. Items are instances of
L<WebService::Blogger::Blog>.

=cut

=head1 AUTHOR

Kedar Warriner, C<< <kedar at cpan.org> >>

=head1 BUGS

Comments are currently not supported.

Please report any bugs or feature requests to C<bug-webservice-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Blogger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Blogger/>

=back

=head1 ACKNOWLEDGEMENTS

 Many thanks to:
  - Egor Shipovalov who wrote the original version of this module
  - Everyone involved with CPAN.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kedar Warriner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
