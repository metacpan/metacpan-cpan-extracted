#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;


use_ok('MMM');
use IO::File;

my $config = IO::File->new_tmpfile();
print $config <<EOF;
[default]
EOF

$config->seek(0, 0);

{
    my $mmm = MMM->new(configfile => $config);
    isa_ok($mmm, 'MMM');
    isa_ok($mmm->hostinfo, 'MMM::Host');
    can_ok($mmm,
        qw(
        list_tasks
        get_tasks_by_name
        )
    );
}
{
    my $mmm = MMM->new(configfile => 't/data/mmm.cfg');
    $mmm->_parse_config();
    isa_ok($mmm, 'MMM');
    is(scalar($mmm->list_tasks), 4, "can get queues list");
    SKIP: {
        skip 'API Changes', 2;
    $mmm->select_queues('dest', '/tmp/mirror/plf/ppc/');
    is(scalar($mmm->selected_queues), 1, "can select queues from destination");
    $mmm->select_queues('source', 'plf');
    is(scalar($mmm->selected_queues), 2, "can select queues from source");
    }

}

