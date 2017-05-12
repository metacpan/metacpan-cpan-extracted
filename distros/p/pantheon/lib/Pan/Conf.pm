package Pan::Conf;

=head1 NAME

Pan::Conf

=head1 SYNOPSIS

 use Pan::Conf;

 my $conf = Pan::Conf->new( '/conf/file' )->dump( 'foo' );

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;

use Hermes;

=head1 CONFIGURATION

A YAML file that defines groups of configurations index by names. Each
group defines the following parameters:

 target : nodes in each group.
 transform : a list of transforms to apply to target.

=cut
our @PARAM = qw( target transform );

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

    my ( $range, %group, %dup ) = Hermes->new();

    while ( my ( $name, $conf ) = each %$conf )
    {
        my $error = "$error: invalid $name definition";
        confess "$error: not HASH" if ref $conf ne 'HASH';

        map { confess "$error: $_ undefined" unless $conf->{$_} } @PARAM;
        my ( $target, $transform ) = @$conf{ 'target', 'transform' };

        confess "$error: transform is not ARRAY" if ref $transform ne 'ARRAY';
        $target = [ $target ] unless ref $target;

        my %target = map { $_ => 1 } map { $range->load( $_ )->list } @$target;

        for my $t ( @{ $conf->{target} = [ keys %target ] } )
        {
            my $group = $group{$t} ||= [];
            push @$group, $name;
            $dup{$t} = $group if @$group > 1;
        }
    }

    %group = ();
    map { push @{ $group{ $range->load( $dup{$_} )->dump() } }, $_ } keys %dup;
    %dup = map { $_ => $range->load( $group{$_} )->dump() } keys %group;
    
    confess 'duplicate targets ' . YAML::XS::Dump \%dup if %dup;
    bless $conf, ref $class || $class;
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

Returns names of all groups.

=cut
sub names
{
    my $self = shift;
    return keys %$self;
}

1;
