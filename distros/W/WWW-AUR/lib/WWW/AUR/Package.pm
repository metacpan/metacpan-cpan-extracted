package WWW::AUR::Package;

use warnings 'FATAL' => 'all';
use strict;

use File::Basename qw(basename);
use File::Path     qw(make_path);
use File::Spec     qw();
use Carp           qw();

use WWW::AUR::Package::File qw();
use WWW::AUR::URI           qw( pkgbuild_uri pkgfile_uri pkg_uri );
use WWW::AUR::RPC           qw();
use WWW::AUR                qw( _path_params _useragent );

##############################################################################
# CONSTANTS
#-----------------------------------------------------------------------------

#---CONSTRUCTOR---
sub new
{
    my $class = shift;
    Carp::croak( "You must at least supply a name as argument" ) if @_ == 0;

    my $name   = shift;
    my %params = @_;

    my $info;
    if ( $params{info} ) {
        $info = $params{info};
    } else { 
        # this might croak on error
        $info = eval { WWW::AUR::RPC::info( $name ) };
        Carp::croak( "Failed to find package: $name" ) unless ( $info );
    }
    $info->{git_clone_ro} = sprintf('https://%s/%s.git', $WWW::AUR::HOST, $name);
    $info->{git_clone_rw} = sprintf('ssh+git://aur@%s/%s.git', $WWW::AUR::HOST, $name);

    my $self = bless { _path_params( @_ ),
                       pkgfile     => "$name.src.tar.gz",
                       info        => $info,
                      }, $class;

    return $self;
}

sub _def_info_accessor
{
    my ($field) = @_;

    no strict 'refs';
    *{ "WWW::AUR::Package::$field" } = sub {
        my ($self) = @_;
        return $self->{info}{$field} || q{};
    };
}

for ( qw{ id name version desc category url urlpath
          license votes outdated ctime mtime } ) {
    _def_info_accessor( $_ );
}

sub maintainer_name
{
    my ($self) = @_;
    return $self->{'info'}{'maintainer'}; # might be undef for orphan
}

#---PUBLIC METHOD---
# Returns a copy of the package info as a hash...
sub info
{
    my ($self) = @_;
    return %{ $self->{info} };
}

#---PRIVATE METHOD---
sub _download_url
{
    my ($self) = @_;

    return pkgfile_uri( $self->name );
}

#---OBJECT METHOD---
sub download_size
{
    my ($self) = @_;
    Carp::cluck("Subroutine download_size does not work due to nginx not returning content-length");
    return 0;
    # TODO: Fix or remove this
    my $ua   = _useragent();
    my $resp = $ua->head( $self->_download_url() );
    return undef unless $resp->is_success;
    return $resp->header( 'content-length' );
}

#---OBJECT METHOD---
sub download
{
    my ($self, $usercb) = @_;

    my $pkgurl  = $self->_download_url();
    my $pkgpath = File::Spec->catfile( $self->{dlpath},
                                       $self->{pkgfile} );

    make_path( $self->{dlpath} );

    open my $pkgfile, '>', $pkgpath or die "Failed to open $pkgpath:\n$!";
    binmode $pkgfile;

    my $store_chunk = sub {
        my $chunk = shift;
        print $pkgfile $chunk;
    };

    if ( $usercb ) {
        my $total = $self->download_size();
        my $dled  = 0;

        my $store = $store_chunk;
        $store_chunk = sub {
            my $chunk = shift;
            $dled += length $chunk;
            $usercb->( $dled, $total );
            $store->( $chunk );
        };
    }

    my $ua   = _useragent();
    my $resp = $ua->get( $self->_download_url(),
                         ':content_cb' => $store_chunk );
    close $pkgfile or die "close: $!";
    Carp::croak( 'Failed to download package file:' . $resp->status_line )
        unless $resp->is_success;

    $self->{pkgfile_obj} = WWW::AUR::Package::File->new
        ( $pkgpath, _path_params( %$self ));

    return $pkgpath;
}

#---PUBLIC METHOD---
# Purpose: Returns an object representing the package maintainer.
sub maintainer
{
    my $self  = shift;
    my $mname = $self->maintainer_name();
    return undef unless defined $mname;

    # Propogate parameters to our new Maintainer object...
    Carp::croak 'Only a hash of path parameters are allowed as argument'
        unless @_ % 2 == 0;

    require WWW::AUR::Maintainer;

    # Propogate parameters to our new Maintainer object...
    # Path parameters given as arguments override the path params the
    # package object was given...
    my %params = ( _path_params( %$self ), _path_params( @_ ) );
    my $mobj   = WWW::AUR::Maintainer->new( $mname, %params );
    return $mobj;
}

sub _def_file_wrapper
{
    my ($name) = @_;

    no warnings 'redefine';
    no strict 'refs';
    my $file_method = *{ $WWW::AUR::Package::File::{$name} }{ 'CODE' };
    *{ $name } = sub {
        my $self = shift;
        return undef unless $self->{'pkgfile_obj'};
        my $ret = eval { $file_method->( $self->{'pkgfile_obj'}, @_ ) };
        die if $@;
        return $ret;
    };
}

_def_file_wrapper( $_ ) for qw{ extract src_pkg_path
                                src_dir_path make_src_path build
                                bin_pkg_path };

# Wrap the Package::File methods to call download first if we have to...
sub _def_dl_wrapper
{
    my ($name) = @_;

    no warnings 'redefine';
    no strict   'refs';

    my $oldcode = *{ $name }{ 'CODE' };
    *{ $name } = sub {
        my $self = shift;
        unless ( $self->{'pkgfile_obj'} ) { $self->download(); }
        return $oldcode->( $self, @_ );
    };
}

_def_dl_wrapper( $_ ) for qw/ extract build /;

#---PRIVATE METHOD---
# Purpose: Download the package's PKGBUILD without saving it to a file.
sub _download_pkgbuild
{
    my ($self) = @_;

    my $name         = $self->name;
    my $pkgbuild_uri = pkgbuild_uri( $name );

    my $ua   = _useragent();
    my $resp = $ua->get( $pkgbuild_uri );

    Carp::croak "Failed to download ${name}'s PKGBUILD: "
        . $resp->status_line() unless $resp->is_success();

    return $resp->content();
}

sub pkgbuild
{
    my ($self) = @_;

    return $self->{pkgfile_obj}->pkgbuild
        if $self->{pkgfile_obj};

    return $self->{pkgbuild_obj}
        if $self->{pkgbuild_obj};

    my $pbtext = $self->_download_pkgbuild;

    $self->{pkgbuild_txt} = $pbtext;
    $self->{pkgbuild_obj} = eval { WWW::AUR::PKGBUILD->new( $pbtext ) };
    Carp::confess if $@; # stack trace

    return $self->{pkgbuild_obj};
}

1;
