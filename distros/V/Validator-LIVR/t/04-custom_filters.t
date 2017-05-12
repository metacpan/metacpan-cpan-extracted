use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

Validator::LIVR->register_default_rules(
    'my_ucfirst' => sub {
        return sub {
            my ( $value, undef, $output_ref ) = @_;
            return if !defined($value) || $value eq '';
            
            $$output_ref = ucfirst($value);
            return;
        }
    },
    'my_lc' => sub {
        return sub {
            my ( $value, undef, $output_ref ) = @_;
            return if !defined($value) || $value eq '';
            
            $$output_ref = lc($value); 
            return;
        }
    },
    'my_trim' => sub {
        return sub {
            my ( $value, undef, $output_ref ) = @_;
            return if !defined($value) || $value eq '';
            
            $$output_ref = $value;
            $$output_ref =~ s/^\s*//;
            $$output_ref =~ s/\s*$//;

            return;
        }
    }, 
);

subtest 'Validate data with registered rules' => sub {
    my $validator = Validator::LIVR->new({
        word1 => ['my_trim', 'my_lc', 'my_ucfirst'],
        word2 => ['my_trim', 'my_lc'],
        word3 => ['my_ucfirst'],
    });

    my $output = $validator->validate({
        word1 => ' wordOne ',
        word2 => ' wordTwo ',
        word3 => 'wordThree ',
    });

    is_deeply($output, {
        word1 => 'Wordone',
        word2 => 'wordtwo',
        word3 => 'WordThree ',
    }, 'Should appluy changes to values' );
};


done_testing();