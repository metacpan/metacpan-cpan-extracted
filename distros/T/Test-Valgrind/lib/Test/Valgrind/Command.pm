package Test::Valgrind::Command;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Command - Base class for Test::Valgrind commands.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class is the base for L<Test::Valgrind> commands.

Commands gather information about the target of the analysis.
They should also provide a default setup for generating suppressions.

=cut

use Test::Valgrind::Util;

use base qw<Test::Valgrind::Carp>;

=head1 METHODS

=head2 C<new>

    my $tvc = Test::Valgrind::Command->new(
     command => $command,
     args    => \@args,
    );

Creates a new command object of type C<$command> by requiring and redispatching the method call to the module named C<$command> if it contains C<'::'> or to C<Test::Valgrind::Command::$command> otherwise.
The class represented by C<$command> must inherit this class.

The C<args> key is used to initialize the L</args> accessor.

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my $cmd = delete $args{command};
 if ($class eq __PACKAGE__ and defined $cmd) {
  ($cmd, my $msg) = Test::Valgrind::Util::validate_subclass($cmd);
  $class->_croak($msg) unless defined $cmd;
  return $cmd->new(%args);
 }

 my $args = delete $args{args};
 $class->_croak('Invalid argument list') if $args and ref $args ne 'ARRAY';

 bless {
  args => $args,
 }, $class;
}

=head2 C<new_trainer>

Creates a new command object suitable for generating suppressions.

Defaults to return C<undef>, which skips suppression generation.

=cut

sub new_trainer { }

=head2 C<args>

    my @args = $tvc->args($session);

Returns the list of command-specific arguments that are to be passed to C<valgrind>.

Defaults to return the contents of the C<args> option.

=cut

sub args { @{$_[0]->{args} || []} }

=head2 C<env>

    my $env = $tvc->env($session);

This event is called in scalar context before the command is ran, and the returned value goes out of scope when the analysis ends.
It's useful for e.g. setting up C<%ENV> for the child process by returning an L<Env::Sanctify> object, hence the name.

Defaults to void.

=cut

sub env { }

=head2 C<suppressions_tag>

    my $tag = $tvc->suppressions_tag($session);

Returns a identifier that will be used to pick up the right suppressions for running the command, or C<undef> to indicate that no special suppressions are needed.

This method must be implemented when subclassing.

=cut

sub suppressions_tag;

=head2 C<check_suppressions_file>

    my $supp_ok = $tvc->check_suppressions_file($file);

Returns a boolean indicating whether the suppressions contained in C<$file> are compatible with the command.

Defaults to true.

=cut

sub check_suppressions_file { 1 }

=head2 C<filter>

    my $filtered_report = $tvc->filter($session, $report);

The C<$session> calls this method after receiving a report from the tool and before forwarding it to the action.
You can either return a mangled C<$report> (which does not need to be a clone of the original) or C<undef> if you want the action to ignore it completely.

Defaults to the identity function.

=cut

sub filter { $_[2] }

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Session>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Command

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # Test::Valgrind::Command
