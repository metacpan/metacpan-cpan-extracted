#!perl

use Test::Lib;
use Test2::Bundle::Extended;

{
    package C1;

    use base 'Parent';

    # do everything
    use overload::reify;

    use Class::Method::Modifiers;

    before 'operator_add_assign' => sub {
        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::before +=" => $other ];
    };

    around 'operator_add_assign' => sub {
        my $orig = shift;

        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::around 1 +=" => $other ];
        my $result = &$orig;
        push @{ $result->logs}, [ __PACKAGE__ . "::around 2 +=" => $other ];
        return $result;
    };

    after 'operator_add_assign' => sub {
        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::after +=" => $other ];
    };

    before 'operator_subtract_assign' => sub {
        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::before -=" => $other ];
    };

    around 'operator_subtract_assign' => sub {
        my $orig = shift;

        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::around 1 -=" => $other ];
        my $result = &$orig;
        push @{ $self->logs}, [ __PACKAGE__ . "::around 2 -=" => $other ];
        return $result;
    };

    after 'operator_subtract_assign' => sub {
        my ( $self, $other ) = @_;
        push @{ $self->logs}, [ __PACKAGE__ . "::after -=" => $other ];
    };

}

subtest "method" => sub {

    my $c1 = C1->new;

    $c1 += 2;

    is( $c1, 2, 'value' );

    is( $c1->logs, [
            [ "C1::before +=" => 2 ],
            [ "C1::around 1 +=" => 2 ],
            [ "Parent::+=" => 2 ],
            [ "C1::around 2 +=" => 2 ],
            [ "C1::after +=" => 2 ],
        ], "operator" );

    # original method should not have been modified
    $c1->clear_logs;
    $c1->plus_equals( 5 );

    is( $c1, 7, 'value' );
    is( $c1->logs, [
            [ "Parent::+=" => 5 ],
        ], "original (inherited) method is unmodified" );

    # parent class should not be modified
    my $p1 = Parent->new;
    $p1 += 2;

    is( $p1->logs, [
            [ "Parent::+=" => 2 ],
        ], "parent operator untouched" );
};

subtest "method" => sub {

    my $c1 = C1->new;

    $c1 -= 2;

    is( $c1, -2, 'value' );

    is( $c1->logs, [
            [ "C1::before -=" => 2 ],
            [ "C1::around 1 -=" => 2 ],
            [ "Parent::-=" => 2 ],
            [ "C1::around 2 -=" => 2 ],
            [ "C1::after -=" => 2 ],
        ], "operator" );

    # original method should not have been modified
    @{ $c1->logs } = ();
    $c1->minus_equals( 5 );

    is( $c1, -7, 'value' );
    is( $c1->logs, [
            [ "Parent::-=" => 5 ],
        ], "original (inherited) method is unmodified" );

    # parent class should not be modified
    my $p1 = Parent->new;
    $p1 -= 2;

    is( $p1->logs, [
            [ "Parent::-=" => 2 ],
        ], "parent operator untouched" );
};

done_testing;
