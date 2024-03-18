use strict;
use warnings;
use Test::More;
use MyNote;
use UUID ();


UUID::generate_time(my $bin);
ok 1, 'generate';

UUID::unparse_upper($bin,my $str);
ok 1, 'unparse ok';
note "unparse: $str\n";

is length($str), 36, 'length';

like $str, qr{^[-0-9A-F]+$}, 'match';

UUID::clear($bin);
ok 1, 'clear';

UUID::unparse_upper($bin,$str);
ok 1, 'unparse null';
note "unparse: $str\n";
is length($str), 36, 'length null';
is $str, '00000000-0000-0000-0000-000000000000', 'value null';

$bin = 'foo';
$str = 'bar';
UUID::unparse_upper($bin,$str);
ok 1, 'unparse garbage';
note "unparse: $str\n";
is $bin, 'foo', 'not mangled';

is $str, '666F6F00-0000-0000-0000-000000000000', 'questionable';

done_testing;
