#!/usr/bin/perl -w
#
# A small example of XML::Genx.  Given a URL and directory, output an
# RSS file linking to files in that directory (which are presumed
# served via the URL).
#
# @(#) $Id: rssdir.pl 447 2004-12-04 22:12:20Z dom $
#

use strict;
use warnings;

use File::Spec::Functions qw( catfile );
use POSIX 'strftime';
use XML::Genx::Simple;

my ( $base_url, $dir ) = @ARGV;

die "usage: $0 base_url dir\n"
  unless $base_url && $dir;

my $w = XML::Genx::Simple->new;

$w->StartDocFile( *STDOUT );
$w->StartElementLiteral( 'rss' );
$w->AddAttributeLiteral( version => '2.0' );

$w->Element( title       => "Contents of $dir" );
$w->Element( link        => $base_url );
$w->Element( description => "A list of all the files in $dir, in date order." );
$w->Element( pubDate     => rfc822date() );
$w->Element( generator   => $0 );

my @files = get_files( $dir );
my %mtime = map { $_ => ( stat catfile $dir, $_ )[9] } @files;
@files = sort { $mtime{ $b } <=> $mtime{ $a } } @files;

my $item = $w->DeclareElement( 'item' );
foreach ( @files ) {
    $item->StartElement;
    $w->Element( title   => $_ );
    $w->Element( link    =>  "$base_url/$_" );
    $w->Element( pubDate => rfc822date( $mtime{ $_ } ) );
    $w->EndElement;
}

$w->EndElement;    # </rss>
$w->EndDocument;

exit 0;

#---------------------------------------------------------------------

sub get_files {
    my ( $dir ) = @_;
    opendir my $dh, $dir
        or die "$0: opendir($dir): $!\n";
    my @files =
        grep { -f catfile( $dir, $_ ) }
        grep { !/^\./ }
        grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return @files;
}

#---------------------------------------------------------------------

sub rfc822date {
    my $when = shift || time;
    return strftime "%a, %m %b %Y %H:%M:%S GMT", gmtime( $when );
}
