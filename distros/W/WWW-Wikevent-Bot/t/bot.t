#!/usr/bin/perl

use warnings;
use strict;
use integer;
use utf8;
#use Test::More tests => 2;
use Test::More qw(no_plan);
use Test::Differences;
use Data::Dumper;

BEGIN {
    use_ok('WWW::Wikevent::Bot', ':options');
}

# This function generates random strings of a given length
sub generate_random_string {
    my $length = shift; # the length of 
    my @chars=('a'..'z','A'..'Z','0'..'9','_');
    my $random_string;
    foreach ( 1..$length ) {
        # rand @chars will generate a random 
        # number between 0 and scalar @chars
        $random_string.=$chars[rand @chars];
    }
    return $random_string;
}

my $bot;
close STDERR;  # prevent excess noise in the test output
ok( $bot = WWW::Wikevent::Bot->new(), 'Can create a new bot' );

# Accessors

# name
ok( $bot->name( 'TestBot', 'name: setter' ) );
is( $bot->name(), 'TestBot', 'name: getter' );

# sample
ok( $bot->sample( 'index.html', 'sample: setter' ) );
is( $bot->sample(), 'index.html', 'sample: getter' );

# charset
ok( $bot->charset( 'utf8' ), 'charset: setter' );
is( $bot->charset(), 'utf8', 'charset: getter' );

# encoding
is( $bot->encoding(), 'utf8' );
ok( $bot->encoding( 'latin1' ) );
is( $bot->encoding(), 'latin1' );

# url
ok( $bot->url( 'http://example.com' ), 'url: setter' );
is( $bot->url(), 'http://example.com', 'url: getter' );

# months
is( $bot->months(), 3, 'months: default setting' );
ok( $bot->months( 4 ), 'months: setter' );
is( $bot->months(), 4, 'months: getter' );

# parser
ok( $bot->parser( sub{ return 'hello world' } ), 'parser: setter' );
is( ref $bot->parser(), 'CODE', 'parser: getter' );
is( $bot->parser->( '' ), 'hello world', 'parser: getter' );
is_deeply( scalar $bot->parse( '' ), [ ], 'parser: getter' );


# user_dir
is( $bot->user_dir(), 'User:TestBot', 'user_dir: default value' );
ok( $bot->user_dir( 'User:TestyBot' ), 'user_dir: setter' );
is( $bot->user_dir(), 'User:TestyBot', 'user_dir: getter' );

# user_page
is( $bot->user_page(), 'User:TestBot.wiki', 'user_page: default value' );
ok( $bot->user_page( 'User:TestyBot.wiki' ), 'user_page: setter' );
is( $bot->user_page(), 'User:TestyBot.wiki', 'user_page: getter' );

# shows_page
is( $bot->shows_page(), 'User:TestBot/Shows.wiki', 'shows_page: default value' );
ok( $bot->shows_page( 'User:TestyBot/Events.wiki' ), 'shows_page: setter' );
is( $bot->shows_page(), 'User:TestyBot/Events.wiki', 'shows_page: getter' );

# events
is_deeply( scalar $bot->events(), [], 'events:  is it an empty arrayref?' );
my @events = $bot->events();
is_deeply( \@events, [], 'events:  and does fetching it as an array work?' );

# Methods

# add_event
my $event;
ok( $event = $bot->add_event(), 'add_event: no errors' );
is( ref $event, 'WWW::Wikevent::Event', 'add_event: returns an event object' );
is_deeply( scalar $bot->events(), [ $event ], 
        'add_event: event returns an array ref with the same event inside');

# parse
$bot = WWW::Wikevent::Bot->new();
$bot->parser( sub {
        my ( $bot, $html ) = @_;
        # for this test $html will really be a list of words
        foreach my $word ( split( ' ', $html ) ) {
            my $e = $bot->add_event();
            $e->name( $word );
        }
    });
ok( $bot->parse( 'this is a test' ), 'parse: function runs ok' );
@events = $bot->events();
is( $events[0]->name(), 'This', 'parse: 1st event has the correct name');
is( $events[1]->name(), 'Is',   'parse: 2nd event has the correct name');
is( $events[2]->name(), 'A',    'parse: 3rd event has the correct name');
is( $events[3]->name(), 'Test', 'parse: 4th event has the correct name');


# scrape_sample
# test that charset has the correct effect on read files
$bot->events( [] );  # clear out the events stack to start
$bot->sample( 't/sample.txt' );
ok( $bot->scrape_sample() );
@events = $bot->events();
is( $events[0]->name(), 'This', 'scrape_sample: 1st event has the correct name');
is( $events[1]->name(), 'Is',   'scrape_sample: 2nd event has the correct name');
is( $events[2]->name(), 'A',    'scrape_sample: 3rd event has the correct name');
is( $events[3]->name(), 'Test', 'scrape_sample: 4th event has the correct name');

# find_month_urls
$bot->url( 'http://example.com/%Y/%L/calendar.html' );
my @found_urls = $bot->find_month_urls();
my @lt = localtime( time );
my $year  = $lt[5] + 1900;
my $month = $lt[4] + 1;
for ( my $i = 0; $i < 3 ; $i++ ) {
    my $mon = $month + $i;
    $mon = $mon % 12;
    $year = $year + ( ( $mon / 12 ) );
    is( $found_urls[$i], 'http://example.com/' . $year . '/' . $mon .  '/calendar.html', 
            'Checking found urls.  This test is in a loop thus suspect.' );
}

# test that months does what it's supposed to do
$bot->months( 30 );
@found_urls = $bot->find_month_urls();
for ( my $i = 0; $i < 30 ; $i++ ) {
    my $mon = $month + $i;
    my $y = $year + ( ( $mon - 1 ) / 12 );
    $mon = $mon % 12;
    $mon = 12 if $mon == 0;
    is( $found_urls[$i], 'http://example.com/' . $y . '/' . $mon .  '/calendar.html', 
            'Checking found urls.  This test is in a loop thus suspect.' );
}

# dump
$bot = WWW::Wikevent::Bot->new();
$bot->parser( sub {
        my ( $bot, $html ) = @_;
        # for this test $html will really be a list of words
        foreach my $word ( split( ' ', $html ) ) {
            my $e = $bot->add_event();
            $e->name( $word );
        }
    });
$bot->parse( 'this is a test' );
my $wikitext = q{<event
    name="This"
></event>
<event
    name="Is"
></event>
<event
    name="A"
></event>
<event
    name="Test"
></event>
};
open STDOUT, ">", "t/dump_output.wiki";
ok( $bot->dump(), 'dump: runs without error' );
my $result;
{
    open IN, "t/dump_output.wiki";
    local $/ = undef;
    $result = <IN>;
    close IN;
}
eq_or_diff( $result, $wikitext, 'dump: produces the expected wikitext' );
$bot->name( 'TestBot' );
ok( $bot->dump_to_file(), 'dump_to_file: runs without error' );

# remember & is_new
$event = WWW::Wikevent::Event->new();
$event->name( generate_random_string( 20 ) );
ok( $bot->is_new( $event ), 'is_new: says our event is new' );
ok( $bot->remember( $event ), 'remember: runs without error' );
ok( ! $bot->is_new( $event ), 'is_new: says our event is not new' );

# load_remembered_events
$bot = WWW::Wikevent::Bot->new();
ok( ! $bot->is_new( $event ), 'is_new: a new bot has seen the same event' );

# NOT YET IMPLEMENTED
# TODO create_account

# CANNOT BE TESTED WITHOUT A SERVER
# TODO scrape
# TODO scrape_page
# TODO check_allowed
# TODO upload



