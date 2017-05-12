use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions;
use Data::Dumper;
use File::Temp;

eval "use Devel::Size";
if ($@) {
    plan skip_all => "Devel::Size required for testing memory usage";
    exit;
}
elsif (!$ENV{RELEASE_TESTING}) {
    plan skip_all => 'Not required for installation';
    exit;
}
else {
    plan tests => 4;
}



# create a document with

# say a 4M document

my $temp = File::Temp->new(TEMPLATE => "XXXXXXXXXX",
                           SUFFIX => ".muse",
                           TMPDIR => 1);

diag "Using " . $temp->filename;

for my $num (1..10_000) {
    my $line = "helo " x 100;
    print $temp "$line\n\n" ;
}

close $temp;

my $size = -s $temp->filename;
diag "Size is $size";

my $doc = Text::Amuse->new(file => $temp->filename);

ok($doc->as_html);
ok($doc->as_latex);
ok($doc->as_splat_html);

my $totalsize = Devel::Size::total_size($doc);
ok(($totalsize  < 60_000_000), "Size lesser than 60 Mb ("
   . sprintf('%0.3f', $totalsize / 1_000_000) . " Mb)");

