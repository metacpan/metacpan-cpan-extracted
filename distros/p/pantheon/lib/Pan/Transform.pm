package Pan::Transform;

=head1 NAME

Pan::Transform - Load and inspect transform code/conf

=head1 SYNOPSIS

 use Pan::Transform;

 my $code = Pan::Transform->new
 (
     code => '/code/file',
     conf => '/conf/file',
 )

 $code = $code->dump( 'foo' );

 &$code( log => \*STDERR );

=cut
use strict;
use warnings;

use Carp;
use YAML::XS;

sub new
{
    my ( $class, %self ) = splice @_;
    
    for my $param ( 'code', 'conf' )
    {
        confess "udefined $param" unless my $path = $self{$param}; 
        $path = readlink $path if -l $path;

        my $error = "invalid $param: $path";
        confess "$error: no such file" unless -f $path;

        $self{$param} = $param eq 'code'
            ? do $path : eval { YAML::XS::LoadFile( $path ) };

        confess "$error: $@" if $@;
    }

    confess "invalid conf: not HASH" if ref $self{conf} ne 'HASH';
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 dump( $set )

Run transform.

=cut
sub dump
{
    my ( $self, $set ) = splice @_;
    return undef unless my $param = $self->{conf}{$set};
    return sub { &{ $self->{code} }( param => $param, @_ ) };
}

1;
