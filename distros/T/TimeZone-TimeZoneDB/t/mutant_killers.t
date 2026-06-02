#!/usr/bin/env perl

# Mutant-killer tests derived from xt/mutant_20260601_211922.t.
# Each subtest targets one surviving mutant and provides assertions that
# pass for the correct code but FAIL if the described mutation is applied.
#
# Mutants targeted:
#   COND_INV_222_2  -- line 222 new():  if(!defined($class))
#   COND_INV_226_3  -- line 226 new():  if(exists($params->{ua}))
#   COND_INV_227_4  -- line 227 new():  if(!defined($params->{ua}))
#   BOOL_NEGATE_418 -- line 418 gtz():  return $cached
#   COND_INV_453_3  -- line 453 gtz():  if(my $logger = ...)
#   BOOL_NEGATE_546 -- line 546 ua():   return $self->{ua} unless @_
#   NUM_BOUNDARY_553-- line 553 ua():   if(@_ == 2 && ...)
#   COND_INV_572_2  -- line 572 ua():   if(!defined($params->{ua}))
#   COND_INV_573_3  -- line 573 ua():   if(my $logger = ...)
#   BOOL_NEGATE_581 -- line 581 ua():   return $self->{ua}  [setter path]
#
# LOW hints (RETURN_UNDEF variants) also implemented below.

use strict;
use warnings;

use lib 'lib';
use lib "$ENV{HOME}/src/njh/Test-Mockingbird/lib";
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";

use HTTP::Response;
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use TimeZone::TimeZoneDB;

# ---------------------------------------------------------------------------
# Configuration constants
# ---------------------------------------------------------------------------
my %config = (
	key        => 'mutant_killer_key',
	host       => 'api.timezonedb.com',
	lat        =>  51.34,
	lng        =>   1.42,
	tz_ok      => 'Europe/London',
	http_ok    => 200,
);

Readonly::Scalar my $KEY => $config{key};
Readonly::Scalar my $LAT => $config{lat};
Readonly::Scalar my $LNG => $config{lng};
Readonly::Scalar my $TZ  => $config{tz_ok};

# Canned JSON that validate_strict accepts as a normal successful response
Readonly::Scalar my $JSON_OK   => '{"status":"OK","zoneName":"Europe/London"}';
Readonly::Scalar my $JSON_FAIL => '{"status":"FAILED","message":"bad key"}';

# ---------------------------------------------------------------------------
# Test-double packages
# ---------------------------------------------------------------------------

