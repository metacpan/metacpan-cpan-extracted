#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw(catfile);

my $server   = 'landfill.bugzilla.org/bugzilla-3.4-branch';
my $email    = 'bmc@shmoo.com';
my $password = 'pileofcrap';

verify_host($server);

plan tests => 22;
use_ok('WWW::Bugzilla::Search');

my $bz = WWW::Bugzilla::Search->new(
            server   => $server,
            email    => $email,
            password => $password,
            protocol => 'https',
            );
ok($bz, 'new');
isa_ok($bz, 'WWW::Bugzilla::Search');


my %fields = (
    'classification' => ['Unclassified', 'Widgets', 'Mercury'],
    'product' => [          'FoodReplicator', 'LJL Test Product', 'MyOwnBadSelf', 'Sam\'s Widget', "Spider S\x{e9}\x{e7}ret\x{ed}\x{f8}ns", 'WorldControl'],
    'component' => [ 'Comp1', 'Component 1', 'Component 2', 'Digestive Goo', 'EconomicControl', 'PoliticalBackStabbing', 'Salt', 'Salt II', 'SaltSprinkler', 'SpiceDispenser', 'Venom', 'VoiceInterface', 'WeatherControl', 'Web', 'Widget Gears', 'comp2', 'renamed component' ],
    'version' => ['1.0', 'unspecified'],
    'target_milestone' => [ '---', 'M1', 'World 2.0' ],
    'bug_status' => [ 'UNCONFIRMED', 'NEW', 'ASSIGNED', 'REOPENED', 'RESOLVED', 'VERIFIED', 'CLOSED' ],
    'resolution' => [ "FIXED", "INVALID", "WONTFIX", "LATER", "REMIND", "DUPLICATE", "WORKSFORME", "MOVED", '---' ],
    'bug_severity' => [ 'blocker', 'critical', 'major', 'normal', 'minor', 'trivial', 'enhancement' ],
    'priority' => [ "P1", "P2", "P3", "P4", "P5" ],
    'rep_platform' => [ "All", "DEC", "HP", "Macintosh", "PC", "SGI", "Sun", "Other" ],
    'op_sys' => [ 'All', 'Windows 3.1', 'Windows 95', 'Windows 98', 'Windows ME', 'Windows 2000', 'Windows NT', 'Windows XP', 'Windows Server 2003', 'Mac System 7', 'Mac System 7.5', 'Mac System 7.6.1', 'Mac System 8.0', 'Mac System 8.5', 'Mac System 8.6', 'Mac System 9.x', 'Mac OS X 10.0', 'Mac OS X 10.1', 'Mac OS X 10.2', 'Linux', 'BSD/OS', 'FreeBSD', 'NetBSD', 'OpenBSD', 'AIX', 'BeOS', 'HP-UX', 'IRIX', 'Neutrino', 'OpenVMS', 'OS/2', 'OSF/1', 'Solaris', 'SunOS', "M\x{e1}\x{e7}\x{d8}\x{df}", 'Other']
    );
       

foreach my $field (sort keys %fields) {
    is_deeply([$bz->$field()], $fields{$field}, $field);
}

$bz->product('FoodReplicator');
$bz->assigned_to('mybutt@inyourface.com');
$bz->reporter('bmc@shmoo.com');

my %searches = ( 'this was my summary' => [8505], 'this isnt my summary' => [8503, 8504] );
foreach my $text (sort keys %searches) {
    $bz->summary($text);
    my @bugs = $bz->search();
    is(scalar(@bugs), scalar(@{$searches{$text}}), 'search count : ' . $text);
    map(isa_ok($_, 'WWW::Bugzilla'), @bugs);
    my @bug_ids = map($_->bug_number, @bugs);
    is_deeply([@bug_ids], $searches{$text}, 'bug numbers : ' . $text);
}

$bz->reset();
is_deeply({}, $bz->{'search_keys'}, 'reset');


sub verify_host {
    my ($server) = @_;
    use WWW::Mechanize;
    my $mech = WWW::Mechanize->new( autocheck => 0);
    $mech->get("https://$server");
    return if ($mech->res()->is_success);
    plan skip_all => 'Cannot access remote host.  not testing';
    exit;
}
