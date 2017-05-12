#!perl -T
use strict;
use warnings;
use Test::More tests => 5;
use Test::GetVolatileData;
use Test::Deep;
use WWW::Purolator::TrackingInfo;

my $t = WWW::Purolator::TrackingInfo->new;

isa_ok($t, 'WWW::Purolator::TrackingInfo');
can_ok($t, qw/new error track/);

my $key = get_data('http://zoffix.com/CPAN/WWW-Purolator-TrackingInfo.txt')
    || '320698578202';

diag "Testing using key $key\n";
my $info = $t->track($key);

if ( $info ) {
    cmp_deeply(
      $info,
        {
            'pin' => re('\w+'),
            'status' => re('^(in transit|package picked up|shipping label created|attention|delivered)$'),
            'history' => array_each(
                 {
                   'comment' => re('.+'),
                   'location' => re('.+'),
                   'scan_time' => re('\A\d{1,2}:\d{2}:\d{2}\z'),
                   'scan_date' => re('\A\d{4}-\d{2}-\d{2}'),
                 }
            ),
        },
      'Tracking info looks fine',
    );
}
else {
    diag 'Got error tracking: ' . $t->error ? $t->error : '[undefined]';
    BAIL_OUT('Got unexpected error!')
      unless $t->error
      =~ /^Tracking system is currently unavailable|^Network error/;
      
    ok(length $t->error, 'Error got something');
    diag q|Didn't get proper tracking info to do more tests.|;
}

$info = $t->track('INVALID_KEY');
ok( length $t->error, 'Error got something when using invalid key' );

##______
my $key2 = get_data('http://zoffix.com/CPAN/WWW-Purolator-TrackingInfo.txt')
    || '320698578202';

diag "Testing using key $key2\n";
my $info2 = $t->track($key2);

if ( $info2 ) {
    cmp_deeply(
      $info2,
        {
            'pin' => re('\w+'),
            'status' => re('^(in transit|package picked up|shipping label created|attention|delivered)$'),
            'history' => array_each(
                 {
                   'comment' => re('.+'),
                   'location' => re('.+'),
                   'scan_time' => re('\A\d{1,2}:\d{2}:\d{2}\z'),
                   'scan_date' => re('\A\d{4}-\d{2}-\d{2}'),
                 }
            ),
        },
      'Tracking info looks fine',
    );
}
else {
    diag 'Got error tracking: ' . $t->error ? $t->error : '[undefined]';
    BAIL_OUT('Got unexpected error!')
      unless $t->error
      =~ /^Tracking system is currently unavailable|^Network error/;
    ok(length $t->error, 'Error got something');
    diag q|Didn't get proper tracking info to do more tests.|;
}

