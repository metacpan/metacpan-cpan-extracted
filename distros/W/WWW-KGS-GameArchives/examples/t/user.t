use strict;
use warnings;
use URI;
use Test::More tests => 4;

BEGIN {
    use_ok 'WWW::KGS::GameArchives::Result::User';
}

my $user = WWW::KGS::GameArchives::Result::User->new({
    name => 'foo [3k]',
    link => URI->new('http://www.gokgs.com/gameArchives.jsp?user=foo'),
});

is $user->name, 'foo';
is $user->rank, '3k';
is $user->link, 'http://www.gokgs.com/gameArchives.jsp?user=foo';
