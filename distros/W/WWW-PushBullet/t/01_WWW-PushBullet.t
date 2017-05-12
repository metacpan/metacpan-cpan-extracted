use strict;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../lib/";

use_ok 'WWW::PushBullet';

use WWW::PushBullet;

my @pb_functions = qw{
    contacts
    devices
    push_address
    push_file
    push_link
    push_list
    push_note
    };

my $INVALID_API_KEY = '1234567890';

#
# checks new() function
#
my $pb = WWW::PushBullet->new();
ok(!defined $pb, "WWW::PushBullet->new() => undef");

my $pb2 = WWW::PushBullet->new({apikey => $INVALID_API_KEY});
ok(
    (defined $pb2) && (ref $pb2 eq 'WWW::PushBullet'),
"WWW::PushBullet->new({apikey => '$INVALID_API_KEY'}) => WWW::PushBullet object"
  );

#
# checks api_key() function
#
my $api_key = $pb2->api_key();
ok($api_key eq $INVALID_API_KEY, 'WWW::PushBullet->api_key() => api_key');

my $debug_mode = $pb2->debug_mode(1);
my $debug_str  = $pb2->DEBUG('test');
ok($debug_mode && ($debug_str eq '[DEBUG] test'), 'debug_mode on');

$debug_mode = $pb2->debug_mode(0);
$debug_str  = $pb2->DEBUG('test');
ok(!$debug_mode && !defined $debug_str, 'debug_mode off');

my $version = $pb2->version();
ok(
    defined $version && $version =~ /^\d+.*/,
    'WWW::PushBullet->version() => version'
  );

foreach my $func (@pb_functions)
{
    ok($pb2->can($func), 'WWW::PushBullet->' . $func . '() exists');
}

done_testing(4 + 2 + 1 + scalar @pb_functions);

=head1 AUTHOR

Sebastien Thebert <www-pushbullet@onetool.pm>

=cut
