use strict;
use warnings;
use Test::More;
use Path::Tiny;

unless ( $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Pod::Markdown";
BAIL_OUT("Pod::Markdown required for README.md sync test: $@") if $@;

my $generated = '';
my $parser    = Pod::Markdown->new;
$parser->output_string(\$generated);
$parser->parse_file('lib/Test2/Aggregate.pm');

is(
    path('README.md')->slurp_utf8,
    $generated,
    'README.md is generated from lib/Test2/Aggregate.pm'
);

done_testing;
