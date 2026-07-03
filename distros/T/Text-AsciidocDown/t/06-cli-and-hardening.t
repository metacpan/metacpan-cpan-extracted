use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(getcwd);

use Text::AsciidocDown;

my $script = File::Spec->catfile(getcwd(), 'script', 'asciidoc-down');
ok(-f $script, 'cli script exists');

my $tmp = tempdir(CLEANUP => 1);
my $in = File::Spec->catfile($tmp, 'doc.adoc');
open my $fh, '>:encoding(UTF-8)', $in or die $!;
print {$fh} "= Title\n\nBody\n";
close $fh;

my $out = File::Spec->catfile($tmp, 'doc.md');
my $cmd = "$^X $script -o $out $in";
my $rc = system($cmd);
is($rc, 0, 'cli converts file to output path');
ok(-f $out, 'output file created');

open my $rfh, '<:encoding(UTF-8)', $out or die $!;
my $out_text = do { local $/; <$rfh> };
close $rfh;
like($out_text, qr/^# Title\n\nBody\n\z/, 'converted content emitted');

my $stdin_cmd = sprintf("printf '= T\\n\\nX\\n' | %s %s -o - -", $^X, $script);
my $stdout = `$stdin_cmd`;
like($stdout, qr/^# T\n\nX\n\z/, 'stdin/stdout mode works');

my $version = `$^X $script -v`;
like($version, qr/^0\.1\.0\n\z/, 'version output works');

my $help = `$^X $script -h`;
like($help, qr/^Usage: asciidoc-down /, 'help output works');

my $man = `$^X $script --man`;
like($man, qr/^NAME\n\s+asciidoc-down - Convert AsciiDoc to Markdown/m, 'man output has NAME section');
like($man, qr/--prepublish/ms, 'man output documents prepublish');
like($man, qr/--postpublish/ms, 'man output documents postpublish');
like($man, qr/hiding the source AsciiDoc file/ms, 'man output explains prepublish usage');
like($man, qr/return the repository to its normal authoring state/ms, 'man output explains postpublish usage');
like($man, qr/--attribute env=npm --attribute env-npm/ms, 'man output suggests explicit env attributes');

my $pre = File::Spec->catfile($tmp, 'README.adoc');
open my $pfh, '>:encoding(UTF-8)', $pre or die $!;
print {$pfh} "ifdef::env-npm[npm]\n";
close $pfh;

$rc = system("cd $tmp && $^X $script --prepublish");
is($rc, 0, 'prepublish routine runs');
ok(-f File::Spec->catfile($tmp, '.README.adoc'), 'prepublish hides input');
ok(-f File::Spec->catfile($tmp, 'README.md'), 'prepublish creates markdown');

open my $pmfh, '<:encoding(UTF-8)', File::Spec->catfile($tmp, 'README.md') or die $!;
my $pre_md = do { local $/; <$pmfh> };
close $pmfh;
is($pre_md, "\n", 'prepublish does not inject env-npm attribute by default');

$rc = system("cd $tmp && $^X $script --postpublish");
is($rc, 0, 'postpublish routine runs');
ok(-f File::Spec->catfile($tmp, 'README.adoc'), 'postpublish restores input');
ok(!-f File::Spec->catfile($tmp, 'README.md'), 'postpublish removes markdown output');

$rc = system("cd $tmp && $^X $script --prepublish -a env=npm -a env-npm");
is($rc, 0, 'prepublish accepts explicit env attributes');
open $pmfh, '<:encoding(UTF-8)', File::Spec->catfile($tmp, 'README.md') or die $!;
$pre_md = do { local $/; <$pmfh> };
close $pmfh;
like($pre_md, qr/^npm\n\z/, 'explicit env attributes enable conditional content');

$rc = system("cd $tmp && $^X $script --postpublish");
is($rc, 0, 'postpublish routine runs after explicit-attribute prepublish');

my $converter = Text::AsciidocDown->new(attributes => { company => 'ACME' });
my $a = $converter->convert(":x: 1\n{company} {x}\n");
my $b = $converter->convert(":x: 1\n{company} {x}\n");
is($a, $b, 'deterministic output for repeated conversion');

done_testing;