# GoodUA: minimal object that satisfies can('get').  Two distinct instances
# can be told apart by reference comparison.
{
	package GoodUA;
	sub new { bless { _id => $_[1] // 'default' }, $_[0] }
	sub get { return undef }	# not called in most tests
	sub id  { $_[0]->{_id} }
}

# MockLogger: records calls to warn() and error()
{
	package MockLogger;
	sub new   { bless { warns => [], errors => [] }, $_[0] }
	sub warn  { push @{$_[0]->{warns}},  $_[1] }
	sub error { push @{$_[0]->{errors}}, $_[1] }
}

# ---------------------------------------------------------------------------
# Helper: build a 200 OK HTTP::Response with a JSON body
# ---------------------------------------------------------------------------
sub _ok_resp {
	my ($body) = @_;
	my $r = HTTP::Response->new($config{http_ok}, 'OK');
	$r->content($body);
	return $r;
}

# ---------------------------------------------------------------------------
# Suppress filesystem access from Object::Configure throughout the file
# ---------------------------------------------------------------------------
mock 'Object::Configure::configure' => sub { $_[1] };

# ===========================================================================
# COND_INV_222_2  --  if(!defined($class))  line 222  new()
#
# Mutation: if(!defined) -> unless(!defined)  (i.e. if(defined))
# Effect:   When $class is a blessed object (defined), the condition fires and
#           sets $class = __PACKAGE__.  The clone branch is never reached.
#           The next step (Object::Configure + key check) sees no key -> CROAK.
# Kill:     Verify $obj->new() returns a clone without croaking.
# ===========================================================================

subtest 'COND_INV_222_2: clone call must not croak and must inherit key' => sub {
	# Create a parent object and clone it with no extra arguments.
	# If the !defined condition is inverted, the clone path is bypassed and
	# the code falls into the normal constructor which croaks for missing key.
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY);
	my $clone;
	lives_ok { $clone = $orig->new() }
		'COND_INV_222_2: $obj->new() must not croak';

	isa_ok($clone, 'TimeZone::TimeZoneDB', 'COND_INV_222_2: clone is correct class');
	diag("clone created OK") if $ENV{TEST_VERBOSE};
};

subtest 'COND_INV_222_2: clone inherits host from original' => sub {
	# The clone must carry all original properties.  If the if/unless is
	# flipped, a new empty object is constructed (and would croak first).
	my $ua    = GoodUA->new('orig-ua');
	my $orig  = TimeZone::TimeZoneDB->new(key => $KEY, host => $config{host}, ua => $ua);
	my $clone = $orig->new();

	# Both original and clone must point at the same UA instance
	is($clone->ua(), $ua, 'COND_INV_222_2: clone inherits original ua');
	diag("clone ua identity verified") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# COND_INV_226_3  --  if(exists($params->{ua}))  line 226  new() clone path
#
# Mutation: if(exists) -> unless(exists)
# Effect:   Validation block fires when ua is ABSENT; skipped when ua IS present.
#           ua=>undef in a clone call bypasses the delete and stores undef.
# Kill:     $orig->new(ua => undef) must preserve the original ua.
# ===========================================================================

subtest 'COND_INV_226_3: clone with ua=>undef inherits original ua' => sub {
	# ua=>undef should trigger the "delete and keep original" logic.
	# With the mutation, exists() is inverted: the ua key exists so the
	# block is skipped and undef is passed straight through.
	my $ua   = GoodUA->new('real-ua');
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $clone;
	lives_ok { $clone = $orig->new(ua => undef) }
		'COND_INV_226_3: clone with ua=>undef must not croak';

	is($clone->ua(), $ua, 'COND_INV_226_3: clone ua matches original after ua=>undef');
	diag("ua preserved through ua=>undef clone") if $ENV{TEST_VERBOSE};
};

subtest 'COND_INV_226_3: clone without ua arg also works' => sub {
	# When ua is NOT supplied (key absent), the exists() check is false in
	# the original and the block is correctly skipped.  With the mutation
	# (unless exists), the block would fire for the ABSENT case and attempt
	# to validate undef -- behaviour depends on inner conditions.
	my $ua   = GoodUA->new('orig-ua-2');
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $clone;
	lives_ok { $clone = $orig->new() }
		'COND_INV_226_3: clone without ua arg must not croak';
	is($clone->ua(), $ua, 'COND_INV_226_3: clone without ua inherits original ua');
};

# ===========================================================================
# COND_INV_227_4  --  if(!defined($params->{ua}))  line 227  new() clone path
#
# Mutation: if(!defined) -> unless(!defined)  (i.e. if(defined))
# Effect 1: ua=>undef -> defined(undef) is FALSE -> skips delete -> undef
#           passes to elsif(!blessed(undef) ...) -> CROAK!
# Effect 2: ua=>$valid_obj -> defined(obj) is TRUE -> delete ua -> clone
#           keeps original ua (the new ua is silently thrown away).
# Kill 1:   ua=>undef must NOT croak.
# Kill 2:   ua=>$new_ua must use $new_ua, not the original.
# ===========================================================================

subtest 'COND_INV_227_4: ua=>undef clone must not croak (delete branch)' => sub {
	# !defined(undef) is TRUE in the original, so we delete and keep original.
	# With mutation, defined(undef) is FALSE, skipping the delete; the elif
	# then gets !blessed(undef) = TRUE and croaks.
	my $ua   = GoodUA->new('ua-227');
	my $orig = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	lives_ok { $orig->new(ua => undef) }
		'COND_INV_227_4: ua=>undef clone must survive without croak';
};

subtest 'COND_INV_227_4: ua=>$new_ua clone must use the new ua' => sub {
	# !defined($new_ua) is FALSE in the original, so the defined ua is kept.
	# With mutation, defined($new_ua) is TRUE -> delete ua -> new_ua is lost!
	my $old_ua = GoodUA->new('old-ua');
	my $new_ua = GoodUA->new('new-ua');
	my $orig   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);
	my $clone  = $orig->new(ua => $new_ua);

	is($clone->ua(), $new_ua,  'COND_INV_227_4: clone uses the supplied new ua');
	isnt($clone->ua(), $old_ua, 'COND_INV_227_4: clone does not use original ua');
	diag("clone ua=".ref($clone->ua())) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# BOOL_NEGATE_418_3  --  return $cached  line 418  get_time_zone()
#
# Mutation: return $cached -> return !$cached
# Effect:   A hashref is truthy; !{} = '' (empty string, not a hashref).
# Kill:     Cache hit must return the actual hashref, not ''.
# Also covers LOW hint: RETURN_UNDEF_418_3 (return undef instead of $cached)
# ===========================================================================

subtest 'BOOL_NEGATE_418_3: cache hit returns the actual hashref not a boolean' => sub {
	# First call populates the cache; second call is the cache hit.
	# With mutation, the second call returns !{} = ''.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my ($r1, $r2);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		$r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		$r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}

	# r2 is the cache hit -- must be a proper hashref, not a boolean
	ok(defined $r2,           'BOOL_NEGATE_418_3: cache hit is defined');
	is(ref($r2), 'HASH',      'BOOL_NEGATE_418_3: cache hit is a hashref');
	is($r2->{zoneName}, $TZ,  'BOOL_NEGATE_418_3: cache hit has correct zoneName');
	returns_ok($r2, { type => 'hashref', min => 1 },
		'BOOL_NEGATE_418_3: cache hit satisfies Return::Set output schema');

	# Also verify the cached value is identical to the original
	is_deeply($r2, $r1, 'BOOL_NEGATE_418_3: cache hit equals original response');
	diag("cache hit zoneName=$r2->{zoneName}") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# COND_INV_453_3  --  if(my $logger = $self->{'logger'})  line 453  get_time_zone()
#
# Mutation: if(logger) -> unless(logger)
# Effect 1: No logger -> unless(undef) = TRUE -> undef->warn() -> CRASH!
# Effect 2: Logger present -> unless(obj) = FALSE -> logger NOT called.
# Kill 1:   Non-OK response with no logger must return undef (not die).
# Kill 2:   Non-OK response with logger must call logger->warn.
# ===========================================================================

subtest 'COND_INV_453_3: non-OK response without logger must return undef, not die' => sub {
	# If the condition is inverted, absent logger means unless(undef)=true,
	# and undef->warn() is called, crashing the process.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $result;
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_FAIL) };
		lives_ok { $result = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG) }
			'COND_INV_453_3: non-OK without logger must not die';
	}
	ok(!defined $result, 'COND_INV_453_3: non-OK without logger returns undef');
};

