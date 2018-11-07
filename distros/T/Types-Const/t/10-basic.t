#!perl

use Test::Most;

use Const::Fast;
use Types::Const -types;

subtest 'ConstArrayRef' => sub {

    const my @ro => qw/ a b c /;
    ok ConstArrayRef->check( \@ro ), 'check';

    ok ConstArrayRef->has_coercion, 'has_coercion';

    like ConstArrayRef->get_message([]),
    qr/ is not readonly$/,
    'get_message';

    my @rw = @ro;
    ok !ConstArrayRef->check( \@rw ), 'check failed';

    ok my $cc = ConstArrayRef->coerce( \@rw ), 'coerce';
    dies_ok {
        $cc->[0]++;
    } 'coerced is read-only';

    ok ConstArrayRef->check( $cc ), 'check';
    ok !ConstArrayRef->check( \@rw ), 'check failed on original';
};


subtest 'ConstHashRef' => sub {

    const my %ro => ( a => 1, b => 2 );
    ok ConstHashRef->check( \%ro ), 'check';

    ok ConstHashRef->has_coercion, 'has_coercion';

    like ConstHashRef->get_message({}),
    qr/ is not readonly$/,
    'get_message';

    my %rw = %ro;
    ok !ConstHashRef->check( \%rw ), 'check failed';

    ok my $cc = ConstHashRef->coerce( \%rw ), 'coerce';
    dies_ok {
        $cc->{a}++;
    } 'coerced is read-only';

    ok ConstHashRef->check( $cc ), 'check';
    ok !ConstHashRef->check( \%rw ), 'check failed on original';
};


done_testing;
