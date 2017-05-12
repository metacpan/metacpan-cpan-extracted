#!perl

use strict;
use warnings;

use Test::More tests => 30;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use File::Temp;

use Text::Amuse::Compile::Webfonts;
use Text::Amuse::Compile;

my $dir = File::Spec->catdir(qw/t webfonts/);
rmdir $dir;

my $webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok(!$webfonts, "Against non-existent directory, return undef");

# populate

mkdir $dir unless -d $dir;
my $spec = <<SPEC;
family Test
regular R.ttf
italic IX.ttf
bold B.ttf

# size
pippo 13
size 12
SPEC

write_file(File::Spec->catfile($dir, 'spec.txt'), $spec);
foreach my $ttf (qw/R I B BI/) {
    write_file(File::Spec->catfile($dir, "$ttf.ttf"), 1); # dummy
}

$webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok(!$webfonts, "Object not created (errors)");

$spec = <<SPEC;
family Test
regular R.ttf
italic I.ttf
bold B.ttf
bolditalic BI.ttf
size 12
SPEC
write_file(File::Spec->catfile($dir, 'spec.txt'), $spec);

$webfonts = Text::Amuse::Compile::Webfonts->new(webfontsdir => $dir);

ok($webfonts, "Object created (no errors)");

isnt $webfonts->srcdir, $dir, "srcdir is not the same as dir";

my %files = $webfonts->files;

my $c = Text::Amuse::Compile->new(epub => 1,
                                  webfontsdir => $dir);

my $target_base = File::Spec->catfile(qw/t testfile for-epub/);
my $epub = $target_base . '.epub';
unlink $epub if -f $epub;
for (1,2) {
    $c->compile($target_base . '.muse');
}
ok (-f $epub) or die "EPUB generation failed";
my $tmpdir = File::Temp->newdir(CLEANUP => 1);
my $zip = Archive::Zip->new;
die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
$zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
  or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
my $css = read_file(File::Spec->catfile($tmpdir->dirname, "stylesheet.css"));
like $css, qr/font-family: "Test"/, "Found font-family";
foreach my $file (keys %files) {
    my $epubfile = File::Spec->catfile($tmpdir->dirname, $file);
    ok (-f $epubfile, "$epubfile embedded");
    like $css, qr/src: url\("\Q$file\E"\)/, "Found the css rules for $file";
}

foreach my $accessor (qw/family regular italic bold bolditalic size format mimetype/) {
    ok ($webfonts->$accessor, "$accessor is ok: " . $webfonts->$accessor);
}

foreach my $file (keys %files) {
    my $relfile = File::Spec->catfile($dir, $file);
    ok (-f $relfile, "$relfile exists indeed");
}

# test and cleanup
foreach my $file (values(%files)) {
    ok (-f $file, "$file exists") and unlink $file;
}



unlink File::Spec->catfile($dir, 'spec.txt');
rmdir $dir;

    
