package Janus::Conf;

=head1 NAME

Janus::Conf - Load/Inspect maintenance configs

=head1 SYNOPSIS

 use Janus::Conf;

 my $conf = Janus::Conf->new( '/conf/file' )->dump( 'foo' );

=cut
use strict;
use warnings;
use Carp;
use YAML::XS;

=head1 CONFIGURATION

YAML file that defines sets of maintenance parameters index by names.
Each set defines the following parameters:

 target : targets of maintenance, to be devided into batches.
 maint : name of maintainance code.
 batch : name of batch code.
 param : ( optional ) parameters of batch code.

=cut
our @PARAM = qw( target maint batch );

sub new
{
    my ( $class, $conf ) = splice @_;

    confess "undefined config" unless $conf;
    $conf = readlink $conf if -l $conf;

    my $error = "invalid config $conf";
    confess $error unless -f $conf;

    eval { $conf = YAML::XS::LoadFile( $conf ) };

    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $conf ne 'HASH';

    my $self = bless $conf, ref $class || $class;

    while ( my ( $name, $conf ) = each %$conf )
    {
        my $error = "$error: invalid $name definition";
        confess $error if ref $conf ne 'HASH';
        eval { $self->check( $conf ) };
        confess "$error: $@" if $@;
    }
    return $self;
}

sub check
{
    my ( $self, $conf ) = splice @_;
    map { die "$_ not defined" if ! $conf->{$_} } @PARAM;
}

=head1 METHODS

=head3 dump( @name )

Returns configurations indexed by @name.

=cut
sub dump
{
    my $self = shift;
    my @conf = return @$self{@_};
    return wantarray ? @conf : shift @conf;
}

=head3 names

Returns names of all maintenance.

=cut
sub names
{
    my $self = shift;
    return keys %$self;
}

1;
