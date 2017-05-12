#! /usr/bin/perl
use strict;
use warnings;

$|++;

my $delay = 0.01;
my $i = 0;

if( fork )
{
  require Win32::MMF::Shareable;
  my $ns = tie( my @share, 'Win32::MMF::Shareable', 'share' ) || die;
  print $ns->namespace()->{_view}, "\n";

  select( undef, undef, undef, $delay / 2 );
  while( $i < 20 )
  {
    $share[$i++] = '-';
    $ns->lock();
    print "parent($i)\t" . join( '', @share ) . "\n";
    $ns->unlock();
    select( undef, undef, undef, $delay );
  }
}
else
{
  require Win32::MMF::Shareable;
  my $ns = tie( my @share, 'Win32::MMF::Shareable', 'share' ) || die;
  print $ns->namespace()->{_view}, "\n";

  while( $i < 20 )
  {
  	$share[$i++] = '#';
  	$ns->lock();
    print "child($i)\t" . join( '', @share ) . "\n";
    $ns->unlock();
    select( undef, undef, undef, $delay );
  }
}


