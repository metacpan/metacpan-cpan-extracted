use strict;
use warnings;
use autodie;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::Clustericious::Log import => 'log_unlike';
use Test::More;
use File::Spec;
use Scalar::Util qw( refaddr );

# this change to Mojolicious in version 3.85 broke the way we set the temp directory:
# https://github.com/kraih/mojo/commit/eff7e8dce836c75e21c1c1b3456fb3f8a9992ecb
# this test checks to see that Mojo::Asset::File#tmpdir is set before Mojo::Asset::File#handle is called
# if the internal ordering of these method calls is changed again in Mojolicious it might show
# up as an error here, but the important thing is that temp files are written to
# $disk_root/tmp and then moved the appropriate $disk_root/xx/xx/xx/... directory
# rather than $TMPDIR and then moved to $disk_root/xx/xx/xx/...

if(eval q{ use Monkey::Patch; use Yars::Client; *patch_class = \&Monkey::Patch::patch_class; 1 })
{ plan tests => 14 }
else
{ plan skip_all => 'test requires Monkey::Patch and Yars::Client' }

my $root = create_directory_ok 'data';
create_config_helper_ok data_dir => sub {
  my $dir = "$root/disk_$_[0]";
  mkdir $dir unless -d $dir;
  mkdir "$dir/tmp" unless -d "$dir/tmp";
  $dir;
};

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

do {
  open my $fh, '>', "$root/disk_5/tmp/right.txt";
  close $fh;
};

$ENV{MOJO_TMPDIR} = create_directory_ok 'tmp';
$ENV{MOJO_MAX_MEMORY_SIZE} = 5;            # Force temp files.
do { 
  open my $fh, '>', "$ENV{MOJO_TMPDIR}/wrong.txt";
  close $fh;
};

my $sample_filename = create_directory_ok('sample') . '/sample.txt';
do {
  open my $fh, '>', $sample_filename;
  binmode $fh;
  print $fh 'hello world';
  close $fh;
};

my $client = Yars::Client->new;

$t->get_ok("$url/version")
  ->status_is(200);

my $tmpdir;
my $path;
my $done = 0;

do {

  my $refaddr;

  $cluster->apps->[0]->hook(after_build_tx => sub {
    my ( $tx, $app ) = @_;
    $tx->req->content->on(body => sub {
      my $content = shift;
      $content->asset->on(upgrade => sub {
          my ( $mem, $file ) = @_;
          $refaddr = refaddr $file if $tx->req->url =~ m{/file/sample.txt/};
      });
    })
  });

  my $patch1 = patch_class('Mojo::Asset::File', handle => sub {
    if($done)
    {
      # give Mojo::Asset::File something to close
      # in DESTROY
      open my $fh, '<', __FILE__;
      return $fh;
    }
    my($original, $self, @rest) = @_;
    if(defined $refaddr && refaddr($self) == $refaddr)
    {
      if(defined $tmpdir)
      {
        die unless $tmpdir eq $self->tmpdir;
      }
      else
      {
        $tmpdir = eval { $self->tmpdir; }; diag $@ if $@;
      }
    }
    my @ret;
    my $ret;
    if(wantarray) {
      @ret = $self->$original(@rest);
    } else {
      $ret = $self->$original(@rest);
    }
    if(defined $refaddr && refaddr($self) == $refaddr)
    {
      if(defined $path)
      {
        die unless $self->path eq $path;
      }
      else
      {
        $path = $self->path;
      }
    }
    wantarray ? return(@ret) : return($ret);
  });

  $client->upload($sample_filename);
  
};

ok( -e File::Spec->catfile( $root, qw( disk_5 5e b6 3b bb e0 1e ee d0 93 cb 22 bb 8f 5a cd c3 sample.txt )), 'file uploaded');
ok( -e File::Spec->catfile( $tmpdir, qw( right.txt )), 'used correct tmp directory ' . ($tmpdir//'undef'));
like $path, qr{disk_5}, 'path = ' . $path;

log_unlike qr{HASH\(0x[a-f0-9]+\)}, 'no hash references in log';
log_unlike qr{ARRAY\(0x[a-f0-9]+\)}, 'no array references in log';

$done = 1;

__DATA__

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url : <%= cluster->url %>

servers :
    - url : <%= cluster->urls->[0] %>
      disks :
% foreach my $prefix (0..9,'a'..'f') {
        - root : <%= data_dir $prefix %>
          buckets : ['<%= $prefix %>']
% }

state_file: <%= create_directory_ok('state') . '/state' %>