subtest 'COND_INV_453_3: non-OK response WITH logger calls logger->warn' => sub {
	# If the condition is inverted, logger->warn is NEVER called when logger
	# is present (the unless fires only when logger is falsy).
	my $logger = MockLogger->new();
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, logger => $logger);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_FAIL) };
		$tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	is(scalar @{$logger->{warns}}, 1,
		'COND_INV_453_3: logger->warn called exactly once for non-OK status');
	diag("logger warn: $logger->{warns}[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# BOOL_NEGATE_546_2  --  return $self->{ua} unless @_  line 546  ua() getter
#
# Mutation: return $self->{ua} -> return !$self->{ua}
# Effect:   A blessed LWP::UserAgent is truthy; !$ua = '' (empty string).
# Also covers LOW hint: RETURN_UNDEF_546_2 (return undef)
# Kill:     ua() with no args must return a blessed object, not '' or undef.
# ===========================================================================

subtest 'BOOL_NEGATE_546_2: getter returns a blessed object, not a boolean' => sub {
	# With mutation, $tzdb->ua() returns !$ua = '' for any truthy ua.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $got  = $tzdb->ua();

	ok(defined $got,        'BOOL_NEGATE_546_2: ua() getter returns a defined value');
	ok(blessed($got),       'BOOL_NEGATE_546_2: ua() getter returns a blessed object');
	can_ok($got, 'get');
	returns_ok($got, { type => 'object' },
		'BOOL_NEGATE_546_2: ua() getter satisfies output schema');
	diag("getter returned: ".ref($got)) if $ENV{TEST_VERBOSE};
};

subtest 'BOOL_NEGATE_546_2: getter is identity -- same object back twice' => sub {
	# The returned object must be the exact same reference each time.
	# A boolean negation would return '' on every call (consistent but wrong).
	my $ua   = GoodUA->new('getter-id-test');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	is($tzdb->ua(), $ua, 'BOOL_NEGATE_546_2: getter returns the stored UA by reference');
};

# ===========================================================================
# NUM_BOUNDARY_553_8_!=  --  if(@_ == 2 && ...)  line 553  ua()
#
# Mutation: @_ == 2 -> @_ != 2
# Effect:   The named-pair fast-path now fires when @_ is NOT 2 (e.g. 1 or 3).
#           For the 2-element named form ua(ua => $obj):
#             @_ = ('ua', $obj), @_ != 2 is FALSE -> falls to Params::Get
#             get_params('ua', ['ua', $obj]) returns {ua => ['ua', $obj]} (bug)
#             validate_strict sees unblessed arrayref -> CROAK!
# Kill:     ua(ua => $obj) named-pair form must succeed and return the object.
# Boundary: also verify 1-arg and 3-arg forms behave as expected.
# ===========================================================================

subtest 'NUM_BOUNDARY_553_8: ua(ua => $obj) named-pair (2 args) must succeed' => sub {
	# With @_ != 2 mutation: 2 args -> condition FALSE -> Params::Get bug -> croak.
	my $ua   = GoodUA->new('named-pair-ua');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $ret;
	lives_ok { $ret = $tzdb->ua(ua => $ua) }
		'NUM_BOUNDARY_553_8: ua(ua => $obj) must not croak';
	is($ret, $ua, 'NUM_BOUNDARY_553_8: ua(ua => $obj) returns the supplied UA');
	diag("named-pair setter returned: ".ref($ret)) if $ENV{TEST_VERBOSE};
};

subtest 'NUM_BOUNDARY_553_8: ua($obj) positional (1 arg) must succeed' => sub {
	# 1 arg: @_ == 1, @_ == 2 is FALSE in original -> Params::Get (works fine).
	# With mutation @_ != 2: @_ = 1, 1 != 2 = TRUE but !ref($obj) = FALSE -> also works.
	my $ua   = GoodUA->new('positional-ua');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $ret;
	lives_ok { $ret = $tzdb->ua($ua) }
		'NUM_BOUNDARY_553_8: positional ua($obj) must not croak';
	is($ret, $ua, 'NUM_BOUNDARY_553_8: positional form returns the supplied UA');
};

subtest 'NUM_BOUNDARY_553_8: ua() with 2 named-pair args returns correct object' => sub {
	# Specifically testing the EXACTLY-2-args path to distinguish from boundary.
	# This is the test that kills the @_ != 2 mutation.
	my $old_ua = GoodUA->new('old');
	my $new_ua = GoodUA->new('new');
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);

	my $ret = $tzdb->ua(ua => $new_ua);
	is($ret,   $new_ua, 'NUM_BOUNDARY_553_8: named-pair returns new UA');
	isnt($ret, $old_ua, 'NUM_BOUNDARY_553_8: named-pair does not return old UA');
};

