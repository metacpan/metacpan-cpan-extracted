package WWW::AUR::URI;

use warnings 'FATAL' => 'all';
use strict;

use Carp     qw();
use URI      qw();
use Exporter qw();

use WWW::AUR qw(); # for global variables

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(pkgfile_uri pkgbuild_uri pkgsubmit_uri pkg_uri rpc_uri);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );
our $Scheme      = 'https';

sub _pkgdir
{
    my ($pkgname) = @_;
    return "cgit/aur.git";
}

sub pkgfile_uri
{
    my ($pkgname) = @_;
    my $dir = _pkgdir($pkgname);
    return "$Scheme://$WWW::AUR::HOST/$dir/snapshot/$pkgname.tar.gz";
}

sub pkgbuild_uri
{
    my ($pkgname) = @_;
    my $dir = _pkgdir($pkgname);
    return "$Scheme://$WWW::AUR::HOST/$dir/plain/PKGBUILD?h=$pkgname"
}

sub pkgsubmit_uri
{
    return;
	return "$Scheme://$WWW::AUR::HOST/submit/";
}

sub pkg_uri
{
    my %params = @_;
    my $uri    = URI->new( "$Scheme://$WWW::AUR::HOST/packages/" );
    $uri->query_form([ %params ]);
    return $uri->as_string;
}

my @_RPC_METHODS = qw/ search info multiinfo msearch /;

sub rpc_uri
{
    my $method = shift;

    Carp::croak( "$method is not a valid AUR RPC method" )
        unless grep { $_ eq $method } @_RPC_METHODS;

    # The RPC only works with https.
    my $uri = URI->new( "$Scheme://$WWW::AUR::HOST/rpc" );

    my @qparms = ( 'type' => $method );
    if ($method eq 'multiinfo') {
        push @qparms, map { ( 'arg[]' => $_ ) } @_;
    }
    else {
        push @qparms, ( 'arg' => shift );
    }

    $uri->query_form( \@qparms );
    return $uri->as_string;
}

1;
