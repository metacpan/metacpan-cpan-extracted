use strict;
use warnings;
use Pod::Markdown;
use Path::Tiny;

my $markdown = '';
my $parser = Pod::Markdown->new;
$parser->output_string(\$markdown);
$parser->parse_file('lib/Test2/Aggregate.pm');
path('README.md')->spew_utf8($markdown);
