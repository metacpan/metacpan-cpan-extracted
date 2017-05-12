use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Pod::Checker;
my $filepath = "$Bin/../lib/Text/Fuzzy.pod";
my %options;
my $checker = Pod::Checker->new (%options);
open my $out, ">", \my $output or die $!;
$checker->parse_from_file ($filepath, $out);
my @lines = split /\n/, $output;
my $errors = 0;
for my $line (@lines) {
    $line =~ s/\*{3} //;
    $line =~ s/^(.*) at line ([0-9]+) in file (.*)$/$3:$2: $1/;
    $line =~ s/WARNING/warning/g;
    $line =~ s/ERROR/error/g;
    if ($line =~ /line containing nothing but whitespace/) {
	next;
    }
    ok (0, $line);
    $errors++;
}
ok ($errors == 0, "No errors");
done_testing ();
