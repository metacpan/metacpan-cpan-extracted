package Test::Stub::Generator;
use 5.008005;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use Exporter qw(import);
use Carp qw(croak);
use Class::Monadic;
use Data::Util qw(is_array_ref is_code_ref);

our $VERSION   = "0.02";
our @EXPORT    = qw(make_subroutine make_method);
our @EXPORT_OK = qw(
    make_subroutine_utils
    make_method_utils
    make_repeat_subroutine
    make_repeat_method
);

sub make_subroutine {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 0 );
}

sub make_subroutine_utils {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 0, want_utils => 1 );
}

sub make_repeat_subroutine {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 0, is_repeat => 1 );
}

sub make_method {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 1 );
}

sub make_method_utils {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 1, want_utils => 1 );
}

sub make_repeat_method {
    my (@args)  = @_;
    return _convert_build( [@args], is_object => 1, is_repeat => 1 );
}

sub _convert_build {
    my ($args, %inner_opts) = @_;
    my ($exp_ret_list, $opts) = @$args;
    $exp_ret_list = [$exp_ret_list] unless is_array_ref $exp_ret_list;
    $opts ||= {};
    return _build( $exp_ret_list, { %{ $opts }, %inner_opts } );
}

sub _build {
    my ($exp_ret_list, $opts) = @_;

    my $message    = $opts->{message}    || "[stub] arguments are as You expected";
    my $is_object  = $opts->{is_object}  || 0;
    my $is_repeat  = $opts->{is_repeat}  || 0;
    my $want_utils = $opts->{want_utils} || 0;
    my $call_count = 0;

    my $method = sub {
        my $input = [@_];
        shift @$input if $is_object;
        $call_count++;

        my $element = $is_repeat ? $exp_ret_list->[0] : shift @$exp_ret_list;
        unless ( defined $element ) {
            fail 'expects and return are already empty.';
            return undef;
        }

        my $expects = $element->{expects};
        my $return  = $element->{return};

        cmp_deeply($input, $expects, $message)
            or note explain +{ input => $input, expects => $expects };

        return is_code_ref($return) ? $return->() : $return;
    };

    unless ($want_utils) {
        return $method;
    }

    my $utils = bless( {}, 'Test::Stub::Generator::Util' );
    Class::Monadic->initialize($utils)->add_methods(
        has_next => sub {
            return @$exp_ret_list ? 1 : 0;
        },
        is_repeat => sub {
            return $is_repeat;
        },
        called_count => sub {
            return $call_count;
        },
    );

    return ($method, $utils);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::Stub::Generator - be able to generate stub (submodule and method) having check argument and control return value.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Test::More;
    use Test::Deep;
    use Test::Deep::Matcher;
    use Test::Stub::Generator qw(make_method_utils);

    ###
    # sample package
    ###
    package Some::Class;
    sub new { bless {}, shift };
    sub method;

    ###
    # test code
    ###
    package main;

    my $MEANINGLESS = -1;

    my ($stub_method, $util) = make_method_utils(
    #my $method = make_method(
        [
            # checking argument
            { expects => [ 0, 1 ], return => $MEANINGLESS },
            # control return_values
            { expects => [$MEANINGLESS], return => [ 0, 1 ] },

            # expects supported ignore(Test::Deep) and type(Test::Deep::Matcher)
            { expects => [ignore, 1],  return => $MEANINGLESS },
            { expects => [is_integer], return => $MEANINGLESS },
        ],
        { message => 'method arguments are ok' }
    );

    my $obj = Some::Class->new;
    *Some::Class::method = $stub_method;
    # ( or use Test::Mock::Guard )
    # my $mock_guard = mock_guard( $obj => +{ method => $stub_method } );

    # { expects => [ 0, 1 ], return => xxxx }
    $obj->method( 0, 1 );
    # ok xxxx- method arguments are ok

    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'return values are as You expected' );
    # { expects => xxxx, return => [ 0, 1 ] }
    # ok xxxx- return values are as You expected

    $obj->method( sub{}, 1 );
    # { expects => [ignore, 1], return => xxxx }
    # ok xxxx- method arguments are ok

    $obj->method(1);
    # { expects => [is_integer], return => xxxx }
    # ok xxxx- method arguments are ok

    ok( !$util->has_next, 'empty' );
    is( $util->called_count, 4, 'called_count is 4' );

    done_testing;

