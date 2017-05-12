use Test::More ($] < 5.016) ? (skip_all => 'utf8 support on this perl is broken') : (no_plan);

use utf8;

BEGIN {
    $utf8_key = "ц";
    $nonutf_key = "ц";
    utf8::encode($nonutf_key);
}

BEGIN {
    *{"main::$nonutf_key"} = sub {42};
}

use namespace::clean::xs;

BEGIN {
    *{"main::$utf8_key"} = sub {24};
}

is(!!main->can($utf8_key), 1);
is(!!main->can($nonutf_key), '');

is(main->can($utf8_key)->(), 24);
