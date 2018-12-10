use Sympatic -oo;
use Test::More;

open my $read_fh , '<','t/12_utf_all.t';
open my $write_fh, '>','t/12_utf_all.write.test';

my @tests =
    ( ['read_fh'  => $read_fh  ]
    , ['write_fh' => $write_fh ]
    , [STDOUT => *STDOUT ]
    , [STDIN  => *STDIN  ]
    , [STDERR => *STDERR ] );

plan tests => 0+@tests;

note "check that every fh are open or reopen as UTF-8 one";

map {
    my ($name, $fh ) = @$_;
    my @layers = PerlIO::get_layers $fh;
    ok +(grep /utf8/, @layers) , "$name handles utf8"
        or diag "$name uses those layers: @layers";
} @tests;

unlink 't/12_utf_all.write.test' or die;
done_testing;
