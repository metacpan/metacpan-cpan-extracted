#! perl -I. -w
use t::Test::abeltje;

require_ok('V');
{
    my $version = V::get_version('Misleading');
    is($version, 0.42, "Misleading version");
}

{
    my $version = V::get_version('Misleading::GetVersion');
    is($version, 0.42, "Another misleading version");
}

abeltje_done_testing();
