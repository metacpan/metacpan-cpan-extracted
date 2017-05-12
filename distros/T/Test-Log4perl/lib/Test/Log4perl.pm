package Test::Log4perl;
use base qw(Class::Accessor::Chained);
__PACKAGE__->mk_accessors(qw(category));

use strict;
use warnings;

use Test::Builder;
my $Tester = Test::Builder->new();

use Lingua::EN::Numbers::Ordinate;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Log::Log4perl qw(:levels);

our $VERSION = '0.1001';

=head1 NAME

Test::Log4perl - test log4perl

=head1 SYNOPSIS

  use Test::More tests => 1;

  # setup l4p
  use Log::Log4Perl;
  # do your normal Log::Log4Perl setup here
  use Test::Log4perl;

  # get the loggers
  my $logger  = Log::Log4perl->get_logger("Foo::Bar");
  my $tlogger = Test::Log4perl->get_logger("Foo::Bar");

  # test l4p
  Test::Log4perl->start();

  # declare we're going to log something
  $tlogger->error("This is a test");

  # log that something
  $logger->error("This is a test");

  # test that those things matched
  Test::Log4perl->end("Test that that logs okay");
  
  # we also have a simplified version:
  {
    my $foo = Test::Logger->expect(['foo.bar.quux', warn => qr/hello/ ]);
    # ... do something that should log 'hello'
  }
  # $foo goes out of scope; this triggers the test.  

=head1 DESCRIPTION

This module can be used to test that you're logging the right thing
with Log::Log4perl.  It checks that we get what, and only what, we
expect logged by your code.

The basic process is very simple.  Within your test script you get
one or more loggers from B<Test::Log4perl> with the C<get_logger> method
just like you would with B<Log::Log4perl>.  You're going to use these
loggers to declare what you think the code you're going to test should
be logging.

  # declare a bunch of test loggers
  my $tlogger = Test::Log4perl->get_logger("Foo::Bar");

Then, for each test you want to do you need to start up the module.

  # start the test
  Test::Log4perl->start();

This diverts all subsequent attempts B<Log::Log4perl> makes to log
stuff and records them internally rather than passing them though to
the Log4perl appenders as normal.

You then need to declare with the loggers we created earlier what
we hope Log4perl will be asked to log.  This is the same syntax as
Test::Log4perl uses, except if you want you can use regular expressions:

  $tlogger->debug("fish");
  $tlogger->warn(qr/bar/);

You then need to run your code that you're testing.

  # call some code that hopefully will call the log4perl methods
  # 'debug' with "fish" and 'warn' with something that contains 'bar'
  some_code();

We finally need to tell B<Test::Log4Perl> that we're done and it
should do the comparisons.

  # start the test
  Test::Log4perl->end("test name");

=head2 Methods

=over

=item get_logger($category)

Returns a new instance of Test::Logger that can be used to log
expected messages in the category passed.

=cut

sub get_logger
{
  my $class = shift;
  my $self = bless {}, $class;
  $self->category(shift);
  return $self;
}

=item Test::Logger->expect(['dotted.path', 'warn' => qr'this', 'warn' => qr'that'], ..)

Class convenience method. Used like this:

  { # start local scope
    my $foo = Test::Logger->expect(['foo.bar.quux', warn => qr/hello/ ]);
    # ... do something that should log 'hello'
  } # $foo goes out of scope; this triggers the test.

=cut

sub expect {
  my ($class, @expects) = @_;
  my @loggers;
  $class->start(ignore_priority => "info");
  for (@expects) {
      my $name = shift @$_;
      my $tlogger = $class->get_logger($name);
      # XXX: respect current loglevel
      while (my ($level, $what) = splice(@$_, 0, 2)) {
          $tlogger->$level($what);
      }
      push @loggers, $tlogger;
  }
  return \@loggers;
}


=item start

Class method.  Start logging.  When you call this method it temporarly
redirects all logging from the standard logging locations to the
internal logging routine until end is called.  Takes parameters to
change the behavior of this (and only this) test.  See below.

=cut

# convet a string priority into a digit one
sub _to_d($)
{
  my $priority = shift;

  # check the priority is all digits
  if ($priority =~ /\D/)
  {
    if    (lc($priority) eq "everything") { $priority = $OFF }
    elsif (lc($priority) eq "nothing")    { $priority = $ALL }
    else  { $priority = Log::Log4perl::Level::to_priority(uc $priority) }
  }

  return $priority;
}

# the list of things we've stored so far
our @expected;
our @logged;

sub start
{
  my $class = shift;
  my %args = @_;

  # empty the record
  @logged = ();
  @expected = ();
  $class->interception_class->reset_temp;

  # the priority
  if ($args{ignore_everything})
    { $args{ignore_priority} = "everything" }
  if ($args{ignore_nothing})
    { $args{ignore_priority} = "nothing" }
  if (exists $args{ignore_priority})
    { $class->interception_class->set_temp("ignore_priority",_to_d $args{ignore_priority}) }

  # turn on the interception code
   foreach (values %$Log::Log4perl::Logger::LOGGERS_BY_NAME)
    { bless $_, $class->interception_class }
}

