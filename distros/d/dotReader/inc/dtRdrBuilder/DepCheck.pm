package inc::dtRdrBuilder::DepCheck;

# Copyright (C) 2006, 2007 by Eric Wilhelm and OSoft, Inc.
# License: GPL

# dependency scanning stuff

use warnings;
use strict;
use Carp;

# TODO use Devel::TraceDeps instead, run entire test suite, save results

=head1 ACTIONS

=over

=item check

=cut

sub ACTION_check {
  my $self = shift;
  $self->check_prereq or die;
} # end subroutine ACTION_check definition
########################################################################

=item traceuse

List used modules.

=cut

sub ACTION_traceuse {
  my $self = shift;
  # XXX not my favorite way to do this
  my $err = _get_used();
  my @modules = map({s/,.*//;$_} grep(/,/, split(/\n\s*/, $err)));
  print join("\n", @modules, '');
} # end subroutine ACTION_traceuse definition
########################################################################

sub ACTION_trace {
  my $self = shift;
  my $err = _get_used();
  print $err;
} # end subroutine ACTION_trace definition
########################################################################

=back

=cut

=head2 _get_used

  _get_used();

=cut

sub _get_used {
  # hmm.  Devel::TraceUse vs Module::ScanDeps
  require IPC::Run;
  my ($in, $out, $err);
  my @command = (
    $^X , qw(-d:TraceUse -Ilib -e), 'require("client/app.pl")'
  );
  IPC::Run::run(\@command, \$in, \$out, \$err);
  $out and die;
  return($err);
} # end subroutine _get_used definition
########################################################################

1;
