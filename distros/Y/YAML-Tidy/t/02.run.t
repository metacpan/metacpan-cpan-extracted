#!/usr/bin/perl
use warnings;
use v5.20;
use Test::More;
use Test::Warnings qw/ :report_warnings /;
use Encode;
use experimental qw/ signatures /;

use FindBin '$Bin';
use YAML::Tidy::Run;

my (@out, @before, @after, %write);
no strict 'refs';
no warnings 'redefine';
local *{"YAML::Tidy::Run::_output"} = sub($, $msg) { push @out, $msg };
local *{"YAML::Tidy::Run::_before"} = sub($, $file, $yaml) { push @before, $yaml };
local *{"YAML::Tidy::Run::_after"} = sub($, $file, $yaml) { push @after, $yaml };
local *{"YAML::Tidy::Run::_write_file"} = sub($, $file, $out) { $write{$file} = $out };

my $data_start = tell *DATA;

sub clean {
    seek DATA, $data_start, 0;
    @out = (); @before = (); @after = (); %write = ();
}

my $infile = "$Bin/data/run.yaml";
my $data = do { local $/; <DATA> };
open my $fh, '<', $infile or die $!;
my $input = do { local $/; <$fh> };
close $fh;

clean();

my $ytr;
my $tidied = <<'EOM';
---
some: input file
that: {should be: tidied}
EOM
my $filelist = <<'EOM';
a/b/1.yaml
c/d/2.yaml
EOM

subtest stdin => sub {
    local @ARGV = qw/ - /;
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    is $out[0], $tidied, 'Tidied stdin';
    clean();

    local @ARGV = qw/ - --debug /;
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    is $before[0], $data, 'debug before';
    is $after[0], $tidied, 'debug after';
    clean();
};

subtest information => sub {
    local @ARGV = qw/ --version /;
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    like $out[0], qr{yamltidy: .*YAML::PP: .*}s, '--version';
    clean();

    local @ARGV = qw/ --help /;
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    like $out[0], qr{yamltidy.*options}s, '--help';
    clean();
};

subtest file => sub {
    local @ARGV = $infile;
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    is $out[0], $tidied, 'Tidied file';
    clean();

    local @ARGV = (qw/ --debug /, $infile);
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    is $before[0], $input, 'debug before';
    is $after[0], $tidied, 'debug after';
    clean();

    local @ARGV = (qw/ --inplace /, $infile);
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    ok exists $write{ $infile }, 'inplace - file written';
    is $write{ $infile }, $tidied, 'inplace - file content correct';
    clean();

    local @ARGV = (qw/ --inplace --verbose /, $infile);
    $ytr = YAML::Tidy::Run->new(stdin => \*DATA);
    $ytr->run;
    like $out[0], qr{info.*Processed.*run.yaml.*\bchanged}, 'Verbose output';
    clean();
};

subtest 'batch stdin' => sub {
    my @f;
    local *{"YAML::Tidy::Run::_process_file"} = sub($, $file) { push @f, $file };
    open my $in, '<', \$filelist;
    local @ARGV = (qw/ -b - --inplace /);
    $ytr = YAML::Tidy::Run->new(stdin => $in);
    $ytr->run;
    is $f[0], 'a/b/1.yaml', 'file 1';
    is $f[1], 'c/d/2.yaml', 'file 2';
    clean();

    local @ARGV = (qw/ --batch - /);
    $ytr = YAML::Tidy::Run->new(stdin => $in);
    eval {
        $ytr->run;
    };
    my $err = $@;
    like $err, qr/--batch currently requires --inplace/, '--inplace required';
    clean();
};

done_testing;

__DATA__
"some":  input file	
that: {"should be":tidied}
