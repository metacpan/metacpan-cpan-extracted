use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $r = Validation::Class::Simple->new(fields => {visa_number => {creditcard => 1}});

sub should_fail {
    my ($name, @numbers) = @_;
    for (@numbers) {
        $r->params->{$name} = $_;
        ok !$r->validate(), "$_ is an invalid $name param";
    }
}

sub should_pass {
    my ($name, @numbers) = @_;
    for (@numbers) {
        $r->params->{$name} = $_;
        ok $r->validate(), "$_ is a valid $name param";
    }
}

# failures

diag 'validating bad visa numbers';
should_fail visa_number => qw(
    1111111111111111
    0000000000000000
    1234567887654321
);

diag 'now validating visa numbers against mastercard validator';
$r->fields->get('visa_number')->creditcard('mastercard');
should_fail visa_number => qw(
    1111111111111111
    0000000000000000
    1234567887654321
);

# successes

diag 'now validating bad visa numbers which are properly formatted';
$r->fields->get('visa_number')->creditcard(1);
should_pass visa_number => qw(
    4222222222222
    4111111111111111
    4012888888881881
);

diag 'now passing the "visa" argument to the creditcard directive';
$r->fields->get('visa_number')->creditcard('visa');
should_pass visa_number => qw(
    4222222222222
    4111111111111111
    4012888888881881
);

diag 'now using mc numbers and passing the "mastercard" argument to the creditcard directive';
$r->fields->get('visa_number')->creditcard('mastercard');
should_pass visa_number => qw(
    5105105105105100
    5555555555554444
);

diag 'now using mc and visa numbers and passing the ["visa", "mastercard"] argument to the creditcard directive';
$r->fields->get('visa_number')->creditcard(['visa', 'mastercard']);
should_pass visa_number => qw(
    4222222222222
    4111111111111111
    4012888888881881
    5105105105105100
    5555555555554444
);

done_testing;
