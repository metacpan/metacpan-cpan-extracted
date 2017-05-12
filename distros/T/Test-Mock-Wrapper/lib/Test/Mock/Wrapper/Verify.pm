package Test::Mock::Wrapper::Verify;
$Test::Mock::Wrapper::Verify::VERSION = '0.18';
use strict;
use warnings;
use Test::Deep;
use Test::More;
use Clone qw(clone);

=head1 NAME

Test::Mock::Wrapped::Verify - Part of the Test::Mock::Wrapper module

=head1 VERSION

version 0.18

=head1 SYNOPIS

    my $verifier = $wrapper->verify('bar');
    
    $verifier->at_least(2)->at_most(5);
    
    $verifier->with(['zomg'])->never;

=head1 DESCRIPTION

Instances of this class are returned by Test::Mock::Wrapper::verify to allow for
flexible, readible call verification with objects mocked by Test::Mock:Wrapper

=head1 METHODS

=cut

sub new {
    my($proto, $method, $calls) = @_;
    $calls ||= [];
    my $class = ref($proto) || $proto;
    return bless({__calls=>$calls, method=>$method}, $class);
}

=head2 getCalls

Returns an array of arrays representing all the calls to the mocked method which
match any criteria added via a "with" call.

=cut

sub getCalls {
    my $self = shift;
    return clone($self->{__calls});
}

=head2 with(['some', 'args', ignore()])

This returns a new verifier object with a call list which has been filtered using the
supplied matcher. See L<Test::Deep> for information about matcher syntax.

=cut

sub with {
    my $self = shift;
    my($matcher) = @_;
    my (@__calls) = grep({eq_deeply($_, $matcher)} @{ $self->{__calls} });
    return bless({__calls=>\@__calls, method=>$self->{method}}, ref($self));
}

=head2 exactly(N)

Assert this method was called exactly N times. This is equivelent to
    
=cut

sub exactly {
    my $self = shift;
    my $times = shift;
    ok(scalar(@{ $self->{__calls} }) == $times, "$self->{method} called ".scalar(@{ $self->{__calls} })." times, wanted exactly $times times");
    return $self;
}

=head2 never

Assert this method was never called. This is syntatic sugar, equivilent to
    
    $verify->exactly(0)

=cut

sub never {
    my $self = shift;
    ok(scalar(@{ $self->{__calls} }) == 0,
       "$self->{method} should never be called but was called ".scalar(@{ $self->{__calls} })." time".(scalar(@{ $self->{__calls} }) > 1 ? "s":'').".");
    return $self;
}

=head2 once

Assert this method was called one time. This is syntatic sugar, equivilent to
    
    $verify->exactly(1)

=cut

sub once {
    my $self = shift;
    ok(scalar(@{ $self->{__calls} }) == 1, "$self->{method} should have been called once, but was called ".scalar(@{ $self->{__calls} })." times.");
    return $self;
}

=head2 at_least(N)

Assert this method was called at least N times.

=cut

sub at_least {
    my $self = shift;
    my $times = shift;
    ok(scalar(@{ $self->{__calls} }) >= $times, "$self->{method} only called ".scalar(@{ $self->{__calls} })." times, wanted at least $times\n");
    return $self;
}

=head2 at_most(N)

Assert this method was called at most N times.

=cut

sub at_most {
    my $self = shift;
    my $times = shift;
    ok(scalar(@{ $self->{__calls} }) <= $times, "$self->{method} called ".scalar(@{ $self->{__calls} })." times, wanted at most $times\n");
    return $self;
}


return 42;

=head1 AUTHOR

  Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Mueller.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
