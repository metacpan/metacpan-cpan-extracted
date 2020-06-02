#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use File::Spec;
use Text::Amuse::Compile;
use PDF::API2;
use Data::Dumper;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";

if ($ENV{TEST_WITH_LATEX}) {
    plan tests => 112;
}
else {
    plan skip_all => "No TEST_WITH_LATEX set, skipping";
}

foreach my $file (File::Spec->catfile(qw/t manual manual.muse/),
                  File::Spec->catfile(qw/t manual br-in-footnotes.muse/)) {
ok (-f $file, "$file found");

my $output = $file;
my $log = $file;
$output =~ s/muse$/pdf/;
$log =~ s/muse$/log/;
if (-f $output) {
    unlink $output or die "Cannot unlink $output $!";
}
ok (! -f $output);
my $c = Text::Amuse::Compile->new(tex => 1, pdf => 1);
$c->compile($file);
ok(!$c->has_errors, "No errors") or die Dumper($c->errors);
ok (-f $output);
like first_line($log), qr{This is XeTeX};
check_metadata($output);

unlink $output or die "Cannot unlink $output $!";

$c = Text::Amuse::Compile->new(tex => 1, pdf => 1, luatex => 1);
$c->compile($file);
ok(!$c->has_errors, "No errors") or die Dumper($c->errors);
ok (-f $output);
check_metadata($output);

unlink $output or die "Cannot unlink $output $!";
like first_line($log), qr{This is Lua(HB)?TeX};
}

foreach my $luatex (0..1) {
    my $expected = File::Spec->catfile(qw/t manual merged/);
    unlink $expected if -f $expected;
    my @exp = map { $expected . $_ } qw/.pdf .a4.pdf .lt.pdf/;
    foreach my $file (@exp) {
        unlink $file if -f $file;
        ok (! -f $file);
    }
    my $c = Text::Amuse::Compile->new(tex => 1, pdf => 1, a4_pdf => 1, lt_pdf => 1, luatex => $luatex);
    $c->compile({
                 files => [qw/manual br-in-footnotes/],
                 path => File::Spec->catdir(qw/t manual/),
                 name => 'merged',
                 title => "Title is Bla *bla* bla",
                 subtitle => "My [subtitle]",
                 author => 'My á Д {author}',
                 topics => '\-=my= \ **cat**, [another] {cat}',
                });
    foreach my $file (@exp) {
        ok (-f $file, "$file created");
        check_metadata($file, {
                               Title => "Title is Bla *bla* bla",
                               Subject => "My [subtitle]",
                               Author => 'My á Д {author}',
                               Keywords => '\-=my= \ **cat**; [another] {cat}',
                              });
    }
}


sub first_line {
    my $file = shift;
    open (my $fh, '<', $file) or die $!;
    my $first = <$fh>;
    close $fh;
    return $first;
}

sub check_metadata {
    my ($file, $checks) = @_;
    my $pdf = PDF::API2->open($file);
    my %info = $pdf->info;
    foreach my $field (qw/Author Title Subject Keywords Creator Producer/) {
        ok $info{$field}, "Found $field metadata" and diag $info{$field};
    }
    if ($checks) {
        foreach my $k (keys %$checks) {
            is $info{$k}, $checks->{$k};
        }
    }
    $pdf->end;
}
