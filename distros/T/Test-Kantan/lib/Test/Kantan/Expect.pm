package Test::Kantan::Expect;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Moo;

has builder  => ( is => 'rw', required => 1 );
has stuff    => ( is => 'rw', required => 1 );
has inverted => ( is => 'rw', default => sub { 0 } );

no Moo;

use Try::Tiny;

use Test::Kantan::Caller;
use Test::Deep::NoTest ();

sub _ok {
    my ($self, %args) = @_;
    exists($args{value}) or die "Missing value";
    my $value = delete $args{value};

    my $caller_level = exists($args{caller_level}) ?
        delete $args{caller_level} : 1;

    $self->builder->ok(
        caller   => Test::Kantan::Caller->new($caller_level),
        value    => $self->inverted ? !$value : $value,
        %args,
    );
}

sub not {
    my $self = shift;
    Test::Kantan::Expect->new(
        builder  => $self->builder,
        stuff    => $self->stuff,
        inverted => !$self->inverted,
    );
}

sub to_be_defined {
    my $self = shift;

    $self->_ok(
        value  => defined($self->stuff),
    );
}

sub to_be_truthy {
    my ($self) = @_;

    $self->_ok(
        value    => $self->stuff,
    );
}
sub to_be_true { goto \&to_be_truthy }

sub to_be_falsy {
    my ($self) = @_;

    $self->_ok(
        value    => !$self->stuff,
    );
}
sub to_be_false { goto \&to_be_falsy }

sub _to_equal_by_test_deep {
    my ($self, $expected, %args) = @_;

    my ($ok, $stack) = Test::Deep::cmp_details($self->stuff, $expected);
    my $diag = $ok ? '-' : Test::Deep::deep_diag($stack);
    $self->_ok(
        value       => $ok,
        description => $diag,
        %args,
    );
}

sub to_equal {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        $expected,
        caller_level => 2,
    );
}

sub to_be { goto \&to_equal }

sub to_throw {
    my ($self) = @_;

    my $thrown;
    try { $self->stuff->() } catch { $thrown++ };
    $self->_ok(
        value => $thrown,
    );
}

sub to_match {
    my ($self, $re) = @_;

    $self->_ok(
        value => scalar($self->stuff =~ $re),
    );
}

sub to_be_a {
    my ($self, $v) = @_;

    $self->_ok(
        value  => scalar(UNIVERSAL::isa($self->stuff, $v)),
    );
}

sub to_be_an { goto \&to_be_a }

sub to_equal_as_a_bag_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::bag(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_bag_of { goto \&to_equal_as_a_bag_of }

sub to_equal_as_a_set_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::set(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_set_of { goto \&to_equal_as_a_set_of }

sub to_be_a_sub_bag_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::subbagof(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_sub_set_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::subsetof(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_super_bag_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::superbagof(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_super_set_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::supersetof(@{$expected}),
        caller_level => 2,
    );
}

sub to_be_a_sub_hash_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::subhashof($expected),
        caller_level => 2,
    );
}

sub to_be_a_super_hash_of {
    my ($self, $expected) = @_;

    $self->_to_equal_by_test_deep(
        Test::Deep::superhashof($expected),
        caller_level => 2,
    );
}

1;
__END__

=for stopwords truthy falsy coderef

=head1 NAME

Test::Kantan::Expect - Assertion

=head1 SYNOPSIS

  expect($x)->to_be(3);

=head1 METHODS

=over 4

=item C<< expect($x)->to_be_defined() >>

Pass if the value is defined.

=item C<< expect($x)->to_be_truthy() >>

=item C<< expect($x)->to_be_true() >>

Pass if the value is truthy.

=item C<< expect($x)->to_be_falsy() >>

=item C<< expect($x)->to_be_false() >>

Pass if the value is falsy.

=item C<< expect($x)->to_equal($y) >>

=item C<< expect($x)->to_be($y) >>

Pass if the value to equal $y.

=item C<< expect($code : CodeRef)->to_throw() >>

Take the coderef. Pass if the code throws exception.

=item C<< expect($x)->to_match($re : Regexp) >>

Pass if $x matches $re.

=item C<< expect($x)->to_be_a($v : Regexp) >>

=item C<< expect($x)->to_be_an($v : Regexp) >>

Pass if C<< $x->$_isa($v) >> is true.

=item C<< expect($x)->to_equal_as_a_set_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_set_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_sub_set_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_super_set_of($v : ArrayRef) >>

Pass if $x to equal $v but ignores the order of the elements.

=item C<< expect($x)->to_equal_as_a_bag_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_bag_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_sub_bag_of($v : ArrayRef) >>

=item C<< expect($x)->to_be_a_super_bag_of($v : ArrayRef) >>

Pass if $x to equal $v but ignores the order of the elements and it ignores duplicate elements.

=item C<< expect($x)->to_be_a_sub_hash_of($v : HashRef) >>

=item C<< expect($x)->to_be_a_super_hash_of($v : HashRef) >>

Pass if $x is a "super-hash" or "sub-hash" of $v.

=back
