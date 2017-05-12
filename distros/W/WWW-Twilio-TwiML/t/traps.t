#-*- mode: cperl -*-#
use Test::More tests => 1;
use WWW::Twilio::TwiML;

#########################

{
    my $tw = new WWW::Twilio::TwiML;
    my $resp = $tw->Respose;
    local $SIG{__WARN__} = sub { die $@ };
    eval { $resp->Dial(undef) };
    is( $@, '', "empty arguments" );
}