# ===========================================================================
# COND_INV_572_2  --  if(!defined($params->{ua}))  line 572  ua()
#
# Mutation: if(!defined) -> unless(!defined)  (i.e. if(defined))
# Effect 1: ua($valid_obj) -> defined(obj) TRUE -> croak! (valid ua rejected)
# Effect 2: ua(undef) -> defined(undef) FALSE -> skip croak -> $self->{ua} = undef
# Kill 1:   ua($valid_obj) must succeed.
# Kill 2:   ua(undef) must croak with exact message.
# ===========================================================================

subtest 'COND_INV_572_2: valid ua setter must not croak' => sub {
	# With mutation, defined($valid_ua) is TRUE -> the croak fires for every
	# valid object.  This completely breaks the setter.
	my $ua   = GoodUA->new('valid-572');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	lives_ok { $tzdb->ua($ua) }
		'COND_INV_572_2: ua($valid_obj) must not croak';
};

subtest 'COND_INV_572_2: ua(undef) must croak with exact error message' => sub {
	# With mutation, defined(undef) is FALSE -> skip croak -> undef silently
	# stored.  The croak for undef is the key guard against corruption.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	throws_ok { $tzdb->ua(undef) }
		qr/ua\(\) requires a defined value/,
		'COND_INV_572_2: ua(undef) croaks with exact message';
};