=item debug(@what)

=item info(@what)

=item warn(@what)

=item error(@what)

=item fatal(@what)

Instance methods.  String of things that you're expecting to log, at
the level you're expecting them, in what class.

=cut

sub _log_at_level
{
  my $self     = shift;
  my $priority = shift;
  my $message  = shift;

  push @expected, {
    category => $self->category,
    priority => $priority,
    message  => $message,
  };
}

foreach my $level (qw(debug info warn error fatal))
{
  no strict 'refs';
  *{$level} = sub {
   my $class = shift;
   $class->_log_at_level($level, @_)
  }
}

=item end()

=item end($name)

Ends the test and compares what we've got with what we expected.
Switches logging back from being captured to going to wherever
it was originally directed in the config.

=cut

# eeek, the hard bit
sub end
{
  my $class = shift;
  my $name = shift || "Log4perl test";

  $class->interception_class->set_temp("ended", 1);
  # turn off the interception code
  foreach (values %$Log::Log4perl::Logger::LOGGERS_BY_NAME)
    { bless $_, $class->original_class }

  my $no;
  while (@logged)
  {
    $no++;

    my $logged   = shift @logged;
    my $expected = shift @expected;

    # not expecting anything?
    unless ($expected)
    {
      $Tester->ok(0,$name);
      $Tester->diag("Unexpected $logged->{priority} of type '$logged->{category}':\n");
      $Tester->diag("  '$logged->{message}'");
      return 0;
    }

    # was this message what we expected?
    # ...
    my %wrong = map { $_ => 1 }
                 grep { !_matches($logged->{ $_ }, $expected->{ $_ }) }
                 qw(category message priority);
    if (%wrong)
    {
      $Tester->ok(0, $name);
      $Tester->diag(ordinate($no)." message logged wasn't what we expected:");
      foreach my $thingy (qw(category priority message))
      {
        if ($wrong{ $thingy })
        {
          $Tester->diag(sprintf(q{ %8s was '%s'}, $thingy, $logged->{ $thingy }));
          if (ref($expected->{ $thingy }) && ref($expected->{ $thingy }) eq "Regexp")
            { $Tester->diag("     not like '$expected->{$thingy}'") }
          else
            { $Tester->diag("          not '$expected->{$thingy}'") }         
        }
      }
      $Tester->diag(" (Offending log call from line $logged->{line} in $logged->{filename})");

      return 0

    }
  }

  # expected something but didn't get it?
  if (@expected)
  {
    $Tester->ok(0, $name);
    $Tester->diag("Ended logging run, but still expecting ".@expected." more log(s)");
    $Tester->diag("Expecting $expected[0]{priority} of type '$expected[0]{category}' next:");
    $Tester->diag("  '$expected[0]{message}'");
    return 0;
  }

  $Tester->ok(1,$name);
  return 1;
}

# this is essentially a trivial implementation of perl 6's smart match operator
sub _matches
{
  my $got      = shift;
  my $expected = shift;

  my $ref = ref($expected);

  # compare as a string
  unless ($ref)
   { return $expected eq $got }

  # compare a regex?
  if (ref($expected) eq "Regexp")
   { return $got =~ $expected }

  # check if it's a reference to something, and die
  if (!blessed($expected))
   { croak "Don't know how to compare a reference to a $ref" }

  # it's an object.  Is that overloaded in some way?
  # (note we avoid calling overload::Overloaded unless someone has used
  # the module first)
  if (defined(&overload::Overloaded) && overload::Overloaded($expected))
   { return $expected eq $got }
   
  croak "Don't know how to compare object $ref"; 
}

=back

=head2 Ignoring All Logging Messages

Sometimes you're going to be testing something that generates a load
of spurious log messages that you simply want to ignore without
testing their contents, but you don't want to have to reconfigure
your log file.  The simpliest way to do this is to do:

  use Test::Log4perl;
  Test::Log4perl->suppress_logging;

All logging functions stop working.  Do not alter the Logging classes
(for example, by changing the config file and use Log4perl's
C<init_and_watch> functionality) after this call has been made.

This function will be effectivly a no-op if the enviromental variable
C<NO_SUPRESS_LOGGING> is set to a true value (so if your code is
behaving weirdly you can turn all the logging back on from the command
line without changing any of the code)

=cut

# TODO: What if someone calls ->start() after this then, eh?
# currently it'll test the logs and then stop supressing logging
# is that what we want?  Because that's what'll happen.

# I canna spell
sub supress_logging { my $class = shift; $class->supress_logging(@_) }

sub suppress_logging
{
  my $class = shift;

  return if $ENV{NO_SUPRESS_LOGGING};

  # tell this to ignore everything.
   foreach (values %$Log::Log4perl::Logger::LOGGERS_BY_NAME)
    { bless $_, $class->ignore_all_class }
}

=head2 Selectivly Ignoring Logging Messages By Priority

