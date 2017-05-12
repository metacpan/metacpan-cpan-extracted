use strict;
use warnings;
use Test::More;
use WorePAN;
use File::Temp qw/tempdir/;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};
plan skip_all => "requires PAUSE::Permissions to test" unless eval "use PAUSE::Permissions 0.08; 1";

my $tmpdir = tempdir(CLEANUP => 1);
my $perms = "$tmpdir/06perms.txt";
{
  open my $fh, '>', $perms;
  print $fh "File:        06perms.txt\n";
  print $fh "\n";
  print $fh "Path::Extended,ISHIGAKI,f\n";
  print $fh "Path::Extended::File,SOMEONE,f\n";
  close $fh;
}

my $worepan = WorePAN->new(
  files => [qw{
    ISHIGAKI/Path-Extended-0.22.tar.gz
  }],
  cleanup => 1,
  use_backpan => 1,
  no_network => 0,
  permissions => PAUSE::Permissions->new(path => $perms),
);
my @lines = $worepan->slurp_packages_details;

ok !grep /Path::Extended::File/, @lines;

note join "\n", @lines, "";

unlink $perms;

done_testing;
