use strict;
use warnings;
use utf8;
use feature qw/say/;

use Benchmark qw/cmpthese timethese/;
use File::Basename;
use File::Spec;
use File::Slurp;

use Text::Diff ();
use Text::Diff::Unified::XS ();

my $data_dir = File::Spec->catfile(dirname(__FILE__), 'data');
my $file_a   = File::Spec->catfile($data_dir, 'alter-7001ae1.c');
my $file_b   = File::Spec->catfile($data_dir, 'alter-5fec257.c');

cmpthese timethese -10 => +{
    PP => sub {
        Text::Diff::diff($file_a, $file_b);
    },
    XS => sub {
        Text::Diff::Unified::XS::diff($file_a, $file_b);
    },
};

