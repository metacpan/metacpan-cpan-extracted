# -*- perl -*-

use Test::SMTP qw(plan);

plan tests => 1;

my $LOCAL_PORT = ($ENV{'SMTP_SERVER_PORT'} || 25000) + 2;

my $c1 = Test::SMTP->connect_ko('Passes because can\'t connect to SMTP on 25000', 
                                AutoHello => 1, 
				Host => '127.0.0.1', 
				Port => $LOCAL_PORT);
