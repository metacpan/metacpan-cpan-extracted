package WWW::Twitpic::API;
use Moose;
use Moose::Util::TypeConstraints;

=head1 NAME

WWW::Twitpic::API - Twitpic simple API

=head1 VERSION

Version 0.02

=cut

use LWP::UserAgent;
use HTTP::Request::Common;
use URI;

use WWW::Twitpic::API::Response;

our $VERSION = '0.01';

coerce 'WWW::Twitpic::API::Response'
    => from 'Str'
     => via { WWW::Twitpic::API::Response->new( xml => $_ ) };

has 'username' => (
    is      => 'rw',
    isa     => 'Str'
);

has 'password' => (
    is      => 'rw',
    isa     => 'Str'
);

has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub { LWP::UserAgent->new() }
);

has 'uri' => (
    is      => 'rw',
    isa     => 'URI',
    default => sub { URI->new('http://twitpic.com') }
);

has 'response' => (
    is        => 'rw',
    isa       => 'WWW::Twitpic::API::Response',
    predicate => 'has_response',
    coerce    => 1
);

=head1 SYNOPSIS

    use WWW::Twitpic::API;

    my $client = WWW::Twitpic::API->new(
        username => 'a twitter username',
        password => 'the big secret'
    );

    # post a new image to the twitter feed
    $clent->post( '/path/to/image_filename' => 'The message for this pic' );

    # or just upload the image to twitpic
    $client->upload( '/path/to/image_filename' );


=head1 METHODS

=head2 username
    set/get the twitter username

=head2 password
    set/get the password for the username provided.

=head2 ua
    Set/get the user agent make API calls.
    LWP::UserAgent->new() by default.

=head2 uri
    Base URI to the API.

=head2 response
    The WWW::Twitpic::API::Response from the last post or upload.
    
=head2 has_response
    Check if exists a reponse.

=head2 meta
    See L<Moose>.
=cut

=head2 upload

    Upload the provided image to twitpic.com

    Returns WWW::Twitpic::API::Response

    Example: $api->upload( '/tmp/my_picture.jpg' );

    See L<http://twitpic.com/api.do#upload>

=cut
sub upload {
    my ( $self, $file ) = @_; 

    $self->_make_request({ 
        path  => '/api/upload',
        media => [ $file ] 
    });
}

=head2 post

    Upload the provided image to twitpic.com and post it
    on the username twitter feed with the optional
    message provided.

    Returns WWW::Twitpic::API::Response

    Example: $api->post( '/tmp/my_picture.jpg' => "Look ma, I'm on twitter!");

    See L<http://twitpic.com/api.do#uploadAndPost>

=cut
sub post {
    my ( $self, $file, $message ) = @_; 

    $self->_make_request({ 
        path  => '/api/uploadAndPost',
        media   => [ $file ],
        message => $message
    });
}

=head2 _make_request

    Create and POST a request and return a Twitpic::API::Response.

=cut
sub _make_request {
    my ( $self, $args ) = @_;

    my $url = $self->uri->clone;
    if ( my $path = delete $args->{path} ) {
        $url->path( $path );
    }
    else { confess 'We need a path to make a request' }

    my $res = $self->ua->request(
        POST(
            $url,
            Content_Type => 'form-data',
            Content      => [ 
                username => $self->username,
                password => $self->password,
                %$args
            ]
        )
    );

    if ( $res->is_success ) {
        $self->response( $res->content );
        return $self->response;
    }
    else {
        confess "Can't post to the server: " . $res->status_line;
    }
}

=head1 AUTHOR

Diego Kuperman, C<< <diego at freekeylabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-twitpic-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Twitpic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Twitpic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Twitpic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Twitpic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Twitpic>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Twitpic>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Diego Kuperman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
