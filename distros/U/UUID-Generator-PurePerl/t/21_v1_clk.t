use strict;
use warnings;
use Test::More;

use UUID::Object;
plan skip_all
  => sprintf("Unsupported UUID::Object (%.2f) is installed.",
             $UUID::Object::VERSION)
  if $UUID::Object::VERSION > 0.80;

plan tests => 3;

eval q{ use UUID::Generator::PurePerl; };
die if $@;

eval q{
no warnings 'redefine';

sub UUID::Generator::PurePerl::set_timestamp {
    my $self = shift;
    $self->{mock_ts} = shift;
}

sub UUID::Generator::PurePerl::get_timestamp {
    my $self = shift;
    return $self->{mock_ts} || 0;
}

};
die if $@;

my $g = UUID::Generator::PurePerl->new();

my ($u1, $u2);

# normal
$g->set_timestamp(1000);
$u1 = $g->generate_v1();
$g->set_timestamp(1001);
$u2 = $g->generate_v1();

ok( $u1->clk_seq == $u2->clk_seq, 'timestamp go ahead' );

# backward
$g->set_timestamp(2001);
$u1 = $g->generate_v1();
$g->set_timestamp(2000);
$u2 = $g->generate_v1();

ok( $u1->clk_seq != $u2->clk_seq, 'timestamp backward' );

# same
$g->set_timestamp(3000);
$u1 = $g->generate_v1();
$g->set_timestamp(3000);
$u2 = $g->generate_v1();

ok( $u1->clk_seq != $u2->clk_seq, 'timestamp stop' );

