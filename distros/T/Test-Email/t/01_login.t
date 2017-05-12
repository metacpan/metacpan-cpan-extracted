#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;
BEGIN { use_ok('Test::POP3') };

#########################

my ($host, $user, $pass) = get_info();

SKIP: {
    skip 'No POP3 settings found', 2 unless $host;

    my $pop3 = Test::POP3->new({
        host    =>  $host,
        user    =>  $user,
        pass    =>  $pass,
    });
    ok($pop3,'new & login');
}

sub get_info {
    return map $ENV{"TEST_POP3_$_"}, map uc, qw(host user pass smtp email);
}

__END__

