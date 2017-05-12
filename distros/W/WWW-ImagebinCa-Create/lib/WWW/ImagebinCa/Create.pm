package WWW::ImagebinCa::Create;

use warnings;
use strict;

our $VERSION = '0.02';

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;
use HTML::TokeParser::Simple;

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;
    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    $args{timeout} ||= 30;

    $args{ua} ||= LWP::UserAgent->new(
            timeout => $args{timeout},
            agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US;'
                        . ' rv:1.8.1.12) Gecko/20080207 Ubuntu/7.10 (gutsy)'
                        . ' Firefox/2.0.0.12',
    );

    return bless \%args, $class;
}

sub upload {
    my $self = shift;
    croak "Must have even number of arguments to upload()"
        if @_ & 1;
    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    unless ( -e $args{filename} ) {
        $self->error("File ($args{filename}) doesn't exist");
        return;
    }

    my @post_request = $self->_make_request_args( \%args );
    my $response = $self->{ua}->request( POST @post_request );

    if ( $response->is_success ) {
        return $self->_check_content( $response->content, \%args );
    }
    else {
        $self->error('Error: ' . $response->status_line );
        return;
    }
}

sub _check_content {
    my ( $self, $content, $args_ref ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );
    my $paste_uri;
    my $error;
    my $get_paste_uri = 0;
    my $is_error = 0;
    while ( my $token = $parser->get_token ) {
        if ( $token->is_start_tag('p') ) {
            $get_paste_uri = 1;
        }
        elsif ( $get_paste_uri and $token->is_start_tag('a') ) {
            $paste_uri = $token->get_attr('href');
        }
        elsif ( $token->is_start_tag('div')
            and defined $token->get_attr('id')
            and $token->get_attr('id') eq 'body'
        ) {
            $is_error = 1;
        }
        elsif ( $is_error == 1 and $token->is_start_tag('h2') ) {
            $is_error = 2;
        }
        elsif ( $is_error == 2 and $token->is_text ) {
            $error = $token->as_is;
            $is_error = 3;
        }
        # this would better be as ->is_start_tag('p') but the parser
        # ...doesn't seem to catch it this way. Bug? Too invalid markup?
        elsif ( $is_error == 3  and $token->is_end_tag('h2') ) {
            $is_error = 4;
        }
        elsif ( $is_error == 4 and $token->is_text ) {
            $error .= '. ' . $token->as_is;
            last;
        }
    }

    if ( $is_error ) {
        $self->error( $error );
        return;
    }
    else {
        my ( $upload_id ) = $paste_uri =~ m{([^/]+)[.]html$};
        $self->upload_id( $upload_id );
        my ( $image_extension ) = $args_ref->{filename} =~ /[.]([^.]+)$/;
        $self->image_uri(
            "http://imagebin.ca/img/$upload_id.$image_extension"
        );
        return $self->page_uri( $paste_uri );
    }
}

sub _make_request_args {
    my ( $self, $args ) = @_;
    return (
        'http://imagebin.ca/upload.php',
        Content_Type => 'form-data',
        Content => [
            sfile       => 'Upload',
            f           => [ $args->{filename} ],
            t           => 'file',
            name        => $args->{name},
            tags        => $args->{tags},
            description => $args->{description},
            adult       => $args->{is_adult} ? 't' : 'f',
        ],
    );
}

sub error {
    my $self = shift;
    if ( @_ ) {
        $self->{ ERROR } = shift;
    }
    return $self->{ ERROR };
}


sub page_uri {
    my $self = shift;
    if ( @_ ) {
        $self->{ PAGE_URI } = shift;
    }
    return $self->{ PAGE_URI };
}

sub image_uri {
    my $self = shift;
    if ( @_ ) {
        $self->{ IMAGE_URI } = shift;
    }
    return $self->{ IMAGE_URI };
}

sub upload_id {
    my $self = shift;
    if ( @_ ) {
        $self->{ UPLOAD_ID } = shift;
    }
    return $self->{ UPLOAD_ID };
}

=head1 NAME

WWW::ImagebinCa::Create - "paste" images to <http://imagebin.ca> from Perl.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::ImagebinCa::Create;

    my $bin = WWW::ImagebinCa::Create->new;

    $bin->upload( filename => 'pic.jpg' )
        or die "Failed to upload: " . $bin->error;

    printf "Upload ID: %s\nPage URI: %s\nDirect image URI: %s\n",
                $bin->upload_id,
                $bin->page_uri,
                $bin->image_uri;

