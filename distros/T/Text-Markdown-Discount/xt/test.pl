#/usr/bin/perl

use ExtUtils::testlib;

use Text::Markdown 'markdown';
use Text::Markdown::Discount;
use Benchmark;
use File::Slurp;
use Text::Diff;

my $text = read_file('xt/index.text');
my $a = Text::Markdown::Discount::markdown($text);
my $b = Text::Markdown::markdown($text);

unless ( $a eq $b ) {
    print diff \$a, \$b; 
    #die "BOO";
}
my $count = 1000;
timethese($count, {
    'B_Text::Markdown::Discount' => sub { Text::Markdown::Discount::markdown($text) },
    'A_Text::Markdown' => sub { Text::Markdown::markdown($text) },
});


