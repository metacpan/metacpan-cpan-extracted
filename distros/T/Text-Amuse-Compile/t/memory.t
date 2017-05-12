#!perl
use strict;
use warnings;
use utf8;
use Test::More;
use Text::Amuse::Compile;
use Data::Dumper;
use File::Spec;

eval "use Test::Memory::Cycle; use Memory::Usage";
if ($@ || !$ENV{TEST_WITH_LATEX} ||
    !$ENV{RELEASE_TESTING} || !$ENV{TEST_WITH_LATEX}) {
    plan skip_all => "Not required for installation";
    exit;
}
else {
    plan tests => 1;
}

my $mu = Memory::Usage->new;

$mu->record('start');

my %opt = (
           'bare_html' => '1',
           'pdf' => '1',
           'zip' => '1',
           'html' => '1',
           'lt_pdf' => '1',
           'epub' => '1',
           'extra' => {
                       'sitename' => 'The Anarchist Library',
                       'mainfont' => 'Linux Libertine O',
                       'division' => '12',
                       'papersize' => '',
                       'siteslogan' => 'Anti-Copyright',
                       'logo' => 'logo',
                       'fontsize' => '10',
                       'site' => 'http://www.amusewiki.org',
                       'twoside' => '1',
                       'bcor' => '1cm'
                      },
           'tex' => '1',
           'a4_pdf' => '1'
          );

my $target = File::Spec->catfile(qw/t manual manual.muse/);

my $compiler = Text::Amuse::Compile->new(%opt);

$mu->record('object ready, compiling');

for my $iter (1..5) {
    $mu->record("Compile iteration $iter");
    $compiler->compile($target);
    
}
$mu->record('end');
diag $mu->report();
memory_cycle_ok($compiler);


