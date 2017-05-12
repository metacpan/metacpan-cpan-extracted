package WWW::Domain::Registry::Joker::Loggish;

use 5.006;
use strict;
use warnings;

use Log::Dispatch;
use Log::Dispatch::Screen;

our $VERSION = '0.02';

=head1 NAME

WWW::Domain::Registry::Joker::Loggish - a simple logging helper

=head1 SYNOPSIS

  use WWW::Domain::Registry::Joker::Loggish;

  @ISA = qw/WWW::Domain::Registry::Joker::Loggish/;

  $self = WWW::Domain::Registry::Joker::Loggish::new($proto,
  	'debug' => 1);

  $self->debug('Diagnostics for the masses');
  $self->error('Nobody loves me!');

  $self->log('notice', 'Something important is about to happen');
  $self->log('debug', 'Nobody ever bothers to read those...');

=head1 DESCRIPTION

The C<WWW::Domain::Registry::Joker::Loggish> class provides a simple
logging interface, implemented using the C<Log::Dispatch> module.
It is meant to serve as a parent class providing the C<log()>, C<debug()>,
and C<error()> methods so that other classes do not have to worry about
implementing them.

=head1 METHODS

The C<WWW::Domain::Registry::Joker::Loggish> class provides the following
methods:

=over 4

=item * new ( PARAMS )

Create a new C<WWW::Domain::Registry::Joker::Loggish> object with
the specified parameters:

=over 4

=item * debug

A boolean flag for the output of diagnostic messages - should the C<debug()>
method actually display the message passed or simply ignore it.

=item * log

The C<Log::Dispatch> object to use for the output; if not passed,
a new object will be created at first use - see the C<logger()> method
below.

=back

=cut

sub new($ %)
{
	my ($proto, %param) = @_;
	my $class = ref $proto || $proto;
	my $self;

	$self = {
		'debug'		=> 0,
		'log'		=> undef,
		%param,
	};
	bless $self, $class;
	return $self;
}

=item * logger ( [OBJECT] )

Get or set the C<Log::Dispatch> object used for the actual logging.

If no object is specified and no logging object has been set yet, this
method will create a C<Log::Dispatch> object and a C<Log::Dispatch::Screen>
destination set to output to the standard error stream.  If tis does not
suit the needs of the application, it should invoke the C<logger()> method
and pass its own C<Log::Dispatch> handler.  This may also be done at
object creation time by passing the C<log> parameter to the C<new()>
method.

=cut

sub logger($ $)
{
	my ($self, $log) = @_;

	if (defined($log)) {
		if (index(ref($log), '::') == -1 ||
		    !$log->isa('Log::Dispatch')) {
			die("Not a Log::Dispatch object: '".ref($log)."'");
		}
		$self->{'log'} = $log;
	} elsif (!defined($self->{'log'})) {
		$log = new Log::Dispatch();
		$log->add(new Log::Dispatch::Screen('name' => 'STDERR',
		    'min_level' => ($self->{'debug'}? 'debug': 'info')));
		$self->{'log'} = $log;
	}
	return $self->{'log'};
}

=item * log ( LEVEL, MESSAGE )

Log the specified message at the specified level.

This method invokes the C<logger()> method, so that a C<Log::Dispatch>
object will be created automatically at first use if none has been
specified.

=cut

sub log($ $ $)
{
	my ($self, $level, $msg) = @_;

	$self->logger()->log('level' => $level, 'message' => "$msg\n");
}

=item * debug ( MESSAGE )

Log a message with a priority of 'debug' using the C<log()> method.
Note that whether the message will actually be logged or not will
depend on the setting of the C<debug> property at object creation time.

=cut

sub debug($ $)
{
	my ($self, $msg) = @_;

	$self->log('debug', $msg);
}

=item * error ( MESSAGE )

Log a message with a priority of 'error' using the C<log()> method.

=cut

sub error($ $)
{
	my ($self, $msg) = @_;

	$self->log('error', $msg);
}

=back

=head1 SEE ALSO

L<Log::Dispatch>

=head1 BUGS

=over 4

=item *

Maybe there ought to be a way to toggle the display of diagnostic
messages after the object has been created.

=back

=head1 HISTORY

The C<WWW::Domain::Registry::Joker::Loggish> class was written by
Peter Pentchev in 2007.

=head1 AUTHOR

Peter Pentchev, E<lt>roam@ringlet.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Peter Pentchev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
