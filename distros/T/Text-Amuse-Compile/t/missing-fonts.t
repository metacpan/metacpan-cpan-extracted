#!perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

if ($ENV{TEST_WITH_LATEX}) {
    diag "Using XeLaTeX for testing";
    plan tests => 2;
}
else {
    plan skip_all => "No TEST_WITH_LATEX env found! skipping tests\n";
    exit;
}

my @logs;

my $c = Text::Amuse::Compile->new(pdf => 1,
                                  tex => 1,
                                  cleanup => 0,
                                  logger => sub {
                                      push @logs, @_;
                                  });
                                  
my $target = File::Spec->catfile(qw/t testfile fonts.muse/);
my $muse = <<'MUSE';
#title 会意字

会意字 龍賣

MUSE

write_file($target, $muse);

my @success = $c->compile($target);
ok(@success);

my @errors = grep { /missing character/i } @logs;
diag @logs;
ok (scalar(@errors), "Found the missing characters in the log");

unlink $target or die $!;

