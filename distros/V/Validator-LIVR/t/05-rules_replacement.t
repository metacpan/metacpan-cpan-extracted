use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;

use Validator::LIVR;

sub patch_rule {
    my ( $rule_name, $rule_builder ) = @_;

    return sub {
        my $rule_validator = $rule_builder->(@_);
        my @rule_args = @_[ 0 .. $#_ - 1 ]; # without rule_builders

        return sub {
            my $error_code = $rule_validator->(@_);
            return { code => $error_code, rule => { $rule_name => \@rule_args } } if $error_code;
            return;
        };
    };
}

subtest 'Rules replacement: Validate data with registered rules' => sub {
    my $original_rules = Validator::LIVR->get_default_rules();

    Validator::LIVR->register_default_rules(
        map { $_ => patch_rule( $_, $original_rules->{$_} ) } keys %$original_rules
    );

    my $validator = Validator::LIVR->new({
        name  => ['required'],
        phone => { max_length => 10 },
    });

    ok( !$validator->validate({ phone => '123456789123456' }), 'Validation should fail' );

    is_deeply($validator->get_errors(), {
        name => {
            code => 'REQUIRED',
            rule => { required => [] }
        },
        phone => {
            code => 'TOO_LONG',
            rule => { max_length => [10] }
        }
    }, 'Should return detailed errors' );

    Validator::LIVR->register_default_rules(%$original_rules);
};

done_testing();