It's a bad idea to completely ignore all messages.  What you probably
want to do is ignore some of the trivial messages that you don't
care about, and just test that there aren't any unexpected messages
of a set priority.

You can temporarly ignore any logging messages that are made by
passing parameters to the C<start> routine

  # for this test, just ignore DEBUG, INFO, and WARN
  Test::Log4perl->start( ignore_priority => "warn" );

  # you can use the levels constants to do the same thing
  use Log::Log4perl qw(:levels);
  Test::Log4perl->start( ignore_priority => $WARN );

You might want to ignore all logging events at all (this can be used
as quick way to not test the actual log messages, but just ignore the
output.

  # for this test, ignore everything
  Test::Log4perl->start( ignore_priority => "everything" );

  # contary to readability, the same thing (try not to write this)
  use Log::Log4perl qw(:levels);
  Test::Log4perl->start( ignore_priority => $OFF );

Or you might want to not ignore anything (which is the default, unless
you've played with the method calls mentioned below:)

  # for this test, ignore nothing
  Test::Log4perl->start( ignore_priority => "nothing" );

  # contary to readability, the same thing (try not to write this)
  use Log::Log4perl qw(:levels);
  Test::Log4perl->start( ignore_priority => $ALL );

You can also perminatly effect what things are ignored with the
C<ignore_priority> method call.  This persists between tests and isn't
autoically reset after each call to C<start>.

  # ignore DEBUG, INFO and WARN for all future tests
  Test::Log4perl->ignore_priority("warn");

  # you can use the levels constants to do the same thing
  use Log::Log4perl qw(:levels);
  Test::Log4perl->ignore_priority($WARN);

  # ignore everything (no log messages will be logged)
  Test::Log4perl->ignore_priority("everything");

  # ignore nothing (messages will be logged reguardless of priority)
  Test::Log4perl->ignore_priority("nothing");

Obviously, you may temporarly override whatever perminant

=cut

sub ignore_priority
{
  my $class = shift;
  my $p = _to_d shift;
  $class->interception_class->set_temp("ignore_priority", $p);
  $class->interception_class->set_perm("ignore_priority", $p);
}

sub ignore_everything
{
  my $class = shift;
  $class->ignore_priority($OFF);
}

sub ignore_nothing
{
  my $class = shift;
  $class->ignore_priority($ALL);
}

sub interception_class { "Log::Log4perl::Logger::Interception" }
sub ignore_all_class   { "Log::Log4perl::Logger::IgnoreAll"    }
sub original_class     { "Log::Log4perl::Logger"               }

sub DESTROY {
  return if $_[0]->interception_class->ended;
  goto $_[0]->can('end');
}

###################################################################################################

package Log::Log4perl::Logger::Interception;
use base qw(Log::Log4perl::Logger);
use Log::Log4perl qw(:levels);

our %temp;
our %perm;

sub reset_temp { %temp = () }
sub set_temp { my ($class, $key, $val) = @_; $temp{$key} = $val }
sub set_perm { my ($class, $key, $val) = @_; $perm{$key} = $val }
sub ended { my ($class) = @_; $temp{ended} }
# all the basic logging functions
foreach my $level (qw(debug info warn error fatal))
{
  no strict 'refs';

  # we need to pass the number to log
  my $level_int = Log::Log4perl::Level::to_priority(uc($level));
  *{$level} = sub {
   my $self = shift;
   $self->log($level_int, @_)
  }
}

sub log
{
  my $self     = shift;
  my $priority = shift;
  my $message  = shift;

  # are we logging anything or what?
  if ($priority <= ($temp{ignore_priority} || 0) or
      $priority <= ($perm{ignore_priority} || 0))
    { return }

  # what's that priority called then?
  my $priority_name = lc( Log::Log4perl::Level::to_level($priority) );

  # find the filename and line
  my ($filename, $line);
  my $cur_filename = _cur_filename();
  my $level = 1;
  do {
    (undef, $filename, $line) = caller($level++);
  } while ($filename eq $cur_filename || $filename eq $INC{"Log/Log4perl/Logger.pm"});

  # log it
  push @Test::Log4perl::logged, {
    category => $self->{category},  # oops, there goes encapsulation
    priority => $priority_name,
    message  => $message,
    filename => $filename,
    line     => $line,
  };

  return;
}

sub _cur_filename { (caller)[1] }

1;

package Log::Log4perl::Logger::IgnoreAll;
use base qw(Log::Log4perl::Logger);

# all the functions we don't want
foreach my $level (qw(debug info warn error fatal log))
{
  no strict 'refs';
  *{$level} = sub { return () }
}

=head1 BUGS

Logging methods don't return the number of appenders they've written
to (or rather, they do, as it's always zero.)

Changing the config file (if you're watching it) while this is testing
/ supressing everything will probably break everything.  As will
creating new appenders, etc...

=head1 AUTHOR

  Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

  Copyright 2005 Fotango Ltd all rights reserved.
  Licensed under the same terms as Perl itself.

=cut

1;
