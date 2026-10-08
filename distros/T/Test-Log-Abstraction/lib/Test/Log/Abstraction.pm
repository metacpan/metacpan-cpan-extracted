package Test::Log::Abstraction;

=head1 NAME

Test::Log::Abstraction - Capture log output in tests and assert on it

=head1 VERSION

0.001.0

=head1 SYNOPSIS

    use Test::Most;
    use Test::Log::Abstraction;

    my $logger = Test::Log::Abstraction->new();
    my $obj = Some::Class->new(logger => $logger);

    $obj->do_something();

    # Assertions on what was logged
    $logger->like(qr/updated/, 'do_something() logs that it updated');
    $logger->has_level('error');
    $logger->unlike(qr/fatal/);
    $logger->count() == 3;
    $logger->clear();

    # Or simply see the messages
    diag($_) foreach @{ $logger->messages() };

=head1 DESCRIPTION

A test double for L<Log::Abstraction>, drop-in wherever code under test is
passed a C<logger =>> object.

Every level method that L<Log::Abstraction> offers (C<trace>, C<debug>,
C<info>, C<notice>, C<warn>, C<error>, C<critical>, C<alert>, C<emergency>
and their syslog aliases) records the message instead of writing it to a
file, and optionally sends it to TAP diagnostics.  Nothing is ever written to
disk, and no logging backend is loaded.

=head2 Diagnostics

Messages at C<warning> and above are printed with L<Test::Builder/diag> by
default, so a test that accidentally triggers a warning is visible; C<trace>,
C<debug>, C<info> and C<notice> are printed only in verbose mode.  Verbose
mode is on when C<verbose =E<gt> 1> is passed to C<new()> or C<$ENV{TEST_VERBOSE}>
is true.

Change it with the C<diag> option: C<'all'> prints everything,
C<'none'> prints nothing (unless verbose), a level name such as C<'error'>
prints that level and everything more severe, and an array reference prints
just those levels.

=head2 Migrating from t/lib/MyLogger.pm

Replace, in each test file:

    use lib 't/lib';
    use MyLogger;
    ...
    logger => MyLogger->new()

with:

    use Test::Log::Abstraction;
    ...
    logger => Test::Log::Abstraction->new()

and delete F<t/lib/MyLogger.pm>.  Unlike the old MyLogger copies, this
implementation is identical everywhere, never recurses when a level method is
called with C<undef> (see C<t/autoload.t>), and records every message so tests
can assert on it instead of only printing it.

=head1 METHODS

=head2 new

    my $logger = Test::Log::Abstraction->new();
    my $logger = Test::Log::Abstraction->new(verbose => 1, diag => 'none');

Takes optional C<verbose> and C<diag> options (see L</DESCRIPTION>); any
other arguments are accepted and ignored, as L<Log::Abstraction/new> allows a
configuration hash to be passed through.  Called on an existing logger it
makes a clone with the same options and a copy of the captured messages, as
L<Log::Abstraction/new> does.

=head2 messages

    my $arrayref = $logger->messages();

Array reference of C<{ level, message }> hash references, in the order they
were logged.  Entries logged with L<Log::Abstraction>'s structured fields
also carry a C<fields> hash reference.

=head2 clear

    $logger->clear();

Empties the captured messages and returns the logger.

=head2 count

    my $n = $logger->count();          # all messages
    my $n = $logger->count('error');   # just one level

Number of captured messages, optionally restricted to one level.

=head2 like

    $logger->like(qr/updated/, 'optional test name');

Passes if any captured message matches the pattern.  Returns the result, and
reports it as a test through L<Test::Builder>, so count it in your plan (or
use C<done_testing()>).

=head2 unlike

    $logger->unlike(qr/fatal/, 'optional test name');

Passes if no captured message matches the pattern.

=head2 has_level

    $logger->has_level('error', 'optional test name');

Passes if at least one message was logged at that level.

=head2 empty

    $logger->empty('nothing was logged');

Passes if nothing at all was captured - the usual assertion after a clean run.

=head2 verbose

    my $verbose = $logger->verbose();
    $logger->verbose(1);

Gets or sets verbose mode.

=head1 DIAGNOSTICS

C<no method 'foo'> - the code under test called C<< $logger->foo() >>, which
is not a log level; the message is captured under that name and the notice is
always printed, so a typo'd level cannot pass silently.

