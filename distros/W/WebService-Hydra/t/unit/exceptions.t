use strict;
use warnings;
use Test::More;
use Module::Load;

my @exceptions_to_test = qw(
    HydraRequestError
    HydraServiceUnreachable
    InvalidLoginChallenge
    InvalidLogoutChallenge
    InvalidLoginRequest
    TokenExchangeFailed
    InvalidIdToken
    InvalidConsentChallenge
    InternalServerError
    InvalidClaims
    InvalidToken
);

# Test that all exception classes can be loaded successfully
for my $exception (@exceptions_to_test) {
    my $full_class = "WebService::Hydra::Exception::$exception";

    use_ok $full_class;

    is($@, '', "Loaded $full_class successfully");

    # Test creating an instance with no additional parameters
    my $instance = $full_class->new();
    ok($instance, "$full_class instance created");

    # Check that required fields like message and category are accessible
    ok($instance->message,  "$full_class has a message");
    ok($instance->category, "$full_class has a category");
}

done_testing();
