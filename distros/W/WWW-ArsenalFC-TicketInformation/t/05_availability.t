#!perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('WWW::ArsenalFC::TicketInformation::Match::Availability'); }

my $availability = new_ok(
    'WWW::ArsenalFC::TicketInformation::Match::Availability',
    [
        memberships =>
          [ WWW::ArsenalFC::TicketInformation::Match::Availability->RED ],
        type =>
          WWW::ArsenalFC::TicketInformation::Match::Availability->FOR_SALE,
    ]
);

is_deeply( $availability->memberships,
    [ WWW::ArsenalFC::TicketInformation::Match::Availability->RED ] );
is( $availability->type,
    WWW::ArsenalFC::TicketInformation::Match::Availability->FOR_SALE );