=cut

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util ();
use Test::Builder ();

our $VERSION = '0.001.0';
our $AUTOLOAD;

# Level -> severity, lower is more severe, following POSIX syslog priorities.
# trace and debug share a severity, as they do in Log::Abstraction
my %SEVERITY = (
	emergency     => 0,
	emerg         => 0,
	panic         => 0,
	alert         => 1,
	critical      => 2,
	crit          => 2,
	fatal         => 2,
	error         => 3,
	err           => 3,
	warning       => 4,
	warn          => 4,
	notice        => 5,
	info          => 6,
	informational => 6,
	debug         => 7,
	trace         => 7,
);

# Every level method this class implements; anything else hits AUTOLOAD
my %LEVEL = map { $_ => 1 } keys %SEVERITY;

# Messages are printed by default at this level and above
my $DEFAULT_DIAG = 'warning';

=head2 trace, debug, info, notice, warn, error, critical, alert, emergency

    $logger->warn('something looks wrong');
    $logger->info('started', { pid => $$ });
    $logger->error({ error => 'cannot open file' });

Every L<Log::Abstraction> level and syslog alias is a method.  Each records
the call and, subject to the C<diag> setting, prints it.  Arguments follow
L<Log::Abstraction>'s rules: they are concatenated into the message, a hash
reference at the end of two or more arguments is captured as structured
C<fields>, and a lone hash reference is the message and is rendered as
C<< key => value >> pairs so it can be matched.  C<undef> arguments become the
string C<undef> and never warn.

Levels are thin wrappers over C<_record>; they exist so that C<AUTOLOAD> only
sees genuinely unknown methods.

=over 4

=item * C<trace>, C<debug>, C<info>, C<informational>, C<notice>

Captured; printed only in verbose mode by default.

=item * C<warn>, C<warning>, C<error>, C<err>, C<critical>, C<crit>,
C<fatal>, C<alert>, C<emergency>, C<emerg>, C<panic>

Captured and printed by default.

=back

=cut

sub trace     { my $self = shift; $self->_record('trace', @_);     return; }
sub debug     { my $self = shift; $self->_record('debug', @_);     return; }
sub info      { my $self = shift; $self->_record('info', @_);      return; }
sub informational { my $self = shift; $self->_record('informational', @_); return; }
sub notice    { my $self = shift; $self->_record('notice', @_);    return; }
sub warn      { my $self = shift; $self->_record('warn', @_);      return; }
sub warning   { my $self = shift; $self->_record('warning', @_);   return; }
sub error     { my $self = shift; $self->_record('error', @_);     return; }
sub err       { my $self = shift; $self->_record('err', @_);       return; }
sub critical  { my $self = shift; $self->_record('critical', @_);  return; }
sub crit      { my $self = shift; $self->_record('crit', @_);      return; }
sub fatal     { my $self = shift; $self->_record('fatal', @_);     return; }
sub alert     { my $self = shift; $self->_record('alert', @_);     return; }
sub emergency { my $self = shift; $self->_record('emergency', @_); return; }
sub emerg     { my $self = shift; $self->_record('emerg', @_);     return; }
sub panic     { my $self = shift; $self->_record('panic', @_);     return; }

=head2 new

See L</new> above.

=cut

sub new {
	my $class = shift;

	# Clone form: $logger->new(%overrides), as in Log::Abstraction
	if(Scalar::Util::blessed($class)) {
		my %args = _args(@_);
		return bless {
			%{$class},
			%args,
			messages => [ @{$class->{'messages'}} ],
		}, ref($class);
	}

	# Also allow the function-call form, Log::Abstraction::new(...)
	$class = __PACKAGE__ if(!defined($class));

	my %args = _args(@_);

	my $verbose;
	if(exists($args{'verbose'})) {
		$verbose = $args{'verbose'} ? 1 : 0;
	} else {
		$verbose = ($ENV{'TEST_VERBOSE'} || $ENV{'VERBOSE'}) ? 1 : 0;
	}

	return bless {
		messages  => [],
		%args,
		verbose   => $verbose,
		diag_rule => _diag_rule(exists($args{'diag'}) ? $args{'diag'} : $DEFAULT_DIAG),
	}, $class;
}

