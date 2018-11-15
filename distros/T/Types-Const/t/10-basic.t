#!perl

use Test::Most;
use Test::TypeTiny;

use Const::Fast;
use Types::Const v0.3.4 -types;
use Types::Standard -types;

subtest 'Const' => sub {

    ok my $type = Const;

    ok_subtype( Ref, $type );

    should_fail( 1, $type);
    should_fail( undef, $type );
    should_fail( my $x = 1, $type, 'Value $x fails type constraint Const' );
    should_fail( \$x, $type, 'Reference \$x fails type constraint Const');

    should_pass( \ 1, $type );
    should_pass( \ 'string', $type );

  TODO: {
      local $TODO = "inlined references are not readonly";

      should_pass( [1], $type );
      should_pass( { a => 1 }, $type );
    }

    const my $re => qr/x/;
  TODO: {
      local $TODO = "Test::TypeTiny::should_pass";
      should_pass($re, $type); # RT 127635
    }
    ok !!$type->check( $re ), 'Reference qr/x/ passes type constraint Const';

    const my @ro => qw/ a b c /;
    should_pass( \@ro, $type);

    ok $type->has_coercion, 'has_coercion';

    like $type->get_message([]),
    qr/ is not readonly$/,
    'get_message';

    my @rw = @ro;
    should_fail( \@rw, $type );

    ok my $cc = $type->coerce( \@rw ), 'coerce';
    dies_ok {
        $cc->[0]++;
    } 'coerced is read-only';

    should_pass( $cc, $type );
    should_fail( \@rw, $type ); # original is unaffected
};

subtest 'Const[ArrayRef]' => sub {

    ok my $type = Const[ArrayRef];

    const my @ro => qw/ a b c /;
    should_pass( \@ro, $type );

    ok $type->has_coercion, 'has_coercion';

    my @rw = @ro;
    should_fail( \@rw, $type );

    ok my $cc = $type->coerce( \@rw ), 'coerce';
    dies_ok {
        $cc->[0]++;
    } 'coerced is read-only';

    should_pass( $cc, $type );
    should_fail( \@rw, $type ); # original is unaffected
};


subtest 'Const[HashRef]' => sub {

    ok my $type = Const[HashRef];

    const my %ro => ( a => 1, b => 2 );
    should_pass( \%ro, $type );

    ok $type->has_coercion, 'has_coercion';

    my %rw = %ro;
    should_fail( \%rw, $type );

    ok my $cc = $type->coerce( \%rw ), 'coerce';
    dies_ok {
        $cc->{a}++;
    } 'coerced is read-only';

    should_pass( $cc, $type );
    should_fail( \%rw, $type ); # original is unaffected
};

done_testing;
