use Test::More tests => 1;
no thanks "Foo'Bar";
is($INC{'Foo/Bar.pm'}, __FILE__);
