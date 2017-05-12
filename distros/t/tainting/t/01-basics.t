#!perl

use Module::Load;
use Test::More 0.98;
use Test::Exception;

sub use_ {
    my $mod = shift;
    load $mod;
    if (@_) {
        $mod->import(@_);
    } else {
        $mod->import;
    }
}

sub no_ {
    my $mod = shift;
    $mod->unimport;
}

dies_ok  { use_ "tainting"; system "true" }
    "tainting is turned on lexically";
lives_ok { use_ "tainting"; { no_ "tainting"; system "true" } }
    "tainting is turned off lexically";

done_testing;
