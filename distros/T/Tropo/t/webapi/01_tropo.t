#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok( 'Tropo' );

my $phone = '+4912345656778';
my $text  = 'hello world';

my $tropo = Tropo->new;
$tropo->call(
  to => $phone,
);
$tropo->say( value => $text );
is $tropo->json, '{"tropo":[{"call":{"to":"+4912345656778"}},{"say":{"value":"hello world"}}]}';

#$tropo->say( 'secret code: 1234' );
#is $tropo->json, '{"tropo":[{"call":[{"to":"+4912345656778"}]},{"say":[{"value":"hello world"},{"value":"secret code: 1234"}]}]}';

done_testing();
