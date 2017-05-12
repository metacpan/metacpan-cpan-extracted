# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VoiceXML-Client.t'

#########################
use Test::More tests => 6;
BEGIN { use_ok('VoiceXML::Client') };

#########################



use_ok('VoiceXML::Client::Parser');
use_ok('VoiceXML::Client::Device::Dummy');
use_ok('VoiceXML::Client::Engine::Component::Interpreter::Perl');

my $parser = new VoiceXML::Client::Parser;

my $runtimeInt = VoiceXML::Client::Engine::Component::Interpreter::Perl->runtime();

# here, we're using the parser directly... usually we'd just hand everything
# off the VoiceXML::Client::UserAgent but we want to inspect some internals
# during the test...
my $vxmlDoc = $parser->parse('./t/phpvoicehello.vxml', $runtimeInt);

ok($vxmlDoc, "Document Parsed");

is( scalar @{$vxmlDoc->{'items'}}, '1', 'Number of items found');

my $dummyHandle = new VoiceXML::Client::Device::Dummy;

$vxmlDoc->execute($dummyHandle);

