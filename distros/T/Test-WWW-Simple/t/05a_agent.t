use Test::More tests=>2;
use Test::WWW::Simple no_agent=>1;

unlike mech->agent(), qr/Windows/, "default agent not IE";
like mech->agent(), qr/Mechanize/, "default agent is Mechanize";

