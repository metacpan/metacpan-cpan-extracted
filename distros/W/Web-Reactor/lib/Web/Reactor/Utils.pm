##############################################################################
##
##  Web::Reactor application machinery
##  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##  
##  LICENSE: GPLv2
##  https://github.com/cade-vs/perl-web-reactor
##
##############################################################################
package Web::Reactor::Utils;
use strict;
use Exporter;

our @ISA = qw( Exporter );

our @EXPORT = qw(
      
                  perl_package_to_file

                  dir_path_make
                  dir_path_check
      
                );

sub perl_package_to_file
{
  my $s = shift;
  $s =~ s/::/\//g;
  $s .= '.pm';
  return $s;
}

##############################################################################
#
#
#

sub dir_path_make
{
  my $path = shift;
  my %opt = @_;

  my $mask = $opt{ 'MASK' } || oct('700');
  
  my $abs;

  $path =~ s/\/+$/\//o;
  $abs = '/' if $path =~ s/^\/+//o;

  my @path = split /\/+/, $path;

  $path = $abs;
  for my $p ( @path )
    {
    $path .= "$p/";
    next if -d $path;

    mkdir( $path, $mask ) or return 0;
    }
  return 1;
}

sub dir_path_check
{
  my $dir = shift;
  my %opt = @_;

  dir_path_make( $dir, $opt{ 'MASK' } ) unless -d $dir;
  if( ! -d $dir )
    {
    die "check_dir: cannot find dir $dir\n" if $opt{ 'FATAL' };
    return undef;
    }
  return $dir;
}


##############################################################################
1;
###EOF########################################################################
