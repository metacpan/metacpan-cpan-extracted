package Argos::Conf;

=head1 NAME

Argos::Conf - Argos configuration interface.

=head1 SYNOPSIS

 use Argos::Conf;

 my $conf = Argos::Conf->new( '/conf/file' )->dump( 'foo' );

 my $expr = '2w,1h,20s';
 my $sec = Argos::Conf->time( $expr );

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;

use constant { MINUTE => 60, HOUR => 3600, DAY => 86400 };

=head1 INTERFACE

Configuration be a YAML file that contains a HASH of HASH.

=cut
sub new
{
    my ( $class, $conf ) = splice @_;

    confess "undefined config" unless $conf;
    $conf = readlink $conf if -l $conf;

    my $error = "invalid config $conf";
    confess "$error: not a regular file" unless -f $conf;

    eval { $conf = YAML::XS::LoadFile( $conf ) };

    confess "$error: $@" if $@;
    confess "$error: not HASH" if ref $conf ne 'HASH';

    my $self = bless $conf, ref $class || $class;

    while ( my ( $name, $conf ) = each %$conf )
    {
        my $error = "$error: invalid $name definition";
        confess $error if ref $conf ne 'HASH';

        if ( $self->can( 'check' ) )
        {
            eval { $self->check( $conf ) };
            confess "$error: $@" if $@;
        }
    }
    return $self;
}

=head3 check( $hash )

Inspects $hash at leaf-level.

=head1 METHODS

=head3 dump( @name )

Returns configurations indexed by @name.

=cut
sub dump
{
    my $self = shift;
    my @conf = map { YAML::XS::Load( YAML::XS::Dump( $_ ) ) } @$self{@_};
    return wantarray ? @conf : shift @conf;
}

=head3 names

Returns names of all watchers.

=cut
sub names
{
    my $self = shift;
    return keys %$self;
}

=head3 time( @expr )

Convert time expressions to seconds. 

=cut
sub time
{
    my $class = shift;
    my @time = map { $class->parse( $_ ) } @_;
    return wantarray ? @time : shift @time;
}

sub parse
{
    my ( $class, $expr ) = splice @_;
    return undef unless defined $expr;

    my @token = split /(\D+)/, $expr;
    return undef if $token[0] !~ /\d/;

    my $sum = 0;
    push @token, 's' if @token % 2;

    while ( @token )
    {
        my ( $num, $unit ) = splice @token, 0, 2;
        $unit = lcfirst $unit;

        if    ( $unit =~ /^s/ ) { $sum += $num }
        elsif ( $unit =~ /^m/ ) { $sum += $num * MINUTE }
        elsif ( $unit =~ /^h/ ) { $sum += $num * HOUR }
        elsif ( $unit =~ /^d/ ) { $sum += $num * DAY }
    }
    return $sum;
}

1;
