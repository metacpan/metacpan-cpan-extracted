#!perl

BEGIN {
    $ENV{AMW_DEBUG} = 1;
}
use strict;
use warnings;
use Text::Amuse::Compile;
use File::Spec;
use File::Basename qw/fileparse/;
use Text::Amuse::Compile::Utils qw/write_file append_file read_file/;
use Test::More;
use Cwd;

my $xelatex = $ENV{TEST_WITH_LATEX};
if ($xelatex) {
    diag "Using (Xe|Lua)LaTeX for testing";
    plan tests => 40;
}
else {
    plan skip_all => "No TEST_WITH_LATEX env found! skipping tests\n";
    exit;
}

for my $luatex (0..1) {

my $c = Text::Amuse::Compile->new(
                                  pdf => 1,
                                  cleanup => 0,
                                  luatex => $luatex,
                                  report_failure_sub => sub {
                                      my @msg = @_;
                                      diag join(" ", @msg);
                                      die join(" ", @msg) },
                                 );

my $target = File::Spec->catfile('t', 'testfile', 'broken.muse');
my $pdf = $target;
my $tex = $target;
my $status = $target;
$pdf =~ s/muse$/pdf/;
$tex =~ s/muse$/tex/;
$status =~ s/muse$/status/;
my $statusline;

if (-f $pdf) {
    unlink $pdf or die $!;
}
if (-f $tex) {
    unlink $tex or die $!;
}

diag "In " . getcwd();

$c->compile($target);

diag "In " . getcwd();

ok(!$c->has_errors);
ok(-f $pdf);
ok(-f $tex);
$statusline = read_file($status);
like $statusline, qr/^OK /, "Status file reported correctly $statusline";



diag "Overwriting $tex with garbage";

write_file($tex, "\\laskdflasdf\\bye");

my $logged;
$c->logger(sub {
               for (@_) { $logged .= $_ };
           });
eval {
    $c->compile($target);
};
ok($@, "Now the compiler dies with $@");

$statusline = read_file($status);
like $statusline, qr/^FAILED/, "Status file reported correctly: $statusline";

diag "In " . getcwd();

like $logged, qr/Undefined control sequence/, "Logged ok";
if ($luatex) {
    like $logged, qr/lualatex/i, "executable reported (lualatex)";;
}
else {
    like $logged, qr/xelatex/i, "executable reported (xelatex)";
}

ok($c->has_errors);


$c->report_failure_sub(sub {
                           diag "Calling report failure with diag: "
                             . scalar (@_) . " lines";
                           diag join(" ", @_);
                           });

unlink $pdf if -f $pdf;

diag "In " . getcwd();

$c->compile($target);
ok($c->has_errors);

ok((! -f $pdf), "Now we're still alive");

my $log = $target;
$log =~ s/muse$/test/;



if (-f $log) {
    unlink $log or die $!;
}

diag "In " . getcwd();


diag $log;
my $logfile = File::Spec->rel2abs($log);
diag $logfile;

$c->logger(sub {
               append_file($logfile, @_);
           });

my $failure = 0;

$c->report_failure_sub(sub {
                           $failure = 1
                       });

$c->compile($target, "t/lasdf/asd.muse", "t/alkasdf/alsf.text");
ok($c->has_errors);

ok((-f $logfile), "Found $logfile");
ok($failure, "Failure set to 1 via sub");

my @lines = read_file($log);

my ($f_name, $f_path, $f_suffix) = fileparse($target);
my @error = grep { /\Q$f_name\E/ } @lines;
ok(@error >= 1, "Found $f_name in the logs") and diag @error;
chop $f_path;
@error = grep { /\Q$f_path\E/ } @lines;
ok(@error >= 1, "Found $f_path in the logs") and diag @error;

@error = grep { /Undefined control sequence/ } @lines;
ok(@error >= 1, "Found the undefined control sequence errors") and diag @error;

@error = grep { /Cannot chdir into/ } @lines;
ok(@error = 2) and diag @error;

unlink $tex or die $!;
unlink $status or die $!;
ok($c->has_errors, "Errors found");
$c->compile($target);
ok(!$c->has_errors, "No errors found now");
}
