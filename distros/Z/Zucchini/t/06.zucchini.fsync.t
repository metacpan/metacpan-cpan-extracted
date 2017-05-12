#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini::Fsync';
}

can_ok(
    'Zucchini::Fsync',
    qw(
        new

        get_config
        set_config

        get_ftp_client
        set_ftp_client

        get_ftp_root
        set_ftp_root

        get_remote_digest
        set_remote_digest

        build_transfer_actions
        do_remote_update
        fetch_remote_digest
        ftp_sync
        local_ftp_wanted
        md5file
        parse_md5file
        prepare_ftp_client
        prepare_ftp_client
    )
);

# evil globals
my ($zucchini_fsync);

# just create a ::Rsync object
$zucchini_fsync = Zucchini::Fsync->new();
isa_ok($zucchini_fsync, q{Zucchini::Fsync});
