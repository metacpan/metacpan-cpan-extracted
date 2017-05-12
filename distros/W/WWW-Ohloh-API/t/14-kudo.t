
use strict;
use warnings;

use Test::More tests => 23;    # last test to print

use List::MoreUtils qw/ all /;
require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'http://www.ohloh.net/accounts/1234/kudos.xml', 'kudos.xml', );

$ohloh->stash( 'http://www.ohloh.net/accounts/1234/kudos/sent.xml',
    'kudos_sent.xml', );

my $kudos = $ohloh->get_kudos( id => 1234 );

ok $kudos->isa('WWW::Ohloh::API::Kudos');

my %all  = $kudos->all;
my @sent = $kudos->sent;
my @rcx  = $kudos->received;

is 0 + @{ $all{sent} },     25, '$all{sent}';
is 0 + @{ $all{received} }, 10, '$all{sent}';
is @sent, 25, "sent()";
is @rcx,  10, "received()";

my $k = $sent[0];

is $k->created_at,            '2008-01-17T09:12:18Z', 'created_at';
is $k->sender_account_id,     '1076',                 'sender_account_id';
is $k->sender_account_name,   'AndyArmstrong',        'sender_account_name';
is $k->receiver_account_name, 'brian d foy',          'receiver_account_name';
is $k->receiver_account_id,   '13530',                'receiver_account_id';
is $k->project_id,            '',                     'project_id';
is $k->project_name,          '',                     'project_name';
is $k->contributor_id,        '',                     'contributor_id';
is $k->contributor_name,      '',                     'contributor_name';

is $k->recipient_type, 'account', "recipient()";

$ohloh->stash( undef => 'account.xml' );
$ohloh->stash( undef => 'account.xml' );

my $sender = $k->sender;
my $rx     = $k->receiver;

isa_ok $sender, 'WWW::Ohloh::API::Account', 'sender()';
isa_ok $rx,     'WWW::Ohloh::API::Account', 'receiver()';

is $sender->name, 'Yanick', 'sender name';

like $k->as_xml, qr#^<(kudo)>.*</\1>$#, 'kudo->as_xml';

like $kudos->as_xml, qr# ^ <(kudos)> .* </\1> $ #x, 'kudos->as_xml';

# via an Account

$ohloh->stash( undef => 'account.xml' );
my $account = $ohloh->get_account( id => 10 );

$kudos = $account->kudos;

isa_ok $kudos, 'WWW::Ohloh::API::Kudos';

$ohloh->stash( undef => 'kudos_sent.xml' );
is scalar( $account->sent_kudos ) => 25, 'sent_kudos()';

$ohloh->stash( undef => 'kudos.xml' );
is scalar( $account->received_kudos ) => 10, 'kudos()';



