use strict;
use warnings;
use Test::More;

use Text::AAlib;

my $aa = Text::AAlib->new(
    width  => 100,
    height => 200,
);

my $render_params = {
    bright    => 1,
    contrast  => 1,
    gamma     => 0.5,
    dither    => 1,
    inversion => 1,
};

can_ok $aa, "render";

eval {
    $render_params->{bright} = -1;
    $aa->render(%{$render_params});
};
like $@, qr/parameter is 0\.\.255/, "invalid 'bright' parameter(< 0)";

eval {
    $render_params->{bright} = 256;
    $aa->render(%{$render_params});
};
like $@, qr/parameter is 0\.\.255/, "invalid 'bright' parameter(> 255)";

$render_params->{bright} = 1;
eval {
    $render_params->{contrast} = -1;
    $aa->render(%{$render_params});
};
like $@, qr/parameter is 0\.\.127/, "invalid 'bright' parameter(< 0)";


eval {
    $render_params->{contrast} = 128;
    $aa->render(%{$render_params});
};
like $@, qr/parameter is 0\.\.127/, "invalid 'bright' parameter(> 127)";

done_testing;