=head1 DESCRIPTION

Test::Stub::Generator is library for supports the programmer in wriring test code.

=head1 Functions

=head2 make_subroutine($expects_and_return, $opts)

simulate subroutine (do not receive $self)

=head2 make_method($expects_and_return, $opts)

simulate object method (receive $self)

=head1 Parameters

=head2 $expects_and_return(first arguments)

$expects_and_return required the hash_ref (single or array_ref)

  my $method = make_method(
      { expects => [1], return => 2 }
  );
  my $method = make_method(
    [
      { expects => [1], return => 2 }
      { expects => [2], return => 3 }
    ]
  );

=over

=item expects

automaic checking $method_argument

    $method->(1); # ok xxxx- [stub] arguments are as You expected

=item return

control return_value

    my $return = $method->(1); # $return = 2;

=back

=head2 $opts(second arguments)

  my $method = make_method(
    { expects => [1], return => 2 },
    { message => "arguments are ok", is_repeat => 1 }
  );

=over

=item message

change message

=item is_repeat

repeat mode ( repeating $expects_and_return->{0] )
( can use make_repeat_method / make_repeat_subroutine )

=back

=head1 Utility Method (second return_value method)

  my ($method, $util) = make_subroutine_utils($expects_and_return, $opts)
  my ($method, $util) = make_method_utils($expects_and_return, $opts)

=over

=item $util->called_count

return a number of times that was method called

=item $util->has_next

return a boolean.
if there are still more $expects_and_return_list, then true(1).
if there are not, then false(0).

=item $util->is_repeat

return a value $opt->{is_repeat}

=back

=head1 Setting Sheat

=head2 single value

    # { expects => [ 1 ], return => xxxx }
    $obj->method(1);

    # { expects => xxxx, return => 1 }
    is_deeply( $obj->method($MEANINGLESS), 1, 'single' );

=head2 array value

    # { expects => [ ( 0, 1 ) ], return => xxxx }
    $obj->method( 0, 1 );

    # { expects => xxxx, return => sub{ ( 0, 1 ) } }
    is_deeply( [$obj->method($MEANINGLESS)], [ ( 0, 1 ) ], 'array' );

=head2 hash value

    # { expects => [ a => 1 ], return => xxxx }
    $obj->method(a => 1);

    # { expects => xxxx, return => sub{ a => 1 } }
    is_deeply( [$obj->method($MEANINGLESS)], [ a => 1 ], 'hash' );

=head2 array ref

    # { expects => [ [ 0, 1 ] ], return => xxxx }
    $obj->method( [ 0, 1 ] );

    # { expects => xxxx, return => [ 0, 1 ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, 1 ], 'array_ref' );

=head2 hash ref

    # { expects => [ { a => 1 } ], return => xxxx }
    $obj->method( { a => 1 } );

    # { expects => xxxx, return => { a => 1 } }
    is_deeply( $obj->method($MEANINGLESS), { a => 1 }, 'hash_ref' );

=head2 complex values

    # { expects => [ 0, [ 0, 1 ], { a => 1 } ], return => xxxx }
    $obj->method( 0, [ 0, 1 ], { a => 1 } );

    # { expects => xxxx, return => [ 0, [ 0, 1 ], { a => 1 } ] }
    is_deeply( $obj->method($MEANINGLESS), [ 0, [ 0, 1 ], { a => 1 } ], 'complex' );

=head2 dont check arguments (Test::Deep)

    # { expects => [ignore, 1], return => xxxx }
    $obj->method(sub{},1);

=head2 check argument using type (Test::Deep::Matcher)

    # { expects => [is_integer], return => xxxx }
    $obj->method(1);

    # { expects => [is_string],  return => xxxx }
    $obj->method("AAAA");

=head1 LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyoshi Houchi E<lt>hixi@cpan.orgE<gt>

=cut