# _args - accept a hash, a hash reference, or (as MyLogger did) anything at all
#
# Purpose:      Constructor arguments of every shape used across the tests.
# Entry:        @args - whatever the caller passed after the class/invocant.
# Exit:         Returns a flattened hash; an odd argument list is ignored
#               rather than dying, so a stray option can't break a test run.
# Notes:        Pure function.
sub _args {
	return () if(!@_);
	return %{$_[0]} if((@_ == 1) && (ref($_[0]) eq 'HASH'));
	return @_ if(!(@_ % 2));
	return ();
}

# _diag_rule - normalise the diag option into an internal rule
#
# Purpose:      Validate the diag option once, at construction time.
# Entry:        $spec - 'all', 'none', a level name, or an array reference of
#               level names.
# Exit:         Returns { all => 1 }, { levels => {...} },
#               { threshold => $severity }, or {} for 'none'.
# Notes:        Croaks on anything unrecognised: a silent typo in a test's
#               diag option would otherwise hide log output forever.
sub _diag_rule {
	my $spec = shift;

	$spec = $DEFAULT_DIAG if(!defined($spec));

	if(ref($spec) eq 'ARRAY') {
		my %levels;
		foreach my $level (@{$spec}) {
			if(!defined($level) || !exists($SEVERITY{lc($level)})) {
				croak(__PACKAGE__, ": invalid diag level '", defined($level) ? $level : 'undef', "'");
			}
			$levels{lc($level)} = 1;
		}
		return { levels => \%levels };
	}

	if(!ref($spec)) {
		return {} if($spec eq 'none');
		return { all => 1 } if($spec eq 'all');
		my $level = lc($spec);
		if(!exists($SEVERITY{$level})) {
			croak(__PACKAGE__, ": invalid diag level '$spec'");
		}
		return { threshold => $SEVERITY{$level} };
	}

	croak(__PACKAGE__, ': diag must be a level name, "all", "none" or an array reference of level names');
}

# _record - capture one logged message
#
# Purpose:      The single place every level method ends up.
# Entry:        $self     - this logger.
#               $level    - level name as called by the code under test.
#               @args     - the log call's arguments.
# Exit:         Returns nothing; the message is pushed onto messages() and
#               printed when the diag rule allows it.
# Notes:        Never dies: undef arguments, references and objects are all
#               stringified safely, so a logging call cannot fail a test.
sub _record {
	my ($self, $level, @args) = @_;

	$level = lc($level);
	my ($message, $fields) = _render(@args);

	my $entry = { level => $level, message => $message };
	$entry->{'fields'} = $fields if(defined($fields));
	push @{$self->{'messages'}}, $entry;

	$self->_emit($message) if($self->_diags($level));

	return;
}

# _render - turn a log call's arguments into a message and optional fields
#
# Purpose:      Mirror Log::Abstraction's argument handling, but render hash
#               references readably instead of as HASH(0x...).
# Entry:        @args - the arguments the code under test passed.
# Exit:         Returns ($message, $fields); $fields is undef unless a hash
#               reference was the last of two or more arguments.
# Notes:        A lone hash reference is a message (Log::Abstraction's rule),
#               rendered as sorted 'key => value' pairs so tests can match on
#               its contents.  Undef becomes 'undef'; nothing warns.
sub _render {
	my @args = @_;

	return ('', undef) if(!@args);

	my $fields;
	if((@args >= 2) && (ref($args[-1]) eq 'HASH') && !Scalar::Util::blessed($args[-1])) {
		$fields = pop(@args);
	}

	if((@args == 1) && (ref($args[0]) eq 'HASH') && !Scalar::Util::blessed($args[0])) {
		return (_stringify($args[0]), undef);
	}

	return (join('', map { _stringify($_) } @args), $fields);
}

# _stringify - render any value as a readable string
#
# Purpose:      Stringify log arguments without warnings or fatals.
# Entry:        $value - scalar, undef, or any reference.
# Exit:         Returns a string: 'undef' for undef, 'k => v' pairs for a
#               hash, a bracketed list for an array, Perl's normal
#               stringification otherwise (objects honour overloading).
# Notes:        Pure function; recursion stops at unblessed scalar refs,
#               which take Perl's default SCALAR(0x...) form.
sub _stringify {
	my $value = shift;

	return 'undef' if(!defined($value));

	my $ref = ref($value);
	if(!$ref) {
		return $value;
	}
	if($ref eq 'HASH') {
		return '{' . join(', ', map { $_ . ' => ' . _stringify($value->{$_}) } sort keys(%{$value})) . '}';
	}
	if($ref eq 'ARRAY') {
		return '[' . join(', ', map { _stringify($_) } @{$value}) . ']';
	}

	return "$value";
}

