#!/usr/bin/perl
#
# Series of tests for the exim config file used on the exim.org machine
#
use Test::More 'no_plan';

BEGIN {
    use_ok('Test::MTA::Exim4');
}

my $exim_path = "/usr/sbin/exim";
my $exim_conf = "/etc/exim/exim.conf";

my $exim = Test::MTA::Exim4->new( { exim_path => $exim_path, config => $exim_conf } );
ok( $exim, 'Created exim test object' );
$exim->config_ok;

# check the version numbers
cmp_ok( $exim->exim_version, 'ge', '4.69', 'Check version number' );

# build number - no idea why you want this!
cmp_ok( $exim->exim_build, '>=', 1, 'Check build number' );

# check that binary has lsearch cdb mysql lookups
foreach (qw[lsearch cdb mysql]) {
    $exim->has_capability( 'lookup', $_ );
}

# routing - we want accept dnslookup manualroute redirect
foreach (qw[accept dnslookup manualroute redirect]) {
    $exim->has_capability( 'router', $_ );
}

# transports - we want appendfile maildir autoreply pipe smtp
foreach (qw[appendfile maildir autoreply pipe smtp]) {
    $exim->has_capability( 'transport', $_ );
}

# other stuff - we need ipv6 openssl content_scanning
foreach (qw[ipv6 openssl content_scanning]) {
    $exim->has_capability( 'support_for', $_ );
}

# options set
foreach (
    qw[accept_8bitmime bounce_return_body bounce_return_message
    check_rfc2047_length delivery_date_remove dns_csa_use_reverse
    envelope_to_remove extract_addresses_remove_arguments local_from_check
    queue_only_load_latch queue_only_override return_path_remove
    smtp_accept_keepalive smtp_check_spool_space smtp_enforce_sync
    smtp_etrn_serialize split_spool_directory strip_trailing_dot
    syslog_duplication syslog_timestamp tcp_nodelay write_rejectlog]
    ) {
    $exim->option_is_true($_);
}

# options not set
foreach (
    qw[allow_domain_literals allow_mx_to_ip allow_utf8_domains
    deliver_drop_privilege disable_ipv6 drop_cr gnutls_compat_mode
    ignore_fromline_local ldap_start_tls local_sender_retain
    log_timezone message_body_newlines message_logs
    move_frozen_messages mua_wrapper preserve_message_logs
    print_topbitchars prod_requires_admin queue_list_requires_admin
    queue_only queue_run_in_order recipients_max_reject
    smtp_return_error_details strict_acl_vars strip_excess_angle_brackets
    tls_remember_esmtp]
    ) {
    $exim->option_is_false($_);
}

# ------------------------------------------------------------------------
#
# Basic routing
#
# Check that we can do abuse and postmaster at all domains
foreach (qw[tahini.csx.cam.ac.uk exim.org pcre.org bugs.exim.org]) {
    $exim->routes_ok( 'postmaster@' . $_ );
    $exim->routes_ok( 'abuse@' . $_ );
}

#
# Bugs router
#
# will accept mail to existing bug numbers (lowish numbers), rejects
# to non-existing (we assume a big number isnt there yet)
$exim->routes_as_ok(
    '23@bugs.exim.org',
    {   router    => 'bugzilla_comment',
        transport => 'bugzilla_deliver',
        discarded => 0,
        ok        => 1
    }
);
$exim->undeliverable_ok('99999999@bugs.exim.org');

# test the same thing re the older router - will be dropped sometime
$exim->routes_as_ok(
    'bug23@exim.org',
    {   router    => 'bugzilla_comment_old',
        transport => 'bugzilla_deliver',
        discarded => 0,
        ok        => 1
    }
);
$exim->undeliverable_ok('bug99999999@exim.org');

#
# List routers
#
# Checks all the list addresses currently known...
foreach my $list (
    qw[exim-announce    exim-users          mailman         site-maintainers
    exim-cvs         exim-maintainers    exim-users-de   pcre-dev
    exim-dev         exim-mirrors        pcre-svn]
    ) {
    foreach my $suffix ( '', qw[ -admin -bounces -confirm -join -leave -owner -request -subscribe -unsubscribe] ) {
        next
            if ( ( $list eq 'mailman' ) && ( $suffix eq '' ) );    # special exception
        $exim->routes_as_ok(
            "$list$suffix\@exim.org",
            {   router    => 'mailman_router',
                transport => 'mailman_transport',
                discarded => 0,
                ok        => 1
            }
        );
    }
}

# mailman list address gets intercepted off to a user
$exim->routes_as_ok(
    'mailman@exim.org',
    {   router    => 'dnslookup',
        transport => 'remote_smtp',
        discarded => 0,
        ok        => 1
    }
);

#
# Misc routers
#
# userforward unfortunately disappears on verification because there are
# no local users, hence everything gets rerouted, however we can do a
# indirect check by checking a user who has a forward set....
$exim->routes_as_ok(
    'nm4@exim.org',
    {   router    => 'dnslookup',
        transport => 'remote_smtp',
        discarded => 0,
        ok        => 1
    }
);
