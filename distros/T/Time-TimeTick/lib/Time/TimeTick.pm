package Time::TimeTick;

use 5.006;
use strict;
use warnings;
use Exporter;
use File::Basename;

our @ISA     = qw(Exporter);
our @EXPORT  = qw(timetick);   # Although we override Exporter's import()
our $VERSION = '0.06';

my @Tix;           # Where we keep the time ticks
our %Opt;          # Global option setting interface
my $Epoch = $^T;   # Point from which times are measured

sub import
{
  my $class = shift;
  %Opt = @_;

  eval { require Time::HiRes };
  $Epoch = _current_time() if $Opt{reset_start};

  unless ($Opt{suppress_initial})
  {
    my $prog = basename($0);
    timetick($Opt{initial_tag} || "Timeticker for $prog starting");
  }

  $class->export_to_level(1, @EXPORT);
}


sub unimport
{
  my $class = shift;
  %Opt = @_;
  no warnings 'redefine';
  *timetick = sub { };
  $class->export_to_level(1, @EXPORT);
}


sub timetick
{
  my $tag = pop;
  $Opt{format_tick_tag} and $tag = $Opt{format_tick_tag}->($tag);
  push @Tix, [ _current_time() - $Epoch, $tag ];
}


sub _current_time
{
  exists &Time::HiRes::time ? Time::HiRes::time() : time;
}


sub report
{
  unless ($Opt{suppress_report})
  {
    &{ $Opt{format_report} || \&_format_report }(@Tix);
  }

  @Tix = ();
}


sub _format_report
{
  printf("%7.4f %s\n", @$_) for @_;
}


sub end
{
  unless ($Opt{suppress_final})
  {
    my $prog = basename($0);
    timetick($Opt{final_tag} || "Timeticker for $prog finishing");
  }

  report();
}


END { end() }

1;

__END__

=head1 NAME

Time::TimeTick - Keep a tally of times at different places in your program

=head1 SYNOPSIS

  use Time::TimeTick;
  # Your code...
  timetick("Starting phase three");
  # More of your code...

=head1 DESCRIPTION

C<Time::TimeTick> provides a quick and convenient way of
instrumenting a program to find out how long it took to reach various
points.  Just use the module and call the C<timetick()> function whenever
you want to mark the time at a point in your program.  When the
program ends, a report will be output giving the times at which each
point was reached.

The times will be recorded using C<Time::HiRes::time()> if
C<Time::HiRes> is available, otherwise C<time()> will be used.  (Since
C<time()> has one-second granularity this is unlikely to be useful.)

=head2 DISABLING

To disable the effect of timing with minimal modification to your
program, just change ``use Time::TimeTick ...'' to
``no Time::TimeTick...''.  The C<timetick()> function will contain
no instructions in order to maximize execution speed, and no report
will be triggered.

=head1 CONFIGURATION

You can customize the action of C<Time::TimeTick> via
options passed as key-value pairs in the C<use> statement.
Recognized keys are:

=over 4

=item suppress_initial

If true, do not put an initial entry in the report when the
module is loaded.

=item suppress_final

If true, do not put a final entry in the report when the 
program terminates.

=item initial_tag

If set, replaces the default entry of ``Timeticker for <program> starting''
output initially (only if C<suppress_initial> is not set.)

=item final_tag

If set, replaces the default entry of ``Timeticker for <program> finishing''
output initially (only if C<suppress_final> is not set.)

=item reset_start

If true, report all times relative to the time that C<Time::TimeTick>
was loaded rather than the actual start of the program.

=item format_tick_tag

If set, should be a reference to a subroutine that will take as
input a tag as passed to C<timetick()> and return the actual tag
to be used.  Can be helpful for applying a lengthy transformation
to every tag while keeping the calling code short.

=item format_report

If set, should be a reference to a subroutine that will take as
input a list of time ticks for reporting.  Each list element will be
a reference to an array containing the time and the tag respectively.
The default C<format_report> callback is:

  sub { printf("%7.4f %s\n", @$_) for @_ }

=item suppress_report

If true, do not output a report when C<report()> is called; just
reset the time tick list instead.

=back

=head1 FUNCTIONS

=over 4

=item Time::TimeTick::timetick($tag)

Record the time at this point of the program and label it with
the string C<$tag>.

=item Time::TimeTick::report()

Output a report (unless C<suppress_report> is set) and reset
the time tick list.

=item Time::TimeTick::end()

Add a final time tick (unless C<suppress_final> is set), and output a
report.  Called by default when the program finishes.

=back

=head2 Exports

C<Time::TimeTick::timetick> is exported to the caller.  Note that
C<Time::TimeTick::report> is not exported; if you want to call it
explicitly you will have to qualify the function name with the
package name.

=head1 EXAMPLE

  use Time::TimeTick suppress_initial => 1;
  # ... picture intervening lines of code
  timetick("Phase 2");
  # ... picture more code
  timetick("Phase 3");
  # ... and yet more
  timetick("Phase 4");
  # Some time later, the program ends

Output from C<Time::TimeTick>:

  0.7524 Phase 2
  0.7945 Phase 3
  0.8213 Phase 4
  0.8328 Timeticker for testprog finishing

=head1 AUTHOR

Peter Scott, E<lt>Peter@PSDT.comE<gt>

=head1 SEE ALSO

L<Benchmark::Timer>, L<Time::HiRes>.

=head1 NOTE

This module was originally written in a modified form and published in
the book "Perl Medic" (Addison-Wesley, 2004): C<http://www.perlmedic.com/>.
Readers of that book should note that the user interface is I<different>
from what appeared there.

=head1 COPYRIGHT

Copyright(c) 2004 Peter Scott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
