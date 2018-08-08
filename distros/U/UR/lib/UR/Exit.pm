package UR::Exit;

=pod

=head1 NAME

UR::Exit - methods to allow clean application exits.

=head1 SYNOPSIS

  UR::Exit->exit_handler(\&mysub);

  UR::Exit->clean_exit($value);

=head1 DESCRIPTION

This module provides the ability to perform certain operations before
an application exits.

=cut

# set up module
require 5.006_000;
use warnings;
use strict;
require UR;
our $VERSION = "0.47"; # UR $VERSION;
our (@ISA, @EXPORT, @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

use Carp;


=pod

=head1 METHODS

These methods provide exit functionality.

=over 4

=item exit_handler

  UR::Exit->exit_handler(\&mysub);

Specifies that a given subroutine be run when the application exits.
(Unimplimented!)

=cut

sub exit_handler
{
    die "Unimplimented";
}

=pod

=item clean_exit

  UR::Exit->clean_exit($value);

Exit the application, running all registered subroutines.
(Unimplimented!  Just exits the application directly.)

=cut

sub clean_exit
{
    my $class = shift;
    my ($value) = @_;
    $value = 0 unless defined($value);
    exit($value);
}

=pod

=item death

Catch any die or warn calls.  This is a universal place to catch die
and warn if debugging.

=cut

sub death
{
    unless ($ENV{'UR_STACK_DUMP_ON_DIE'}) {
        return;
    }

    # workaround common error
    if ($_[0] =~ /Can.*t upgrade that kind of scalar during global destruction/)
    {
        exit 1;
    }

    if (defined $^S) {
        # $^S is defined when perl is executing (as opposed to interpreting)
        if ($^S) {
            # $^S is true when its executing in an eval, false outside of one
            return;
        }
    } else {
        # interpreter is parsing a module or string eval
        # check the call stack depth for up-stream evals
        # fall back to perls default handler if there is one
        my $call_stack_depth = 0;
        for (1) {
            my @details = caller($call_stack_depth);
            #print Data::Dumper::Dumper(\@details);
            last if scalar(@details) == 0;

            if ($details[1] =~ /\(eval .*\)/) {
                #print "<no carp due to eval string>";
                return;
            }
            elsif ($details[3] eq "(eval)") {
                #print "<no carp due to eval block>";
                return;
            }
            $call_stack_depth++;
            redo;
        }
    }

    if
    (
        $_[0] =~ /\n$/
        and UNIVERSAL::can("UR::Context::Process","is_initialized")
        and defined(UR::Context::Process->is_initialized)
        and (UR::Context::Process->is_initialized == 1)
    )
    {
        # Do normal death if there is a newline at the end, and all other
        # things are sane.
        return;
    }
    else
    {
        # Dump the call stack in other cases.
        # This is a developer error occurring while things are
        # initializing.
        local $Carp::CarpLevel = 1;
        Carp::confess(@_);
    	return;
    }
}

=pod

=item warning

Give more informative warnings.

=cut

sub warning
{

    unless ($ENV{'UR_STACK_DUMP_ON_WARN'}) {
        warn @_;
        return;
    }

    return if $_[0] =~ /Attempt to free unreferenced scalar/;
    return if $_[0] =~ /Use of uninitialized value in exit at/;
    return if $_[0] =~ /Use of uninitialized value in subroutine entry at/;
    return if $_[0] =~ /One or more DATA sections were not processed by Inline/;
    UR::ModuleBase->warning_message(@_);
    if ($_[0] =~ /Deep recursion on subroutine/)
    {
        print STDERR "Forced exit by UR::Exit on deep recursion.\n";
        print STDERR Carp::longmess("Stack tail:");
        exit 1;
    }
    return;
}

#$SIG{__DIE__} = \&death unless ($SIG{__DIE__});
#$SIG{__WARN__} = \&warning unless ($SIG{__WARN__});

sub enable_hooks_for_warn_and_die {
    $SIG{__DIE__} = \&death;
    $SIG{__WARN__} = \&warning;
}

&enable_hooks_for_warn_and_die();


1;
__END__

=pod

=back

=head1 SEE ALSO

UR(3), Carp(3)

=cut

#$Header$

