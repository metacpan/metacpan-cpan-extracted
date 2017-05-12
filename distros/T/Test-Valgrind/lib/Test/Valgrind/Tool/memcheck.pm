package Test::Valgrind::Tool::memcheck;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Tool::memcheck - Run an analysis through the memcheck tool.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class contains the information required by the session for running the C<memcheck> tool.

=cut

use Scalar::Util ();

use base qw<Test::Valgrind::Tool>;

=head1 METHODS

This class inherits L<Test::Valgrind::Tool>.

=head2 C<requires_version>

    my $required_version = $tvt->requires_version;

This tool requires C<valgrind> C<3.1.0>.

=cut

sub requires_version { '3.1.0' }

=head2 C<new>

    my $tvtm = Test::Valgrind::Tool::memcheck->new(
     callers => $callers,
     %extra_args,
    );

Your usual constructor.

C<$callers> specifies the number of stack frames to inspect for errors : the bigger you set it, the more granular the analysis is.

Other arguments are passed straight to C<< Test::Valgrind::Tool->new >>.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $callers = delete $args{callers};
 $callers = 24 unless $callers;
 die 'Invalid number of callers'
            unless Scalar::Util::looks_like_number($callers) and $callers > 0
                                                             and $callers <= 24;

 my $self = bless $class->Test::Valgrind::Tool::new(%args), $class;

 $self->{callers} = $callers;

 $self;
}

sub new_trainer { shift->new(callers => 24) }

=head2 C<callers>

    my $callers = $tvtm->callers;

Read-only accessor for the C<callers> option.

=cut

sub callers { $_[0]->{callers} }

sub suppressions_tag { 'memcheck-' . $_[1]->version }

=head2 C<parser_class>

    my $parser_class = $tvtm->parser_class($session);

This tool uses a L<Test::Valgrind::Parser::XML::Twig> parser in analysis mode, and a L<Test::Valgrind::Parser::Suppressions::Text> parser in suppressions mode.

=cut

sub parser_class {
 my ($self, $session) = @_;

 my $class = $session->do_suppressions
           ? 'Test::Valgrind::Parser::Suppressions::Text'
           : 'Test::Valgrind::Parser::XML::Twig';

 {
  local $@;
  eval "require $class; 1" or die $@;
 }

 return $class;
}

=head2 C<report_class>

    my $report_class = $tvtm->report_class($session);

This tool emits C<Test::Valgrind::Tool::memcheck::Report> object reports in analysis mode, and C<Test::Valgrind::Report::Suppressions> object reports in suppressions mode.

=cut

sub report_class {
 my ($self, $session) = @_;

 if ($session->do_suppressions) {
  require Test::Valgrind::Parser::Suppressions::Text;
  return 'Test::Valgrind::Report::Suppressions';
 } else {
  return 'Test::Valgrind::Tool::memcheck::Report';
 }
}

sub args {
 my $self = shift;
 my ($sess) = @_;

 my @args = (
  '--tool=memcheck',
  '--leak-check=full',
  '--leak-resolution=high',
  '--show-reachable=yes',
  '--num-callers=' . $self->callers,
  '--error-limit=yes',
 );

 push @args, '--track-origins=yes' if  $sess->version >= '3.4.0'
                                   and not $sess->do_suppressions;

 push @args, $self->SUPER::args(@_);

 return @args;
}

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Tool>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Tool::memcheck

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# End of Test::Valgrind::Tool::memcheck

package Test::Valgrind::Tool::memcheck::Report;

use base qw<Test::Valgrind::Report>;

our $VERSION = '1.19';

my @kinds = qw<
 InvalidFree
 MismatchedFree
 InvalidRead
 InvalidWrite
 InvalidJump
 Overlap
 InvalidMemPool
 UninitCondition
 UninitValue
 SyscallParam
 ClientCheck
 Leak_DefinitelyLost
 Leak_IndirectlyLost
 Leak_PossiblyLost
 Leak_StillReachable
>;
push @kinds, __PACKAGE__->SUPER::kinds();

my %kinds_hashed = map { $_ => 1 } @kinds;

sub kinds      { @kinds }

sub valid_kind { exists $kinds_hashed{$_[1]} }

sub is_leak    { $_[0]->kind =~ /^Leak_/ ? 1 : '' }

my $pad;
BEGIN {
 require Config;
 $pad = 2 * ($Config::Config{ptrsize} || 4);
}

sub dump {
 my ($self) = @_;

 my $data = $self->data;

 my $desc = '';

 for ([ '', 2, 4 ], [ 'aux', 4, 6 ], [ 'orig', 4, 6 ]) {
  my ($prefix, $wind, $sind) = @$_;

  my ($what, $stack) = @{$data}{"${prefix}what", "${prefix}stack"};
  next unless defined $what and defined $stack;

  $_ = ' ' x $_ for $wind, $sind;

  $desc .= "$wind$what\n";
  for (@$stack) {
   my ($ip, $obj, $fn, $dir, $file, $line) = map { (defined) ? $_ : '?' } @$_;
   my $frame;
   if ($fn eq '?' and $obj eq '?') {
    $ip =~ s/^0x//gi;
    my $l = length $ip;
    $frame = '0x' . ($l < $pad ? ('0' x ($pad - $l)) : '') . uc($ip);
   } else {
    $frame = sprintf '%s (%s) [%s:%s]', $fn, $obj, $file, $line;
   }
   $desc .= "$sind$frame\n";
  }
 }

 return $desc;
}

# End of Test::Valgrind::Tool::memcheck::Report

