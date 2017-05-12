package Test::Magpie::ArgumentMatcher;
{
  $Test::Magpie::ArgumentMatcher::VERSION = '0.11';
}
# ABSTRACT: Various templates to catch arguments

use strict;
use warnings;

use Devel::PartialDump;
use Exporter qw( import );
use MooseX::Types::Moose qw( Str CodeRef );
use Set::Object ();
use Test::Magpie::Util;

use overload '""' => sub { $_[0]->{name} }, fallback => 1;

our @EXPORT_OK = qw(
    anything
    custom_matcher
    hash
    set
    type
);

my $Dumper = Devel::PartialDump->new(pairs => 0);

sub anything {
    return __PACKAGE__->new(
        name => 'anything()',
        matcher => sub { return () },
    );
}

sub custom_matcher (&;) {
    my ($test) = @_;
    return __PACKAGE__->new(
        name => "custom_matcher($test)",
        matcher => sub {
            local $_ = $_[0];
            $test->(@_) ? () : undef
        },
    );
}

sub hash {
    my (%template) = @_;
    return __PACKAGE__->new(
        name => 'hash(' . $Dumper->dump(%template) . ')',
        matcher => sub {
            my %hash = @_;
            for (keys %template) {
                if (my $v = delete $hash{$_}) {
                    return unless Test::Magpie::Util::match($v, $template{$_});
                }
                else {
                    return;
                }
            }
            return %hash;
        },
    );
}

sub set {
    my ($take) = Set::Object->new(@_);
    return __PACKAGE__->new(
        name => 'set(' . $Dumper->dump(@_) . ')',
        matcher => sub {
            return Set::Object->new(@_) == $take ? () : undef;
        },
    );
}

sub type {
    my ($type) = @_;
    return __PACKAGE__->new(
        name => "type($type)",
        matcher => sub {
            my ($arg, @in) = @_;
            $type->check($arg) ? @in : undef
        },
    );
}


sub new {
    my ($class, %args) = @_;
    ### assert: defined $args{name}
    ### assert: defined $args{matcher}
    ### assert: ref( $args{matcher} ) eq 'CODE'

    return bless \%args, $class;
}

sub match {
    my ($self, @input) = @_;
    return $self->{matcher}->(@input);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Magpie::ArgumentMatcher - Various templates to catch arguments

=head1 SYNOPSIS

    use Test::Magpie;
    use Test::Magpie::ArgumentMatcher qw( anything );

    my $mock = mock;
    $mock->push( button => 'red' );

    verify($mock)->push(anything);

=head1 DESCRIPTION

Argument matchers allow you to be more general in your specification to stubs
and verification. An argument matcher is an object that takes all remaining
paremeters of an invocation, consumes 1 or more, and returns the remaining
arguments back. At verification time, a invocation is verified if all arguments
have been consumed by all argument matchers.

An argument matcher may return C<undef> if the argument does not pass
validation.

=head2 Custom argument validators

An argument validator is just a subroutine that is blessed as
C<Test::Magpie::ArgumentMatcher>. You are welcome to subclass this package if
you wish to use a different storage system (like a traditional hash-reference),
though a single sub routine is normally all you will need.

=head2 Default argument matchers

This module provides a set of common argument matchers, and will probably handle
most of your needs. They are all available for import by name.

=head1 METHODS

=head2 match @in

Match an argument matcher against @in, and return a list of parameters still to
be consumed, or undef on validation.

=head1 FUNCTIONS

=head2 anything

Consumes all remaining arguments (even 0) and returns none. This effectively
slurps in any remaining arguments and considers them valid. Note, as this
consumes I<all> arguments, you cannot use further argument validators after this
one. You are, however, welcome to use them before.

=head2 custom_matcher { ...code.... }

Creates a custom argument matcher for you. This argument matcher is assumed to
be the final argument matcher. If this matcher passes (that is, returns a true
value), then it is assumed that all remaining arguments have been matched.

Custom matchers are code references. You can use $_ to reference to the first
argument, but a custom argument matcher may match more than one argument. It is
passed the contents of C<@_> that have not yet been matched, in essence.

=head2 type $type_constraint

Checks that a single value meets a given Moose type constraint. You may want to
consider the use of L<MooseX::Types> here for code clarity.

=head2 hash %match

Does deep comparison on all remaining arguments, and verifies that they meet the
specification in C<%match>. Note that this is for hashes, B<not> hash
references!

=head2 set @values

Compares that all remaining arguments match the set of values in C<@values>.
This allows you to compare objects out of order.

Note: this currently uses real L<Set::Object>s to do the work which means
duplicate arguments B<are ignored>. For example C<1, 1, 2> will match C<1, 2>,
C<1, 2, 2>. This is probably a bug and I will fix it, but for now I'm mostly
waiting for a bug report - sorry!

=for Pod::Coverage new match

=head1 AUTHORS

=over 4

=item *

Oliver Charles <oliver.g.charles@googlemail.com>

=item *

Steven Lee <stevenwh.lee@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
