package Vulcan::Symlink::Conf;

use strict;
use warnings;

use Carp;
use YAML::XS;

sub new
{
    my ( $class, %param ) = splice @_;
    my ( $conf, $name ) = map { defined $param{$_}
        ? $param{$_} : confess "'$_' not defined" } qw( conf name );

    confess "$conf: $@" unless my $self = eval { YAML::XS::LoadFile( $conf ) };

    my $error = "$conf: $name";
    confess "$error: not defined" unless $conf = $self->{$name};
    confess "$error: link not defined" unless $self = $conf->{link};

    for my $link ( keys %$self )
    {
        my $c = $self->{$link} ||= {};
        my $regex = $c->{regex};

        $c->{regex} = $regex ? eval $regex : qr/$link/;
        map { $c->{$_} ||= $conf->{$_} } qw( root chown );
        confess "$error: root not defined for '$link'" unless $c->{root};
    }
    bless $self, ref $class || $class;
}

sub dump
{
    my ( $self, %conf ) = shift;
    my @link = keys %$self;

    for my $path ( @_ )
    {
        if ( $self->{$path} )
        {
            $conf{$path} = +{ %{ $self->{$path} }, path => $path };
        }
        else
        {
            map { $conf{$_} = +{ %{ $self->{$_} }, path => $path } }
            grep { $path =~ $self->{$_}{regex} } @link;
        }
    }

    map { $conf{$_} = +{ %{ $self->{$_} } } } @link unless @_;
    return wantarray ? %conf : %conf ? \%conf : undef;
}

1;
