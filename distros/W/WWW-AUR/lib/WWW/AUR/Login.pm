package WWW::AUR::Login;

use warnings 'FATAL' => 'all';
use strict;

use HTTP::Cookies  qw();
use Carp           qw();

use WWW::AUR::Maintainer qw();
use WWW::AUR::URI        qw( pkg_uri pkgsubmit_uri );
use WWW::AUR             qw( _category_index _useragent );

our @ISA = qw(WWW::AUR::Maintainer);

my $COOKIE_NAME    = 'AURSID';
my $BAD_LOGIN_MSG  = 'Bad username or password.';
my $PKG_EXISTS_MSG = ( 'You are not allowed to overwrite the '
                       . '<b>.*?</b> package.' );
my $PKG_EXISTS_ERR = 'You tried to submit a package you do not own';
my $COMMADD_MSG    = quotemeta '<b>Comment has been added.</b>';

my $PKGOUTPUT_MATCH = qr{ <p [ ] class="pkgoutput"> ( [^<]+ ) </p> }xms;

sub _new_cookie_jar
{
    my $jar = HTTP::Cookies->new();

    my ($domain, $port) = split /:/, $WWW::AUR::HOST;
    $port ||= 443; # we use https for logins

    # This REALLY should take a hash as argument...
    $jar->set_cookie( 0, 'AURLANG' => 'en', # version, key, val
                      '/', $domain, $port,  # path, domain, port
                      0, 0,                 # path_spec, secure
                      0, 0,                 # maxage, discard
                      {} );                 # rest

    return $jar;
}

sub new
{
    my $class = shift;

    Carp::croak 'You must supply a name and password as argument'
        unless @_ >= 2;
    my ($name, $password) = @_;

    my $ua = _useragent( 'cookie_jar' => _new_cookie_jar());
    $ua->InitTLS;
    my $resp = $ua->post( "https://$WWW::AUR::HOST/login",
        [ user => $name, passwd => $password ] );

    Carp::croak 'Failed to login to AUR: bad username or password'
        if $resp->content =~ /$BAD_LOGIN_MSG/;

    unless ( $resp->code == 302 ) {
        Carp::croak 'Failed to login to AUR: ' . $resp->status_line
            unless $resp->is_success;
    }

    my $self = $class->SUPER::new( $name );
    $self->{'useragent'} = $ua;
    $self->{'sid'} = _sidcookie($ua)
        or Carp::croak 'Failed to read session cookie from login';

    return $self;
}

sub _sidcookie
{
    my ($ua) = @_;
    my $jar = $ua->cookie_jar;
    my $sid;
    $jar->scan(sub { $sid = $_[2] if($_[1] eq 'AURSID') });
    return $sid;
}

my %_PKG_ACTIONS = map { ( lc $_ => "do_$_" ) }
    qw{ Adopt Disown Vote UnVote Notify UnNotify Flag UnFlag Delete };

sub _do_pkg_action
{
    my ($self, $act, $pkg, @params) = @_;

    Carp::croak 'Please provide a proper package ID/name/obj argument'
        unless $pkg;

    my $action = $_PKG_ACTIONS{ $act }
        or Carp::croak "$act is not a valid action for a package";

    my $id   = _pkgid( $pkg );
    my $ua   = $self->{'useragent'};
    my $uri  = pkg_uri( 'https' => 1, 'ID' => $id );
    my $resp = $ua->post( $uri, [ "IDs[$id]" => 1,
                                  'ID'       => $id,
                                  'token'    => $self->{'sid'},
                                  $action    => 1,
                                  @params ] );

    Carp::croak 'Failed to send package action: ' . $resp->status_line
        unless $resp->is_success;

    my ($pkgoutput) = $resp->content =~ /$PKGOUTPUT_MATCH/;
    Carp::confess 'Failed to parse package action response'
        unless $pkgoutput;

    return $pkgoutput;
}

