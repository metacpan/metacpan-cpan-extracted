use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;

use_ok('WWW::Github::Files::Mock');

my $respodir;
{
    my ($volume,$directories,$file) = File::Spec->splitpath( $FindBin::Bin, 1 );
    my @dirs = File::Spec->splitdir( $directories );
    pop @dirs;
    $respodir = File::Spec->catpath( $volume, File::Spec->catdir( @dirs ), $file );
}

my $gitfiles = WWW::Github::Files::Mock->new($respodir);

ok($gitfiles, "object created");

my @files = $gitfiles->open('/')->readdir();

ok(scalar(@files), "read root directory");

my ($manifest) = grep { $_->name eq 'MANIFEST' } @files;

ok($manifest, "found manifest file");

my $c = $manifest->read();

ok($c =~ m/^README$/m, "successfully read manifest file");

my ($t_dir) = grep { $_->name eq 't' } @files;

ok($t_dir, "found t directory");

my @t_files = $t_dir->readdir();

ok(scalar(@t_files), "read files from t dir");

$manifest = $gitfiles->open('/MANIFEST');

ok($manifest, "found manifest file - direct");

$c = $manifest->read();

ok($c =~ m/^README$/m, "successfully read manifest file - direct");

done_testing();
