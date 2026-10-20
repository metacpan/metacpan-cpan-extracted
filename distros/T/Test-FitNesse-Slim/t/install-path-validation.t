use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib "$Bin/lib";
use Test::More;
use Test::FitNesse::Slim::InstallPath qw(verify_installed_path);

my $root = tempdir('test-slim-install-path-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my $prefix = "$root/prefix";
my $module = "$prefix/lib/perl5/Test/FitNesse/Slim.pm";
make_path("$prefix/lib/perl5/Test/FitNesse");
open my $module_fh, '>', $module or die "create installed module: $!";
print {$module_fh} "package Test::FitNesse::Slim; 1;\n";
close $module_fh or die "close installed module: $!";

my $alias = "$root/prefix-alias";
symlink($prefix, $alias) or plan skip_all => "directory symlinks unavailable: $!";
is(
  verify_installed_path(
    "$alias/lib/perl5/Test/FitNesse/Slim.pm", $module, $prefix,
    'symlink alias',
  ),
  abs_path($module),
  'the same physical module is accepted through a symlinked parent path',
);

my $unrelated = "$root/unrelated.pm";
open my $unrelated_fh, '>', $unrelated or die "create unrelated file: $!";
print {$unrelated_fh} "package Other; 1;\n";
close $unrelated_fh or die "close unrelated file: $!";
my $ok = eval {
  verify_installed_path($unrelated, $module, $prefix, 'external module');
  1;
};
ok(!$ok, 'a module loaded from an unrelated location is rejected');
like($@, qr/loaded from unexpected location/, 'external module rejection identifies mismatch');

$ok = eval {
  verify_installed_path($module, "$prefix/lib/perl5/Missing.pm", $prefix, 'missing module');
  1;
};
ok(!$ok, 'a missing expected module is rejected');
like($@, qr/expected file is missing/, 'missing expected module has a distinct diagnostic');

my $sibling_prefix = "$root/prefix-other";
make_path("$sibling_prefix/lib/perl5/Test/FitNesse");
my $sibling_module = "$sibling_prefix/lib/perl5/Test/FitNesse/Slim.pm";
open my $sibling_fh, '>', $sibling_module or die "create sibling-prefix module: $!";
print {$sibling_fh} "package Test::FitNesse::Slim; 1;\n";
close $sibling_fh or die "close sibling-prefix module: $!";
$ok = eval {
  verify_installed_path($sibling_module, $sibling_module, $prefix, 'prefix sibling');
  1;
};
ok(!$ok, 'a lexical prefix sibling is outside the installation prefix');
like($@, qr/expected path is outside installation prefix/, 'prefix sibling is rejected by path components');

done_testing;
