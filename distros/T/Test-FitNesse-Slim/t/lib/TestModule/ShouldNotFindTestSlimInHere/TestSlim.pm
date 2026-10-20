package TestModule::ShouldNotFindTestSlimInHere::TestSlim;

sub new { bless {}, shift }

sub return_string { "ERROR: should not find TestSlim here!" }
