use strictures;

package WebService::Plotly;

our $VERSION = '1.133400'; # VERSION

# ABSTRACT: access plot.ly programmatically

#
# This file is part of WebService-Plotly
#
# This software is Copyright (c) 2013 by Plotly, Inc..
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#


use JSON qw( decode_json encode_json );
use LWP::UserAgent;
use version 0.77;

use Moo;

has $_ => ( is => 'rw', required => 1 ) for qw( un key  );
has $_ => ( is => 'rw' ) for qw( fileopt filename );
has verbose => ( is => 'rw', default => sub { 1 } );

sub version   { __PACKAGE__->VERSION }
sub _platform { "Perl" }

sub signup {
    my ( $class, $un, $email ) = @_;
    my $payload = { version => $class->version, un => $un, email => $email, platform => $class->_platform };
    return $class->new( un => undef, key => undef )->_json_from_post( 'https://plot.ly/apimkacct', $payload );
}

sub plot   { shift->_call_wrap( @_ ) }
sub style  { shift->_call_wrap( @_ ) }
sub layout { shift->_call_wrap( @_ ) }

sub _makecall {
    my ( $self, $args, $un, $key, $origin, %kwargs ) = @_;

    my ( $json_args, $json_kwargs );
    {
        no warnings 'once';
        my $required = 2.006;
        local *PDL::TO_JSON = sub {
            die "PDL version $required required to encode PDL data to JSON"
              if version::->parse( PDL->VERSION ) < $required;
            return shift->unpdl;
        };
        my $convert = sub { JSON->new->utf8->convert_blessed( 1 )->canonical( 1 )->encode( $_[0] ) };
        $json_args   = $convert->( $args );
        $json_kwargs = $convert->( \%kwargs );
    }

    my $payload = {
        platform => $self->_platform,
        version  => $self->version,
        args     => $json_args,
        un       => $un,
        key      => $key,
        origin   => $origin,
        kwargs   => $json_kwargs,
    };
    my $content = $self->_json_from_post( 'https://plot.ly/clientresp', $payload );
    $self->filename( $content->{filename} ) if $content->{filename};

    return $content;
}

sub _call_wrap {
    my $self = shift;
    my @args;
    push @args, shift @_ while ref $_[0];
    my %kwargs = @_;

    my @login = map { $kwargs{$_} || $self->$_ } qw( un key );

    $kwargs{filename} ||= $self->filename;
    $kwargs{fileopt}  ||= $self->fileopt;

    my $full_func_name = ( caller 1 )[3];
    my ( $origin ) = reverse split "::", $full_func_name;

    return $self->_makecall( \@args, @login, $origin, %kwargs );
}

sub _json_from_post {
    my ( $self, $url, $payload ) = @_;

    my $response = LWP::UserAgent->new->post( $url, $payload );
    die $response if !$response->is_success;

    my $content = decode_json $response->decoded_content;

    die $content->{error} if $content->{error};
    print STDERR $content->{warning} if $content->{warning};
    print $content->{message} if $self->verbose and $content->{message};

    return $content;
}

1;

__END__
=pod

=head1 NAME

WebService::Plotly - access plot.ly programmatically

=head1 VERSION

version 1.133400

=head1 SYNOPSIS

    use WebService::Plotly;
    
    my $user = USERNAME_HERE;
    my $login = WebService::Plotly->signup( $user, EMAIL_HERE );
    warn "temp password is $login->{tmp_pw}";
    
    my $plotly = WebService::Plotly->new( un => $user, key => $login->{api_key} );

    my $x0 = [ 1,  2,  3,  4 ];
    my $y0 = [ 10, 15, 13, 17 ];
    my $x1 = [ 2,  3,  4,  5 ];
    my $y1 = [ 16, 5,  11, 9 ];
    my $response = $plotly->plot( $x0, $y0, $x1, $y1 );
    
    print "url is: $response->{url}";
    print "filename on our server is: $response->{filename}";

=head1 DESCRIPTION

This module provides a smooth interface to the REST API of L<http://plot.ly>. It
will take both plain perl data as well as PDL objects and transform them as
needed.

Note that WS::Plotly caches the filename on the plotly server inside the object,
so that further plot/style/layout calls can be used to modified an existing
plot.

=head1 EXAMPLES

You can find examples plots at L<https://plot.ly/api/perl/>.

A sample of the plots available are shown below (if you don't see images below,
view this documentation on L<MetaCPAN|https://metacpan.org/pod/WebService::Plotly>).
To view the example code, follow the links.

=over 2

=item * L<Fishschool Scatter Graph|https://plot.ly/perl/script-demos/fishschool>

=for html <div><img src="https://plot.ly/static/img/demoscriptthumbs/fishschool.png"></div>

=item * L<Histogram Area Plot|https://plot.ly/perl/script-demos/histarea>

=for html <div><img src="https://plot.ly/static/img/demoscriptthumbs/histarea.png"></div>

=item * L<Math Scores|https://plot.ly/perl/script-demos/math>

=for html <div><img src="https://plot.ly/static/img/demoscriptthumbs/math.png"></div>

=back

=head1 CONSTRUCTOR

WS::Plotly uses a standard Moo constructor.

=head1 ATTRIBUTES

=head2 un

Expects a string containing the username to be sent to the API for
authentification.

Required attribute.

=head2 key

Expects a string containing the API key to be sent to the API for
authentification.

Required attribute.

=head2 fileopt

Expects a string containing options sent to the API with every data call,
concerning usage of the filename parameter. See the bottom of
L<https://plot.ly/api/>.

=head2 filename

Expects a string containing options sent to the API with every data call,
determining the name for the plot resulting of the call, or a name of the plot
to be reused for this call.

=head2 verbose

Boolean that determines whether the server message (containing the plot url and
filename) will be printed to the console. Defaults to 1.

=head1 METHODS

=head2 version

Returns the version of the API object, which will be sent to the API.

=head2 my $response = $plotly->signup( $username, $email )

Creates a new account on the server, if possible. Returns a hash containing the
temporary password of the new account, as well as the api key.

=head3 DATA CALLS

All of these calls take arguments in this fashion:

    $plotly->plot( @data, %options );

Beginning from the start of the argument list all elements will be slurped into
a data array (they're generally expected to be array references or PDL objects)
until the first scalar with a ref() value is reached.

This is assumed to be a hash key and it along with all following scalars will be
slurped into an option hash.

This means that the data calls generally do not care if they are sent an array
reference containing a list of data array referencess as the first argument, or
a flat list of data array references.

All of the data calls return a response hash containing the keys url, message,
warning, filename and error. Normally only url and filename will be interesting
to you; however message can contain extra information and will be printed if
verbose is set to 1, warning can contain warnings from the server and is always
printed with warn(), while a value in the error key triggers the module to die.

These data calls exist and reading the documentation at the bottom of
L<https://plot.ly/api/> is recommended.

=head2 plot

This sends data to Plotly to be plotted and stored.

=head2 style

This call is used to style the data sets sent to the server with the plot call.

=head2 layout

This call customizes the style of the layout, the axes, and the legend.

=head1 THANKS

Many thanks for Christopher Parmer specifically and Plotly, Inc. in general for
providing much support and help in creating this module, as well as footing the
bill for it.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/plotly/Perl-API/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/plotly/Perl-API>

  git clone https://github.com/plotly/Perl-API.git

=head1 AUTHORS

=over 4

=item *

Christian Walde <walde.christian@gmail.com>

=item *

Christopher Parmer <chris@plot.ly>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Plotly, Inc..

This is free software, licensed under:

  The MIT (X11) License

=cut

