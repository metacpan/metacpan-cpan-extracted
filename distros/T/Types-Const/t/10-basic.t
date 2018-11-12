#!perl

use Test::Most;

use Const::Fast;
use Types::Const v0.3.2 -types;
use Types::Standard -types;

subtest 'Const' => sub {

    ok my $type = Const;

    ok !$type->check( 1 ), 'check fails (not a reference)';
    ok !$type->check( undef ), 'check fails (undef)';

    ok !$type->check( my $x = 1 ), 'check fails (not a reference)';
    ok !$type->check( \$x ), 'check fails (not readonly)';
    ok $type->check( \ 1 ), 'check (ref to const)';
    ok $type->check( \ 'string' ), 'check (ref to const)';

    const my $re => qr/x/;
    ok $type->check( $re ), 'check (regex)';

    const my @ro => qw/ a b c /;
    ok $type->check( \@ro ), 'check';

    ok $type->has_coercion, 'has_coercion';

    like $type->get_message([]),
    qr/ is not readonly$/,
    'get_message';

    my @rw = @ro;
    ok !$type->check( \@rw ), 'check failed';

    ok my $cc = $type->coerce( \@rw ), 'coerce';
    dies_ok {
        $cc->[0]++;
    } 'coerced is read-only';

    ok $type->check( $cc ), 'check';
    ok !$type->check( \@rw ), 'check failed on original';
};

subtest 'Const[ArrayRef]' => sub {

    ok my $type = Const[ArrayRef];

    const my @ro => qw/ a b c /;
    ok $type->check( \@ro ), 'check';

    ok $type->has_coercion, 'has_coercion';

    my @rw = @ro;
    ok !$type->check( \@rw ), 'check failed';

    ok my $cc = $type->coerce( \@rw ), 'coerce';
    dies_ok {
        $cc->[0]++;
    } 'coerced is read-only';

    ok $type->check( $cc ), 'check';
    ok !$type->check( \@rw ), 'check failed on original';
};


subtest 'Const[HashRef]' => sub {

    ok my $type = Const[HashRef];

    const my %ro => ( a => 1, b => 2 );
    ok $type->check( \%ro ), 'check';

    ok $type->has_coercion, 'has_coercion';

    my %rw = %ro;
    ok !$type->check( \%rw ), 'check failed';

    ok my $cc = $type->coerce( \%rw ), 'coerce';
    dies_ok {
        $cc->{a}++;
    } 'coerced is read-only';

    ok $type->check( $cc ), 'check';
    ok !$type->check( \%rw ), 'check failed on original';
};

done_testing;
