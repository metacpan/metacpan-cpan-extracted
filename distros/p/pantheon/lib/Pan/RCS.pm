package Pan::RCS;

=head1 NAME

Pan::RCS - File manangement through RCS.

=head1 SYNOPSIS

 use Pan::RCS;

 my $src = Pan::RCS->init( '/src/dir' );
 my $rcs = Pan::RCS->new( '/path/conf' );

 $rcs->co();
 $rcs->ci();

=cut
use strict;
use warnings;

use Carp;
use Tie::File;
use File::Basename;

=head1 CONFIGURATION

I<src> and I<dst> dir must be defined. See Pan::Path.

All files in I<src> dir should be managed through RCS, including a
I<manifest>, where paths (relative to I<src>) of managed files are recorded.

=cut
use Pan::Path;

our $MANIFEST = 'manifest';

sub new
{
    my ( $class, $path ) = splice @_;

    $path = Pan::Path->new( $path )->make();
    my $list = $path->path( src => $MANIFEST );

    confess "no $MANIFEST: $list" unless -f "$list,v";
    confess "$MANIFEST busy" if -f $list;

    bless { path => $path, list => $list }, ref $class || $class;
}

=head1 METHODS

=head3 co()

Check out files from I<src> dir to I<dst> dir. Returns invoking object.

=cut
sub co
{
    my $self = shift;
    my ( $path, $list ) = @$self{ qw( path list ) };
    my ( %list, @list ) = ( $list => $path->path( dst => $MANIFEST ) );

    system( "co -l $list" );
    tie @list, qw( Tie::File ), $list;

    for my $file ( @list )
    {
        $file =~ s/^\s*//; $file =~ s/[#\s]+.*$//;
        next if $file =~ /^$/;

        my $src = $path->path( src => $file );
        next if $list{$src} || ! -f "$src,v";

        my $dst = $path->path( dst => $file );
        my $dir = File::Basename::dirname( $dst );

        unlink $src, ( $list{$src} = $dst );
        system( "co -l $src && mkdir -p $dir && mv $src $dst" );
    }

    system( "cp $list $list{$list}" ); ## $list: persist until DESTROY()
    untie @list;
    return $self;
}

=head3 ci()

Check in files from I<dst> dir to I<src> dir. Returns invoking object.

=cut
sub ci
{
    my $self = shift;
    my ( $path, $list ) = @$self{ qw( path list ) };
    my ( %list, @list );
    tie @list, qw( Tie::File ), $list;

    for my $file ( $list, @list )
    {
        my ( $src, $dst ) = map { $path->path( $_ => $file ) } qw( src dst );
        next if $list{$src} || ! -f ( $list{$src} = $dst );
        system( "mv $dst $src && logname | ci -r $src" );
    }
    return $self;
}

=head3 init( $dir )

Create a I<manifest> of all regular files under $dir, and check them into RCS.
Returns $dir.

=cut
sub init
{
    my ( $class, $dir ) = splice @_;

    confess "undefined source" unless $dir;
    $dir = readlink $dir if -l $dir;
    
    confess "invalid source $dir: not a directory" unless $dir;
    my $manifest = File::Spec->join( $dir, $MANIFEST );
    unlink $manifest;

    my $find = "find $dir -type f";
    my $list = "$find | sed -e 's/,v//; s/^$dir.//' | sort | uniq";
    my $ci = "logname | $find ! -iname '*,v' -exec ci -r {} \\;";

    system( "$list > $manifest && sync && $ci" );
    return $dir;
}

1;
