package WebService::HtmlKitCom::FavIconFromImage;

use warnings;
use strict;

our $VERSION = '1.001001'; # VERSION

use Carp;
use WWW::Mechanize;
use Devel::TakeHashArgs;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors( simple => qw(
    error
    mech
    response
));


sub new {
    my $self = bless {}, shift;

    get_args_as_hash( \@_, \ my %args, { timeout => 180 } )
        or croak $@;

    $args{mech} ||= WWW::Mechanize->new(
        autocheck => 0,
        timeout => $args{timeout},
        agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.8.1.12)'
                    .' Gecko/20080207 Ubuntu/7.10 (gutsy) Firefox/2.0.0.12',
    );

    $self->mech( $args{mech} );

    return $self;
}

sub favicon {
    my $self = shift;

    $self->$_(undef) for qw(error response);

    my $image = shift;
    get_args_as_hash( \@_, \ my %args, { # also used: `file`
            image   => $image,
        },
    ) or croak $@;

    -e $args{image}
        or return $self->_set_error("File `$args{image}` does not exist");

    my $mech = $self->mech;

    $mech->get('http://www.html-kit.com/favicon/')->is_success
        or return $self->_set_error( $mech, 'net' );

    $mech->form_number(1)
        or return $self->_set_error('Failed to find favicon form');

    $mech->set_visible(
        $args{image},
    );

    $mech->click->is_success
        or return $self->_set_error( $mech, 'net' );

#         use Data::Dumper;
#     print $mech->res->decoded_content;
#     exit;
    my $response = $mech->follow_link(
        url_regex => qr|^\Qhttp://favicon.htmlkit.com/favicon/download/|
    ) or return $self->_set_error(
            'Failed to create favicon. Check your args'
        );

    $response->is_success
        or return $self->_set_error( $mech, 'net' );

    if ( $args{file} ) {
        open my $fh, '>', $args{file}
            or return $self->_set_error(
                "Failed to open `$args{file}` for writing ($!)"
            );
        binmode $fh;
        print $fh $response->content;
        close $fh;
    }
    return $self->response($response);
}

sub _set_error {
    my ( $self, $mech_or_message, $type ) = @_;
    if ( $type ) {
        $self->error(
            'Network error: ' . $mech_or_message->res->status_line
        );
    }
    else {
        $self->error( $mech_or_message );
    }
    return;
}


1;
__END__

=encoding utf8

=for stopwords FireFox RT parsable pics favicons favicon

=head1 NAME

WebService::HtmlKitCom::FavIconFromImage - generate favicons from images on http://www.html-kit.com/favicon/

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use strict;
    use warnings;

    use WebService::HtmlKitCom::FavIconFromImage;

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new;

    $fav->favicon( 'some_pics.jpg', file => 'out.zip' )
        or die $fav->error;

=for html  </div></div>

=head1 DESCRIPTION

The module provides interface to web service on
L<http://www.html-kit.com/favicon/> which allows one to create favicons
from regular images. What's a "favicon"? See
L<http://en.wikipedia.org/wiki/Favicon>

=head1 CONSTRUCTOR

=head2 C<new>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new;

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new( timeout => 10 );

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

Bakes and returns a fresh WebService::HtmlKitCom::FavIconFromImage object.
Takes two I<optional> arguments which are as follows:

=head3 C<timeout>

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new( timeout => 10 );

Takes a scalar as a value which is the value that will be passed to
the L<WWW::Mechanize> object to indicate connection timeout in seconds.
B<Defaults to:> C<180> seconds

=head3 C<mech>

    my $fav = WebService::HtmlKitCom::FavIconFromImage->new(
        mech => WWW::Mechanize->new( agent => '007', timeout => 10 ),
    );

If a simple timeout is not enough for your needs feel free to specify
the C<mech> argument which takes a L<WWW::Mechanize> object as a value.
B<Defaults to:> plain L<WWW::Mechanize> object with C<timeout> argument
set to whatever WebService::HtmlKitCom::FavIconFromImage's C<timeout> argument
is set to as well as C<agent> argument is set to mimic FireFox.

=head1 METHODS

=head2 C<favicon>

    my $response = $fav->favicon('some_pic.jpg')
        or die $fav->error;

    $fav->favicon('some_pic.jpg',
        file    => 'out.zip',
    ) or die $fav->error;

Instructs the object to create a favicon. First argument is mandatory
and must be a file name of the image you want to use for making a favicon.
B<Note:> the site is being unclear about what it likes and what it doesn't.
What I know so far is that it doesn't like 1.5MB pics but I'll leave you at
it :). Return value is described below. Optional arguments are passed in a
key/value form. Possible optional arguments are as follows:

=head3 C<file>

    ->favicon( 'some_pic.jpg', file => 'out.zip' );

B<Optional>.
If C<file> argument is specified the archive containing the favicon will
be saved into the file name of which is the value of C<file> argument.
B<By default> not specified and you'll have to fish out the archive
from the return value (see below)

=head3 C<image>

    ->favicon( '', image => 'some_pic.jpg' );

B<Optional>. You can call the method in an alternative way by specifying
anything as the first argument and then setting C<image> argument. This
functionality is handy if your arguments are coming from a hash, etc.
B<Defaults to:> first argument of this method.

=head3 RETURN VALUE

On failure C<favicon()> method returns either C<undef> or an empty list
depending on the context and the reason for failure will be available
via C<error()> method. On success it returns an L<HTTP::Response> object
obtained while fetching your precious favicon. If you didn't specify
C<file> argument to C<favicon()> method you'd obtain the favicon via
C<content()> method of the returned L<HTTP::Response> object (note that
it would be a zip archive)

=head2 C<error>

    my $response = $fav->favicon('some_pic.jpg')
        or die $fav->error;

Takes no arguments, returns a human parsable error message explaining why
the call to C<favicon()> failed.

=head2 C<mech>

    my $old_mech = $fav->mech;

    $fav->mech( WWW::Mechanize->new( agent => 'blah' ) );

Returns a L<WWW::Mechanize> object used by this class. When called with an
optional argument (which must be a L<WWW::Mechanize> object) will use it
in any subsequent C<favicon()> calls.

=head2 C<response>

    my $response = $fav->response;

Must be called after a successful call to C<favicon()>. Takes no arguments,
returns the exact same return value as last call to C<favicon()> did.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/WebService-HtmlKitCom-FavIconFromImage/issues>

If you can't access GitHub, you can email your request
to C<bug-webservice-htmlkitcom-faviconfromimage at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
