#!/usr/bin/perl

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use strict;
use warnings;

require v5.6.0;

use WWW::SimpleRobot;
use LWP::Simple;
use Getopt::Long;
use File::Basename;
use Mail::Mailer;

our( 
    $INSTALL_DIR, 
    $VERSION,
    $opt_depth,
    $opt_verbose,
    $opt_email,
);

sub usage()
{
    die <<EOF;
Usage: $0 <url>
EOF
}

{
    my %checked;
    sub check_url( $ )
    {
        my $url = shift;
        return $checked{$url} if $checked{$url};
        return $checked{$url} = head( $url );
    }

    sub nchecked()
    {
        return scalar keys %checked;
    }
}

$VERSION = '0.001';

GetOptions( qw( depth=i email=s verbose ) ) or usage;
my $url = shift or die usage;

$INSTALL_DIR = dirname( $0 );

my $base_uri = URI->new( $url );
my $base_url = $base_uri->scheme . '://' . $base_uri->authority . '/';
my ( %bimg, %blink, $nlink );
my $robot = WWW::SimpleRobot->new(
    URLS            => [ $url ],
    FOLLOW_REGEX    => "^$base_url",
    DEPTH           => $opt_depth,
    VISIT_CALLBACK  => sub { 
        my ( $url, undef, $html, $links ) = @_;
        warn "Visiting $url ...\n" if $opt_verbose;
        $nlink++;
        for my $link ( @$links )
        {
            my ( $tag, %attr ) = @$link;
            if ( $tag eq 'img' and my $src = $attr{src} )
            {
                unless ( check_url( $src ) )
                {
                    $bimg{$src}{$url}++;
               }
            }
        }
    },
    BROKEN_LINK_CALLBACK => sub {
        my $url = shift;
        my $linked_from = shift;
        $blink{$url}{$linked_from}++;
        $nlink++;
    }
);

$robot->traverse;

if ( $opt_email )
{
    my $mailer = Mail::Mailer->new() or die "Can't create mailer\n";
    $mailer->open( {
        To      => $opt_email,
        Subject => "BROKEN LINKS REPORT FOR $url AT " . scalar( localtime ) 
    } ) or die "Can't open mailer\n";
    select( $mailer );
}
my $header = "BROKEN LINKS REPORT FOR $url";
print "$header\n", "-" x length( $header ), "\n";
print "$nlink links and ", nchecked, " images checked\n\n";
print "BROKEN LINKS\n\n", 
    map( 
        { ( "$_ on:", map { "\n\t$_" } keys %{$blink{$_}} ); }
        keys( %blink )
    ),
    "\n"
if %blink;
print 
    "BROKEN IMAGES\n\n", 
    map( 
        { ( "$_ on:", map { "\n\t$_" } keys %{$bimg{$_}} ); }
        keys ( %bimg )
    ),
    "\n"
if %bimg;

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

stresstest.pl

=head1 SYNOPSIS

Usage: ./blinks.pl
    [ -depth <depth> ]
    [ -email <email> ]
    [ -verbose ]
    <base url>

=head1 DESCRIPTION

blinks.pl - a broken links checker.

=head1 AUTHOR

Ave.Wrigley@itn.co.uk

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------
