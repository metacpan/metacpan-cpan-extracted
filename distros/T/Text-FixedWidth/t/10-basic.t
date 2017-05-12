use Test::More(tests => 33);
use Test::Warn;
use Text::FixedWidth;
use warnings;

ok(my $fw = new Text::FixedWidth, "new()");
ok($fw->set_attributes(qw(
      fname            undef  %10s
      mi               undef  %1s
      lname            undef  %-10s
      points           0      %04d
   )),                                         "set_attributes()");
is($fw->get_fname, undef,                      "get_fname()");
is($fw->get_points, 0,                         "get_points()");
ok($fw->set_fname('Jay'),                      "set_fname()");
ok($fw->set_mi('W'),                           "set_mi()");
ok($fw->set_lname('Hannah'),                   "set_lname()");
ok($fw->set_points(3),                         "set_points()");
is($fw->get_fname, 'Jay',                      "get_fname()");
is($fw->get_mi, 'W',                           "get_mi()");
is($fw->get_lname, 'Hannah',                   "get_lname()");
is($fw->string, "       JayWHannah    0003",   "string()");
ok($fw->parse(string => "     ChuckWNorris    0017"),   "parse()");
is($fw->get_fname, 'Chuck',                    "get_fname()");
is($fw->get_mi, 'W',                           "get_mi()");
is($fw->get_lname, 'Norris',                   "get_lname()");
is($fw->get_points, '0017',                    "get_points()");
is($fw->string, "     ChuckWNorris    0017",   "string()");

ok($fw->auto_truncate(qw(fname lname)),        "auto_truncate()");
ok($fw->set_fname("f" x 20),                   "set_fname()");
ok($fw->set_lname("l" x 20),                   "set_lname()");
is($fw->get_fname(), "f" x 10,                 "set_fname()");
is($fw->get_lname(), "l" x 10,                 "set_lname()");

warning_like 
    { $fw->set_mi("xxxxx") } 
    { carped => qr/Can't set_mi.* Value must be 1 characters or shorter/ }, 
    "set_mi() too long, throws warning";
is($fw->get_mi(), "W",                         "get_mi()");   # still old value

is($fw->string, "ffffffffffWllllllllll0017",   "string()");

# Suppress spurious warnings when at attribute is explicitly set to undef.
$fw->set_fname(undef);
$fw->string;

# Carp out a warning if the user tries to set auto_truncate() on an attribute that doesn't exit.
warning_like 
    { $fw->auto_truncate("bogus") } 
    { carped => qr/Can't auto_truncate attribute .* does not exist/ }, 
    "auto_truncate('bogus') throws warning";

ok($fw->set_points(""),                        "set a numeric to zero-length string");
warning_like 
    { $fw->string } 
    qr/Text::FixedWidth attribute 'points' contains '' which is not numeric/,
    "string() for '' formatted for numeric throws warning";

ok($fw->set_points(undef),                     "set a numeric to undef");
warning_like 
    { $fw->string } 
    qr/Text::FixedWidth attribute 'points' contains '' which is not numeric/,
    "string() for undef formatted for numeric throws warning";

ok($fw->set_points(undef),                     "set a numeric to undef");
warning_like 
    { $fw->string } 
    qr/Text::FixedWidth attribute 'points' contains '' which is not numeric/,
    "string() for non-numerics formatted for numeric throws warning";