# _diags - should this level be printed?
#
# Purpose:      One decision per message, from the diag rule and verbosity.
# Entry:        $self  - this logger.
#               $level - the (lower-cased) level name.
# Exit:         Returns true if the message should go to TAP diagnostics.
# Notes:        An unknown level has no severity, so the rule alone never
#               prints it; AUTOLOAD prints its own notice for those.
sub _diags {
	my ($self, $level) = @_;

	return 1 if($self->{'verbose'});

	my $rule = $self->{'diag_rule'} || {};
	return 1 if($rule->{'all'});
	return 1 if($rule->{'levels'} && $rule->{'levels'}->{$level});
	return 0 if(!defined($rule->{'threshold'}));

	my $severity = $SEVERITY{$level};
	return 0 if(!defined($severity));

	return ($severity <= $rule->{'threshold'}) ? 1 : 0;
}

# _emit - send a line to TAP diagnostics
#
# Purpose:      Isolate the Test::Builder dependency in one place.
# Entry:        $self    - this logger.
#               $message - text to print.
# Exit:         Returns nothing.
# Notes:        Uses Test::Builder directly rather than main::diag, so it
#               works in tests that never imported Test::More.
sub _emit {
	my ($self, $message) = @_;

	Test::Builder->new->diag($message);

	return;
}

# _notice - print something that must always be seen
#
# Purpose:      Report misuse (an unknown level) whatever the diag rule.
# Entry:        $self, @message - arguments concatenated, so callers may
#               pass pre-built fragments.
# Exit:         Returns nothing.
sub _notice {
	my ($self, @message) = @_;

	Test::Builder->new->diag(join('', @message));

	return;
}

=head2 AUTOLOAD

Any other method call - typically a level name that doesn't exist, such as a
typo - captures the message under that name and prints a notice, instead of
dying part way through a test.

=cut

sub AUTOLOAD {
	my $self = shift;

	my ($name) = ($AUTOLOAD =~ /::([^:]+)$/);
	return if($name eq 'DESTROY');

	$self->_record($name, @_);
	$self->_notice(__PACKAGE__, ": no method '$name'");

	return;
}

sub DESTROY { }

=head2 messages, clear, count, like, unlike, has_level, empty, verbose

See L</METHODS> above.

=cut

sub messages {
	my $self = shift;

	return $self->{'messages'};
}

sub clear {
	my $self = shift;

	@{$self->{'messages'}} = ();

	return $self;
}

sub count {
	my ($self, $level) = @_;

	if(defined($level)) {
		$level = lc($level);
		return scalar(grep { $_->{'level'} eq $level } @{$self->{'messages'}});
	}

	return scalar(@{$self->{'messages'}});
}

sub like {
	my ($self, $pattern, $name) = @_;

	croak(__PACKAGE__, ': like() needs a pattern') if(!defined($pattern));

	my $matched = grep { $_->{'message'} =~ $pattern } @{$self->{'messages'}};

	return Test::Builder->new->ok($matched, $name);
}

sub unlike {
	my ($self, $pattern, $name) = @_;

	croak(__PACKAGE__, ': unlike() needs a pattern') if(!defined($pattern));

	my $matched = grep { $_->{'message'} =~ $pattern } @{$self->{'messages'}};

	return Test::Builder->new->ok(!$matched, $name);
}

sub has_level {
	my ($self, $level, $name) = @_;

	croak(__PACKAGE__, ': has_level() needs a level name') if(!defined($level));

	$level = lc($level);
	my $found = grep { $_->{'level'} eq $level } @{$self->{'messages'}};

	return Test::Builder->new->ok($found, $name);
}

sub empty {
	my ($self, $name) = @_;

	return Test::Builder->new->ok(!@{$self->{'messages'}}, $name);
}

sub verbose {
	my ($self, $value) = @_;

	if(@_ >= 2) {
		$self->{'verbose'} = $value ? 1 : 0;
	}

	return $self->{'verbose'};
}

=head1 SEE ALSO

L<Log::Abstraction>, L<Test::Builder>, L<Test::Most>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
