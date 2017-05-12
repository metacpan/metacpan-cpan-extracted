#!perl
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd on %s\n", $^V, $Config{archname};

use Text::ClearSilver;

print "Text::ClearSilver/$Text::ClearSilver::VERSION\n";

my $vars      = do 'benchmark/data/var.pl' or die "cannot load data: $!$@";
my @load_path = qw(benchmark/template);
my $template  = 'index.cs';

$vars->{hdf}{loadpaths} = \@load_path;

#Text::ClearSilver->new->process($template, $vars);

cmpthese -1, {
    'raw' => sub {
        my $tcs = Text::ClearSilver->new();
        $tcs->process($template, $vars, \my $output);
    },
    'utf8::decode' => sub {
        my $tcs = Text::ClearSilver->new();
        $tcs->process($template, $vars, \my $output);
        utf8::decode($output);
    },
    'encoding => "utf8"' => sub {
        my $tcs = Text::ClearSilver->new(encoding => "utf8");
        $tcs->process($template, $vars, \my $output, encoding => "utf8");
    },
};

