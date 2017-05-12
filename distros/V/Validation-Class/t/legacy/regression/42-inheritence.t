use Test::More;

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/modules";
}

package main;

use MyVal::Temp;

my $v = MyVal::Temp->new;

ok $v, 'new temp obj';
ok $v->fields->{name},     'temp obj has name';
ok $v->fields->{email},    'temp obj has email';
ok $v->fields->{login},    'temp obj has login';
ok $v->fields->{password}, 'temp obj has password';

# ok $v->mixins->{TMP}, 'temp obj has TMP mixin'; - DEPRECATED
ok $v->proto->mixins->{TMP}, 'temp obj has TMP mixin';

done_testing;
