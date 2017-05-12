# Test symlink in path.
# It is required to run test with admin privileges on windows system with NTFS.
#########################
use warnings;
use strict;

use Test::More;

if( $^O eq 'MSWin32' ) {
    plan skip_all => "This test is not required under Windows.";
} else {
    plan tests => 5;
}
use Treex::PML;
use File::Spec;
use File::Copy;
use File::Temp;
#use if $^O eq 'MSWin32', 'Win32::Symlink';

my $up  = File::Spec->updir;
my $sep = File::Spec->catfile(q(), q());

my $gzm = 'sample0.m.gz';
my $gzw = 'sample0.w.gz';

my $dir = File::Temp->newdir();
my $h   = $dir->dirname;


my %tests = (
            "$h${sep}x"         => 'no ..',
            "$h${sep}xa"        => '/../ in the middle',
            "$h${sep}b${sep}xc" => '/../../ repeated connected',
            "$h${sep}ad"        => '/../da/../ repeated (symlink to symlink)',
            "$h${sep}ce"        => '/../da/../../ repeated (symlink to symlink)'
            );
mkdir "$h${sep}x";
mkdir "$h${sep}b";
symlink "$h${sep}x"         , "$h${sep}xa";
symlink "$h${sep}x"         , "$h${sep}b${sep}xc";
symlink "$h${sep}xa"        , "$h${sep}ad";
symlink "$h${sep}b${sep}xc" , "$h${sep}ce";

#tree of dirs and symlinks:
#.
#├── ad -> xa
#├── b
#│   └── xc -> x
#├── ce -> b/xc
#├── x       (this dir contains sample0.w.gz and wdata_schema.xml diles)
#└── xa -> x

copy("test_data${sep}url$sep$gzw"              , "$h${sep}x${sep}$gzw");
copy("test_data${sep}url$sep$gzm"              , "$h${sep}x${sep}$gzm");
copy("test_data${sep}url${sep}wdata_schema.xml", "$h${sep}x${sep}wdata_schema.xml");
copy("test_data${sep}url${sep}mdata_schema.xml", "$h${sep}x${sep}mdata_schema.xml");


for my $p (keys %tests) {
  my $document = Treex::PML::StandardFactory->createDocumentFromFile("$p$sep$gzm");
  $document->save("${h}${sep}result.xml");

  my $line;
  open my $FILE, '<', "${h}${sep}result.xml" or die "Could not open file: $!";
  1  while (defined($line = <$FILE>) and $line !~ m/.*$gzw.*/);
  $line =~ s/.*(\".*\Q$gzw\E\").*/$1/s;
  is($line, qq("$gzw"), $tests{$p});
}


# removing links due to warning in File::Temp
rmdir "$h${sep}xa";
rmdir  "$h${sep}b${sep}xc";
rmdir  "$h${sep}ad";
rmdir  "$h${sep}ce";

done_testing();