=head1 DESCRIPTION

The module provides interface to L<http://imagebin.ca> for uploading
new images and including uploader's name, picture description and picture
"tags" along with your upload.

=head1 CONSTRUCTOR

=head2 new

    my $bin = WWW::ImagebinCa::Create->new;

    my $bin = WWW::ImagebinCa::Create->new(
        timeout => 10,
    );

    my $bin = WWW::ImagebinCa::Create->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new WWW::ImagebinCa::Create
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for uploading. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for uploading, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::ImagebinCa::Create>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 upload

    $bin->upload( filename => 'some_pic.jpg' )
        or die "Upload error: " . $bin->error;

    my $page_uri = $bin->upload(
            filename    => 'another_pic.bmp',
            name        => 'Pic name',
            tags        => 'Space separated "tags" for the image',
            description => 'Description of the image',
            is_adult    => 1, # is adult content?
    ) or die "Upload error: " . $bin->error;

Instructs the object to upload a certain image. Takes several arguments,
only one of them (C<filename>) is mandatory. If the upload
was successful returns a URI to the
L<http://imagebin.ca> page with the image but you don't have
to store it (see C<page_uri()> method below). If upload failed
returns either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method
(see below). Possible arguments are as follows:

=head3 filename

    $bin->upload( filename => 'pic.jpg' );

B<Mandatory>. Takes a scalar representing the filename of the image to
upload.

=head3 name

    $bin->upload( filename => 'pic.jpg', name => 'Kitty meow!' );

B<Optional>. Specifies the name of the image you are uploading.
B<Defaults to:> C<undef> (no name).

=head3 tags

    $bin->upload( filename => 'pic.jpg', tags => 'space separated tags');

B<Optional>. Specifies "tags" for the image you are uploading. Multiple
tags are separated by space character. B<Defaults to:> C<undef>
(no tags).

=head3 description

    $bin->upload( filename => 'pic.jpg', description => 'My kitty!' );

B<Optional>. Specifies the description of the image you are uploading.
B<Defaults to:> C<undef> (no description).

=head3 is_adult

    $bin->upload( filename => 'pr0n.jpg', is_adult => 1 );

B<Optional>. Specifies whether or not to flag the image as containing
adult content. When set to a I<true value> will mark the image as suitable
only for adult humans. When set to a I<false value> will mark the image
as suitable for everyone. B<Defaults to:> C<0> (suitable for everyone).

=head2 error

    $bin->upload( filename => 'some_pic.jpg' )
        or die "Upload error: " . $bin->error;

If an error occured during the call to C<upload()> method (see above)
it will return either C<undef> or an empty list depending on the context.
When that happens you will be able to get the reason for the error
via C<error()> method. Takes no arguments, returns human readable error
message.

=head2 page_uri

    print "Yey! You can see your pic on: " . $bin->page_uri;

Must be called after a successful call to C<upload()>. Takes no arguments,
returns the URI to the page containing the uploaded image.

=head2 image_uri

    printf qq|<div style="background: url(%s);">meow</div>\n|,
            $bin->image_uri;

Must be called after a successful call to C<upload()>. Takes no arguments,
returns a direct URI to the image you have uploaded. Note that this
is not the same as C<page_uri()> (see above). The C<page_uri()> method
returns URI to the I<page> containing the image and all the optional
information you have provided whereas C<image_uri()> method returns the
URI to the image itself. For example, you may wish to use this on
on some temporary web page.

=head2 upload_id

    print "Your upload ID is: " . $bin->upload_id;

Must be called after a successful call to C<upload()>. Takes
no arguments, returns the ID
of the image you have uploaded. In other words, if C<page_uri()> method
(see above) returns C<http://imagebin.ca/view/GGdpHcV.html> the
C<upload_id()> method will return C<GGdpHcV>.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS AND CAVEATS

The module relies on HTML parsing, thus it's possible for it to break
one day if the author of the site decides to recode it.

According to the bug in
L<HTTP::Request::Common>
( L<http://rt.cpan.org/Public/Bug/Display.html?id=30538> ) it breaks
if the filename contains C<"> (double quotes). Avoid those in the images
you upload until the bug is resolved.

Please report any bugs or feature requests to C<bug-www-imagebinca-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-ImagebinCa-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ImagebinCa::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-ImagebinCa-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-ImagebinCa-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-ImagebinCa-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-ImagebinCa-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