#---HELPER FUNCTION---
sub _pkgid
{
    my $pkg = shift;

    if ( ! ref $pkg ) {
        return $pkg if $pkg =~ /\A\d+\z/;

        require WWW::AUR::Package;
        my $pkgobj = WWW::AUR::Package->new( $pkg );
        return $pkgobj->id;
    }

    Carp::croak 'You must provide a package name, id, or object'
        unless eval { $pkg->isa( 'WWW::AUR::Package' ) };

    return $pkg->id;
}

#---HELPER FUNCTION---
# If provided pkg is an object, call its name method, otherwise pass through.
sub _pkgdesc
{
    my ($pkg) = @_;
    my $name;
    return $name if $name = eval { $pkg->name };
    return $pkg;
}

sub _def_action_method
{
    my ($name, $goodmsg) = @_;
    
    no strict 'refs';
    *{ $name } = sub {
        my ($self, $pkg) = @_;

        my $txt = $self->_do_pkg_action( $name => $pkg );
        unless ( $txt =~ /\A$goodmsg/ ) {
            Carp::confess sprintf qq{%s action on "%s" failed:\n%s\n},
                ucfirst $name, _pkgdesc( $pkg ), $txt;
        }
        return $txt;
    };

    return;
}

my %_ACTIONS = ( 'adopt'    => 'The selected packages have been adopted.',
                 'disown'   => 'The selected packages have been disowned.',

                 'vote'     => ( 'Your votes have been cast for the selected '
                                 . 'packages.' ),
                 'unvote'   => ( 'Your votes have been removed from the '
                                 . 'selected packages.' ),

                 'notify'   => ( 'You have been added to the comment '
                                 . 'notification list for' ),
                 'unnotify' => ( 'You have been removed from the comment '
                                 . 'notification list for' ),

                 'flag'     => ( 'The selected packages have been flagged '
                                 . 'out-of-date.' ),
                 'unflag'   => 'The selected packages have been unflagged.',
                );

while ( my ($name, $goodmsg) = each %_ACTIONS ) {
    _def_action_method( $name, $goodmsg );
}

sub delete
{
    my ($self, $pkg) = @_;

    my $txt = $self->_do_pkg_action( 'delete'         => $pkg,
                                     'confirm_Delete' => 1 );

    unless ( $txt =~ /\AThe selected packages have been deleted[.]/ ) {
        my $msg = sprintf q{Failed to perform the delete action on }
            . q{package "%s"}, _pkgdesc( $pkg );
        Carp::croak $msg;
    }

    return $txt;

}

sub upload
{
    my ($self, $path, $catname) = @_;
    unless ( -f $path ) {
        Carp::croak "Given file path ($path) does not exist";
    }

    my $catidx = _category_index( $catname );
    my $form = [
        'category' => $catidx,
        'submit' => 'Upload',
        'token' => $self->{'sid'},
        'pkgsubmit' => 1,

        # The AUR does not use the provided filename or mimetype.
        # Specify dummy values to prevent LWP from detecting them.
        'pfile' => [ $path, 'ignored-filename', 'ignored-mimetype' ],
    ];
    my $resp = $self->{'useragent'}->post(
        pkgsubmit_uri(),
        'Content-Type' => 'form-data',
        'Content' => $form 
    );

    Carp::croak $PKG_EXISTS_ERR if $resp->content =~ /$PKG_EXISTS_MSG/;
    return;
}

sub comment
{
    my ($self, $pkg, $com) = @_;

    Carp::croak 'comment text cannot be empty' unless
        ( defined $com && length $com );

    my $id = _pkgid($pkg);
    my $ua = $self->{'useragent'};
    my $uri = pkg_uri('https' => 1, 'ID' => $id); # GET & POST params... meh
    my $prms = [ 'ID' => $id, 'comment' => $com, 'submit' => 'Submit',
                 'token' => $self->{'sid'}, ];
    my $resp = $ua->post($uri, $prms);

    Carp::croak "failed to post comment to package #$id"
        unless $resp->is_success && $resp->content =~ /$COMMADD_MSG/;

    return;
}

# Create a nifty alias, to match the "My Packages" AUR link...
*my_packages = \&WWW::AUR::Maintainer::packages;

1;

