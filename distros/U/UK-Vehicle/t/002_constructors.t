#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 0.98;
use Test2::Tools::Exception qw/dies lives try_ok/;
use UK::Vehicle;
use Scalar::Util qw(looks_like_number);

my $tool;
my $fake_valid_key = "fortycharactersxofxatozxAtoZxandx0to9xxx";
my $fake_short_key = "fortycharactersxofxatozxAtoZxandx0to9xx";
my $fake_long_key = "fortycharactersxofxatozxAtoZxandx0to9xxxx";
my $fake_invalid_key = "fortycharactersxofxatozxAtoZxandx0to9   ";

# Test bad parameters
like(dies { $tool = UK::Vehicle->new(); }, qr/parameter 'ves_api_key' must be supplied/, "Handled no VES API key 1") or note($@);
like(dies { $tool = UK::Vehicle->new(timeout => 20); }, qr/parameter 'ves_api_key' must be supplied/, "Handled no VES API key 1") or note($@);

# Test that API keys look right
like(dies { $tool = UK::Vehicle->new(ves_api_key => $fake_short_key); }, qr/parameter 'ves_api_key' should be 40 characters long/, "Handled short VES API key") or note($@);
like(dies { $tool = UK::Vehicle->new(ves_api_key => $fake_long_key); }, qr/parameter 'ves_api_key' should be 40 characters long/, "Handled long VES API key") or note($@);
like(dies { $tool = UK::Vehicle->new(ves_api_key => $fake_invalid_key); }, qr/parameter 'ves_api_key' has invalid characters/, "Handled invalid VES API key") or note($@);

# Test timeout looks like a number
like(dies { $tool = UK::Vehicle->new(ves_api_key => $fake_valid_key, timeout => "blah"); }, qr/Timeout value must be a number/, "Handled weird timeout value") or note($@);

# And if it's all valid we should live
ok(lives { $tool = UK::Vehicle->new(ves_api_key => $fake_valid_key); }, "Valid constructor without timeout lives") or note($@);
ok(lives { $tool = UK::Vehicle->new(ves_api_key => $fake_valid_key, timeout => 20); }, "Valid constructor with timeout lives") or note($@);
is($tool->timeout, 20, "Timeout successfully set");

done_testing;
