#!perl
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd on %s\n", $^V, $Config{archname};

use Text::ClearSilver;
use HTML::Template::Pro;
use MobaSiF::Template;

foreach my $mod(qw(Text::ClearSilver HTML::Template::Pro MobaSiF::Template)) {
    print $mod, "/", $mod->VERSION, "\n";
}

my $vars      = {
    hoge => 1,
    fuga => "fuga",
};
my @load_path = qw(benchmark/template);

$vars->{hdf}{loadpaths} = \@load_path;

my $mst_in  = "benchmark/template/simple.mst";
my $mst_bin = "benchmark/template/simple.mst.out";
MobaSiF::Template::Compiler::compile($mst_in, $mst_bin);

if(0){
    my $tcs = Text::ClearSilver->new();
    print "T::CS\n";
    $tcs->process('simple.cs', $vars);

    print "MobaSiF::T\n";
    print MobaSiF::Template::insert($mst_bin, $vars);
    exit;
}

print "Persistent processes:\n";
my $tcs = Text::ClearSilver->new();
my $ht = HTML::Template::Pro->new(
    filename       => 'simple.ht',
    case_sensitive => 1,
    path           => \@load_path,
);

cmpthese -1, {
    'T::CS' => sub {
        $tcs->process('simple.cs', $vars, \my $output);
        return;
    },
    'MobaSiF::T' => sub {
        MobaSiF::Template::insert($mst_bin, $vars);
        return;
    },
    'H::T::Pro' => sub {
        $ht->param(%{$vars});
        my $output = $ht->output();
        return;
    },
};
