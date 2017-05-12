#!perl
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd on %s\n", $^V, $Config{archname};

use Text::ClearSilver;
use ClearSilver;
use Data::ClearSilver::HDF;

print "Text::ClearSilver/$Text::ClearSilver::VERSION\n";

my $vars      = do 'benchmark/data/var.pl' or die "cannot load data: $!$@";
my @load_path = qw(benchmark/template);
my $template  = 'index.cs';

$vars->{hdf}{loadpaths} = \@load_path;

#Text::ClearSilver->new->process($template, $vars);

$SIG{__WARN__} = sub {};

cmpthese -1, {
    'T::CS' => sub {
        my $output;

        my $tcs = Text::ClearSilver->new();
        $tcs->process($template, $vars, \$output);
        undef $output;
    },
    'CS & D::CS::HDF' => sub {
        my $output;

        my $hdf = Data::ClearSilver::HDF->hdf($vars);
        my $cs  = ClearSilver::CS->new($hdf);
        $cs->parseString($template);
        $output = $cs->render();
        undef $output;
    },
};

