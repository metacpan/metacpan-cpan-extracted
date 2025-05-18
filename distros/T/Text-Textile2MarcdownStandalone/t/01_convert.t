use strict;
use Test::More 0.98;
use open qw(:std :utf8);
binmode STDOUT => ':encoding(UTF-8)';

use_ok $_ for qw(
    Text::Textile2MarcdownStandalone
);

my $t2m = Text::Textile2MarcdownStandalone->new();
ok $t2m;

# Set Class Property
my $input_file = "t/files/textile01.txt";
my $output_file = "t/files/output01.md";
is $t2m->input_file($input_file), $input_file;
is $t2m->output_file($output_file), $output_file;
ok $t2m->convert();
unlink $output_file;

# Set Instance Property
$input_file = "t/files/textile02.txt";
$output_file = "t/files/output02.md";
$t2m = Text::Textile2MarcdownStandalone->new(
    input_file  => $input_file,
    output_file => $output_file,
);
is $t2m->input_file, $input_file;
is $t2m->output_file, $output_file;
$t2m->convert();
unlink $output_file;

# STDOUT
my $markdown = Text::Textile2MarcdownStandalone->new(
    input_file  => $input_file
)->convert();
ok $markdown;
note $markdown;

done_testing;
