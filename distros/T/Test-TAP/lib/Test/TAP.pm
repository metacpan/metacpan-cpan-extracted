package Test::TAP;

use strict;
use Carp;
use Test::Builder;

use vars '$VERSION';

=head1 NAME

Test::TAP - Test your TAP

=head1 VERSION

Version 0.03

=cut

$VERSION = '0.03';

my $TEST = Test::Builder->new;

sub import {
    my $self   = shift;
    my $caller = caller;

    my @subs = qw/is_passing_tap is_failing_tap/;
    foreach my $sub (@subs) {
        no strict 'refs';
        *{"${caller}::$sub"} = \&{$sub};
    }

    $TEST->exported_to($caller);
    $TEST->plan(@_);
}

=head1 SYNOPSIS

 use Test::TAP;

 is_passing_tap $tap1, 'TAP tests passed';
 is_failing_tap $tap2, 'TAP tests failed';

=head1 EXPORT

=over 4

=item * is_passing_tap

=item * is_failing_tap

=back

=head1 DESCRIPTION

Experimental module to tell if a TAP document is 'passing' or 'failing'.
We'll add more later, but for the time being, this module is for TAP
developers to experiment with.

=head1 TESTS

=head2 C<is_passing_tap>

 is_passing_tap <<'END_TAP', '... TAP tests passed';
 1..1
 ok 1 This test passed
 END_TAP

Test passes if the string passed if the following criteria are met:

=over 4

=item * One plan

You must have one and only one plan.  It may be at the beginning or end of the
TAP, but not embedded.  Plans found in nested TAP are acceptable.

=item * Correct plan.

Number of tests run must match the plan.

=item * No failing tests.

No 'not ok' tests may be found unless they are TODO tests.

=back

=head2 C<is_failing_tap>

 is_failing_tap <<'END_TAP', '... TAP tests passed';
 1..1
 not ok 1 This test passed
 END_TAP

=cut

sub is_passing_tap ($;$) {
    my ( $tap, $test_name ) = @_;
    croak "usage: is_passing_tap(tap,test_name)"
      unless defined $tap;

    if ( my $error = _tap_failed($tap) ) {
        $TEST->ok( 0, $test_name );
        $TEST->diag("TAP failed:\n\n\t$error");
        return;
    }
    else {
        $TEST->ok( 1, $test_name );
        return 1;
    }
}

sub is_failing_tap ($;$) {
    my ( $tap, $test_name ) = @_;
    croak "usage: is_failing_tap(tap,test_name)"
      unless defined $tap;

    if ( my $error = _tap_failed($tap) ) {
        $TEST->ok( 1, $test_name );
        return;
    }
    else {
        $TEST->ok( 0, $test_name );
        return 1;
    }
}

sub _tap_failed {
    my $tap      = shift;
    my $plan_re  = qr/1\.\.(\d+)/;
    my $test_re  = qr/(?:not )?ok/;
    my $failed;
    my $core_tap = '';
    foreach ( split "\n" => $tap ) {
        if (/^not ok/) {    # TODO tests are not failures
            $failed++
              unless m/^ ( [^\\\#]* (?: \\. [^\\\#]* )* )
                 \# \s* TODO \b \s* (.*) $/ix
        }
        $core_tap .= "$_\n" if /^(?:$plan_re|$test_re)/;
    }
    my $plan;
    if ( $core_tap =~ /^$plan_re/ or $core_tap =~ /$plan_re$/ ) {
        $plan = $1;
    }
    return 'No plan found'                     unless defined $plan;
    return "Failed $failed out of $plan tests" if $failed;

    my $plans_found = 0;
    $plans_found++ while $core_tap =~ /^$plan_re/gm;
    return "$plans_found plans found" if $plans_found > 1;

    my $tests = 0;
    $tests++ while $core_tap =~ /^$test_re/gm;
    return "Planned $plan tests and found $tests tests" if $tests != $plan;

    return;
}

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-tap@rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-TAP>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SEE ALSO

C<Test::Simple>, C<TAP::Harness>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

