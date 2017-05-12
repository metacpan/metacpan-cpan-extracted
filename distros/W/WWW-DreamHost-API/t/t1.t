#!/usr/env perl

# $Id: t1.t 28 2011-03-31 14:05:13Z stro $

use strict;
use warnings;

use WWW::DreamHost::API;

eval 'use Test::More 0.88';

if (my $msg = $@) {
    # Skip all tests because we need Test::More 0.88
    $msg =~ s/\sat\s.*$//sx;
    print '1..0 # SKIP ', $msg, "\n";

} else {
    my $key = '6SHU5P2HLDAYECUM';
    # This account only has access to "list" functions however (and only user-list_users_no_pw, not user-list_users) .. as well as dreamhost_ps-set_size, dreamhost_ps-set_settings, and dreamhost_ps-reboot to ps7093.

    my %extra_params = (
         'announcement_list-list_subscribers' => [
            'domain'   => '',
            'domain' => 'filesforever.com',
            'listname' => 'dumb',
         ],
         'dreamhost_ps-list_settings' => [
            'ps' => 'ps7093',
         ],
         'dreamhost_ps-set_settings' => [
            'ps' => 'ps7093',
         ],
         'dreamhost_ps-list_size_history' => [
            'ps' => 'ps7093',
         ],
         'dreamhost_ps-set_size' => [
            'ps' => 'ps7093',
            'size' => 1024,
         ],
         'dreamhost_ps-list_reboot_history' => [
            'ps' => 'ps7093',
         ],
         'dreamhost_ps-reboot' => [
            'ps' => 'ps7093',
         ],
         'dreamhost_ps-list_usage' => [
            'ps' => 'ps7093',
         ],
    );

    $|=1;

    my $api = WWW::DreamHost::API->new($key);
    is($api->{'__key'}, $key, 'WWW::DreamHost::API->new()');

    my $res = $api->command('api-list_accessible_cmds');

    my $tests = 2;

    if ($res->{'result'} eq 'success') {
        is($res->{'result'}, 'success', 'api-list_accessible_cmds (init)');

        foreach my $cmdref (@{ $res->{'data'} }) {
            my $cmd = $cmdref->{'cmd'};
            $tests++;

            # Check extra parameters to current command
            my @extra;
            if ($extra_params{$cmd}) {
                @extra = @{ $extra_params{$cmd} };
            }

            my $cmdres = $api->command($cmd, @extra);

            if ($cmd eq 'dreamhost_ps-set_size') {
                is($cmdres->{'result'}, 'error', $cmd . ' (error)');
                is($cmdres->{'data'}, 'cant_modify_billing', $cmd . ' (cant_modify_billing)');
                $tests++;
            } else {
                is($cmdres->{'result'}, 'success', $cmd);
            }
        }
    } else {
        SKIP: {
            skip('Cannot get results from api-list_accessible_cmds', 1);
        }
    }

    done_testing($tests);
}