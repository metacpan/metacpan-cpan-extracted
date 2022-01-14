package WebService::WsScreenshot;
use Moo;
use URI::Encode qw( uri_encode );
use LWP::UserAgent;
use JSON::MaybeXS qw( decode_json );
use URI;

our $VERSION = '0.002';

has base_url => (
    is       => 'rw',
    required => 1,
);

has res_x => (
    is      => 'rw',
    default => sub { 1280 },
);

has res_y => (
    is      => 'rw',
    default => sub { 900 },
);

has out_format => (
    is      => 'rw',
    default => sub { 'jpg' },
);

has is_full_page => (
    is      => 'rw',
    default => sub { 'false' },
);

has wait_time => (
    is => 'rw',
    default => sub { 100 },
);

has ua => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { 
        return LWP::UserAgent->new( timeout => 300, headers => [ 'Accept-Encoding' => '' ]); 
    },
);

has mech => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { 
        my $mech = WWW::Mechanize->new( timeout => 300 );
        $mech->add_header( 'Accept-Encoding' => '' );
        return $mech;
    },
);

sub create_screenshot_url {
    my ( $self, @in ) = @_;

    my $args = ref $in[0] eq 'HASH' ? $in[0] : { @in };

    die "Error: create_screenshot_url() requires a url argument.\n" unless 
        $args->{url};

    die "Error: create_screenshot_url() must be http(s)\n"
        unless URI->new($args->{url})->scheme =~ /^https?$/;

    return sprintf( "%s/api/screenshot?resX=%d&resY=%d&outFormat=%s&waitTime=%d&isFullPage=%s&url=%s",
        $self->base_url,
        exists $args->{res_x}         ? $args->{res_x}         : $self->res_x,
        exists $args->{res_y}         ? $args->{res_y}         : $self->res_y,
        exists $args->{out_format}    ? $args->{out_format}    : $self->out_format,
        exists $args->{wait_time}     ? $args->{wait_time}     : $self->wait_time,
        exists $args->{is_full_page}  ? $args->{is_full_page}  : $self->is_full_page,
        uri_encode($args->{url})
    );
}

sub fetch_screenshot {
    my ( $self, @in ) = @_;

    my $args = ref $in[0] eq 'HASH' ? $in[0] : { @in };
    
    my $res = $self->ua->get( $self->create_screenshot_url( $args ) );
    
    if ( $res->content_type eq 'application/json' ) {
        die "Error: " . decode_json($res->decoded_content)->{details};
    } 

    return $res;
}

sub store_screenshot {
    my ( $self, @in ) = @_;

    my $args = ref $in[0] eq 'HASH' ? $in[0] : { @in };
    
    die "Error: store_screenshot() requires an out_file argument.\n" unless 
        $args->{out_file};

    my $res = $self->fetch_screenshot( $args );

    open my $sf, ">", $args->{out_file}
        or die "Failed to open handle to " . $args->{out_file} . ": $!";
    print $sf $res->decoded_content;
    close $sf;

    return $res;
}

1;

=encoding utf8

=head1 NAME

WebService::WsScreenshot - API client For ws-screenshot

=head1 DESCRIPTION

WebService::WsScreenshot is an api client for L<https://github.com/elestio/ws-screenshot/>. It
makes it simple to get URLs, or download screenshots in a Perl application, using the backend
provided by L<Elesstio|https://github.com/elestio/ws-screenshot/>.


=head1 SYNOPSIS

    #!/usr/bin/env perl
    use warnings;
    use strict;
    use WebService::WsScreenshot;

    # Run the backend with....
    #   $ docker run --name ws-screenshot -d --restart always -p 3000:3000 -it elestio/ws-screenshot.slim

    my $screenshot = WebService::WsScreenshot->new(
        base_url => 'http://127.0.0.1:3000',
    );

    $screenshot->store_screenshot(
        url      => 'https://modfoss.com/',
        out_file => 'modfoss.jpg',
    );


=head1 CONSTRUCTOR

The following options may be passed to the constructor.

=head2 base_url

This is the URL that ws-screenshot is running at.  It is required.

=head2 res_x

The horizontal pixel size for the screenshot.

Default: 1280.

=head2 res_y

The vertical pixel size for the screenshot.

Default: 900

=head2 out_format

The output format.  

Valid options are: jpg png pdf

Default: jpg

=head2 is_full_page

If the screenshot should include the full page

Valid options are: true false

Default: false

=head2 wait_time

How long to wait before capuring the screenshot, in ms.

Default: 100

=head1 METHODS

=head2 create_screenshot_url

This method will return the full URL to the screen shot.  It could be used
for embedding the screenshot, for example.

You must pass C<url> with the URL to be used for the screenshot.

    my $img_url = $screenshot->create_screenshot_url(
        url => 'http://modfoss.com',
    );


=head2 fetch_screenshot

This method will construct the URL for the screenshot, and then
fetch the screenshot, making the API call to the ws-screenshot
server.

It will return the HTTP::Response object from the API call.

If there is any error, it will die.

You must pass C<url> with the URL to be used for the screenshot.

    my $res = $screenshot->fetch_screenshot(
        url => 'http://modfoss.com',
    );

=head2 store_screenshot

This method is the same as fetch_screenshot, however the screenshot
itself will be written to disk.

You must pass C<url> with the URL to be used for the screenshot, as
well as C<out_file> for the path the file is to be written to.

    my $res = $screenshot->fetch_screenshot(
        url      => 'http://modfoss.com',
        out_file => 'modfoss-screenshot.jpg',
    );

=head1 AUTHOR

Kaitlyn Parkhurst (SymKat) I<E<lt>symkat@symkat.comE<gt>> ( Blog: L<http://symkat.com/> )

=head1 COPYRIGHT

Copyright (c) 2021 the WebService::WsScreenshot L</AUTHOR>, L</CONTRIBUTORS>, and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=head1 AVAILABILITY

The most current version of App::dec can be found at L<https://github.com/symkat/WebService-WsScreenshot>
