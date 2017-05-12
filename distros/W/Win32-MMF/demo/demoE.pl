#!C:/Perl/bin/perl -w
use strict;
use Data::Dumper;

if( fork )
{
  require Win32::MMF::Shareable;
  my $ns = tie( my %share, 'Win32::MMF::Shareable', 'share' ) || die;
  select undef, undef, undef, 0.5;
  $share{parent} = 1;
  print Dumper(\%share);
}
else
{
  require Win32::MMF::Shareable;
  select undef, undef, undef, 0.2;
  my $ns = tie( my %share, 'Win32::MMF::Shareable', 'share' ) || die;
  $share{child} = 1;
}

