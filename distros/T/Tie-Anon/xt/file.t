use strict;
use warnings;
use Test::More;
use Tie::Anon qw(tiea);
use Test::Requires {
    'Tie::File' => "0"
};
use Tie::File;
use Fcntl 'O_RDONLY';

{
    note("--- synopsis example");
    my $result = "";
    for my $line (@{tiea('Tie::File', "xt/hoge.dat", mode => O_RDONLY)}) {
        $result .= $line;
    }
    is $result, "hogefoobar", "read file OK";
}

done_testing;
