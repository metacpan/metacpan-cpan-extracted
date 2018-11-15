#!perl

use Test::Most;
use Test::TypeTiny;

use Const::Fast;
use Types::Const -types;
use Types::Standard -types;

subtest 'parameterize empty Const' => sub {

    ok my $type = Const [], 'parameterize';
    is $type->display_name => Const->display_name, 'display_name'

};

subtest 'parameterize ArrayRef[Int] on Const' => sub {

    ok my $type = Const[ArrayRef[Int]], 'parameterize';
    is $type->display_name => "Const[ArrayRef[Int]]", 'display_name';

    const my @empty => ();
    const my @ints  => ( 1 .. 3 );
    const my @strs  => qw/ a b c /;

    should_pass( \@empty, $type );
    should_pass( \@ints, $type );
    should_fail( \@strs, $type );

    my @vals = ( 1 .. 3 );
    should_fail( \@vals, $type );

    is_deeply $type->coerce( \@ints ), \@ints, 'coerce on const';
    should_pass( $type->coerce( \@ints ), $type );

    should_pass( $type->parent->coerce( \@vals ), $type );

    ok my $cvals = $type->coerce( \@vals ), 'coerce';
    should_pass( $cvals, $type );
    is_deeply $cvals, \@vals, 'same values';

    lives_ok { $vals[0]++ } 'original unchanged';
    dies_ok  { $cvals->[0]++ } 'coerced is readonly';

};


subtest 'parameterize HashRef[Int] on Const' => sub {

    ok my $type = Const[HashRef [Int]], 'parameterize';
    is $type->display_name => "Const[HashRef[Int]]", 'display_name';

    const my %empty => ();
    const my %ints  => ( A => 1, B => 2, C => 3 );
    const my %strs  => ( A => 1, B => 'bee', C => 'see' );

    should_pass( \%empty, $type );
    should_pass( \%ints, $type );
    should_fail( \%strs, $type );

    my %vals = ( A => 1, B => 2, C => 3 );
    should_fail( \%vals, $type );

    is_deeply $type->coerce( \%ints ), \%ints, 'coerce on const';
    should_pass( $type->coerce( \%ints ), $type );

    should_pass( $type->parent->coerce( \%vals ), $type );

    ok my $cvals = $type->coerce( \%vals ), 'coerce';
    should_pass( $cvals, $type );
    is_deeply $cvals, \%vals, 'same values';

    lives_ok { $vals{b}++ } 'original unchanged';
    dies_ok  { $cvals->{b}++ } 'coerced is readonly';

};

done_testing;
