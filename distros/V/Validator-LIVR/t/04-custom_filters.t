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

subtest 'list_of, or and aliases pass the same arguments to rules as validate()' => sub {
    my @calls;
    my $validator = Validator::LIVR->new({
        list    => { list_of => ['my_spy', 'my_spy'] },
        any     => { or => [ ['my_spy', { eq => 'nope' }], ['my_spy'] ] },
        aliased => 'my_spied_alias',
        empty   => { list_of => [] },
    });

    $validator->register_rules( 'my_spy' => sub {
        return sub {
            my ( $value, $all_values, $output_ref ) = @_;
            push @calls, [ $value, {%$all_values} ];

            $$output_ref = $value . '!';
            return;
        }
    });
    $validator->register_aliased_rule({ name => 'my_spied_alias', rules => ['my_spy'] });

    my $output = $validator->validate({ list => ['a'], any => 'b', aliased => 'c', empty => [1, 2] });

    is_deeply($output, { list => ['a!!'], any => 'b!', aliased => 'c!', empty => [undef, undef] }, 'Should apply rules');

    # Fields are validated in hash order, so the calls are sorted
    is_deeply([ sort { $a->[0] cmp $b->[0] } @calls ], [
        [ 'a',  { field => 'a' } ],
        [ 'a!', { field => 'a' } ],
        [ 'b',  { field => 'b' } ],
        [ 'b',  { field => 'b' } ],
        [ 'c',  { value => 'c' } ],
    ], 'Should pass the value and all values to each rule' );
};

# The test suite has the other edge cases of these rules
subtest 'Rules edge cases out of the test suite' => sub {
    my $validator = Validator::LIVR->new({ email => 'email', date => 'iso_date' });

    is_deeply(
        $validator->validate({ email => '"q"@b.com', date => '0000-01-31' }),
        { email => '"q"@b.com', date => '0000-01-31' },
        'Should accept a quoted local part and the year 0000'
    );
};

# The local part is up to 64 characters, a domain label up to 63 and the address up to 254
subtest 'Emails near the length limits' => sub {
    my $validator = Validator::LIVR->new({ email => 'email' });
    my $long_domain = join( '', ( 'b' x 63 . '.' ) x 3 );

    my %emails = (
        ( 'a' x 64 ) . '@mail.com'                       => undef,
        ( 'a' x 65 ) . '@mail.com'                       => 'WRONG_EMAIL',
        'a@' . $long_domain . ( 'c' x 56 ) . '.com'      => undef,
        'a@' . $long_domain . ( 'c' x 57 ) . '.com'      => 'WRONG_EMAIL',
        'a-b+c_d.e@mail-1.co'                            => undef,
        'a@-mail.com'                                    => 'WRONG_EMAIL',
        'a@mail-.com'                                    => 'WRONG_EMAIL',
        'a..b@mail.com'                                  => 'WRONG_EMAIL',
    );

    for my $email ( sort keys %emails ) {
        $validator->validate({ email => $email });
        is( $validator->get_errors && $validator->get_errors->{email}, $emails{$email}, length($email) . " characters: $email" );
    }
};


done_testing();