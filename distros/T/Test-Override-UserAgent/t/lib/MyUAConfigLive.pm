package MyUAConfigLive;

use IO::String;
use Test::Override::UserAgent for => 'configuration';

# Allow live requests
allow_live;

1;
