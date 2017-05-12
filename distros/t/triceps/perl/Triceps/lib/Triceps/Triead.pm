#
# (C) Copyright 2011-2015 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Perl methods for the Triead creation (it's not really a class but a helper
# for TrieadOwner that makes the names look better).

package Triceps::Triead;

our $VERSION = 'v2.0.1';

use Carp;
use threads;

use strict;

# The options for start(). Keeping them in a variable allows the individual
# thread main functions to copy and reuse their definition instead of
# reinventing it.
our @startOpts = (
	app => [ undef, \&Triceps::Opt::ck_mandatory ],
	thread => [ undef, \&Triceps::Opt::ck_mandatory ],
	fragment => [ "", undef ],
	main => [ undef, sub { &Triceps::Opt::ck_ref(@_, "CODE") } ],
);

# The default set of options that a new thread gets from start().
our @opts = (
	@startOpts,
	owner => [ undef, sub { &Triceps::Opt::ck_mandatory(@_); &Triceps::Opt::ck_ref(@_, "Triceps::TrieadOwner") } ],
	immed => [ 0, undef ],
);

# Start a new Triead.
# Use:
# Triceps::Triead::start(@options);
# 
# All the options are passed through to the main function, even if they are not recognized.
# The recognized options are:
#
# app => $appname
# Name of the app that owns this thread.
#
# thread => $threadname
# Name for this thread.
#
# fragment => $fragname
# Name of the fragment (default: "").
#
# immed => 0/1
# Flag: when the new thread imports its nexuses, it should import them in the
# immediate mode. This flag is purely advisory, and the thread's main function
# is free to use or ignore it depending on its logic. It's provided as a
# convenience, since it's a typical concern for the helper threads. Default: 0.
#
# main => \&function
# The main function of the thread that will be called with all the options
# plus some more:
#     &$func(@opts, owner => $ownerObj)
# owner: the TrieadOwner object constructed for this thread
#
sub start # (@opts)
{
	my $myname = "Triceps::Triead::start";
	my $opts = {};

	&Triceps::Opt::parse($myname, $opts, {
		@startOpts,
		'*' => [],
	}, @_);

	# This avoids the race if we're about to wait for this thread.
	Triceps::App::declareTriead($opts->{app}, $opts->{thread});

	my @args = @_;
	@_ = (); # workaround for threads leaking objects
	threads->create(sub {
		my $owner = Triceps::TrieadOwner->new(threads->self()->tid(), threads->self()->_handle(), 
			$opts->{app}, $opts->{thread}, $opts->{fragment});
		push(@_, "owner", $owner);
		eval { &{$opts->{main}}(@_) };
		$owner->abort($@) if ($@);
		# In case if the thread just wrote some rows outside of nextXtray()
		# and exited, flush to get the rows through. Otherwise things might
		# get stuck in a somewhat surprising way.
		eval { $owner->flushWriters(); };
		# markDead() here is optional since it would happen anyway when the
		# owner object gets destroyed, and the only reference to it is from
		# this thread, so it will be destroyed when the thread exits.
		# But better be safe than sorry.
		$owner->markDead();
	}, @args);
}

# Start a new Triead in the current thread, without creating a new thread.
# This is convenient for the tests, to put this Triead at the end of
# the pipelne and thus concentrating all the ok() calls in it, preventing
# the races in the test results.
# But it can also be useful in the real-world program as an anchor that
# connectes the multithreaded Triceps model to the rest of the application.
# An easy way to send a set of data through the model is to create a writer
# facet on a reverse nexus (for the unliited buffering) for the input data,
# and whatever needed reader facets on the output data. Then send all the
# input data to the writer facet and read the results from the reader facet(s).
#
# This function won't return until the pseudo-thread's main function
# returns.
#
# The options are the same as for start() with an addition:
#
# harvest => 0/1
# After the main function exits, automatically run the harvesrer.
# If you set it to 0, don't forget to call the harvester after this 
# function returns. (Default: 1)
# This option will not be passed to main().
#
# makeApp => 0/1
# Before doing anything, create the App. This is convenient because typically
# this thread becomes the "anchor" of the App that creates all the other
# threads.
# (Default: 1)
#
sub startHere # (@opts)
{
	my $myname = "Triceps::Triead::start";
	my $opts = {};
	my @myOpts = ( # options that don't propagate through
		harvest => [ 1, undef ],
		makeApp => [ 1, undef ],
	);

	&Triceps::Opt::parse($myname, $opts, {
		@startOpts,
		@myOpts,
		'*' => [],
	}, @_);

	my @args = &Triceps::Opt::drop({
		@myOpts
	}, \@_);
	@_ = (); # workaround for threads leaking objects

	# no need to declare the Triead, since all the code executes synchronously anyway
	my $app;
	if ($opts->{makeApp}) {
		$app = &Triceps::App::make($opts->{app});
	} else {
		$app = &Triceps::App::resolve($opts->{app});
	}
	my $owner = Triceps::TrieadOwner->new(undef, undef, $app, $opts->{thread}, $opts->{fragment});
	push(@args, "owner", $owner);
	eval { &{$opts->{main}}(@args) };
	$owner->abort($@) if ($@);
	# In case if the thread just wrote some rows outside of nextXtray()
	# and exited, flush to get the rows through. Otherwise things might
	# get stuck in a somewhat surprising way.
	eval { $owner->flushWriters(); };
	$owner->markDead();
	if ($opts->{harvest}) {
		$app->harvester();
	}
}

1;
