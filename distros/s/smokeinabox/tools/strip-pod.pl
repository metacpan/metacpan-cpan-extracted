use strict;
use warnings;
use Pod::Stripper;
use File::Copy qw(cp);
use File::Find;

my $dir = shift || die;
die unless -d $dir;

find( \&_wanted, $dir,  );
exit 0;

sub _wanted {
  my $file = $_;
  return if -d $file;
  print $File::Find::name, "\n";
  my $p = Pod::Stripper->new();
  my $tmp = $file . '.tmp';
  cp( $file, $tmp ) or die "$!\n";
  chmod 0644, $file or die"$!\n";
  $p->parse_from_file( $tmp, $file );
  unlink $tmp;
  return;
}

=for comment
my $p = Pod::Stripper->new();
my $backup = $file . '.bak';
my $tmp = $file . '.tmp';
cp( $file, $backup ) or die "$!\n";
cp( $file, $tmp ) or die "$!\n";
$p->parse_from_file( $tmp, $file );
unlink $tmp;
=cut
