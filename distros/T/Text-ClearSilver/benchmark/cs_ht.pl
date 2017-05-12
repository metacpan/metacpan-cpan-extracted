#!perl
use strict;
use Benchmark qw(:all);
use Config; printf "Perl/%vd on %s\n", $^V, $Config{archname};

use Text::ClearSilver;
use HTML::Template::Pro;

print "Text::ClearSilver/$Text::ClearSilver::VERSION\n";

my $vars      = {
    hoge => 1,
    fuga => "fuga",
};
my @load_path = qw(benchmark/template);

$vars->{hdf}{loadpaths} = \@load_path;

if(0){
    my $tcs = Text::ClearSilver->new();
    print "T::CS\n";
    $tcs->process('simple.cs', $vars);

    print "H::T::Pro";
    my $ht = HTML::Template::Pro->new(
        filename       => 'simple.ht',
        case_sensitive => 1,
        path           => \@load_path,
    );
    $ht->param(%{$vars});
    print $ht->output();
}

print "Normal processes:\n";
cmpthese -1, {
    'T::CS' => sub {
        my $output;

        my $tcs = Text::ClearSilver->new();
        $tcs->process('simple.cs', $vars, \$output);
        undef $output;
    },
    'H::T::Pro' => sub {
        my $output;

        my $ht = HTML::Template::Pro->new(
            filename       => 'simple.ht',
            case_sensitive => 1,
            path           => \@load_path,
        );
        $ht->param(%{$vars});
        $output = $ht->output();
        undef $output;
    },
};


print "Persistent processes:\n";
my $tcs = Text::ClearSilver->new();
my $ht = HTML::Template::Pro->new(
    filename       => 'simple.ht',
    case_sensitive => 1,
    path           => \@load_path,
);

cmpthese -1, {
    'T::CS' => sub {
        my $output;
        $tcs->process('simple.cs', $vars, \$output);
        return;
    },
    'H::T::Pro' => sub {
        $ht->param(%{$vars});
        my $output = $ht->output();
        return;
    },
};
