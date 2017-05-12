use strict;
use warnings;
use Test::More qw[no_plan];
use File::Temp qw[tempfile];
use App::SmokeBrew::IniFile;

{
  my ($fh, $filename) = tempfile( DIR => '.', UNLINK => 1);
  print $fh "builddir=/home/moo/cow/\n";
  print $fh "prefix=/home/moo/perls/\n";
  print $fh "mirrors=http://cpan.mirror.local/\n";
  print $fh "mirrors=ftp://cpan.perl.org/CPAN/\n";
  print $fh "\n[CPANPLUS::YACSmoke]\n\n";
  print $fh "test=1\n";
  close $fh;
  my $cfg = App::SmokeBrew::IniFile->read_file($filename);
  is( ref $cfg, 'HASH', 'We got a hashref back' );
  ok( exists $cfg->{_}, 'The underscore section exsists' );
  my $under = $cfg->{_};
  my $yacsmoke = $cfg->{'CPANPLUS::YACSmoke'};
  is( ref $under, 'HASH', 'The underscore section is a hashref' );
  is( $under->{builddir}, '/home/moo/cow/', 'builddir was okay' );
  is( $under->{prefix}, '/home/moo/perls/', 'prefix was okay' );
  is( ref $under->{mirrors}, 'ARRAY', 'The mirrors part is an arrayref' );
  is( scalar @{ $under->{mirrors} }, 2, 'There are two elements in the arrayref' );
  is( $under->{mirrors}->[0], 'http://cpan.mirror.local/', 'First element is as should be' );
  is( $under->{mirrors}->[1], 'ftp://cpan.perl.org/CPAN/', 'Second element is as should be' );

  is( ref $yacsmoke, 'HASH', 'The CPANPLUS::YACSmoke section is a hashref' );
  is( $yacsmoke->{test}, 1, 'test value was okay' );
}
