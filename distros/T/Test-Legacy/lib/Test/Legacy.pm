=head1 NAME

Test::Legacy - Test.pm workalike that plays well with other Test modules


=head1 SYNOPSIS

  # use Test;
  use Test::Legacy;

  ...leave all else the same...


=head1 DESCRIPTION

Test.pm suffers from the problem of not working well with other Test
modules.  If you have a test written using Test.pm and want to use another
module, Test::Exception for example, you cannot.

Test::Legacy is a reimplementation of Test.pm using Test::Builder.
What this means is Test::Legacy can be used with other Test::Builder
derived modules (such as Test::More, Test::Exception, and most
everything released in the last couple years) in the same test script.

Test::Legacy strives to work as much like Test.pm as possible.  It
allows one to continue to take advantage of additional Test modules
without having to immediately rewrite all your tests to use Test::More.


=head2 Test::Legacy and Test::More

You're often going to be wanting to use Test::Legacy in conjunction
with Test::More.  Because they export a bunch of the same functions
they can get a little annoying to deal with.  Fortunately,
L<Test::Legacy::More> is provided to smooth things out.


=head1 DIFFERENCES

Test::Legacy does have some differences from Test.pm.  Here are the known
ones.  Patches welcome.

=over 4

=item * diagnostics

Because Test::Legacy uses Test::Builder for most of the work, failure 
diagnostics are not the same as Test.pm and are unlikely to ever be.


=item * onfail

Currently the onfail subroutine does not get passed a description of test
failures.  This is slated to be fixed in the future.

=back


=head1 AUTHOR

Michael G Schwern E<lt>schwern@pobox.comE<gt>


=head1 COPYRIGHT

Copyright 2004, 2005 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=head1 NOTES

This is an emulation of Test.pm 1.25.

=head1 SEE ALSO

L<Test>, L<Test::More>, L<Test::Legacy::More>

=cut


package Test::Legacy;

require 5.004_05;

use strict;
use vars qw($VERSION
            @ISA @EXPORT @EXPORT_OK
            $TESTERR $TESTOUT
            $ntest
           );

$VERSION        = '1.2502';


require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(plan ok skip);
@EXPORT_OK = qw($ntest $TESTOUT $TESTERR);


use Carp;


use Test::Builder;
my $TB   = Test::Builder->new;
my $Self = { todo => {}, onfail => sub {} };


tie $TESTOUT, 'Test::Legacy::FH', $TB, 'output', 'todo_output';
tie $TESTERR, 'Test::Legacy::FH', $TB, 'failure_output';

tie $ntest, 'Test::Legacy::ntest', $TB;


sub _print { 
    local($\, $,);   # guard against -l and other things that screw with
                     # print

    print $TESTOUT @_ 
}


sub import {
    my $class = shift;

    my $caller = caller;

    $TB->exported_to($caller);

    $class->export_to_level(1, $class, @_);
}


my %Plan_Keys = map { $_ => 1 } qw(test tests todo onfail);
sub plan {
    my %args = @_;

    croak "Test::plan(%args): odd number of arguments" if @_ & 1;

    if( my @unrecognized = grep !$Plan_Keys{$_}, keys %args ) {
        carp "Test::plan(): skipping unrecognized directive(s) @unrecognized";
    }

    $Self->{todo}   = { map { $_ => 1 } @{$args{todo}} } if $args{todo};
    $Self->{onfail} = $args{onfail}                      if $args{onfail};

    $TB->plan( tests => $args{test} || $args{tests} );

    #### Taken from Test.pm 1.25
    _print "# Running under perl version $] for $^O",
      (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";

    _print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
      if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();

    _print "# MacPerl version $MacPerl::Version\n"
      if defined $MacPerl::Version;

    _print sprintf
      "# Current time local: %s\n# Current time GMT:   %s\n",
      scalar(localtime($^T)), scalar(gmtime($^T));
     ### End

    _print "# Using Test::Legacy version $VERSION\n";
}


END {
    $Self->{onfail}->() if $Self->{onfail} and _is_failing($TB);
}

sub _is_failing {
    my $tb = shift;

    return grep(!$_, $tb->summary) ? 1 : 0;
}

sub _make_faildetail {
    my $tb = shift;

    # package, repetition, result

}


# Taken from Test.pm 1.25
sub _to_value {
    my ($v) = @_;
    return ref $v eq 'CODE' ? $v->() : $v;
}


sub ok ($;$$) {
    my($got, $expected, $diag) = @_;
    ($got, $expected) = map _to_value($_), ($got, $expected);

    my($caller, $file, $line) = caller;

    # local doesn't work with soft refs in 5.5.4.  So we do it manually.
    my $todo;
    {
        no strict 'refs';
        $todo = \${ $caller .'::TODO' };
    }
    my $orig_todo = $$todo;

    if( $Self->{todo}{$TB->current_test + 1} ) {
        $$todo = "set in plan, $file at line $line";
    }

    my $ok = 0;
    if( @_ == 1 ) {
        $ok = $TB->ok(@_)
    }
    elsif( defined $expected && $TB->maybe_regex($expected) ) {
        $ok = $TB->like($got, $expected);
    }
    else {
        $ok = $TB->is_eq($got, $expected);
    }

    $$todo = $orig_todo;

    return $ok;
}


sub skip ($;$$$) {
    my $reason = _to_value(shift);

    if( $reason ) {
        $reason = '' if $reason !~ /\D/;
        return $TB->skip($reason);
    }
    else {
        goto &ok;
    }
}


package Test::Legacy::FH;

sub TIESCALAR {
    my($class, $tb, @methods) = @_;
    bless { tb => $tb, methods => \@methods }, $_[0];
}

sub STORE {
    my($self, $arg) = @_;

    my $tb    = $self->{tb};
    my @meths = @{ $self->{methods} };

    foreach my $meth (@meths) {
        $tb->$meth($arg);
    }

    return $arg;
}

sub FETCH {
    my $self = shift;

    my $tb    = $self->{tb};
    my($meth) = @{ $self->{methods} };

    return $tb->$meth();
}


package Test::Legacy::ntest;

sub TIESCALAR {
    my($class, $tb) = @_;

    bless { tb => $tb }, $class;
}

sub FETCH {
    my $self = shift;

    return $self->{tb}->current_test;
}

sub STORE {
    my($self, $val) = @_;

    return $self->{tb}->current_test($val - 1);
}

1;
