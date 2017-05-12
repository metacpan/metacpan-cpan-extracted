package WWW::ImagebinCa::Retrieve;

use warnings;
use strict;

our $VERSION = '0.01';

use Carp;
use URI;
use LWP::UserAgent;
require File::Spec;
use HTML::TokeParser::Simple;
use base qw(Class::Data::Accessor);

__PACKAGE__->mk_classaccessors( qw(
        page_id  image_uri  page_uri  description  error
        full_info  what  where  do_download_image
    )
);

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

sub retrieve {
    my $self = shift;
    my %args;
    if ( @_ == 1 ) {
        $args{what} = shift;
    }
    else {
        croak "Must have even number or only 1 argument to retrieve()"
            if @_ & 1;
        %args = @_;
        $args{ +lc } = delete $args{ $_ } for keys %args;
    }
    for (qw(page_id image_uri where page_uri description error full_info)){
        $self->$_( undef );
    }

    unless ( defined $args{do_download_image} ) {
        $args{do_download_image} = 1;
    }
    
    unless ( defined $args{what} ) {
        $self->error('Undefined page ID was specified');
        return;
    }
    
    $self->what( $args{what} );
    $args{what} =~ s{http://imagebin.ca/view/(\S+?).html}{$1}i;
    $self->page_id( $args{what} );

    $self->do_download_image( $args{do_download_image} );

    my $page_uri = URI->new("http://imagebin.ca/view/$args{what}.html");
    my $response = $self->{ua}->get($page_uri);
    if ( $response->is_success ) {
        $self->page_uri($page_uri);

        my $full_info_ref
        = $self->_parse_response( $response->content, \%args );

        return $self->full_info( $full_info_ref );
    }
    else {
        $self->error($response->status_line);
        return;
    }
}

sub _parse_response {
    my ( $self, $content, $args_ref ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my ( $description, $image_uri );
    my $get_description = 0;
    while ( my $token = $parser->get_token ) {
        if ( $token->is_start_tag('img')
            and $token->get_attr('id')
            and $token->get_attr('id') eq 'theimg'
        ) {
            $image_uri = URI->new($token->get_attr('src'));
            $get_description = 1;
        }
        elsif ( $get_description == 1
            and $token->is_start_tag('div')
            and defined $token->get_attr('style')
        ) {
            if ( $token->get_attr('style') =~ /background/i ) {
                $get_description = 2;
            }
            else {
                last;
            }
        }
        elsif ( $get_description == 2 and $token->is_text ) {
            $description = $token->as_is;
            last;
        }
    }
    unless ( defined $image_uri ) {
        $self->error(q|This page ID doesn't seem to exist|);
        return;
    }

    unless ( defined $description ) {
        $description = 'N/A';
    }
    
    $self->image_uri($image_uri);
    $self->description($description);

    if ( $args_ref->{do_download_image} ) {
        my $image_uri_filename = ($image_uri->path_segments)[-1];
        my ( $extension ) = $image_uri_filename =~ /([.][^.]+$)/;

        my $save_as_where_file;
        if ( defined $args_ref->{save_as} ) {
            $save_as_where_file = File::Spec->catfile(
                $args_ref->{where},
                $args_ref->{save_as} . $extension
            );
        }

        my $where_file = File::Spec->catfile(
            $args_ref->{where},
            $image_uri_filename,
        );

        my $local_name ;
        if ( defined $args_ref->{save_as} ) {
            $local_name = defined $args_ref->{where}
                        ? $save_as_where_file
                        : $args_ref->{save_as} . $extension;
        }
        else {
            $local_name = defined $args_ref->{where}
                        ? $where_file
                        : $image_uri_filename;
        }

        my $response = $self->{ua}->mirror( $image_uri, $local_name );
        if ( $response->is_success ) {
            $args_ref->{where} = $local_name;
        }
        else {
            $self->error(
                'Failed to download image: ' . $response->status_line
            );
            return;
        }
    }
    return $self->full_info( {
            page_id     => $self->page_id,
            page_uri    => $self->page_uri,
            image_uri   => $image_uri,
            description => $description,
            where       => $self->where( $args_ref->{where} ),
            what        => $self->what,
        }
    );
}


1;

__END__

=head1 NAME

WWW::ImagebinCa::Retrieve - retrieve uploaded images from
L<http://imagebin.ca>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::ImagebinCa::Retrieve;

    my $bin = WWW::ImagebinCa::Retrieve->new;

    my $full_info_ref = $bin->retrieve('MfUHEPkH') # can be a full URI
        or die "Error: " . $bin->error;

    printf "Page ID:%s\nImage located on: %s\nImage URI: %s\n"
            . "Image Description: %s\nSaved image locally as: %s\n",
                @$full_info_ref{ qw(
                    page_id      page_uri  image_uri
                    description  where
                )};

=head1 DESCRIPTION

The module provides means of downloading images from
L<http://imagebin.ca> along with their description and direct URI for
the image.

=head1 CONSTRUCTOR

=head2 new

    my $bin = WWW::ImagebinCa::Retrieve->new;

    my $bin = WWW::ImagebinCa::Retrieve->new(
        timeout => 10,
    );

    my $bin = WWW::ImagebinCa::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new WWW::ImagebinCa::Retrieve
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::ImagebinCa::Retrieve>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 retrieve

    $bin->retrieve('1FEgcOol')
        or die 'Error: ' . $bin->error;

    my $full_info = $bin->retrieve(
        what              => 'http://imagebin.ca/view/1FEgcOol.html',
        do_download_image => 1, 
        save_as           => 'pic',
        where             => '/tmp',
    ) or die 'Error: ' . $bin->error;

Instructs the object to retrieve a certain image from
L<http://imagebin.ca> given its ID or full URI.
Takes either one standalone or several paired arguments. On
success returns a hashref
of information about retrieved image, see the C<full_info()> method's
description for the keys in the returned hashref. If an error occured
during the retrieving process returns either C<undef> or an empty list
depending on the context and the error will be available via C<error()>
method.

When called with a single non-paired argument it will be interpreted
as a value for the mandatory C<what> argument. When called with two
or more arguments they will be interpreted as follows:

=head3 what

    # all these are the SAME
    $bin->retrieve('1FEgcOol');
    $bin->retrieve('http://imagebin.ca/view/1FEgcOol.html');
    $bin->retrieve( what => '1FEgcOol' );
    $bin->retrieve( what => 'http://imagebin.ca/view/1FEgcOol.html' );

B<Mandatory>. As a value takes either the page ID or the full URI to
the page with the image you wish to retrieve.

=head3 do_download_image

    $bin->retrieve( what => '1FEgcOol', do_download_image => 0 );

B<Optional> Specifies whether or not to download the image. When set
to a true value the image represented by C<what> argument will be
downloaded, see C<save_as> and C<where> arguments for information on
local image filename. When set to a false value, the object will not
download the image but will process information about it
(such us direct URI to the image and its description). B<Defaults to:> C<1>

=head3 where

    $bin->retrieve( what => '1FEgcOol', where => '/tmp' );

B<Optional>. Specifies the directory into which to download the image.
B<Defaults to:> C<undef> (current directory).

=head3 save_as

    $bin->retrieve( what => '1FEgcOol', save_as => 'pic' );

B<Optional>. Specifies the name of the file representing the downloaded
image. I<Note:> do NOT specify the extension, it will be determined from
the page the image is on. In other words, if page with ID C<1FEgcOol>
contains an image of PNG format and you specify C<save_as> argument
as C<pic> the image will be stored as C<pic.png>. B<Defaults to:>
the ID of the imagebin.ca page the image belongs to.

=head2 error

    $bin->retrieve('1FEgcOol')
        or die 'Error: ' . $bin->error;

If an error occured during the call to C<retrieve()> it will return
either C<undef> or an empty list depending on the context and the reason
for the error will be available via C<error()> method. Takes no arguments,
returns a human readable error message.

=head2 page_id

    my $image_page_id = $bin->page_id;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the ID of the page the image was retrieved from. In other words,
after calling either one of:

    $bin->retrieve('1FEgcOol');
    $bin->retrieve('http://imagebin.ca/view/1FEgcOol.html');

The C<page_id()> will return C<1FEgcOol> in both cases.

=head2 image_uri

    printf qq|<div style="background: url(%s)">FOOS!</div>\n|,
                $bin->image_uri;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a L<URI> object representing the direct URI to the image itself.

=head2 page_uri

    printf "You can see your image on: %s\n",
                $bin->page_uri;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a L<URI> object representing the L<http://imagebin.ca> page
on which your image is present. In other words, after calling either one of:

    $bin->retrieve('1FEgcOol');
    $bin->retrieve('http://imagebin.ca/view/1FEgcOol.html');

The C<page_uri()> will return C<http://imagebin.ca/view/1FEgcOol.html>
in both cases.

=head2 description 

    my $pic_description = $bin->description;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the description of your image or C<N/A> if no description is
available.

=head2 where

    printf "I have saved your image locally as: %s\n",
                $bin->where;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the location (or possible location if C<do_download_image>
argument to C<retrieve()> was set to a false value) of the local copy of
the image. B<Note:> this is B<NOT> the same as C<where> argument to
C<retrieve()> method. This will include the C<save_as> and C<where>
arguments to C<retrieve()> as well as the extension of the image.

=head2 what

    printf "You've asked me to fetch %s\n",
                $bin->what;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns whatever you have specified in the C<what> argument to the
C<retrieve()> method.

=head2 full_info

    my $full_info_ref = $bin->full_info;

    use Data::Dumper;
    print Dumper($full_info_ref);
    # prints:
    {
        'page_id' => '1FEgcOol',
        'page_uri' => bless( do{\(my $o = 'http://imagebin.ca/view/1FEgcOol.html')}, 'URI::http' ),
        'image_uri' => bless( do{\(my $o = 'http://imagebin.ca/img/1FEgcOol.jpg')}, 'URI::http' ),
        'description' => 'Bored Cat_ZZZDescription',
        'where' => '/home/zoffix/Desktop/1FEgcOol.jpg',
        'what'  => '1FEgcOol',
    },

Must be called after a successful call to C<retrieve()>.
Instead of calling each of the above methods you may fish to call
C<full_info()>. The hashref which C<full_info()> returns is the
I<same> as a hashref which C<retrieve()> returns on success.
Takes no arguments, returns a hashref keys/values of which are as follows:

=head3 page_id

    { 'page_id' => '1FEgcOol', }

The page ID, see C<page_id()> method for description.

=head3 page_uri

    { 'page_uri' => bless( do{\(my $o = 'http://imagebin.ca/view/1FEgcOol.html')}, 'URI::http' ), }

The L<URI> object representing the URI of the page. See C<page_uri()>
method for description.

=head3 image_uri

    {image_uri' => bless( do{\(my $o = 'http://imagebin.ca/img/1FEgcOol.jpg')}, 'URI::http' ), }

The L<URI> object representing the direct URI to the image. See
C<image_uri()> method for description.

=head3 description

    { 'description' => 'Bored Cat_ZZZDescription', }

The description of your image if available. See C<description()> method
for more information.

=head3 where

    { 'where' => '/home/zoffix/Desktop/1FEgcOol.jpg', }

Where the image was saved as locally (or would have been saved as
if C<do_download_image> argument to C<retrieve()> was set to a false
value). See C<where()> method for description.

=head3 what

    { 'what'  => '1FEgcOol' }

The C<what> argument which you have specified to the C<retrieve()> method
call. See C<what()> method for more information.

=head1 PREREQUISITES

For healthy operation this module requires the following modules/versions:

        'Carp'                     => 1.04,
        'URI'                      => 1.35,
        'LWP::UserAgent'           => 2.036,
        'File::Spec'               => 3.2701,
        'HTML::TokeParser::Simple' => 3.15,
        'Class::Data::Accessor'    => 0.04001,

Earlier versions might work, but were not tested.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

The module relies on HTML parsing thus one day when the author of
L<http://imagebin.ca> will decide to recode his or her site the
WWW::ImagebinCa::Retrieve will send billions of children to bed hungry.

Please report any bugs or feature requests to C<bug-www-imagebinca-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-ImagebinCa-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ImagebinCa::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-ImagebinCa-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-ImagebinCa-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-ImagebinCa-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-ImagebinCa-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
