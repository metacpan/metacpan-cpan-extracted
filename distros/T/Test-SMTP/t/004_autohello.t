# -*- perl -*-

use Test::SMTP;
use Test::More;
use Test::Exception;

plan tests => 2;

throws_ok {
    my $c1 = Test::SMTP->connect_ok('Passes because can\'t connect to SMTP on 25000');
} qr/AutoHello/, 'Dies when AutoHello not passed to connect_ko';

throws_ok {
    my $c1 = Test::SMTP->connect_ok('Passes because can\'t connect to SMTP on 25000', AutoHello => 7);
} qr/AutoHello/, 'Dies when AutoHello not passed to connect_ko';
