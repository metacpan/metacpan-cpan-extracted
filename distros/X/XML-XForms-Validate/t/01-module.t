
use Test::More tests => 5;
BEGIN { use_ok('XML::XForms::Validate') };

eval { XML::XForms::Validate->import(qw(validate normalize)) };
ok(!$@, 'imports work');

is(\&validate, \&XML::XForms::Validate::validate, 'correct functions imported');
is(\&normalize, \&XML::XForms::Validate::normalize, 'correct functions imported');

eval { XML::XForms::Validate->import(qw(new)) };
ok($@, '"new" not importable');
