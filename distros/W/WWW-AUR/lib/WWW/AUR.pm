package WWW::AUR;

use warnings 'FATAL' => 'all';
use strict;

use Exporter;
use Carp       qw();
use File::Spec qw();

BEGIN {
    # We must define these as soon as possible. They are used in other
    # WWW::AUR modules. Like the ones we use after this block...

    our $VERSION   = '0.22';
    our $BASEPATH  = '/tmp/WWW-AUR';
    our $HOST      = 'aur.archlinux.org';
    our $UA        = 'WWW::AUR::UserAgent';

    our @ISA       = qw(Exporter);
    our @EXPORT_OK = qw(_is_path_param _path_params
                        _category_name _category_index
                        _useragent);
}

use WWW::AUR::RPC;

#---CONSTRUCTOR---
sub new
{
    my $class = shift;
    return bless { _path_params( @_ ) }, $class
}

#---PUBLIC METHOD---
sub search
{
    my ($self, $query) = @_;
    my $found_ref = WWW::AUR::RPC::search( $query );

    require WWW::AUR::Package;
    return map {
        WWW::AUR::Package->new( $_->{name}, info => $_, %$self );
    } @$found_ref;
}

#---HELPER FUNCTION---
sub _def_wrapper_method
{
    my ($name, $class) = @_;

    no strict 'refs';
    *{ "WWW::AUR::$name" } = sub {
        my $self = shift;
        eval "require $class";
        if ( $@ ) {
            Carp::confess "Failed to load $class module:\n$@";
        }
        return eval { $class->new( @_, %$self ) };
    };
}

_def_wrapper_method( 'find'       => 'WWW::AUR::Package'    );
_def_wrapper_method( 'maintainer' => 'WWW::AUR::Maintainer' );
_def_wrapper_method( 'iter'       => 'WWW::AUR::Iterator'   );
_def_wrapper_method( 'login'      => 'WWW::AUR::Login'      );

#-----------------------------------------------------------------------------
# UTILITY FUNCTIONS
#-----------------------------------------------------------------------------
# These functions are used internally by other WWW::AUR modules...

my %_IS_PATH_PARAM = map { ( $_ => 1 ) }
    qw/ basepath dlpath extpath destpath /;

#---INTERNAL FUNCTION---
sub _is_path_param
{
    my ($name) = @_;
    return $_IS_PATH_PARAM{ $name };
}

#---INTERNAL FUNCTION---
sub _path_params
{
    my @filterme = @_;
    my %result;

    FILTER_LOOP:
    while ( my $key = shift @filterme ) {
        next unless _is_path_param( $key );
        my $val = shift @filterme or last FILTER_LOOP;
        $result{ $key } = $val;
    }

    # Fill path parameters with default values if they are unspecified...
    our $BASEPATH;
    my $base = $result{ 'basepath' } || $BASEPATH;
    return ( 'dlpath'   => File::Spec->catdir( $base, 'src'   ),
             'extpath'  => File::Spec->catdir( $base, 'build' ),
             'destpath' => File::Spec->catdir( $base, 'cache' ),
             %result );
}

my @_CATEGORIES = qw{ daemons devel editors emulators games gnome
                      i18n kde lib modules multimedia network office
                      science system x11 xfce kernels fonts };

#---INTERNAL FUNCTION---
sub _category_name
{
    my ($i) = @_;
    $i -= 2;
    if ( $i >= 0 && $i <= $#_CATEGORIES ) {
        return $_CATEGORIES[$i];
    } else {
        return 'undefined';
    }
}

#---INTERNAL FUNCTION---
sub _category_index
{
    my ($name) = @_;
    $name = lc $name;

    for my $i ( 0 .. $#_CATEGORIES ) {
        return 2 + $i if $name eq $_CATEGORIES[ $i ];
    }

    Carp::croak "$name is not a valid category name";
}

#---INTERNAL FUNCTION---
# Create a user-agent object. The class name is specified in $UA.
sub _useragent
{
    our $UA;
    eval "require $UA" or die;
    return $UA->new(@_);
}

1;
