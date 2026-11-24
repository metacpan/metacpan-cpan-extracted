use strict;
use warnings;

use lib 't/lib';

use Data::Dumper ();
use Storable ();
use Test::More;
use VPNDetection;
use VPNDetectionTest::Origin;

# The bot, SSH, SMTP, web, DNS resolver and BitTorrent details' first_seen and
# last_seen are days, read as every other `date` member is: served as given when
# well formed, a retried server_error carrying the status when not.

my $day = '2026-11-22';
my %seen = (first_seen => $day, last_seen => $day);
my $answer = {
    ip => '9.9.9.9', is_vpn => \0,
    (map { ("is_$_" => \1) } qw(bot ssh smtp web dns_resolver bittorrent)),
    bot => { provider => 'google', provider_name => 'Google', agents => ['Googlebot'], categories => ['search'],
        verified => \1, identity => 'Googlebot', verified_by => 'rdns', confidence => 'high', %seen },
    ssh => { port => 22, banner => 'SSH-2.0-OpenSSH_9.6', host_key_fp => 'SHA256:x', session_ok => \1, %seen },
    smtp => { port => 25, banner => '220 mx', session_ok => \1, %seen },
    web => [{
        port => 443, status_code => 200, tls_ok => \1, session_ok => \1, cert_browser_trusted => \1,
        (map { ($_ => 'x') } qw(server location title cert_subject_cn cert_subject_o cert_issuer_dn tls_version)),
        %seen,
    }],
    dns_resolver => { port => 53, rcode => 0, recursion_available => \1, answer_correct => \1, %seen },
    bittorrent => { verified => \1, id_matches_ip => \1, indexer => \0, last_reachable => '', days_seen => 3,
        num_ports => 1, peak_num_ports => 1, clients => ['qBittorrent'], %seen },
};
my @members = (
    (map { my $d = $_; map { [$d, $_] } qw(first_seen last_seen) } qw(bot ssh smtp dns_resolver bittorrent)),
    [web => 0, 'first_seen'], [web => 0, 'last_seen'],
);
is(scalar @members, 12, 'twelve day members');

my $body;
my $origin = VPNDetectionTest::Origin->new(sub { $_[0]->render(json => $body) });

# The outcome of one lookup of an answer whose member at @$path holds $value, and
# how many requests it took, retried once.
sub outcome_of {
    my ($path, $value) = @_;
    $body = Storable::dclone($answer);
    my $node = $body;
    $node = ref $node eq 'ARRAY' ? $node->[$_] : $node->{$_} for @$path[0 .. $#$path - 1];
    $node->{ $path->[-1] } = $value;
    $origin->reset;
    my $client = VPNDetection->new(base_url => $origin->url, retries => 1, cache_size => 0);
    my $result = eval { $client->lookup('9.9.9.9') };
    my $error = $@;
    my $what = $result ? 'read' : ref $error && $error->can('kind') ? $error->kind . ' ' . ($error->status // '') : "$error";
    return ("$what after " . $origin->count, $result);
}

subtest 'a well-formed answer reads, every day as served' => sub {
    my ($outcome, $result) = outcome_of(['bot', 'first_seen'], $day);
    is($outcome, 'read after 1', 'the whole answer reads');
    for my $member (@members) {
        my ($detail, @rest) = @$member;
        my $node = $result->$detail;
        $node = ref $node eq 'ARRAY' ? $node->[$_] : $node->{$_} for @rest;
        is($node, $day, join('.', @$member) . ' is the day as served');
    }
    is($result->bittorrent->{last_reachable}, '', 'bittorrent.last_reachable stays a plain string');
};

subtest 'a day that is not RFC 3339 full-date is a retried server_error' => sub {
    my $arabic = join '', map { chr(0x660 + $_) } 2, 0, 2, 6;
    my $shown = sub { Data::Dumper->new([shift])->Useqq(1)->Terse(1)->Indent(0)->Dump };
    is((outcome_of(['bot', 'first_seen'], $day))[0], 'read after 1', 'the same harness reads the well-formed day first');
    for my $value ('x', 'tomorrow', 'monday', '2026-02-30', '2026-11-31', '2026-13-01', '2026-10-00', '2026-10-5',
        '20261005', '2026-W40-1', '24:00', '2026-10-05T24:00:00Z', '2026-10-05T10:00:00Z', '2026-10-05T10:00:00',
        '2026-10-05+05', '2026-10-05+05:00', "2026-10-05\n", ' 2026-10-05', "$arabic-10-05", '') {
        is((outcome_of(['bot', 'first_seen'], $value))[0], 'server_error 200 after 2',
            'bot.first_seen of ' . $shown->($value) . ': refused and retried');
    }
};

subtest 'each of the twelve refuses a malformed day' => sub {
    for my $member (@members) {
        my $at = join '.', @$member;
        is((outcome_of($member, $day))[0], 'read after 1', "$at of a day: read");
        is((outcome_of($member, 'x'))[0], 'server_error 200 after 2', "$at of 'x': refused and retried");
    }
};

done_testing();