subtest 'COND_INV_572_2: after valid setter, ua() returns the new UA' => sub {
	# Confirms the setter stored the object (not that it silently croaked).
	my $old_ua = GoodUA->new('old-572');
	my $new_ua = GoodUA->new('new-572');
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);

	$tzdb->ua($new_ua);
	is($tzdb->ua(), $new_ua, 'COND_INV_572_2: ua() returns new UA after setter');
};

# ===========================================================================
# COND_INV_573_3  --  if(my $logger = $self->{'logger'})  line 573  ua()
#
# Mutation: if(logger) -> unless(logger)
# Effect 1: No logger -> unless(undef) = TRUE -> undef->error() -> CRASH!
# Effect 2: Logger present -> unless(obj) = FALSE -> logger->error NOT called.
# Kill 1:   ua(undef) without logger must croak with exact message (not crash).
# Kill 2:   ua(undef) with logger must call logger->error.
# ===========================================================================

subtest 'COND_INV_573_3: ua(undef) without logger croaks, does not die with method-on-undef' => sub {
	# With mutation, undef->error() would be called, producing a different
	# "Can't call method" fatal error instead of the documented croak message.
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $err;
	eval { $tzdb->ua(undef) };
	$err = $@;

	ok($err, 'COND_INV_573_3: ua(undef) without logger does produce an error');
	like($err, qr/ua\(\) requires a defined value/,
		'COND_INV_573_3: error is the documented croak, not a method-on-undef crash');
	unlike($err, qr/Can't call method/,
		'COND_INV_573_3: no "Can\'t call method" error (that would indicate undef->error() was called)');
	diag("error: $err") if $ENV{TEST_VERBOSE};
};

