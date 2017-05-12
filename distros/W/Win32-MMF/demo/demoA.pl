#! /usr/bin/perl

use strict;
use warnings;

$|++;

my $delay = 0.01;
my $i = 0;

if( fork )
{
  require Win32::MMF::Shareable;
  my $ns = tie( my %share, 'Win32::MMF::Shareable', 'share' ) || die;

  # select( undef, undef, undef, $delay / 2 );
  while( $i < 20 )
  {
    $ns->lock();
    $share{ 'P' . $i++ } = '-';
    print "parent($i)\t" . join( '', values( %share ) ) . "\n";
    $ns->unlock();
    select( undef, undef, undef, $delay );
  }
}
else
{
  require Win32::MMF::Shareable;
  my $ns = tie( my %share, 'Win32::MMF::Shareable', 'share' ) || die;

  while( $i < 20 )
  {
  	$ns->lock();
  	$share{ 'P' . $i++ } = '#';
    print "child($i)\t" . join( '', values( %share ) ) . "\n";
    $ns->unlock();
    select( undef, undef, undef, $delay );
  }
}


