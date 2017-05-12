#!/usr/bin/env perl

#
# Start this and use https://www.pubnub.com/console/ to send messages to it
#

$|=1;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use WWW::PubNub;

WWW::PubNub->subscribe( demo => my_channel => sub {
  print $_[0]->response->decoded_content."\n";
} );
