use strict;
use warnings;
use Test::More;
use IPC::Open3;

BEGIN {
  my $fh;
  my $pid = eval { open3 undef, $fh, undef, "cvs --version" };
  my $version = join '', <$fh> if $fh;
  plan skip_all => '"cvs" execution failed.'
    if $@ or waitpid($pid, 0) != $pid or $?>>8 != 0;
  $version =~ s#^\s*##;
  $version = (split ' ', $version)[4];
  diag "CVS version: $version"; # track "cvsadmin" problem
}

use File::Copy qw(cp);
use File::Temp;
use File::Path qw(mkpath);
use URI::URL;
my $td = File::Temp->newdir;

my $repository = "$td/repository";
my $sandbox = "$td/sandbox";
my $base_url = "vcs://localhost/VCS::Cvs"
  . URI::URL->newlocal($sandbox)->unix_path
  . "/td";

BEGIN { use_ok('VCS') }

$ENV{CVSROOT} = $repository;
system 'cvs init';
mkpath $sandbox, "$repository/td/dir", +{};
cp('t/cvs_testfiles/td/dir/file,v_for_testing',$repository.'/td/dir/file,v');

system <<EOF;
cd $sandbox
cvs -Q co td
cd td/dir
cvs -Q tag mytag1 file
cvs -Q tag mytag2 file
EOF

my $f = VCS::File->new("$base_url/dir/file");
ok(defined $f,'VCS::File->new');

my $h = $f->tags();
is($h->{mytag1},'1.2','file tags 1');
is($h->{mytag2},'1.2','file tags 2');

my @versions = $f->versions;
ok(scalar(@versions),'versions');
my ($old, $new) = @versions;
is($old->version(),'1.1','old version');
is($new->version(),'1.2','new version');

like($new->date, qr/2001.11.\d+ \d+:10:29/, 'date');

is($new->author(),'user','author');

my $d = VCS::Dir->new("$base_url/dir");
ok (defined($d),'Dir');

my $th = $d->tags();
#warn("\n",Dumper($th),"\n");
ok (exists $th->{'mytag1'});
ok (exists $th->{'mytag1'}->{$sandbox.'/td/dir/file'});
is($th->{'mytag1'}->{$sandbox.'/td/dir/file'},'1.2');

my @c = $d->content;
is(scalar(@c),1,'content');
is($c[0]->url(),"$base_url/dir/file",'content url');

done_testing;
