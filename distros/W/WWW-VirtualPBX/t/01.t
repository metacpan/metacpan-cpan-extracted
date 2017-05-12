use strict;
use warnings;

use Test::More skip_all => 'Requires login credentials';

use WWW::VirtualPBX;

my $t_phone = '';
my $t_ext   = '';
my $t_pass  = '';
my $t_queue = 2;

my $vpbx = WWW::VirtualPBX->new(
    phone     => $t_phone,
    extension => $t_ext,
    password  => $t_pass,
);

$vpbx->queue_logout($t_queue);

$vpbx->queue_login($t_queue);

is $vpbx->queue_status($t_queue), 1;

$vpbx->queue_logout($t_queue);

is $vpbx->queue_status($t_queue), 0;