subtest 'COND_INV_573_3: ua(undef) with logger must call logger->error' => sub {
	# With mutation, unless(logger)=FALSE when logger is present, so error() is
	# never called.  This test detects that suppression.
	my $logger = MockLogger->new();
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, logger => $logger);
	eval { $tzdb->ua(undef) };

	is(scalar @{$logger->{errors}}, 1,
		'COND_INV_573_3: logger->error called exactly once when ua(undef) with logger');
	diag("logger error: $logger->{errors}[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# BOOL_NEGATE_581_2  --  return $self->{ua}  line 581  ua() setter path
#
# Mutation: return $self->{ua} -> return !$self->{ua}
# Effect:   Setter returns !$ua_obj = '' (empty string for truthy blessed ref).
# Also covers LOW hint: RETURN_UNDEF_581_2 (return undef)
# Kill:     Setter must return the actual UA object reference.
# ===========================================================================

subtest 'BOOL_NEGATE_581_2: setter returns the actual UA object' => sub {
	# With mutation, !$blessed_ua = '' which is not a reference and is not $ua.
	my $ua   = GoodUA->new('setter-581');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $ret  = $tzdb->ua($ua);

	ok(defined $ret,     'BOOL_NEGATE_581_2: setter return is defined');
	ok(blessed($ret),    'BOOL_NEGATE_581_2: setter return is a blessed object');
	is($ret, $ua,        'BOOL_NEGATE_581_2: setter returns the exact same UA object');
	returns_ok($ret, { type => 'object' },
		'BOOL_NEGATE_581_2: setter return satisfies output schema');
	diag("setter returned: ".ref($ret)) if $ENV{TEST_VERBOSE};
};

subtest 'BOOL_NEGATE_581_2: chaining ua() getter after setter returns same object' => sub {
	# The POD says both getter and setter return the UA.  Verify setter-then-get.
	my $old_ua = GoodUA->new('old-chain');
	my $new_ua = GoodUA->new('new-chain');
	my $tzdb   = TimeZone::TimeZoneDB->new(key => $KEY, ua => $old_ua);

	my $set_ret = $tzdb->ua($new_ua);
	my $get_ret = $tzdb->ua();

	is($set_ret, $new_ua, 'BOOL_NEGATE_581_2: setter returned new UA');
	is($get_ret, $new_ua, 'BOOL_NEGATE_581_2: getter after setter returns same new UA');
};

# ===========================================================================
# LOW HINTS implemented as full assertions
# ===========================================================================

# LOW: RETURN_UNDEF_418_3  --  return $cached -> return undef  line 418
# Kill: cache hit must return defined value (undef mutation would make it undef)

subtest 'RETURN_UNDEF_418_3: cache hit must return a non-undef hashref' => sub {
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my ($r1, $r2);
	{
		my $g = mock_scoped 'LWP::UserAgent::get' => sub { _ok_resp($JSON_OK) };
		$r1 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
		$r2 = $tzdb->get_time_zone(latitude => $LAT, longitude => $LNG);
	}
	ok(defined $r2,  'RETURN_UNDEF_418_3: cache-hit result is not undef');
	ok(ref($r2),     'RETURN_UNDEF_418_3: cache-hit result is a reference');
	is($r2->{zoneName}, $TZ, 'RETURN_UNDEF_418_3: cache-hit has correct zoneName');
};

# LOW: RETURN_UNDEF_546_2  --  return $self->{ua} unless @_ -> return undef unless @_
# Kill: getter must return non-undef

subtest 'RETURN_UNDEF_546_2: ua() getter must not return undef' => sub {
	# With the undef mutation, every getter call returns undef.
	my $ua   = GoodUA->new('low-546');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY, ua => $ua);
	my $got  = $tzdb->ua();
	ok(defined $got,   'RETURN_UNDEF_546_2: ua() getter is defined');
	is($got, $ua,      'RETURN_UNDEF_546_2: ua() getter returns the stored UA');
};

# LOW: RETURN_UNDEF_581_2  --  return $self->{ua} -> return undef  line 581
# Kill: setter must return non-undef

subtest 'RETURN_UNDEF_581_2: ua() setter must not return undef' => sub {
	# With the undef mutation, every setter call returns undef.
	my $ua   = GoodUA->new('low-581');
	my $tzdb = TimeZone::TimeZoneDB->new(key => $KEY);
	my $ret  = $tzdb->ua($ua);
	ok(defined $ret,   'RETURN_UNDEF_581_2: ua() setter return is defined');
	is($ret, $ua,      'RETURN_UNDEF_581_2: ua() setter returns the stored UA');
};

# ---------------------------------------------------------------------------
# Tear down all mocks
# ---------------------------------------------------------------------------
restore_all();

done_testing();
