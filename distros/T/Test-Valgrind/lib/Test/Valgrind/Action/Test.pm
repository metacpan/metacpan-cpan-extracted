package Test::Valgrind::Action::Test;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Action::Test - Test that an analysis didn't generate any error report.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This action uses C<Test::Builder> to plan and pass or fail tests according to the reports received.

=cut

use Test::Builder;

use base qw<Test::Valgrind::Action Test::Valgrind::Action::Captor>;

=head1 METHODS

This class inherits L<Test::Valgrind::Action> and L<Test::Valgrind::Action::Captor>.

=head2 C<new>

    my $tvat = Test::Valgrind::Action::Test->new(
     diag        => $diag,
     extra_tests => $extra_tests,
     %extra_args,
    );

Your usual constructor.

When C<$diag> is true, the original output of the command and the error reports are intermixed as diagnostics.

C<$extra_tests> specifies how many extraneous tests you want to plan in addition to the default ones.

Other arguments are passed straight to C<< Test::Valgrind::Action->new >>.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $diag        = delete $args{diag};
 my $extra_tests = delete $args{extra_tests} || 0;

 my $self = bless $class->SUPER::new(%args), $class;

 $self->{diag}        = $diag;
 $self->{extra_tests} = $extra_tests;

 $self;
}

=head2 C<diag>

    my $diag = $tvat->diag;

Read-only accessor for the C<diag> option.

=cut

sub diag { $_[0]->{diag} }

=head2 C<kinds>

    my @kinds = $tvat->kinds;

Returns the list of all the monitored report kinds.

=cut

sub kinds { @{$_[0]->{kinds} || []} }

sub start {
 my ($self, $sess) = @_;

 $self->SUPER::start($sess);

 my @kinds = grep $_ ne 'Diag', $sess->report_class->kinds;
 $self->{kinds}  = \@kinds;
 $self->{status} = 0;

 my $tb = Test::Builder->new;

 $tb->plan(tests => $self->{extra_tests} + scalar @kinds);

 $self->restore_all_fh;

 delete $self->{capture};
 if ($self->diag) {
  require File::Temp;
  $self->{capture}     = File::Temp::tempfile();
  $self->{capture_pos} = 0;
 }

 $self->save_fh(\*STDOUT => '>' => $self->{capture});
 $self->save_fh(\*STDERR => '>' => $self->{capture});

 return;
}

sub abort {
 my ($self, $sess, $msg) = @_;

 $self->restore_all_fh;

 my $tb = Test::Builder->new;
 my $plan = $tb->has_plan;
 if (defined $plan) {
  $tb->BAIL_OUT($msg);
  $self->{status} = 255;
 } else {
  $tb->skip_all($msg);
  $self->{status} = 0;
 }

 return;
}

sub report {
 my ($self, $sess, $report) = @_;

 if ($report->is_diag) {
  my $tb = Test::Builder->new;
  $tb->diag($report->data);
  return;
 }

 $self->SUPER::report($sess, $report);

 $self->{reports}->{$report->kind}->{$report->id} = $report;

 if ($self->diag) {
  my $tb = Test::Builder->new;
  my $fh = $self->{capture};
  seek $fh, $self->{capture_pos}, 0;
  $tb->diag($_) while <$fh>;
  $self->{capture_pos} = tell $fh;
  $tb->diag($report->dump);
 }

 return;
}

sub finish {
 my ($self, $sess) = @_;

 $self->SUPER::finish($sess);

 my $tb = Test::Builder->new;

 $self->restore_all_fh;

 if (my $fh = $self->{capture}) {
  seek $fh, $self->{capture_pos}, 0;
  $tb->diag($_) while <$fh>;
  close $fh or $self->_croak('close(capture[' . fileno($fh) . "]): $!");
  delete @{$self}{qw<capture capture_pos>};
 }

 my $failed = 0;

 for my $kind ($self->kinds) {
  my $reports = $self->{reports}->{$kind} || { };
  my $errors  = keys %$reports;
  $tb->is_num($errors, 0, $kind);
  if ($errors) {
   ++$failed;
   unless ($self->diag) {
    $tb->diag("\n" . $_->dump) for values %$reports;
   }
  }
 }

 $self->{status} = $failed < 255 ? $failed : 254;

 return;
}

sub status {
 my ($self, $sess) = @_;

 $self->SUPER::status($sess);

 $self->{status};
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Action>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Action::Test

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Action::Test
