#!C:/Perl/bin/perl -w
use strict;
use warnings;
use Data::Dumper;

if( fork )
{
  require Win32::MMF::Shareable;
  my $ns = tie( my @share, 'Win32::MMF::Shareable', 'share' ) || die;
  sleep(1);
  push @share, 'PARENT';

  print Dumper(\@share);
}
else
{
  require Win32::MMF::Shareable;
  my $ns = tie( my @share, 'Win32::MMF::Shareable', 'share' ) || die;
  push @share, 'CHILD';
}

