#!/usr/bin/env perl

# White-box function tests for every module under lib/.
#
# Each module is exercised in its own top-level subtest, one function per
# nested subtest.  Collaborators outside the function under test are replaced
# with Test::Mockingbird so that a failure points at one function and nothing
# touches the network, sendmail or the real configuration directories.
#
# Most of these tests are negative: they feed hostile, malformed or
# exhausting input, or force a collaborator to fail mid-flight, and check that
# the code refuses cleanly with the exact message it promises.

use strict;
use warnings;

# time() and sleep() are overridden before any module under test is compiled,
# so that throttle windows and cache lifetimes can be moved without waiting,
# and so that the deliberate sleep(1) on a throttled request costs nothing
our ($FAKE_TIME, @SLEEPS);
BEGIN {
	*CORE::GLOBAL::time = sub () { defined($FAKE_TIME) ? $FAKE_TIME : CORE::time() };
	*CORE::GLOBAL::sleep = sub (;$) { push @SLEEPS, $_[0]; return $_[0] // 0 };
}

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;

use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use POSIX qw(strftime);
use Readonly;
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

# Loaded up front: the code under test require()s these at run time, and a
# mock installed before the first require would be overwritten by it
use CGI::IDS ();
use CHI ();
use Data::Throttler ();
use Data::Validate::URI ();
use DateTime ();
use DBI ();
use HTTP::Response ();
use JSON::MaybeXS qw(encode_json);
use LWP::Simple::WithCache ();
use LWP::UserAgent ();
use XML::LibXML ();
use YAML ();

use Web::VWF;
use Web::VWF::Allow;
use Web::VWF::Blacklist;
use Web::VWF::CAPTCHA;
use Web::VWF::Config;
use Web::VWF::Data::index;
use Web::VWF::Data::vwf_log;
use Web::VWF::Display;
use Web::VWF::Display::captcha;
use Web::VWF::Display::index;
use Web::VWF::Display::meta_data;
use Web::VWF::Display::table;
use Web::VWF::Throttle;
use Web::VWF::Utils;

# ---------------------------------------------------------------------------
# Fixed values shared by the tests.  Addresses come from the documentation
# ranges (RFC 5737) so that nothing here can be mistaken for a real client.
# ---------------------------------------------------------------------------
Readonly my %CONFIG => (
	client_ip => '203.0.113.7',
	private_ip => '192.168.1.20',
	other_ip => '198.51.100.250',
	domain => 'example.com',
	blocked_country => 'CN',
	allowed_country => 'GB',
	csrf_secret => 'function-test-secret',
	default_vwf_directory => '/usr/lib/vwf',
	throttle_max_items => 30,
	throttle_interval => 90,
	status_ttl => 300,
	ids_block_impact => 31,		# Allow blocks above 30
	ids_warn_impact => 10,
	display_ids_threshold => 50,	# Display blocks above 50
	hex_md5_length => 32,
	hex_sha256_length => 64,
	london => [51.5074, -0.1278],
	paris => [48.8566, 2.3522],
	london_paris_km => 343.5,
	distance_tolerance => 1.5,
	max_valid_port => 65535,
	mail_limit => 2,
	slow_min_samples => 5,
	slow_top_n => 10,
	seconds_per_minute => 60,
	cache_duration => '5 minutes',
	dshield_duration => '1 day',
);

# Only talk when asked to: the internal state is noise on a passing run
sub explain_state
{
	my ($label, @things) = @_;

	return unless $ENV{'TEST_VERBOSE'};
	diag($label, ': ', explain(@things));
}

# Error::Simple appends " at FILE line N." to its text, so compare ->text
# to get an exact match on the message itself
sub error_text_is
{
	my ($code, $expected, $name) = @_;

	my $ok = eval { $code->(); 1 };
	my $err = $@;
	if($ok) {
		fail("$name (no exception)");
		return;
	}
	if(blessed($err) && $err->isa('Error')) {
		is($err->text(), $expected, $name);
	} else {
		fail("$name (not an Error object: $err)");
	}
	return $err;
}

# As error_text_is, for messages that include run-time details such as paths
sub error_text_like
{
	my ($code, $expected, $name) = @_;

	my $ok = eval { $code->(); 1 };
	my $err = $@;
	if($ok) {
		fail("$name (no exception)");
	} elsif(blessed($err) && $err->isa('Error')) {
		like($err->text(), $expected, $name);
	} else {
		fail("$name (not an Error object: $err)");
	}
	return;
}

# Anchor a croak/die message at the start and allow the location after it
sub croaks_with
{
	my ($code, $expected, $name) = @_;

	throws_ok { $code->() } qr/\A\Q$expected\E(?: at \S+ line \d+\.?)?\n?/, $name;
}

# ---------------------------------------------------------------------------
# Stand-ins for the objects the framework is handed at run time
# ---------------------------------------------------------------------------

# A logger that records what it is told, level by level
package Local::Logger {
	sub new { return bless { messages => [] }, shift }

	foreach my $level (qw(trace debug info notice warn error)) {
		no strict 'refs';
		*{$level} = sub {
			my $self = shift;
			my $text = join('', map { ref($_) eq 'HASH' ? ($_->{'message'} // '') : ($_ // '') } @_);
			push @{$self->{'messages'}}, [$level, $text];
			return;
		};
	}

	sub messages
	{
		my ($self, $level) = @_;
		return [ map { $_->[1] } grep { !defined($level) || ($_->[0] eq $level) } @{$self->{'messages'}} ];
	}
}

# CGI::Info, reduced to whatever values a test puts in it
package Local::Info {
	our $AUTOLOAD;

	sub new
	{
		my ($class, %args) = @_;
		return bless {
			domain_name => $CONFIG{'domain'},
			is_search_engine => 0,
			is_mobile => 0,
			is_ai => 0,
			is_robot => 0,
			baidu => 0,
			protocol => 'http',
			script_name => '/cgi-bin/page.fcgi',
			as_string => 'page=index',
			status_calls => [],
			cookies => {},
			%args,
		}, $class;
	}

	sub status { my ($self, $code) = @_; push @{$self->{'status_calls'}}, $code if(defined($code)); return $code }
	sub get_cookie { my ($self, %args) = @_; return $self->{'cookies'}{$args{'cookie_name'}} }
	sub params { return $_[0]->{'params'} }
	sub param { my ($self, $key) = @_; return $self->{'params'} ? $self->{'params'}{$key} : undef }

	sub AUTOLOAD
	{
		my $self = shift;
		(my $name = $AUTOLOAD) =~ s/.*:://;
		return if($name eq 'DESTROY');
		my $value = $self->{$name};
		return (ref($value) eq 'CODE') ? $value->($self, @_) : $value;
	}
}

package Local::Lingua {
	sub new { my ($class, %args) = @_; return bless { %args }, $class }
	sub country { return $_[0]->{'country'} }
	sub language_code_alpha2 { return $_[0]->{'language'} }
	sub sublanguage_code_alpha2 { return $_[0]->{'dialect'} }
	sub requested_language { return $_[0]->{'requested'} // 'English' }
}

# A CHI-like cache held in a plain hash, recording how it was used
package Local::Cache {
	sub new { my ($class, %data) = @_; return bless { data => { %data }, sets => [], removed => [] }, $class }
	sub get { return $_[0]->{'data'}{$_[1]} }
	sub set { my ($self, $k, $v, $d) = @_; push @{$self->{'sets'}}, [$k, $v, $d]; $self->{'data'}{$k} = $v; return $v }
	sub remove { my ($self, $k) = @_; push @{$self->{'removed'}}, $k; delete $self->{'data'}{$k}; return }
}

package Local::Throttler {
	sub new { my ($class, $allow) = @_; return bless { allow => $allow, pushes => [] }, $class }
	sub try_push { my ($self, %args) = @_; push @{$self->{'pushes'}}, $args{'key'}; return $self->{'allow'} }
}

package Local::IDS {
	our $IMPACT = 0;
	sub new { return bless {}, shift }
	sub set_scan_keys { return 1 }
	sub detect_attacks { my ($self, %args) = @_; $self->{'request'} = $args{'request'}; return $IMPACT }
	sub get_attacks { return [] }
}

package Local::ConfigAbstraction {
	our ($DATA, @NEW_ARGS);
	# A fresh copy each time, as a real reader builds a new hash per call
	sub all { return (ref($DATA) eq 'HASH') ? { %{$DATA} } : $DATA }
}

package Local::SocialMedia {
	sub as_string { my ($self, %args) = @_; return 'button:' . join(',', sort keys %args) }
}

package main;

# Every subtest starts with no mocks left over from the one before
sub fresh
{
	restore_all();
	@SLEEPS = ();
	$FAKE_TIME = undef;
	$Local::IDS::IMPACT = 0;
	return;
}

# Route CGI::IDS through Local::IDS
sub mock_ids
{
	mock 'CGI::IDS::new' => sub { return Local::IDS->new() };
	mock 'CGI::IDS::set_scan_keys' => sub { return 1 };
	return;
}

# Route Config::Abstraction through Local::ConfigAbstraction
sub mock_config_abstraction
{
	my ($data) = @_;

	$Local::ConfigAbstraction::DATA = $data;
	@Local::ConfigAbstraction::NEW_ARGS = ();
	mock 'Config::Abstraction::new' => sub {
		my ($class, %args) = @_;
		push @Local::ConfigAbstraction::NEW_ARGS, \%args;
		return bless {}, 'Local::ConfigAbstraction';
	};
	return;
}

# Capture whatever is printed to STDOUT while running $code
sub capture_stdout
{
	my ($code) = @_;

	my $buffer = '';
	{
		local *STDOUT;
		open(STDOUT, '>', \$buffer) or die "Can't capture STDOUT: $!";
		$code->();
		close(STDOUT);
	}
	return $buffer;
}

# A Display object built by hand, for testing methods without new()
sub make_display
{
	my (%args) = @_;

	my $info = delete $args{'info'} // Local::Info->new();
	my $config = delete $args{'config'} // { security => { csrf => { secret => $CONFIG{'csrf_secret'} } } };
	my $class = delete $args{'class'} // 'Web::VWF::Display';
	return bless {
		info => $info,
		_info => $info,
		config => $config,
		_config => $config,
		%args,
	}, $class;
}

# ===========================================================================
subtest 'Web::VWF::Blacklist' => sub {
	fresh();

	subtest 'new - default list' => sub {
		# Without configuration the built-in list applies, and every entry
		# must come back normalised to upper case and sorted
		my $bl = Web::VWF::Blacklist->new();
		isa_ok($bl, 'Web::VWF::Blacklist');
		my $countries = $bl->countries();
		returns_ok($countries, { type => 'arrayref' }, 'countries() returns an arrayref');
		is_deeply($countries, [sort qw(BY MD RU CN BR UY TR MA VE SA CY CO MX IN RS PK UA XH)], 'built-in list');
		memory_cycle_ok($bl, 'no cycles in a default blacklist');
		explain_state('default blacklist', $bl);
	};

	subtest 'new - string and arrayref forms' => sub {
		# Configuration files give either a list or "CN, RU": both must give
		# the same, case-normalised result
		is_deeply(Web::VWF::Blacklist->new(countries => 'ru, cn')->countries(), ['CN', 'RU'], 'comma/space string');
		is_deeply(Web::VWF::Blacklist->new({ countries => ['ru', 'Cn'] })->countries(), ['CN', 'RU'], 'arrayref, hashref call style');
		is_deeply(Web::VWF::Blacklist->new(countries => ['CN', 'cn', 'Cn'])->countries(), ['CN'], 'duplicates collapse');
		is_deeply(Web::VWF::Blacklist->new(countries => [])->countries(), [], 'explicitly empty list blocks nobody');
		is_deeply(Web::VWF::Blacklist->new(countries => ',, ,')->countries(), [], 'separators only blocks nobody');
	};

	subtest 'new - hostile entries are refused' => sub {
		# A bad entry must stop construction rather than be silently dropped,
		# or a typo in the configuration would quietly unblock a country
		foreach my $bad ('CHN', 'C', '1A', 'C-', "CN\n", "C\x{c7}", 'C N') {
			(my $printable = $bad) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;
			croaks_with(sub { Web::VWF::Blacklist->new(countries => [$bad]) },
				"Invalid country code '$bad' in the blacklist", "rejects '$printable'");
		}
		croaks_with(sub { Web::VWF::Blacklist->new(countries => 'CN, RUS') },
			"Invalid country code 'RUS' in the blacklist", 'one bad entry in a string spoils it');
		throws_ok { Web::VWF::Blacklist->new(countries => { CN => 1 }) } qr/countries/, 'hashref refused by the schema';
		throws_ok { Web::VWF::Blacklist->new(countries => \'CN') } qr/countries/, 'scalar ref refused by the schema';
		throws_ok { Web::VWF::Blacklist->new(bogus => 1) } qr/bogus/, 'unknown parameter refused';
	};

	subtest 'new - validation failure propagates' => sub {
		# If the validator itself fails, construction must fail with it
		# rather than fall back to some default list
		mock_exception 'Params::Validate::Strict::validate_strict' => 'validator broke';
		throws_ok { Web::VWF::Blacklist->new() } qr/\Avalidator broke/, 'validator exception is not swallowed';
		restore_all();

		my $spy = spy 'Params::Validate::Strict::validate_strict';
		Web::VWF::Blacklist->new(countries => 'CN');
		cmp_ok(scalar($spy->()), '>=', 1, 'every construction is validated');
		restore_all();
	};

	subtest 'is_blocked' => sub {
		my $bl = Web::VWF::Blacklist->new(countries => ['CN']);
		returns_is($bl->is_blocked('CN'), { type => 'integer', min => 1, max => 1 }, 'blocked returns 1');
		is($bl->is_blocked('cn'), 1, 'case-insensitive');
		returns_is($bl->is_blocked('GB'), { type => 'integer', min => 0, max => 0 }, 'other country returns 0');

		# GeoIP failing to place a client must never lock everyone out
		is($bl->is_blocked(undef), 0, 'undef is never blocked');
		is($bl->is_blocked(''), 0, 'empty string is never blocked');

		# Near misses must not match by prefix or by accident
		is($bl->is_blocked('CNX'), 0, 'longer code does not match');
		is($bl->is_blocked('C'), 0, 'shorter code does not match');
		is($bl->is_blocked(" CN"), 0, 'padded code does not match');
		is($bl->is_blocked('blocked'), 0, 'internal key name is not a country');
	};

	subtest 'objects are independent' => sub {
		# Each object owns its list, so one site cannot change another's
		my $one = Web::VWF::Blacklist->new(countries => ['CN']);
		my $two = Web::VWF::Blacklist->new(countries => ['RU']);
		is($one->is_blocked('RU'), 0, 'first object unaffected by second');
		is($two->is_blocked('CN'), 0, 'second object unaffected by first');
	};

	subtest 'countries - returns a copy' => sub {
		# A caller editing the returned list must not change what is blocked
		my $bl = Web::VWF::Blacklist->new(countries => ['CN']);
		my $list = $bl->countries();
		push @{$list}, 'GB';
		@{$list} = ();
		is_deeply($bl->countries(), ['CN'], 'internal list untouched');
		is($bl->is_blocked('GB'), 0, 'adding to the copy blocks nothing');
	};
};

# ===========================================================================
subtest 'Web::VWF::Throttle (Data::Throttler::Backend::VWF)' => sub {
	fresh();
	my $class = 'Data::Throttler::Backend::VWF';
	my $dir = tempdir(CLEANUP => 1);

	# A store whose chain carries the parameters Data::Throttler compares
	my $good_store = {
		chain => { max_items => $CONFIG{'throttle_max_items'}, interval => $CONFIG{'throttle_interval'}, buckets => [] },
	};

	# Open a store file the way Data::Throttler::Backend::YAML::lock() does
	my $open_store = sub {
		my ($name, $content) = @_;
		my $file = File::Spec->catfile($dir, $name);
		open(my $out, '>', $file) or die "$file: $!";
		print $out $content;
		close($out);
		open(my $fh, '+<', $file) or die "$file: $!";
		return ($file, bless({ db_file => $file, fh => $fh }, $class));
	};

	subtest '_chain_is_usable' => sub {
		my $usable = bless({ max_items => 1, interval => 1 }, 'Data::Throttler::BucketChain');
		ok($class->_chain_is_usable($usable), 'bucket chain with both parameters');

		# Each of these would make Data::Throttler compare undef values and
		# warn, so each must be reported as unusable
		ok(!$class->_chain_is_usable(undef), 'undef');
		ok(!$class->_chain_is_usable({ max_items => 1, interval => 1 }), 'unblessed hash');
		ok(!$class->_chain_is_usable(bless({}, 'Data::Throttler::BucketChain')), 'empty chain: {}');
		ok(!$class->_chain_is_usable(bless({ max_items => 1 }, 'Data::Throttler::BucketChain')), 'interval missing');
		ok(!$class->_chain_is_usable(bless({ interval => 1 }, 'Data::Throttler::BucketChain')), 'max_items missing');
		ok(!$class->_chain_is_usable(bless({ max_items => 1, interval => 1 }, 'Some::Other::Class')), 'wrong class');
		ok(!$class->_chain_is_usable('Data::Throttler::BucketChain'), 'class name as a string');
		ok(!$class->_chain_is_usable([1, 1]), 'arrayref');
	};

	subtest 'load - before the store is locked' => sub {
		# With no handle yet the parent's by-name read is the only option
		mock 'Data::Throttler::Backend::YAML::load' => sub { return { from => 'parent' } };
		my $backend = bless({ db_file => File::Spec->catfile($dir, 'none') }, $class);
		is_deeply($backend->load(), { from => 'parent' }, 'falls back to the parent');
		restore_all();
	};

	subtest 'load - through the locked handle' => sub {
		my (undef, $backend) = $open_store->('good', YAML::Dump($good_store));

		# Nothing may be read through a second handle, so the parent must
		# not be called at all
		mock 'Data::Throttler::Backend::YAML::load' => sub { die 'parent load must not be used' };
		local $/ = "\n";
		local $_ = 'sentinel';
		my $data = $backend->load();
		returns_ok($data, { type => 'hashref' }, 'returns a hashref');
		isa_ok($data->{'chain'}, 'Data::Throttler::BucketChain', 'chain blessed back');
		is($data->{'chain'}{'max_items'}, $CONFIG{'throttle_max_items'}, 'chain parameters kept');
		is($/, "\n", 'input record separator restored');
		is($_, 'sentinel', '$_ untouched');
		restore_all();
	};

	subtest 'load - unusable stores are healed, not fatal' => sub {
		# Garbage, the wrong shape, an empty file and a chain without its
		# parameters must all come back as a store with no chain, so that
		# Data::Throttler rebuilds it rather than dying or warning
		my %cases = (
			garbage => "::: not yaml [\n\t- {",
			list => YAML::Dump([1, 2, 3]),
			scalar => YAML::Dump('just a string'),
			empty => '',
			empty_chain => YAML::Dump({ chain => {} }),
			half_chain => YAML::Dump({ chain => { max_items => 1 } }),
		);
		foreach my $name (sort keys %cases) {
			my (undef, $backend) = $open_store->($name, $cases{$name});
			my $data;
			warnings_are { $data = $backend->load() } [], "$name: no warnings";
			returns_ok($data, { type => 'hashref' }, "$name: still a hashref");
			ok(!exists($data->{'chain'}), "$name: no chain, so it will be rebuilt");
			explain_state("load($name)", $data);
		}
	};

	subtest 'load - a handle that cannot seek' => sub {
		# A broken handle must not be read from at an unknown position
		my (undef, $backend) = $open_store->('closed', YAML::Dump($good_store));
		close($backend->{'fh'});
		mock 'Data::Throttler::Backend::YAML::load' => sub { return { from => 'parent' } };
		my $data;
		{
			no warnings 'closed';
			local $SIG{__WARN__} = sub { };
			$data = $backend->load();
		}
		is_deeply($data, { from => 'parent' }, 'falls back to the parent');
		restore_all();
	};

	subtest 'save - before the store is locked' => sub {
		my @saved;
		mock 'Data::Throttler::Backend::YAML::save' => sub { push @saved, $_[1]; return 1 };
		my $backend = bless({ db_file => File::Spec->catfile($dir, 'none') }, $class);
		$backend->save({ a => 1 });
		is_deeply(\@saved, [{ a => 1 }], 'parent save used');
		restore_all();
	};

	subtest 'save - through the locked handle' => sub {
		# Start with more data than will be written, so a missing truncate
		# would leave stale YAML on the end of the file
		my ($file, $backend) = $open_store->('rewrite', YAML::Dump({ padding => 'x' x 4096 }));
		mock 'Data::Throttler::Backend::YAML::save' => sub { die 'parent save must not be used' };
		is($backend->save($good_store), 1, 'returns true');
		restore_all();
		close($backend->{'fh'});
		my $written = YAML::LoadFile($file);
		is_deeply($written, $good_store, 'file holds exactly the new store');
	};

	subtest 'save - failures are fatal and say why' => sub {
		# A write that cannot happen must not be reported as a success
		my ($file) = $open_store->('readonly', 'x');
		open(my $ro, '<', $file) or die "$file: $!";
		my $backend = bless({ db_file => $file, fh => $ro }, $class);
		throws_ok { $backend->save($good_store) } qr/\ACan't (?:truncate|write) \Q$file\E: /, 'read-only handle refused';
	};

	subtest 'backend_store_ok' => sub {
		my $missing = bless({ db_file => File::Spec->catfile($dir, 'does-not-exist') }, $class);
		is($missing->backend_store_ok(), 1, 'no store yet: fine, it will be created');

		my (undef, $good) = $open_store->('ok-good', YAML::Dump($good_store));
		ok($good->backend_store_ok(), 'usable store');

		my (undef, $bad) = $open_store->('ok-bad', "::: [");
		ok(!$bad->backend_store_ok(), 'unparsable store must be rebuilt');

		my (undef, $empty) = $open_store->('ok-empty', YAML::Dump({ chain => {} }));
		ok(!$empty->backend_store_ok(), 'chain without parameters must be rebuilt');

		# A load that blows up mid-flight must not take the request down
		my (undef, $dies) = $open_store->('ok-dies', YAML::Dump($good_store));
		mock "${class}::load" => sub { die "disk on fire\n" };
		is($dies->backend_store_ok(), 0, 'exception from load() reported as unusable');
		restore_all();
	};

	subtest 'works as a Data::Throttler backend' => sub {
		# The whole point: the limit is enforced through this backend
		my $file = File::Spec->catfile($dir, 'live');
		my $throttler = Data::Throttler->new(
			max_items => 2,
			interval => $CONFIG{'throttle_interval'},
			backend => 'VWF',
			backend_options => { db_file => $file },
		);
		ok($throttler->try_push(key => $CONFIG{'client_ip'}), 'first request allowed');
		ok($throttler->try_push(key => $CONFIG{'client_ip'}), 'second request allowed');
		ok(!$throttler->try_push(key => $CONFIG{'client_ip'}), 'third request throttled');
		ok($throttler->try_push(key => $CONFIG{'other_ip'}), 'other clients unaffected');
		ok(-s $file, 'store written');
	};
};

# ===========================================================================
subtest 'Web::VWF::Utils' => sub {
	fresh();

	subtest 'create_disc_cache / create_memory_cache' => sub {
		# Both are thin wrappers: each must pass its own cache type and the
		# caller's arguments, whichever calling style was used
		my @calls;
		mock 'Web::VWF::Utils::_create_cache' => sub { push @calls, [@_]; return 'cache' };
		is(Web::VWF::Utils::create_disc_cache(config => { a => 1 }), 'cache', 'disc returns the cache');
		is(Web::VWF::Utils::create_memory_cache({ config => { b => 2 } }), 'cache', 'memory returns the cache');
		is_deeply(\@calls, [
			['disc_cache', { config => { a => 1 } }],
			['memory_cache', { config => { b => 2 } }],
		], 'cache type and arguments passed through');
		restore_all();
	};

	subtest 'create_* - config is not optional' => sub {
		error_text_is(sub { Web::VWF::Utils::create_memory_cache(logger => Local::Logger->new()) },
			'config is not optional', 'memory cache without config');
		error_text_is(sub { Web::VWF::Utils::create_disc_cache(config => undef) },
			'config is not optional', 'disc cache with undef config');
		error_text_is(sub { Web::VWF::Utils::create_disc_cache(config => '') },
			'config is not optional', 'disc cache with empty config');
	};

	subtest '_create_cache - real memory cache' => sub {
		my $cache = Web::VWF::Utils::_create_cache('memory_cache', { config => {}, namespace => 'function-test' });
		returns_ok($cache, { type => 'object', isa => 'CHI::Driver' }, 'returns a CHI driver');
		$cache->set('k', 'v');
		is($cache->get('k'), 'v', 'cache works');
	};

	subtest '_create_cache - unavailable driver falls back' => sub {
		# A configured driver that is not installed must not stop the site
		my $logger = Local::Logger->new();
		mock 'Web::VWF::Utils::_is_driver_available' => sub { return 0 };
		my $cache = Web::VWF::Utils::_create_cache('memory_cache', { config => { memory_cache => { driver => 'Redis' } }, logger => $logger });
		isa_ok($cache, 'CHI::Driver');
		like($logger->messages('warn')->[0], qr/\ACHI driver Redis not available, falling back to Memory\z/, 'fallback logged');
		restore_all();
	};

	subtest '_create_cache - CHI failure is reported' => sub {
		# CHI dying mid-construction must surface as a clear error, logged
		my $logger = Local::Logger->new();
		mock 'CHI::new' => sub { die "no shared memory\n" };
		error_text_is(sub { Web::VWF::Utils::_create_cache('memory_cache', { config => {}, logger => $logger }) },
			"Failed to create memory_cache cache with driver Memory: no shared memory\n", 'exception text');
		is(scalar(@{$logger->messages('error')}), 1, 'error logged once');
		restore_all();
	};

	subtest '_validate_cache_config' => sub {
		lives_ok { Web::VWF::Utils::_validate_cache_config({}, 'disc_cache') } 'absent section is fine';
		lives_ok { Web::VWF::Utils::_validate_cache_config({ disc_cache => { driver => 'File', port => 80, shm_size => 1, max_size => 1 } }, 'disc_cache') } 'valid section';

		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ disc_cache => 'File' }, 'disc_cache') },
			'Cache configuration must be a hash reference', 'string section');
		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ disc_cache => [] }, 'disc_cache') },
			'Cache configuration must be a hash reference', 'array section');
		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ disc_cache => { driver => 'Evil' } }, 'disc_cache') },
			"Invalid driver 'Evil'. Valid drivers: Memory, BerkeleyDB, DBI, Redis, Memcached, SharedMem, File, Null", 'unknown driver');
		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ disc_cache => { driver => 'memory' } }, 'disc_cache') },
			"Invalid driver 'memory'. Valid drivers: Memory, BerkeleyDB, DBI, Redis, Memcached, SharedMem, File, Null", 'driver names are case-sensitive');

		# Every way a number can be wrong, including a trailing newline that
		# a careless /^\d+$/ would let through
		foreach my $param (qw(port shm_size max_size)) {
			foreach my $bad (undef, '', 0, -1, '1.5', '80abc', 'abc', "80\n", ' 80', '0x50') {
				my $label = defined($bad) ? "'$bad'" : 'undef';
				$label =~ s/\n/\\n/g;
				croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ c => { $param => $bad } }, 'c') },
					"$param must be a positive integer", "$param $label refused");
			}
		}
		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ c => { port => $CONFIG{'max_valid_port'} + 1 } }, 'c') },
			'Port must be between 1 and 65535', 'port out of range');
		lives_ok { Web::VWF::Utils::_validate_cache_config({ c => { port => $CONFIG{'max_valid_port'} } }, 'c') } 'highest port allowed';
		croaks_with(sub { Web::VWF::Utils::_validate_cache_config({ c => { driver => 'Memory', global => 1, datastore => {} } }, 'c') },
			'Memory cache cannot have both global and datastore', 'global and datastore together');
	};

	subtest '_get_default_driver / _get_fallback_driver' => sub {
		local $ENV{'TEST_DISC_CACHE_DRIVER'};
		local $ENV{'TEST_MEMORY_CACHE_DRIVER'};
		is(Web::VWF::Utils::_get_default_driver('disc_cache', undef), 'BerkeleyDB', 'disc default');
		is(Web::VWF::Utils::_get_default_driver('memory_cache', undef), 'Memory', 'memory default');
		$ENV{'TEST_DISC_CACHE_DRIVER'} = 'Null';
		is(Web::VWF::Utils::_get_default_driver('disc_cache', undef), 'Null', 'environment override');
		$ENV{'TEST_DISC_CACHE_DRIVER'} = '';
		is(Web::VWF::Utils::_get_default_driver('disc_cache', undef), 'BerkeleyDB', 'empty override ignored');
		is(Web::VWF::Utils::_get_fallback_driver('disc_cache'), 'File', 'disc fallback');
		is(Web::VWF::Utils::_get_fallback_driver('memory_cache'), 'Memory', 'memory fallback');
		is(Web::VWF::Utils::_get_fallback_driver('anything else'), 'Memory', 'unknown type falls back to memory');
	};

	subtest '_is_driver_available' => sub {
		is(Web::VWF::Utils::_is_driver_available('Memory'), 1, 'Memory is built in');
		is(Web::VWF::Utils::_is_driver_available('Null'), 1, 'Null is built in');
		is(Web::VWF::Utils::_is_driver_available('File'), 1, 'File ships with CHI');

		# A driver whose module cannot be loaded must be reported missing,
		# not crash the caller
		SKIP: {
			skip('CHI::Driver::Memcached is installed', 1) if(CHI::Driver::Memcached->can('new'));
			mock 'Web::VWF::Utils::require_module' => sub { die "Can't locate CHI/Driver/Memcached.pm\n" };
			is(Web::VWF::Utils::_is_driver_available('Memcached'), 0, 'unloadable driver reported missing');
			restore_all();
		}

		# The anchored match must not accept a name that merely contains one
		mock 'Web::VWF::Utils::require_module' => sub { die 'should not get here' };
		is(Web::VWF::Utils::_is_driver_available('MemoryX'), 1, 'unlisted names are left to the validator');
		restore_all();
	};

	subtest '_build_chi_args' => sub {
		my $logger = Local::Logger->new();
		my %args = Web::VWF::Utils::_build_chi_args('Null', {}, {}, undef, 'memory_cache');
		is($args{'namespace'}, 'default', 'default namespace');
		is($args{'on_get_error'}, 'warn', 'no logger: warn on get errors');
		is($args{'on_set_error'}, 'die', 'no logger: die on set errors');

		%args = Web::VWF::Utils::_build_chi_args('Null', {}, { namespace => 'ns' }, $logger, 'memory_cache');
		is($args{'namespace'}, 'ns', 'caller namespace');
		$args{'on_get_error'}->('get went wrong');
		$args{'on_set_error'}->('set went wrong');
		is_deeply($logger->messages('warn'), ['Cache get error: get went wrong'], 'get errors logged as warnings');
		is_deeply($logger->messages('error'), ['Cache set error: set went wrong'], 'set errors logged as errors');

		# Each driver must reach its own configuration routine and no other
		my %route = (Redis => '_configure_redis', DBI => '_configure_dbi', SharedMem => '_configure_shared_memory',
			Memory => '_configure_memory', Memcached => '_configure_memcached', File => '_configure_file_based');
		foreach my $driver (sort keys %route) {
			my @called;
			foreach my $routine (values %route) {
				mock "Web::VWF::Utils::$routine" => sub { push @called, $routine };
			}
			Web::VWF::Utils::_build_chi_args($driver, {}, {}, undef, 'c');
			is_deeply(\@called, [$route{$driver}], "$driver routed to $route{$driver}");
			restore_all();
		}
		my @called;
		mock "Web::VWF::Utils::$_" => sub { push @called, 1 } foreach values %route;
		Web::VWF::Utils::_build_chi_args('Null', {}, {}, undef, 'c');
		is(scalar(@called), 0, 'Null needs no configuration');
		restore_all();
	};

	subtest '_configure_redis' => sub {
		my %chi;
		Web::VWF::Utils::_configure_redis(\%chi, { server => 'a:1, b:2', redis_options => { every => 5 } }, {}, undef);
		is_deeply($chi{'servers'}, ['a:1', 'b:2'], 'servers parsed and trimmed');
		is($chi{'server'}, 'a:1', 'first server is primary');
		is_deeply($chi{'redis_options'}, { reconnect => 60, every => 5, encoding => 'utf8' }, 'defaults with caller override');

		%chi = ();
		Web::VWF::Utils::_configure_redis(\%chi, {}, {}, undef);
		ok(!exists($chi{'servers'}), 'no servers configured, none invented');
		throws_ok { Web::VWF::Utils::_configure_redis({}, { server => 'evil host:1' }, {}, undef) }
			qr/\AInvalid server format: 'evil host:1' \(expected host:port\)/, 'bad server propagates';
	};

	subtest '_configure_dbi' => sub {
		croaks_with(sub { Web::VWF::Utils::_configure_dbi({}, {}, {}, undef) },
			"DBI driver requires 'connect' parameter", 'connect string required');

		# A database that cannot be reached must be logged and fatal
		my $logger = Local::Logger->new();
		mock 'DBI::connect' => sub { die "connection refused\n" };
		throws_ok { Web::VWF::Utils::_configure_dbi({ namespace => 'x' }, { connect => 'dbi:Nope:' }, {}, $logger) }
			qr/\AFailed to connect to database: connection refused/, 'connect failure';
		like($logger->messages('error')->[0], qr/\AFailed to connect to database: connection refused/, 'failure logged');
		restore_all();

		# Table names come from the namespace, so punctuation must go
		mock 'DBI::connect' => sub { return bless({}, 'Local::DBH') };
		my %chi = (namespace => 'Web::VWF::Allow; DROP TABLE x');
		Web::VWF::Utils::_configure_dbi(\%chi, { connect => 'dbi:SQLite::memory:' }, {}, undef);
		is($chi{'namespace'}, 'Web__VWF__Allow__DROP_TABLE_x', 'namespace reduced to word characters');
		isa_ok($chi{'dbh'}, 'Local::DBH');
		is($chi{'create_table'}, 1, 'tables created by default');
		%chi = (namespace => 'n');
		Web::VWF::Utils::_configure_dbi(\%chi, { connect => 'dbi:SQLite::memory:', create_table => 0 }, {}, undef);
		is($chi{'create_table'}, 0, 'create_table => 0 respected, not defaulted');
		restore_all();
	};

	subtest '_configure_shared_memory' => sub {
		croaks_with(sub { Web::VWF::Utils::_configure_shared_memory({}, {}, {}) },
			"SharedMem driver requires 'shm_key' parameter", 'shm_key required');
		my %chi;
		Web::VWF::Utils::_configure_shared_memory(\%chi, { shm_key => 1 }, {});
		is_deeply(\%chi, { shm_key => 1, shm_size => 16 * 1024, max_size => 1024 }, 'defaults');
		%chi = ();
		Web::VWF::Utils::_configure_shared_memory(\%chi, { shm_key => 1, shm_size => 2 }, { shm_key => 9, max_size => 3 });
		is_deeply(\%chi, { shm_key => 9, shm_size => 2, max_size => 3 }, 'arguments beat configuration');
	};

	subtest '_configure_memory' => sub {
		my %chi;
		Web::VWF::Utils::_configure_memory(\%chi, {});
		is_deeply(\%chi, { datastore => {} }, 'private datastore by default');
		%chi = ();
		Web::VWF::Utils::_configure_memory(\%chi, { global => 0 });
		is_deeply(\%chi, { global => 0 }, 'global respected even when false');
	};

	subtest '_configure_memcached' => sub {
		my $logger = Local::Logger->new();
		my %chi;
		Web::VWF::Utils::_configure_memcached(\%chi, {}, {}, $logger);
		is_deeply($chi{'servers'}, ['127.0.0.1:11211'], 'localhost by default');
		like($logger->messages('debug')->[0], qr/default Memcached server/, 'default logged');
		%chi = ();
		Web::VWF::Utils::_configure_memcached(\%chi, { host => 'cache', port => 1 }, {}, undef);
		is_deeply($chi{'servers'}, ['cache:1'], 'host and port combined');
	};

	subtest '_configure_file_based' => sub {
		local $ENV{'root_dir'};
		my $dir = tempdir(CLEANUP => 1);
		croaks_with(sub { Web::VWF::Utils::_configure_file_based({}, {}, { config => {} }) },
			"File-based cache drivers require 'root_dir' parameter", 'root_dir required');
		my $nowhere = File::Spec->catdir($dir, 'nowhere');
		croaks_with(sub { Web::VWF::Utils::_configure_file_based({}, { root_dir => $nowhere }, {}) },
			"Root directory '$nowhere' does not exist or is not writable", 'missing directory');

		my %chi;
		Web::VWF::Utils::_configure_file_based(\%chi, { root_dir => $nowhere }, { root_dir => $dir });
		is($chi{'root_dir'}, $dir, 'argument beats configuration');
		%chi = ();
		Web::VWF::Utils::_configure_file_based(\%chi, {}, { config => { root_dir => $dir } });
		is($chi{'root_dir'}, $dir, 'falls back to the top-level configuration');
		$ENV{'root_dir'} = $dir;
		%chi = ();
		Web::VWF::Utils::_configure_file_based(\%chi, { root_dir => $nowhere }, {});
		is($chi{'root_dir'}, $dir, 'environment beats everything');
	};

	subtest '_parse_server_config' => sub {
		is_deeply([Web::VWF::Utils::_parse_server_config({}, undef)], [], 'nothing configured');
		is_deeply([Web::VWF::Utils::_parse_server_config({ server => ' a:1 ,b.example-2:65535 ' }, undef)],
			['a:1', 'b.example-2:65535'], 'trimmed list');
		is_deeply([Web::VWF::Utils::_parse_server_config({ host => 'a', port => 6379 }, undef)], ['a:6379'], 'default port added');

		croaks_with(sub { Web::VWF::Utils::_parse_server_config({ server => 'a' }, undef) },
			"Port not specified for server 'a'", 'no port anywhere');
		croaks_with(sub { Web::VWF::Utils::_parse_server_config({ server => 'a:0' }, undef) },
			'Invalid port number: 0', 'port zero');
		croaks_with(sub { Web::VWF::Utils::_parse_server_config({ server => 'a:65536' }, undef) },
			'Invalid port number: 65536', 'port too high');

		# Anything that could smuggle extra text into a connection string
		foreach my $bad ('evil host:1', 'a:1;rm -rf /', "a:1\nX-Evil: 1", 'a:b', ':1', 'a:1:2', "a\x{0}:1") {
			(my $printable = $bad) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;
			throws_ok { Web::VWF::Utils::_parse_server_config({ server => $bad, port => 1 }, undef) }
				qr/\AInvalid server format: /, "rejects '$printable'";
		}
		throws_ok { Web::VWF::Utils::_parse_server_config({ server => 'a:1,,b:2' }, undef) }
			qr/\APort not specified for server ''/, 'empty entry in the list is not ignored';
	};

	subtest 'distance - correct answers' => sub {
		my $km = Web::VWF::Utils::distance(@{$CONFIG{'london'}}, @{$CONFIG{'paris'}}, 'K');
		returns_ok($km, { type => 'number', min => 0 }, 'returns a non-negative number');
		cmp_ok(abs($km - $CONFIG{'london_paris_km'}), '<', $CONFIG{'distance_tolerance'}, "London-Paris is about $CONFIG{london_paris_km} km");
		my $miles = Web::VWF::Utils::distance(@{$CONFIG{'london'}}, @{$CONFIG{'paris'}});
		cmp_ok($miles, '<', $km, 'miles by default, and fewer of them than km');
		is(Web::VWF::Utils::distance(@{$CONFIG{'london'}}, @{$CONFIG{'paris'}}, 'k'), $km, 'unit is case-insensitive');
		is(Web::VWF::Utils::distance(@{$CONFIG{'london'}}, @{$CONFIG{'paris'}}, ''), $miles, 'empty unit means miles');
		cmp_ok(Web::VWF::Utils::distance(@{$CONFIG{'london'}}, @{$CONFIG{'paris'}}, 'N'), '<', $miles, 'nautical miles');
		is(Web::VWF::Utils::distance(@{$CONFIG{'paris'}}, @{$CONFIG{'london'}}, 'K'), $km, 'symmetric');
		is(Web::VWF::Utils::distance(1, 2, 1, 2), 0, 'identical points');
		cmp_ok(Web::VWF::Utils::distance(90, 0, 90, 180), '<', 1e-6, 'every longitude meets at the pole');
	};

	subtest 'distance - antipodes never go complex' => sub {
		# Rounding can push the haversine term over 1; asin() would then
		# return a Math::Complex object instead of a number
		foreach my $pair ([0, 0, 0, 180], [45, 10, -45, -170], [33.3, -71.1, -33.3, 108.9], [89.999, 0, -89.999, 180], [12.34, 56.78, -12.34, -123.22]) {
			my $d = Web::VWF::Utils::distance(@{$pair}, 'K');
			ok(!ref($d), "@{$pair}: a plain number");
			cmp_ok($d, '<=', 3.1416 * 6371 + 1, "@{$pair}: no more than half way round");
		}
	};

	subtest 'distance - hostile input' => sub {
		my @args = (1, 2, 3, 4);
		foreach my $i (0 .. 3) {
			my $name = (qw(lat1 lon1 lat2 lon2))[$i];
			my @bad = @args;
			$bad[$i] = undef;
			croaks_with(sub { Web::VWF::Utils::distance(@bad) }, "$name must be defined", "$name undef");
			foreach my $junk ('abc', '', '1; system("id")', 'NaN', '-nan', [1], { 1 => 1 }) {
				@bad = @args;
				$bad[$i] = $junk;
				croaks_with(sub { Web::VWF::Utils::distance(@bad) }, "$name must be numeric", "$name '" . (ref($junk) || $junk) . "'");
			}
		}
		croaks_with(sub { Web::VWF::Utils::distance(90.0001, 0, 0, 0) }, 'Latitude must be between -90 and 90 degrees', 'latitude too high');
		croaks_with(sub { Web::VWF::Utils::distance(0, 0, -91, 0) }, 'Latitude must be between -90 and 90 degrees', 'latitude too low');
		croaks_with(sub { Web::VWF::Utils::distance(0, 180.5, 0, 0) }, 'Longitude must be between -180 and 180 degrees', 'longitude too high');
		croaks_with(sub { Web::VWF::Utils::distance('Inf', 0, 0, 0) }, 'Latitude must be between -90 and 90 degrees', 'infinity');
		croaks_with(sub { Web::VWF::Utils::distance(1, 2, 3, 4, 'X') }, "Unknown unit 'X'. Use 'K', 'N', or 'M'", 'unknown unit');
		croaks_with(sub { Web::VWF::Utils::distance(1, 2, 3, 4, 'KM') }, "Unknown unit 'KM'. Use 'K', 'N', or 'M'", 'unit must be one letter');
		croaks_with(sub { Web::VWF::Utils::distance(1, 2, 3, 4, "K\n") }, "Unknown unit 'K\n'. Use 'K', 'N', or 'M'", 'unit with a newline');

		# A bad unit is a bad call, even when the answer would be zero anyway
		croaks_with(sub { Web::VWF::Utils::distance(1, 2, 1, 2, 'X') }, "Unknown unit 'X'. Use 'K', 'N', or 'M'", 'bad unit on identical points');
	};

	subtest 'helpers leave $_ alone' => sub {
		local $_ = 'sentinel';
		Web::VWF::Utils::_parse_server_config({ server => 'a:1,b:2' }, undef);
		Web::VWF::Utils::_validate_cache_config({ c => { driver => 'Memory', port => 1 } }, 'c');
		Web::VWF::Utils::distance(1, 2, 3, 4);
		is($_, 'sentinel', '$_ unchanged');
	};
};

# ===========================================================================
subtest 'Web::VWF::Config' => sub {
	fresh();
	my $dir = tempdir(CLEANUP => 1);
	my $script_dir = File::Spec->catdir($dir, 'site', 'cgi-bin');

	local $ENV{'CONFIG_DIR'};
	local $ENV{'CONFIG_FILE'};
	local $ENV{'DOCUMENT_ROOT'};
	local $ENV{'HOME'} = $dir;

	my $info = sub { Local::Info->new(script_dir => $script_dir, lang => undef, @_) };

	subtest 'new - merges file, caller and environment values' => sub {
		mock_config_abstraction({ SiteTitle => ['My', 'Site'], Contents => 'c', colour => 'red', size => 'small', nested => 'x' });
		local $ENV{'colour'} = 'blue';
		local $ENV{'nested'} = 'key=value';
		my $config = Web::VWF::Config->new(info => $info->(), config => { size => 'large' });
		returns_ok($config, { type => 'object', isa => 'Web::VWF::Config' }, 'returns a config object');
		is($config->{'SiteTitle'}, 'My Site', 'array fields put back together');
		is($config->{'size'}, 'large', 'caller beats file');
		is($config->{'colour'}, 'blue', 'environment beats file');
		is_deeply($config->{'nested'}, { key => 'value' }, 'key=value in the environment makes a hash');
		memory_cycle_ok($config, 'no cycles');
		explain_state('Config::Abstraction->new args', \@Local::ConfigAbstraction::NEW_ARGS);
		restore_all();
	};

	subtest 'new - search path' => sub {
		mock_config_abstraction({});
		Web::VWF::Config->new(info => $info->());
		my $dirs = $Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'};
		is($dirs->[0], File::Spec->catdir($script_dir, File::Spec->updir(), File::Spec->updir(), 'conf'), 'script-relative first');
		ok((grep { $_ eq File::Spec->catdir($dir, 'lib', 'conf') } @{$dirs}), '$HOME/lib/conf searched');
		ok((grep { $_ eq File::Spec->catdir($dir, 'lib', 'conf', 'default') } @{$dirs}), 'each directory has a default/');
		is_deeply($Local::ConfigAbstraction::NEW_ARGS[0]{'config_files'}, ['default', $CONFIG{'domain'}, undef, undef], 'default then the site');

		@Local::ConfigAbstraction::NEW_ARGS = ();
		Web::VWF::Config->new(info => $info->(), lingua => Local::Lingua->new(language => 'fr'));
		$dirs = $Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'};
		ok((grep { m{/fr\z} } @{$dirs}), 'localised directory added for the language');

		@Local::ConfigAbstraction::NEW_ARGS = ();
		Web::VWF::Config->new(info => $info->(), config_directory => $dir);
		is($Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'}[0], $dir, 'caller directory comes first');
		restore_all();
	};

	subtest 'new - server directory per site' => sub {
		mock_config_abstraction({});
		Web::VWF::Config->new(info => $info->(), directory => $CONFIG{'default_vwf_directory'});
		my $dirs = $Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'};
		my $site = File::Spec->catdir($CONFIG{'default_vwf_directory'}, $CONFIG{'domain'});
		ok((grep { $_ eq $site } @{$dirs}), 'directory/site searched');

		# The site name comes from the Host header: it must never be able to
		# walk out of the server's directory
		foreach my $hostile ('../../etc', '..', 'a/../../b', 'example.com/../../etc', "example.com\n", '', 'exa mple.com') {
			@Local::ConfigAbstraction::NEW_ARGS = ();
			Web::VWF::Config->new(info => $info->(domain_name => $hostile), directory => $CONFIG{'default_vwf_directory'});
			$dirs = $Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'};
			(my $printable = $hostile) =~ s/\n/\\n/g;
			ok(!(grep { index($_, $CONFIG{'default_vwf_directory'}) == 0 } @{$dirs}), "hostile site name '$printable' not used");
		}
		error_text_is(sub { Web::VWF::Config->new(info => $info->(), directory => [$dir]) }, 'directory must be a string', 'directory ref refused');
		restore_all();
	};

	subtest 'new - CONFIG_DIR' => sub {
		mock_config_abstraction({});
		local $ENV{'CONFIG_DIR'} = $dir;
		Web::VWF::Config->new(info => $info->());
		is($Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'}[0], $dir, 'CONFIG_DIR used');
		ok(!(grep { m{/lib/conf} } @{$Local::ConfigAbstraction::NEW_ARGS[0]{'config_dirs'}}), 'and nothing else');
		$ENV{'CONFIG_DIR'} = File::Spec->catdir($dir, 'missing');
		error_text_is(sub { Web::VWF::Config->new(info => $info->()) },
			"CONFIG_DIR '$ENV{CONFIG_DIR}' does not exist or is not readable", 'missing CONFIG_DIR');
		restore_all();
	};

	subtest 'new - hostile arguments' => sub {
		mock_config_abstraction({});
		error_text_is(sub { Web::VWF::Config->new(logger => 'not an object') },
			'logger must be an object with debug method', 'string logger');
		error_text_is(sub { Web::VWF::Config->new(logger => bless({}, 'Local::Nothing')) },
			'logger must be an object with debug method', 'logger without debug()');
		error_text_is(sub { Web::VWF::Config->new(info => $info->(), config => [1]) },
			'config must be a hash reference', 'config arrayref');
		error_text_is(sub { Web::VWF::Config->new(info => $info->(), config => 'x=y') },
			'config must be a hash reference', 'config string');
		error_text_is(sub { Web::VWF::Config->new(info => $info->(), config_directory => { a => 1 }) },
			'config_directory must be a string', 'config_directory ref');
		my $missing = File::Spec->catdir($dir, 'missing');
		error_text_is(sub { Web::VWF::Config->new(info => $info->(), config_directory => $missing) },
			"config_directory '$missing' does not exist", 'config_directory missing');
		restore_all();
	};

	subtest 'new - configuration reader failures' => sub {
		# Whatever goes wrong while reading must come out as one clear error
		mock 'Config::Abstraction::new' => sub { die "parse error at line 3\n" };
		error_text_is(sub { Web::VWF::Config->new(info => $info->()) },
			"Configuration error: parse error at line 3\n", 'reader dies');
		restore_all();

		mock_config_abstraction(undef);
		error_text_is(sub { Web::VWF::Config->new(info => $info->()) }, 'Configuration error: ', 'reader returns nothing');
		restore_all();

		mock_config_abstraction([1, 2]);
		error_text_is(sub { Web::VWF::Config->new(info => $info->()) }, 'Configuration must be a hash reference', 'reader returns a list');
		restore_all();
	};

	subtest 'new - debug logs, but only with a logger' => sub {
		mock_config_abstraction({ a => 1 });
		my $logger = Local::Logger->new();
		local $ENV{'VWF_FUNCTION_TEST'} = 'present';
		Web::VWF::Config->new(info => $info->(), logger => $logger, debug => 1);
		ok((grep { $_ eq 'VWF_FUNCTION_TEST=present' } @{$logger->messages('debug')}), 'environment dumped');
		lives_ok { Web::VWF::Config->new(info => $info->(), debug => 1) } 'debug without a logger';
		restore_all();
	};

	subtest 'AUTOLOAD' => sub {
		my $config = bless { site => 'x', empty => '' }, 'Web::VWF::Config';
		is($config->site(), 'x', 'existing key');
		is($config->empty(), '', 'false value returned as is');
		is($config->missing(), undef, 'missing key is undef');
		ok(!exists($config->{'missing'}), 'and is not created');

		# Called on the class there is no hash, and strict refs must not die
		is(Web::VWF::Config->site(), undef, 'class method returns undef');

		my $bad = 'bad-name';
		croaks_with(sub { $config->$bad() }, 'Web::VWF::Config: Invalid key name: bad-name', 'punctuation in a key');
		$bad = '1abc';
		croaks_with(sub { $config->$bad() }, 'Web::VWF::Config: Invalid key name: 1abc', 'key starting with a digit');
		lives_ok { $config->DESTROY() } 'DESTROY is not a key';
	};
};

# ===========================================================================
subtest 'Web::VWF' => sub {
	fresh();

	subtest 'new' => sub {
		my $vwf = Web::VWF->new(directory => '/etc/vwf', logger => 'l');
		returns_ok($vwf, { type => 'object', isa => 'Web::VWF' }, 'object');
		is($vwf->{'directory'}, '/etc/vwf', 'directory kept');
		is(Web::VWF->new({ directory => '/srv' })->{'directory'}, '/srv', 'hashref style');
		isa_ok($vwf->new(), 'Web::VWF', 'new() on an object');
		memory_cycle_ok($vwf, 'no cycles');

		croaks_with(sub { Web::VWF->new(directory => ['/etc']) }, 'directory must be a string', 'arrayref directory');
		croaks_with(sub { Web::VWF->new(directory => \'/etc') }, 'directory must be a string', 'scalar ref directory');
	};

	subtest 'directory' => sub {
		is(Web::VWF->new(directory => '/etc/vwf')->_directory(), '/etc/vwf', 'given directory');
		is(Web::VWF->new()->_directory(), $CONFIG{'default_vwf_directory'}, 'documented default');
		is(Web::VWF->new(directory => undef)->_directory(), $CONFIG{'default_vwf_directory'}, 'undef means the default');
	};

	subtest 'config' => sub {
		# Read once, with the server directory and the caller's own arguments
		my @calls;
		mock 'Web::VWF::Config::new' => sub { push @calls, $_[1]; return bless({}, 'Web::VWF::Config') };
		my $vwf = Web::VWF->new(config_file => 'site.xml');
		my $config = $vwf->_config();
		isa_ok($config, 'Web::VWF::Config');
		is($vwf->_config(), $config, 'kept, not re-read');
		is(scalar(@calls), 1, 'configuration read once');
		is_deeply($calls[0], { config_file => 'site.xml', directory => $CONFIG{'default_vwf_directory'} }, 'arguments passed on');
		restore_all();

		# A failed read must not be remembered as a configuration
		mock 'Web::VWF::Config::new' => sub { die "unreadable\n" };
		throws_ok { $vwf->new()->_config() } qr/\Aunreadable/, 'error propagates';
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::CAPTCHA' => sub {
	fresh();
	my $json_reply = sub { HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], shift) };

	subtest 'new / get_site_key' => sub {
		my $c = Web::VWF::CAPTCHA->new(site_key => 'site', secret_key => 'secret');
		returns_ok($c, { type => 'object', isa => 'Web::VWF::CAPTCHA' }, 'object');
		is($c->get_site_key(), 'site', 'site key');
		memory_cycle_ok($c, 'no cycles');

		throws_ok { Web::VWF::CAPTCHA->new(secret_key => 'secret') } qr/\Asite_key required/, 'site_key required';
		throws_ok { Web::VWF::CAPTCHA->new(site_key => 'site') } qr/\Asecret_key required/, 'secret_key required';
		throws_ok { Web::VWF::CAPTCHA->new(site_key => '', secret_key => 'x') } qr/\Asite_key required/, 'empty site_key';
	};

	subtest 'verify - success' => sub {
		my $logger = Local::Logger->new();
		my @posts;
		mock 'LWP::UserAgent::post' => sub { push @posts, [@_[1, 2]]; return $json_reply->(encode_json({ success => \1 })) };
		my $c = Web::VWF::CAPTCHA->new(site_key => 's', secret_key => 'k', logger => $logger);
		is($c->verify('token', $CONFIG{'client_ip'}), 1, 'verified');
		is($posts[0][0], 'https://www.google.com/recaptcha/api/siteverify', 'Google endpoint');
		is_deeply($posts[0][1], { secret => 'k', response => 'token', remoteip => $CONFIG{'client_ip'} }, 'form sent');
		like($logger->messages('info')->[0], qr/successful for \Q$CONFIG{client_ip}\E/, 'success logged');
		restore_all();
	};

	subtest 'verify - every failure is 0, never an exception' => sub {
		my $logger = Local::Logger->new();
		my $c = Web::VWF::CAPTCHA->new(site_key => 's', secret_key => 'k', logger => $logger);

		# No token: no network traffic at all
		mock 'LWP::UserAgent::post' => sub { die 'must not be called' };
		is($c->verify(undef, $CONFIG{'client_ip'}), 0, 'undef token');
		is($c->verify('', $CONFIG{'client_ip'}), 0, 'empty token');
		restore_all();

		mock 'LWP::UserAgent::post' => sub { return HTTP::Response->new(500, 'Server Error') };
		is($c->verify('t', $CONFIG{'client_ip'}), 0, 'HTTP failure');
		like($logger->messages('error')->[-1], qr/\AreCAPTCHA verification failed: 500/, 'HTTP failure logged');
		restore_all();

		mock 'LWP::UserAgent::post' => sub { return $json_reply->(encode_json({ success => \0, 'error-codes' => ['timeout-or-duplicate', 'bad'] })) };
		is($c->verify('t', $CONFIG{'client_ip'}), 0, 'rejected by Google');
		like($logger->messages('warn')->[-1], qr/timeout-or-duplicate, bad\z/, 'error codes logged');
		restore_all();

		# A reply that is not JSON, or JSON of the wrong shape, is a failure
		foreach my $body ('<html>gateway</html>', '', '[1,2]', '"yes"', '{"success":') {
			mock 'LWP::UserAgent::post' => sub { return $json_reply->($body) };
			my $rc;
			lives_ok { $rc = $c->verify('t', $CONFIG{'client_ip'}) } "reply '$body' does not die";
			is($rc, 0, "reply '$body' is a failure");
			restore_all();
		}

		# Truthy but not true
		mock 'LWP::UserAgent::post' => sub { return $json_reply->('{}') };
		is($c->verify('t', $CONFIG{'client_ip'}), 0, 'no success field');
		restore_all();
	};

	subtest 'verify - no address, no warnings' => sub {
		mock 'LWP::UserAgent::post' => sub { return $json_reply->('{"success":false}') };
		my $c = Web::VWF::CAPTCHA->new(site_key => 's', secret_key => 'k', logger => Local::Logger->new());
		warnings_are { $c->verify('t', undef) } [], 'undef address does not warn';
		my $quiet = Web::VWF::CAPTCHA->new(site_key => 's', secret_key => 'k');
		warnings_are { $quiet->verify('t', undef) } [], 'and nor does no logger';
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::Data::index / vwf_log' => sub {
	fresh();

	subtest 'index' => sub {
		ok(Web::VWF::Data::index->isa('Database::Abstraction'), 'is a Database::Abstraction');
	};

	subtest 'vwf_log::_open' => sub {
		# The log has no header line, so the column names must always be
		# supplied, whichever calling style is used
		my @calls;
		mock 'Database::Abstraction::_open' => sub { my $self = shift; push @calls, {@_}; return $self };
		my $db = bless {}, 'Web::VWF::Data::vwf_log';
		$db->_open();
		$db->_open({ table => 't' });
		$db->_open(sep_char => ';');
		is($calls[0]{'sep_char'}, ',', 'comma separated');
		is_deeply($calls[0]{'column_names'},
			[qw(domain_name time IP country type language http_code template args warnings error duration_ms)], 'column names');
		is($calls[1]{'table'}, 't', 'hashref arguments passed on');
		is($calls[2]{'sep_char'}, ';', 'caller may override');
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::Allow' => sub {
	fresh();
	my $dir = tempdir(CLEANUP => 1);
	my $today = DateTime->today()->ymd();
	my $ip_count = 0;

	# The decision is cached per address, so each case gets its own address
	my $next_ip = sub { $ip_count++; return "203.0.113.$ip_count" };

	# A cache that already holds today's DShield list, so nothing is fetched
	my $quiet_cache = sub { Local::Cache->new($today => $CONFIG{'other_ip'}) };

	my $setup = sub {
		my (%opts) = @_;
		mock_ids();
		mock 'Data::Throttler::new' => sub { return Local::Throttler->new($opts{'throttle'} // 1) };
		mock 'LWP::Simple::WithCache::get' => sub { die 'DShield must not be fetched' } unless $opts{'fetch'};
		return;
	};

	local %ENV = %ENV;
	delete @ENV{qw(HTTP_USER_AGENT HTTP_REFERER SCRIPT_URI REQUEST_METHOD)};

	subtest 'not a CGI request' => sub {
		local $ENV{'REMOTE_ADDR'};
		is(Web::VWF::Allow::allow(), 1, 'no REMOTE_ADDR: allowed');
	};

	subtest 'clean client is allowed, and the answer cached' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		my $logger = Local::Logger->new();
		my $info = Local::Info->new(tmpdir => $dir);
		is(Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->(), logger => $logger), 1, 'allowed');
		like($logger->messages('trace')->[-1], qr/\AAllowing connexion from /, 'logged');

		# The second call must not run the checks again
		mock 'Data::Throttler::new' => sub { die 'checks must not run again' };
		is(Web::VWF::Allow::allow({ info => $info, cache => $quiet_cache->(), logger => $logger }), 1, 'cached answer');
		like($logger->messages('debug')->[-1], qr/cached value 1\z/, 'cache hit logged');
		restore_all();
	};

	subtest 'cached answers expire' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		my $info = Local::Info->new(tmpdir => $dir);
		$FAKE_TIME = CORE::time();
		Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->());
		my $runs = 0;
		mock 'Data::Throttler::new' => sub { $runs++; return Local::Throttler->new(1) };
		$FAKE_TIME += $CONFIG{'status_ttl'} - 1;
		Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->());
		is($runs, 0, 'still cached just before expiry');
		$FAKE_TIME += 2;
		Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->());
		is($runs, 1, 'checked again after expiry');
		$FAKE_TIME = undef;
		restore_all();
	};

	subtest 'blacklisted user agents' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		local $ENV{'HTTP_USER_AGENT'} = 'masscan';
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()) },
			"$ip: Masscan is blacklisted", 'masscan refused');
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir)), 0, 'refusal remembered');

		# Only an exact match counts: a substring must not block a browser
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		local $ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (masscan-lookalike)';
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()), 1, 'lookalike allowed');
		restore_all();
	};

	subtest 'no info' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		warning_like { is(Web::VWF::Allow::allow(), 1, 'allowed without info') } qr/\AInfo not given/, 'carps';
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		my $logger = Local::Logger->new();
		warnings_are { Web::VWF::Allow::allow(logger => $logger) } [], 'logger instead of a warning';
		is_deeply($logger->messages('warn'), ['Info not given'], 'logged');
		restore_all();
	};

	subtest 'throttling' => sub {
		$setup->(throttle => 0);
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		my $info = Local::Info->new(tmpdir => $dir);
		error_text_is(sub { Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->()) }, "$ip has been throttled", 'throttled');
		is_deeply($info->{'status_calls'}, [429], '429 Too Many Requests');
		restore_all();

		# Configuration controls the limits
		my %args;
		mock_ids();
		mock 'Data::Throttler::new' => sub { shift; %args = @_; return Local::Throttler->new(1) };
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->(), config => { throttle => { max_items => 5, interval => 7, file => '/x' } });
		is_deeply([@args{qw(max_items interval)}, $args{'backend_options'}{'db_file'}], [5, 7, '/x'], 'limits from configuration');

		# Search engines are not throttled at all
		mock 'Data::Throttler::new' => sub { die 'search engines must not be throttled' };
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		is(Web::VWF::Allow::allow(info => Local::Info->new(is_search_engine => 1), cache => $quiet_cache->()), 1, 'search engine skipped');
		restore_all();
	};

	subtest 'broken throttle store fails open' => sub {
		$setup->();
		my $store = File::Spec->catfile($dir, 'throttle');
		open(my $fh, '>', $store) or die "$store: $!";
		print $fh "corrupt\n";
		close($fh);
		mock 'Data::Throttler::new' => sub { die "YAML Error: bad indentation\n" };
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		my $logger = Local::Logger->new();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->(), logger => $logger), 1, 'served');
		ok(!-e $store, 'corrupt store removed');
		like($logger->messages('info')->[0], qr/\Aremoving corrupt throttle DB /, 'removal logged');
		restore_all();
	};

	subtest 'country blacklist' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		my $info = Local::Info->new(tmpdir => $dir);
		error_text_is(sub { Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->(), lingua => Local::Lingua->new(country => $CONFIG{'blocked_country'})) },
			"$ip: blocked connexion from $CONFIG{blocked_country}", 'blocked country refused');
		is_deeply($info->{'status_calls'}, [403], '403 Forbidden');

		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->(),
			lingua => Local::Lingua->new(country => $CONFIG{'blocked_country'}), config => { blacklist_countries => 'RU' }), 1, 'site list replaces the default');

		local $ENV{'REMOTE_ADDR'} = $CONFIG{'private_ip'};
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->(),
			lingua => Local::Lingua->new(country => $CONFIG{'blocked_country'})), 1, 'local network never blocked by country');
		restore_all();
	};

	subtest 'intrusion detection' => sub {
		$setup->();
		local $ENV{'REQUEST_METHOD'} = 'GET';
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		$Local::IDS::IMPACT = $CONFIG{'ids_block_impact'};
		my $info = Local::Info->new(tmpdir => $dir, params => { q => '<script>' });
		error_text_is(sub { Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->()) },
			"$ip: IDS blocked connexion for page=index", 'high impact refused');
		is_deeply($info->{'status_calls'}, [403], '403 Forbidden');

		# Low impact is logged but served
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		$Local::IDS::IMPACT = $CONFIG{'ids_warn_impact'};
		my $logger = Local::Logger->new();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir, params => { q => 'x', fbclid => 'f' }), cache => $quiet_cache->(), logger => $logger), 1, 'low impact served');
		like($logger->messages('warn')->[0], qr/impact = $CONFIG{ids_warn_impact}\z/, 'and logged');

		# /etc/passwd is refused whatever the IDS thinks of it
		$Local::IDS::IMPACT = 0;
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		$info = Local::Info->new(tmpdir => $dir, params => { file => '/etc/passwd' });
		is(Web::VWF::Allow::allow(info => $info, cache => $quiet_cache->()), 0, '/etc/passwd refused');
		is_deeply($info->{'status_calls'}, [403], '403 Forbidden');

		# POSTs are not scanned here
		local $ENV{'REQUEST_METHOD'} = 'POST';
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		$Local::IDS::IMPACT = 1000;
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir, params => { q => 'x' }), cache => $quiet_cache->()), 1, 'POST not scanned');
		restore_all();
	};

	subtest 'referer checks' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		local $ENV{'HTTP_REFERER'} = 'http://www.tcsindustry.com/page';
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()) },
			"$ip: Blocked trawler", 'known trawler');

		local $ENV{'REMOTE_ADDR'} = $ip = $next_ip->();
		local $ENV{'HTTP_REFERER'} = '() { :;}; /bin/bash -c "id"';
		(my $plussed = $ENV{'HTTP_REFERER'}) =~ tr/ /+/;
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()) },
			"$ip: Blocked shellshocker for $plussed", 'shellshock referer');

		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		local $ENV{'HTTP_REFERER'} = 'https://www.example.com/search?q=a b';
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()), 1, 'ordinary referer allowed');
		restore_all();
	};

	subtest 'attack scripts' => sub {
		$setup->();
		foreach my $script ('/shell.php', '/cmd.php') {
			local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
			local $ENV{'SCRIPT_URI'} = "https://example.com$script";
			error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()) },
				"$ip: Blocked attacker for $ip", "$script refused");
		}
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		local $ENV{'SCRIPT_URI'} = 'https://example.com/shell.php.html';
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->()), 1, 'only the exact ending');
		restore_all();
	};

	subtest 'DShield list' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = my $ip = $next_ip->();
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => Local::Cache->new($today => "$CONFIG{other_ip},$ip")) },
			"Dshield blocked connexion from $ip", 'listed address refused');

		# An empty cached list is deleted so that it is fetched again
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		restore_all();
		$setup->(fetch => 1);
		mock 'LWP::Simple::WithCache::get' => sub { return };
		my $cache = Local::Cache->new($today => ',');
		my $logger = Local::Logger->new();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $cache, logger => $logger), 1, 'served');
		is_deeply($cache->{'removed'}, [$today], 'empty list removed');
		like($logger->messages('warn')->[-1], qr/\ACouldn't download /, 'failed download logged');
		restore_all();
	};

	subtest 'DShield download' => sub {
		$setup->(fetch => 1);
		local $ENV{'REMOTE_ADDR'} = '10.0.0.1';
		my $xml = "<sources><data><ip>010.000.000.001</ip><lastseen>$today</lastseen></data>"
			. "<data><ip>198.051.100.009</ip><lastseen>$today</lastseen></data></sources>";
		mock 'LWP::Simple::WithCache::get' => sub { return $xml };
		my $cache = Local::Cache->new();
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $cache) },
			'Dshield blocked connexion from 10.0.0.1', 'leading zeros are not octal');
		is_deeply($cache->{'sets'}, [[$today, '10.0.0.1,198.51.100.9', $CONFIG{'dshield_duration'}]], 'list cached for a day');
		restore_all();

		# A garbled download must not take the site down
		$setup->(fetch => 1);
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		mock 'LWP::Simple::WithCache::get' => sub { return '<sources><data>' };
		$cache = Local::Cache->new();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $cache), 1, 'malformed XML ignored');
		is_deeply($cache->{'sets'}, [], 'nothing cached');
		restore_all();

		# Without a logger the failure goes to STDERR, and is still survived
		$setup->(fetch => 1);
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		mock 'LWP::Simple::WithCache::get' => sub { return };
		warning_like { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => Local::Cache->new()) }
			qr/\ACouldn't download https:\/\/secure\.dshield\.org\//, 'warns without a logger';
		restore_all();
	};

	subtest 'cache comes from configuration' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir)) },
			'Either cache or config must be given', 'neither cache nor config');

		my %args;
		mock 'Web::VWF::Utils::create_memory_cache' => sub { %args = @_; return $quiet_cache->() };
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		is(Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), config => { a => 1 }), 1, 'served');
		is($args{'namespace'}, 'Web::VWF::Allow', 'cache built in our namespace');
		restore_all();
	};

	subtest 'tracking cookie' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		error_text_is(sub { Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir, cookies => { mycustomtrackid => 'x' }), cache => $quiet_cache->()) },
			'Blocking possible jqic', 'jqic cookie refused');
		restore_all();
	};

	subtest 'allow leaves $_ alone' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $next_ip->();
		local $_ = 'sentinel';
		Web::VWF::Allow::allow(info => Local::Info->new(tmpdir => $dir), cache => $quiet_cache->());
		is($_, 'sentinel', '$_ unchanged');
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::Display' => sub {
	fresh();
	my $dir = tempdir(CLEANUP => 1);

	local %ENV = %ENV;
	delete @ENV{qw(HTTP_REFERER REMOTE_ADDR CONFIG_DIR root_dir DOCUMENT_ROOT)};

	# A template tree: <root>/templates/web/Web/VWF/Display.tmpl, plus a
	# French one to check that the language is preferred
	my $root = File::Spec->catdir($dir, 'site');
	my $write = sub {
		my ($path, $content) = @_;
		my $file = File::Spec->catfile($root, 'templates', @{$path});
		my (undef, $parent) = File::Spec->splitpath($file);
		File::Path::make_path($parent);
		open(my $out, '>', $file) or die "$file: $!";
		print $out $content;
		close($out);
		return $file;
	};
	require File::Path;
	my $web_template = $write->([qw(web Web VWF Display.tmpl)], 'Hello [% name %]');
	my $fr_template = $write->([qw(fr web Web VWF Display.tmpl)], 'Bonjour [% name %]');

	my $mock_new_collaborators = sub {
		my (%opts) = @_;
		$Web::VWF::Display::sm = undef;
		mock 'Object::Configure::configure' => sub { return $_[1] };
		mock_config_abstraction($opts{'config'} // { root_dir => $root });
		mock 'HTML::SocialMedia::new' => sub { return bless({}, 'Local::SocialMedia') };
		mock 'Web::VWF::Display::create_memory_cache' => sub { return Local::Cache->new() };
		mock 'Data::Throttler::new' => sub { return Local::Throttler->new($opts{'throttle'} // 1) };
		mock_ids();
		return;
	};

	subtest 'new - builds a display' => sub {
		$mock_new_collaborators->();
		my $info = Local::Info->new(params => { key => 'k1', page => 'about' }, script_dir => $dir);
		my $lingua = Local::Lingua->new(country => $CONFIG{'allowed_country'});
		my $display = Web::VWF::Display->new(info => $info, lingua => $lingua, config => { extra => 1 }, config_directory => $dir);
		returns_ok($display, { type => 'object', isa => 'Web::VWF::Display' }, 'object');
		is($display->{'config'}{'root_dir'}, $root, 'file configuration loaded');
		is($display->{'config'}{'extra'}, 1, 'caller configuration merged');
		is_deeply([@{$display}{qw(key page)}], ['k1', 'about'], 'key and page taken from the request');
		is($display->{'lingua'}, $lingua, 'lingua kept');
		is($display->{'_social_media'}{'facebook_share_button'}, 'button:facebook_share_button', 'share button');
		explain_state('Display object keys', [sort keys %{$display}]);
		restore_all();
	};

	subtest 'new - on an object clones it' => sub {
		my $display = make_display(page => 'one');
		my $clone = $display->new(page => 'two');
		isa_ok($clone, 'Web::VWF::Display');
		is($clone->{'page'}, 'two', 'new values win');
		is($display->{'page'}, 'one', 'original untouched');
	};

	subtest 'new - invalid referer is refused' => sub {
		$mock_new_collaborators->();
		local $ENV{'HTTP_REFERER'} = '() { :;}; echo vulnerable';
		is(Web::VWF::Display->new(info => Local::Info->new(script_dir => $dir)), undef, 'returns nothing');
		is($Local::ConfigAbstraction::NEW_ARGS[0], undef, 'refused before any configuration is read');
		$ENV{'HTTP_REFERER'} = 'https://www.example.com/';
		isa_ok(Web::VWF::Display->new(info => Local::Info->new(script_dir => $dir)), 'Web::VWF::Display', 'valid referer');
		restore_all();
	};

	subtest 'new - configuration failure' => sub {
		$mock_new_collaborators->();
		mock 'Config::Abstraction::new' => sub { die "bad XML\n" };
		throws_ok { Web::VWF::Display->new(info => Local::Info->new(script_dir => $dir)) }
			qr/\AConfiguration error: bad XML\n/, 'reader failure is fatal';
		restore_all();
		$mock_new_collaborators->(config => undef);
		$Local::ConfigAbstraction::DATA = undef;
		throws_ok { Web::VWF::Display->new(info => Local::Info->new(script_dir => $dir)) }
			qr/\AConfiguration error: /, 'no configuration is fatal';
		restore_all();
	};

	subtest 'new - intrusion detection' => sub {
		$mock_new_collaborators->();
		local $ENV{'REMOTE_ADDR'} = $CONFIG{'client_ip'};
		$Local::IDS::IMPACT = $CONFIG{'display_ids_threshold'} + 1;
		my $info = Local::Info->new(params => { q => 'attack' }, script_dir => $dir, tmpdir => $dir);
		throws_ok { Web::VWF::Display->new(info => $info) }
			qr/\A\Q$CONFIG{client_ip}\E: IDS impact is $Local::IDS::IMPACT/, 'attack refused';

		# The threshold is configurable both ways
		$Local::IDS::IMPACT = $CONFIG{'display_ids_threshold'};
		isa_ok(Web::VWF::Display->new(info => $info), 'Web::VWF::Display', 'at the threshold is allowed');
		restore_all();
		$mock_new_collaborators->(config => { root_dir => $root, security => { ids_threshold => 5 } });
		$Local::IDS::IMPACT = 6;
		throws_ok { Web::VWF::Display->new(info => $info) } qr/IDS impact is 6/, 'lower configured threshold';

		# Search engines are not scanned
		isa_ok(Web::VWF::Display->new(info => Local::Info->new(params => { q => 'x' }, is_search_engine => 1, script_dir => $dir)),
			'Web::VWF::Display', 'search engine not scanned');
		restore_all();
	};

	subtest 'new - throttling' => sub {
		$mock_new_collaborators->(throttle => 0);
		local $ENV{'REMOTE_ADDR'} = $CONFIG{'client_ip'};
		my $info = Local::Info->new(script_dir => $dir, tmpdir => $dir);
		my $logger = Local::Logger->new();
		is(Web::VWF::Display->new(info => $info, logger => $logger), undef, 'throttled client gets nothing');
		is_deeply($info->{'status_calls'}, [429], '429 Too Many Requests');
		is_deeply(\@SLEEPS, [1], 'slowed down');
		like($logger->messages('info')->[-1], qr/connexion throttled\z/, 'logged');
		restore_all();

		# An unparsable store is removed and the request served
		$mock_new_collaborators->();
		mock 'Data::Throttler::new' => sub { die "YAML Error\n" };
		my $store = File::Spec->catfile($dir, 'throttle');
		open(my $fh, '>', $store) or die;
		close($fh);
		isa_ok(Web::VWF::Display->new(info => $info, logger => $logger), 'Web::VWF::Display', 'served');
		ok(!-e $store, 'store removed');
		like($logger->messages('notice')->[-1], qr/\ARemoving unparsable YAML file /, 'logged');
		restore_all();
	};

	subtest 'new - country blacklist' => sub {
		$mock_new_collaborators->();
		local $ENV{'REMOTE_ADDR'} = $CONFIG{'client_ip'};
		my $info = Local::Info->new(script_dir => $dir, tmpdir => $dir);
		throws_ok { Web::VWF::Display->new(info => $info, lingua => Local::Lingua->new(country => $CONFIG{'blocked_country'})) }
			qr/\A\Q$CONFIG{client_ip}\E is from a blacklisted country $CONFIG{blocked_country}/, 'blocked country refused';
		isa_ok(Web::VWF::Display->new(info => $info, lingua => Local::Lingua->new(country => undef)), 'Web::VWF::Display', 'unknown country allowed');
		restore_all();
	};

	subtest '_find_config_dir' => sub {
		my $conf = File::Spec->catdir($dir, 'conf');
		File::Path::make_path($conf);
		{
			local $ENV{'CONFIG_DIR'} = '/anything';
			is(Web::VWF::Display::_find_config_dir({}, Local::Info->new()), '/anything', 'CONFIG_DIR wins outright');
		}
		{
			local $ENV{'root_dir'} = $dir;
			is(Web::VWF::Display::_find_config_dir({}, Local::Info->new()), $conf, 'root_dir/conf');
		}
		my $cgi = File::Spec->catdir($dir, 'cgi-bin');
		File::Path::make_path($cgi);
		is(Web::VWF::Display::_find_config_dir({}, Local::Info->new(script_dir => $cgi)),
			File::Spec->catdir($cgi, File::Spec->updir(), 'conf'), 'beside cgi-bin');

		# When nothing exists the caller's directory is the last resort
		local $ENV{'HOME'} = File::Spec->catdir($dir, 'no-home');
		my $logger = Local::Logger->new();
		my $nowhere = File::Spec->catdir($dir, 'x', 'y');
		is(Web::VWF::Display::_find_config_dir({ config_directory => '/fallback' }, Local::Info->new(script_dir => $nowhere)), '/fallback', 'fallback directory');
		Web::VWF::Display::_find_config_dir({ logger => $logger }, Local::Info->new(script_dir => $nowhere));
		ok(scalar(@{$logger->messages('debug')}), 'environment logged to help find it');
	};

	subtest 'get_template_path' => sub {
		mock_config_abstraction({ root_dir => $root });
		my $display = make_display(config_dir => $dir);
		my $path = $display->get_template_path();
		is($path, $web_template, 'web template found');
		returns_ok($path, { type => 'string' }, 'returns a string');

		# Remembered, so the configuration is not read again
		mock 'Config::Abstraction::new' => sub { die 'must not re-read' };
		is($display->get_template_path(), $web_template, 'remembered');
		restore_all();

		mock_config_abstraction({ root_dir => $root });
		$display = make_display(config_dir => $dir, _lingua => Local::Lingua->new(language => 'fr'));
		is($display->get_template_path(), $fr_template, 'language preferred');

		my @logged;
		$display = make_display(config_dir => $dir, log => bless({ t => \@logged }, 'Local::Log'));
		{
			no strict 'refs';
			*{'Local::Log::template'} = sub { push @{$_[0]->{'t'}}, $_[1] };
		}
		$display->get_template_path();
		is_deeply(\@logged, [$web_template], 'template recorded in the log');
		restore_all();
	};

	subtest 'get_template_path - refusals' => sub {
		# A configuration that walks up the tree must be refused outright
		mock_config_abstraction({ root_dir => "$root/../../etc" });
		error_text_is(sub { make_display(config_dir => $dir)->get_template_path() },
			"Prefix must not contain ../ ($root/../../etc/templates/web:$root/../../etc/templates/default/web:$root/../../etc/templates/default:$root/../../etc/templates)",
			'../ in root_dir');
		restore_all();

		# No template: a clear error, even with no config_path to mention
		mock_config_abstraction({ root_dir => $root });
		my $display = make_display(config_dir => $dir);
		error_text_like(sub { $display->get_template_path(modulepath => 'No::Such::Page') },
			qr/\ACan't find suitable No\/Such\/Page html or tmpl\/tt file in .* \(check \)\z/, 'missing template, no config_path');
		restore_all();
	};

	subtest 'set_cookie' => sub {
		my $display = make_display();
		is($display->set_cookie(name => 'value'), $display, 'chains');
		$display->set_cookie({
			"crlf" => "a\r\nSet-Cookie: admin=1",
			"semi" => 'a; Domain=evil.com',
			"bad name" => 'x',
			"bad;name" => 'x',
			"bad\nname" => 'x',
			"undefined" => undef,
		});
		is_deeply($display->{'_cookies'}, {
			name => 'value',
			crlf => 'aSet-Cookie: admin=1',
			semi => 'a Domain=evil.com',
		}, 'header-breaking characters removed, bad names dropped');
	};

	subtest 'add_preload' => sub {
		my $display = make_display();
		is($display->add_preload('/style.css', 'style'), $display, 'chains');
		$display->add_preload('/font.woff2', 'font')->add_preload('/f2.woff2', 'font', crossorigin => 0);
		is_deeply($display->{'_preloads'}, [
			{ href => '/style.css', as => 'style', crossorigin => 0 },
			{ href => '/font.woff2', as => 'font', crossorigin => 1 },
			{ href => '/f2.woff2', as => 'font', crossorigin => 0 },
		], 'queued, fonts crossorigin by default');

		my $types = 'audio, document, embed, fetch, font, image, object, script, style, track, video, worker';
		croaks_with(sub { $display->add_preload('/x', 'stylesheet') }, "Unknown preload type 'stylesheet'; must be one of: $types", 'unknown type');
		croaks_with(sub { $display->add_preload('/x', 'Style') }, "Unknown preload type 'Style'; must be one of: $types", 'types are case-sensitive');

		# Anything that could break out of the Link header
		my $msg = "Preload href must be a root-relative path starting with '/'";
		foreach my $bad ('style.css', 'https://evil.com/x.js', '//evil.com/x.js', '/\\evil.com/x.js', "/x\r\nSet-Cookie: a=b", "/x\nX: y", "/x\n", "/x\r", '') {
			(my $printable = $bad) =~ s/\r/\\r/g;
			$printable =~ s/\n/\\n/g;
			croaks_with(sub { $display->add_preload($bad, 'script') }, $msg, "href '$printable' refused");
		}
		{
			local $SIG{__WARN__} = sub { };
			croaks_with(sub { $display->add_preload(undef, 'script') }, $msg, 'undef href refused');
		}
		is(scalar(@{$display->{'_preloads'}}), 3, 'nothing queued by the refusals');
	};

	subtest 'http' => sub {
		my $display = make_display(_filename => '/t/page.tmpl', info => Local::Info->new(protocol => 'https'));
		$display->add_preload('/a.css', 'style')->add_preload('/f.woff', 'font');
		$display->set_cookie(session => 'abc');
		my $headers;
		my $printed = capture_stdout(sub { $headers = $display->http() });
		like($headers, qr/\AContent-Type: text\/html; charset=UTF-8\n/, 'HTML content type');
		like($headers, qr/\n\n\z/, 'ends the header block');
		foreach my $h ('X-Frame-Options: SAMEORIGIN', 'X-Content-Type-Options: nosniff', 'Referrer-Policy: strict-origin-when-cross-origin',
			"Content-Security-Policy: default-src 'self'", 'Strict-Transport-Security: max-age=31536000; includeSubDomains') {
			like($headers, qr/^\Q$h\E/m, "has $h");
		}
		like($printed, qr/^Link: <\/a\.css>; rel=preload; as=style$/m, 'preload header');
		like($printed, qr/^Link: <\/f\.woff>; rel=preload; as=font; crossorigin$/m, 'font preload is crossorigin');
		like($printed, qr/^Set-Cookie: session=abc; path=\/; HttpOnly; SameSite=Strict; Secure$/m, 'secure cookie over https');

		$display = make_display(_filename => '/t/robots.txt');
		$headers = $display->http();
		like($headers, qr/\AContent-Type: text\/plain\n/, 'text content type');
		like($display->http('Content-Type' => 'Content-Type: application/json'), qr/\AContent-Type: application\/json\n/, 'override');
		like($display->http({ 'Retry-After' => 120 }), qr/^Retry-After: 120$/m, 'Retry-After');

		# Retry-After goes straight into the headers, so only digits will do
		foreach my $bad ('1.5', '-1', 'soon', "10\r\nSet-Cookie: a=b", "10\n", '', ' 10') {
			(my $printable = $bad) =~ s/\r/\\r/g;
			$printable =~ s/\n/\\n/g;
			croaks_with(sub { $display->http('Retry-After' => $bad) }, "Retry-After must be a number of seconds, not '$bad'", "Retry-After '$printable'");
		}
	};

	subtest 'html - templates' => sub {
		my $config = { name => 'config', SiteTitle => 'Site' };
		my $info = Local::Info->new(params => { name => 'request' });
		my $display = make_display(_filename => $web_template, config => $config, info => $info);
		is($display->html(), 'Hello request', 'request beats configuration');
		is($display->html(name => 'caller'), 'Hello caller', 'caller beats request');
		is($display->html({ name => 'hashref' }), 'Hello hashref', 'hashref style');

		# Rendering must not leave template variables behind in the object
		is_deeply($config, { name => 'config', SiteTitle => 'Site' }, 'configuration not polluted');
		is_deeply($info->{'params'}, { name => 'request' }, 'request parameters not polluted');

		# No configuration and no request parameters must not die
		$display = make_display(_filename => $web_template, info => Local::Info->new());
		$display->{'_config'} = undef;
		is($display->html(name => 'bare'), 'Hello bare', 'works with neither');

		my $broken = $write->([qw(broken.tmpl)], '[% IF %]');
		error_text_like(sub { make_display(_filename => $broken)->html() }, qr/\Afile error - parse error/, 'template syntax error');
	};

	subtest 'html - static files and refusals' => sub {
		my $static = $write->([qw(page.html)], "<p>static</p>\n");
		is(make_display(_filename => $static)->html(), "<p>static</p>\n", 'static HTML read as is');
		my $gone = File::Spec->catfile($dir, 'gone.html');
		error_text_like(sub { make_display(_filename => $gone)->html() }, qr/\A\Q$gone\E: No such file/, 'missing static file');
		error_text_is(sub { make_display(_filename => '/t/page.php')->html() }, 'Unhandled file type /t/page.php', 'unknown type');

		# Plain mailto: links are harvested by spammers, so they are flagged
		my $mail = $write->([qw(mail.html)], '<a href= mailto:a@b.com>x</a>');
		my $logger = Local::Logger->new();
		make_display(_filename => $mail, _logger => $logger)->html();
		like($logger->messages('warn')->[0], qr/Found mailto link a\@b\.com, you should remove it or use &#97;&#64;/, 'mailto flagged');
	};

	subtest '_debug' => sub {
		my $display = make_display();
		is($display->_debug(message => 'quiet'), $display, 'no logger: chains, does nothing');
		my $logger = Local::Logger->new();
		$display->{'_logger'} = $logger;
		$display->_debug({ message => 'one' });
		local $ENV{'REMOTE_ADDR'} = $CONFIG{'client_ip'};
		$display->_debug(message => 'two');
		is_deeply($logger->messages('debug'), ['one', "$CONFIG{client_ip}: two"], 'address added when known');
	};

	subtest 'obfuscate' => sub {
		is(Web::VWF::Display::obfuscate('a@b'), '&#97;&#64;&#98;', 'entities');
		is(Web::VWF::Display::obfuscate(''), '', 'empty string');
		is('x' . Web::VWF::Display::obfuscate('ab') . 'y', 'x&#97;&#98;y', 'one string inside a concatenation');
		is(Web::VWF::Display::obfuscate('<"&>'), '&#60;&#34;&#38;&#62;', 'markup characters encoded too');
	};

	subtest '_types' => sub {
		my %cases = (
			'search engine' => [{ is_search_engine => 1 }, [qw(search robot web)]],
			mobile => [{ is_mobile => 1 }, [qw(mobile web)]],
			ai => [{ is_ai => 1 }, [qw(ai robot search web)]],
			robot => [{ is_robot => 1 }, [qw(robot search web)]],
			browser => [{}, ['web']],
		);
		foreach my $name (sort keys %cases) {
			my ($flags, $expect) = @{$cases{$name}};
			is_deeply([make_display(info => Local::Info->new(%{$flags}))->_types()], $expect, $name);
		}
		my $logger = Local::Logger->new();
		make_display(_logger => $logger)->_types();
		like($logger->messages('trace')->[0], qr/_types returning web\z/, 'traced');
	};

	subtest '_send_csrf_token' => sub {
		my $display = make_display();
		is(capture_stdout(sub { $display->_send_csrf_token('<p>no form</p>') }), '', 'no form, no cookie');
		is(capture_stdout(sub { $display->_send_csrf_token('<formula>') }), '', '<formula> is not a form');
		like(capture_stdout(sub { $display->_send_csrf_token('<FORM method="post">') }),
			qr/\ASet-Cookie: csrf_token=\d+:[0-9a-f]{64}:[0-9a-f]{64}; path=\/; HttpOnly; SameSite=Strict\n\z/, 'form gets a token');
		$display->{'config'}{'security'}{'csrf'}{'enable'} = 0;
		is(capture_stdout(sub { $display->_send_csrf_token('<form>') }), '', 'disabled in configuration');
	};

	subtest '_generate_csrf_token' => sub {
		my $display = make_display();
		my $token = $display->_generate_csrf_token();
		like($token, qr/\A(\d+):([0-9a-f]{$CONFIG{hex_sha256_length}}):([0-9a-f]{$CONFIG{hex_sha256_length}})\z/, 'time:random:signature');
		my ($time, $random, $signature) = split(/:/, $token);
		is($signature, Digest::SHA::sha256_hex("$time:$random:$CONFIG{csrf_secret}"), 'signed with the configured secret');
		isnt($display->_generate_csrf_token(), $token, 'never the same twice');

		# A forged signature with another secret must not match
		isnt($signature, Digest::SHA::sha256_hex("$time:$random:wrong"), 'secret matters');

		# Without a secret: one warning per process, then silence
		my $unconfigured = make_display(config => {});
		my $first;
		warning_like { $first = $unconfigured->_generate_csrf_token() } qr/\AVWF: security\.csrf\.secret is not configured/, 'warns once';
		warnings_are { $unconfigured->_generate_csrf_token() } [], 'only once';
		like($first, qr/\A\d+:[0-9a-f]+:[0-9a-f]+\z/, 'still a valid token');
	};

	subtest 'cache_key_from_hashref' => sub {
		my $key = Web::VWF::Display::cache_key_from_hashref({ a => 1, b => 2 });
		like($key, qr/\A[0-9a-f]{$CONFIG{hex_md5_length}}\z/, 'MD5 hex');
		my %reordered;
		$reordered{'b'} = 2;
		$reordered{'a'} = 1;
		is(Web::VWF::Display::cache_key_from_hashref(\%reordered), $key, 'key order does not matter');
		isnt(Web::VWF::Display::cache_key_from_hashref({ a => 1, b => 3 }), $key, 'values matter');
		isnt(Web::VWF::Display::cache_key_from_hashref({ a => 1, b => '2 ' }), $key, 'whitespace matters');
		like(Web::VWF::Display::cache_key_from_hashref(undef), qr/\A[0-9a-f]{32}\z/, 'undef is fine');

		# Data::Dumper settings are global, so they must be put back
		local $Data::Dumper::Sortkeys = 0;
		local $Data::Dumper::Indent = 2;
		Web::VWF::Display::cache_key_from_hashref({ x => 1 });
		is($Data::Dumper::Sortkeys, 0, 'Sortkeys restored');
		is($Data::Dumper::Indent, 2, 'Indent restored');
	};

	subtest 'as_string - cart cookie' => sub {
		my %seen;
		mock 'Web::VWF::Display::http' => sub { return "Content-Type: text/html\n\n" };
		mock 'Web::VWF::Display::html' => sub { my ($self, $args) = @_; %seen = %{$args}; return '<p>page</p>' };
		mock 'Web::VWF::Display::create_memory_cache' => sub { return Local::Cache->new() };

		my $display = make_display(info => Local::Info->new(cookies => { cart => 'sku1:2:sku2:1' }));
		$display->as_string({});
		is($seen{'itemsincart'}, 3, 'items counted');

		# An odd number of fields is not a cart
		%seen = ();
		make_display(info => Local::Info->new(cookies => { cart => 'sku1:2:sku2' }))->as_string({});
		ok(!$seen{'cart'}, 'malformed cart ignored');

		# Anything that is not a plain word must not reach the template,
		# whether it is smuggled in the key or in the value
		%seen = ();
		make_display(info => Local::Info->new(cookies => { cart => 'good:1:<script>:1:bad:<img src=x>:x y:1' }))->as_string({});
		is_deeply($seen{'cart'}, { good => 1 }, 'hostile keys and values stripped');
		is($seen{'itemsincart'}, 1, 'and not counted');

		# A cart passed in is used as is, and empty entries dropped
		%seen = ();
		make_display()->as_string({ cart => { a => 2, b => '', c => undef } });
		is_deeply($seen{'cart'}, { a => 2 }, 'empty entries removed');
		is($seen{'itemsincart'}, 2, 'counted');
		restore_all();
	};

	subtest 'as_string - caching and redirects' => sub {
		my $html_calls = 0;
		my $cache = Local::Cache->new();
		mock 'Web::VWF::Display::http' => sub { return "Content-Type: text/html\n\n" };
		mock 'Web::VWF::Display::html' => sub { $html_calls++; return '<form>x</form>' };
		mock 'Web::VWF::Display::create_memory_cache' => sub { return $cache };

		my $display = make_display();
		my $page;
		my $printed = capture_stdout(sub { $page = $display->as_string({ page => 'p' }) });
		is($page, "Content-Type: text/html\n\n<form>x</form>", 'headers then body');
		like($printed, qr/\ASet-Cookie: csrf_token=/, 'form page gets a token');
		is_deeply([map { $_->[2] } @{$cache->{'sets'}}], [$CONFIG{'cache_duration'}], 'cached for five minutes');

		# The second request comes from the cache, and still gets a fresh token
		$printed = capture_stdout(sub { is($display->as_string({ page => 'p' }), $page, 'same page') });
		is($html_calls, 1, 'not rendered again');
		like($printed, qr/\ASet-Cookie: csrf_token=/, 'cached form page still gets a token');

		# A page with things in the cart is never shared through the cache
		$cache = Local::Cache->new();
		capture_stdout(sub { $display->as_string({ itemsincart => 2 }) });
		is_deeply($cache->{'sets'}, [], 'cart pages not cached');

		# A redirect is returned as is, without a body
		mock 'Web::VWF::Display::http' => sub { return "Location: /elsewhere\n\n" };
		$html_calls = 0;
		is(make_display()->as_string({ page => 'redirect' }), "Location: /elsewhere\n\n", 'redirect');
		is($html_calls, 0, 'no body rendered');
		restore_all();
	};

	subtest 'display objects have no cycles' => sub {
		my $display = make_display(_logger => Local::Logger->new());
		$display->add_preload('/a.css', 'style')->set_cookie(a => 1);
		memory_cycle_ok($display, 'no cycles');
	};
};

# ===========================================================================
subtest 'Web::VWF::Display::captcha' => sub {
	fresh();
	local $ENV{'SCRIPT_NAME'};

	my $config = sub { bless({ recaptcha => { enabled => 1, site_key => 'site' }, @_ }, 'Web::VWF::Config') };
	my %seen;
	my $mock_parent = sub { mock 'Web::VWF::Display::html' => sub { %seen = %{$_[1]}; return 'page' } };

	subtest 'html - defaults' => sub {
		$mock_parent->();
		my $display = make_display(class => 'Web::VWF::Display::captcha', config => $config->());
		is($display->html(), 'page', 'parent renders');
		is_deeply(\%seen, { site_key => 'site', script_name => '/cgi-bin/page.fcgi', soft_limit => 100, time_window => 60,
			is_hard_block => 0, request_count => 0 }, 'defaults');
		restore_all();
	};

	subtest 'html - configured' => sub {
		$mock_parent->();
		local $ENV{'SCRIPT_NAME'} = '/page';
		my $logger = Local::Logger->new();
		my $display = make_display(class => 'Web::VWF::Display::captcha', logger => $logger,
			config => $config->(security => { rate_limiting => { max_requests => 7, time_window => '30s' } }));
		$display->html(hard_block => 1, request_count => 99);
		is_deeply(\%seen, { site_key => 'site', script_name => '/page', soft_limit => 7, time_window => 30,
			is_hard_block => 1, request_count => 99 }, 'configured values');
		like($logger->messages('debug')->[0], qr/hard block\z/, 'logged');
		restore_all();
	};

	subtest 'html - refusals' => sub {
		$mock_parent->();
		%seen = ();
		my $display = make_display(class => 'Web::VWF::Display::captcha', config => $config->());
		delete $display->{'config'};
		throws_ok { $display->html() } qr/\AMissing 'config' handle/, 'no config';
		$display = make_display(class => 'Web::VWF::Display::captcha', config => $config->());
		delete $display->{'info'};
		throws_ok { $display->html() } qr/\AMissing 'info' handle/, 'no info';
		foreach my $recaptcha (undef, {}, { enabled => 0, site_key => 's' }) {
			$display = make_display(class => 'Web::VWF::Display::captcha', config => $config->(recaptcha => $recaptcha));
			throws_ok { $display->html() } qr/\AreCAPTCHA is not enabled in configuration/, 'reCAPTCHA disabled';
		}
		is_deeply(\%seen, {}, 'nothing rendered');
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::Display::index' => sub {
	fresh();
	local $ENV{'REMOTE_ADDR'};

	my (@rendered, $cache);
	my $setup = sub {
		@rendered = ();
		$cache = Local::Cache->new();
		mock 'Web::VWF::Display::html' => sub { my $self = shift; push @rendered, [@_]; return 'page' };
		mock 'Web::VWF::Display::index::create_disc_cache' => sub { return $cache };
		return;
	};
	my $index_db = bless({ updated => 'today', emails => { alice => 'alice@example.com' } }, 'Local::IndexDB');
	{
		no strict 'refs';
		*{'Local::IndexDB::updated'} = sub { return $_[0]->{'updated'} };
		*{'Local::IndexDB::email'} = sub { my ($self, $args) = @_; my $e = $self->{'emails'}{$args->{'entry'}}; return defined($e) ? ($e) : () };
	}
	my $page = sub {
		my (%info) = @_;
		return make_display(class => 'Web::VWF::Display::index', info => Local::Info->new(%info));
	};

	subtest 'no parameters' => sub {
		$setup->();
		is($page->()->html(), 'page', 'index page');
		is_deeply(\@rendered, [[]], 'rendered with nothing extra');

		@rendered = ();
		my $params = { page => 'index', lang => 'en', fbclid => 'x' };
		$page->(params => $params)->html(index => $index_db);
		is_deeply(\@rendered, [['updated', 'today']], 'tracking parameters ignored');
		is_deeply($params, { page => 'index', lang => 'en', fbclid => 'x' }, 'request parameters restored afterwards');
		restore_all();
	};

	subtest 'refusals' => sub {
		$setup->();
		my $display = $page->();
		delete $display->{'_info'};
		croaks_with(sub { $display->html() }, 'Missing _info in object', 'no info');
		croaks_with(sub { $page->(params => { name => 'x' })->html() }, "Missing 'index' handle", 'no database');
		croaks_with(sub { $page->(params => { name => 'x' }, person => 'mallory')->html(index => $index_db) },
			'No email entry assigned to mallory', 'unknown person');
		restore_all();
	};

	subtest 'login' => sub {
		$setup->();
		$page->(params => { action => 'login', name => 'VWF' })->html(index => $index_db);
		is_deeply(\@rendered, [[{ error => 'Fill in name and password' }]], 'password required');

		# Every wrong combination is refused, and none starts a session
		foreach my $creds (['VWF', 'wrong'], ['wrong', 'Password'], ['vwf', 'password'], ['Password', 'VWF']) {
			@rendered = ();
			my $display = $page->(params => { action => 'login', name => $creds->[0], password => $creds->[1] });
			$display->html(index => $index_db);
			is_deeply(\@rendered, [[{ error => 'Incorrect name or password' }]], "refused: @{$creds}");
			ok(!$display->{'_cookies'}, 'no session cookie');
		}
		is_deeply($cache->{'sets'}, [], 'no session stored');

		my $display = $page->(params => { action => 'login', name => 'VWF', password => 'Password' });
		is($display->html(index => $index_db), 'Location: /cgi-bin/page.fcgi?page=admin', 'right credentials redirect');
		my $session = $display->{'_cookies'}{'session'};
		like($session, qr/\A\w{8}\z/, 'session cookie set');
		is($cache->get('VWF'), $session, 'session stored');
		restore_all();
	};

	subtest 'session cookie' => sub {
		$setup->();
		$cache->set('VWF', 'goodkey1');
		is($page->(params => { name => 'x' }, cookies => { session => 'goodkey1' })->html(index => $index_db),
			'Location: /cgi-bin/page.fcgi?page=admin', 'valid session goes to admin');

		# A forged cookie gets nowhere, and must not end the real session
		@rendered = ();
		$page->(params => { name => 'x' }, cookies => { session => 'forged!!' })->html(index => $index_db);
		is_deeply(\@rendered, [[{ error => 'You need to login to access the admin screen' }]], 'forged cookie refused');
		is($cache->get('VWF'), 'goodkey1', 'real session survives');
		restore_all();
	};

	subtest 'mail rate limit' => sub {
		$setup->();
		local $ENV{'REMOTE_ADDR'} = $CONFIG{'client_ip'};
		my $display = $page->(params => { name => 'x' }, person => 'alice');
		$display->{'mailfrom'}{$CONFIG{'client_ip'}} = $CONFIG{'mail_limit'};
		warnings_are { $display->html(index => $index_db) } [], 'no logger, no crash';
		is_deeply(\@rendered, [[{ error => 'You have reached your limit for sendmail e-mails' }]], 'limit enforced');
		is($display->{'mailfrom'}{$CONFIG{'client_ip'}}, $CONFIG{'mail_limit'}, 'count not increased by a refusal');
		restore_all();
	};

	subtest 'who to contact' => sub {
		$setup->();
		$page->(params => { name => 'x' })->html(index => $index_db);
		is_deeply(\@rendered, [[{ error => 'Who do you want to contact?' }]], 'person required');
		restore_all();
	};
};

# ===========================================================================
subtest 'Web::VWF::Display::meta_data' => sub {
	fresh();

	# Log rows are written in local time
	my $stamp = sub { strftime('%Y-%m-%d %H:%M:%S', localtime(CORE::time() - shift)) };
	my $log = sub {
		my (@rows) = @_;
		return bless({ rows => \@rows }, 'Local::VwfLog');
	};
	{
		no strict 'refs';
		*{'Local::VwfLog::selectall_array'} = sub { return @{$_[0]->{'rows'}} };
		*{'Local::VwfLog::type'} = sub { my ($self, $args) = @_; return grep { ref($_) eq 'HASH' && ($_->{'type'} // '') eq $args->{'type'} } @{$self->{'rows'}} };
		*{'Local::VwfLog::http_code'} = sub { return map { $_->{'http_code'} } grep { ref($_) eq 'HASH' } @{$_[0]->{'rows'}} };
	}
	my $display = make_display(class => 'Web::VWF::Display::meta_data');
	my $minute = $CONFIG{'seconds_per_minute'};

	subtest 'html' => sub {
		my %seen;
		mock 'Web::VWF::Display::html' => sub { %seen = %{$_[1]}; return 'page' };
		mock 'Web::VWF::Display::meta_data::get_server_metrics' => sub { return { cpu_count => 1 } };
		my $rows = $log->(
			{ time => $stamp->($minute), type => 'web', http_code => 200, duration_ms => 5, template => 't' },
			{ time => $stamp->($minute), type => 'robot', http_code => 404, duration_ms => 5, template => 't' },
		);
		is($display->html(vwf_log => $rows), 'page', 'rendered');
		like($seen{'browser_chart'}, qr/id="browser_chart"/, 'browser chart');
		like($seen{'status_chart'}, qr/id="status_chart"/, 'status chart');
		# Two snippets both declare "const data", so each script needs its own
		# scope or the second chart throws and draws nothing
		like($seen{'browser_chart'}, qr/\(function \(\) \{.*\}\)\(\);/s, 'browser chart script scoped');
		like($seen{'status_chart'}, qr/\(function \(\) \{.*\}\)\(\);/s, 'status chart script scoped');
		like($seen{'rate_chart'}, qr/id="rate_chart"/, 'rate chart');
		like($seen{'latency_chart'}, qr/id="latency_chart"/, 'latency chart');
		like($seen{'slow_chart'}, qr/Not enough data yet/, 'placeholder instead of an empty slow panel');
		is_deeply($seen{'server'}, { cpu_count => 1 }, 'server metrics');
		throws_ok { $display->html() } qr/\AMissing 'vwf_log' handle/, 'log required';
		restore_all();
	};

	subtest 'get_server_metrics' => sub {
		mock 'System::Info::new' => sub { return bless({}, 'Local::SysInfo') };
		{
			no strict 'refs';
			*{'Local::SysInfo::ncpu'} = sub { return 4 };
			*{'Local::SysInfo::cpu_type'} = sub { return 'x86' };
		}
		mock 'Web::VWF::Display::meta_data::df' => sub { return { per => 42 } };
		mock 'Sys::MemInfo::totalmem' => sub { return 1000 };
		mock 'Sys::MemInfo::freemem' => sub { return 250 };
		my $m = Web::VWF::Display::meta_data->get_server_metrics();
		returns_ok($m, { type => 'hashref' }, 'hashref');
		is_deeply($m, { cpu_count => 4, cpu_type => 'x86', disk_used_pct => 42, memory_used_pct => 75 }, 'metrics');

		# Odd readings must not divide by zero or invent numbers
		mock 'Web::VWF::Display::meta_data::df' => sub { return { blocks => 0, bfree => 0 } };
		mock 'Sys::MemInfo::totalmem' => sub { return 0 };
		lives_ok { $m = Web::VWF::Display::meta_data->get_server_metrics() } 'empty filesystem and no memory';
		is($m->{'disk_used_pct'}, undef, 'no disk percentage');
		is($m->{'memory_used_pct'}, 0, 'no memory percentage');
		mock 'Web::VWF::Display::meta_data::df' => sub { return };
		mock 'Sys::MemInfo::totalmem' => sub { return };
		$m = Web::VWF::Display::meta_data->get_server_metrics();
		is($m->{'disk_used_pct'}, undef, 'df failed');
		mock 'Web::VWF::Display::meta_data::df' => sub { return { blocks => 200, bfree => 50 } };
		is(Web::VWF::Display::meta_data->get_server_metrics()->{'disk_used_pct'}, 75, 'computed when per is missing');
		restore_all();
	};

	subtest 'get_traffic_metrics' => sub {
		my $rows = $log->(
			{ time => $stamp->($minute), ip => 'a', http_code => 200 },
			{ time => $stamp->(2 * $minute), ip => 'a', http_code => 500 },
			{ time => $stamp->(3 * $minute), ip => 'b', http_code => 404 },
			{ time => $stamp->(2 * 3600), ip => 'c', http_code => 500 },		# too old
			{ time => 'yesterday', ip => 'd' },					# unparsable
			{ ip => 'e' },								# no time
			'not a hash',
			undef,
		);
		my $m;
		warnings_are { $m = $display->get_traffic_metrics($rows, $CONFIG{'domain'}) } [], 'junk rows skipped quietly';
		is_deeply($m, { requests_per_hour => 3, active_users => 2, errors_last_hour => 2 }, 'last hour only');
		is_deeply($display->get_traffic_metrics($log->(), $CONFIG{'domain'}), { requests_per_hour => 0, active_users => 0, errors_last_hour => 0 }, 'empty log');
	};

	subtest 'get_request_rate_24h' => sub {
		my $t = $stamp->($minute);
		my $hour = substr($t, 11, 2) . ':00';
		my $rows = $log->(
			{ time => $t, http_code => 200 },
			{ time => $t, http_code => 503 },
			{ time => $t },
			{ time => $stamp->(2 * 86400), http_code => 500 },
			{ time => '2024-13-45 99:99:99' },
			'junk',
		);
		my $r = $display->get_request_rate_24h($rows, $CONFIG{'domain'});
		is_deeply($r->{'total'}, [[$hour, 3]], 'total');
		is_deeply($r->{'errors'}, [[$hour, 1]], 'errors');
		is_deeply($r->{'error_pct'}, [[$hour, 33.33]], 'error percentage');
		is_deeply($display->get_request_rate_24h($log->(), 'x'), { total => [], errors => [], error_pct => [] }, 'empty log');
	};

	subtest 'get_latency_24h' => sub {
		my $t = $stamp->($minute);
		my $hour = substr($t, 11, 2) . ':00';
		my $r = $display->get_latency_24h($log->(map { { time => $t, duration_ms => $_ } } 10, 20, 30, 40), 'x');
		is_deeply($r->{'avg'}, [[$hour, 25]], 'average');
		is_deeply($r->{'p95'}, [[$hour, 30]], '95th percentile');

		# Rows written by the old timer bug hold about 1.8e12 ms: no request
		# lasted a day, so they are not measurements and must not skew a chart
		my $stale = $display->get_latency_24h($log->(map { { time => $t, duration_ms => $_ } } 10, 20, 30, 40, 1_794_339_232_583), 'x');
		is_deeply($stale->{'avg'}, [[$hour, 25]], 'implausible duration ignored in the average');
		is_deeply($stale->{'p95'}, [[$hour, 30]], 'implausible duration ignored in the percentile');

		# The log is written from requests: a duration must never be run as
		# code, and anything that is not a number is not a duration
		our $PWNED = 0;
		my @hostile = ('$main::PWNED = 1', 'die "pwned"', 'system("false")', '1; $main::PWNED = 1', 'abc', '');
		my $rows = $log->((map { { time => $t, duration_ms => $_ } } @hostile), { time => $t, duration_ms => 8 });
		warnings_are { $r = $display->get_latency_24h($rows, 'x') } [], 'no warnings';
		is($PWNED, 0, 'log contents not executed');
		is_deeply($r->{'avg'}, [[$hour, 8]], 'only the number counted');
		is_deeply($display->get_latency_24h($log->({ time => $t }), 'x'), { avg => [], p95 => [] }, 'no durations');
	};

	subtest 'get_slow_endpoints_24h' => sub {
		my $t = $stamp->($minute);
		my @rows;
		foreach my $n (1 .. $CONFIG{'slow_top_n'} + 2) {
			push @rows, map { { time => $t, template => "/srv/templates/web/p$n.tmpl", duration_ms => $n * 10 } } 1 .. $CONFIG{'slow_min_samples'};
		}
		push @rows, map { { time => $t, template => 'rare', duration_ms => 99999 } } 1 .. $CONFIG{'slow_min_samples'} - 1;
		my $dp = $display->get_slow_endpoints_24h($log->(@rows), 'x');
		my @labels = map { $_->[0] } @{$dp};
		is(scalar(@labels), $CONFIG{'slow_top_n'}, 'top ten only');
		is($labels[0], 'web/p12.tmpl', 'slowest first, templates/ prefix removed');
		ok(!(grep { $_ eq 'rare' } @labels), 'too few samples to rank');

		# A stale timer reading must not fill the slow-endpoint chart
		my @stale = map { { time => $t, template => 'stale.tmpl', duration_ms => 1_794_339_232_583 } } 1 .. $CONFIG{'slow_min_samples'};
		my $stale_dp = $display->get_slow_endpoints_24h($log->(@rows, @stale), 'x');
		ok(!(grep { $_->[0] eq 'stale.tmpl' } @{$stale_dp}), 'implausible duration not ranked');

		# A whole day is the boundary: longer than this window is impossible,
		# a whole day itself is merely the worst request imaginable
		my @boundary = map { { time => $t, template => 'boundary.tmpl', duration_ms => 86_400_000 } } 1 .. $CONFIG{'slow_min_samples'};
		is_deeply($display->get_slow_endpoints_24h($log->(@boundary), 'x'), [['boundary.tmpl', 86_400_000]], 'a full-window duration is plausible');

		# Labels are data for HTML::D3, which escapes them when it writes the
		# chart: they are passed through here unchanged, never run or quoted.
		my $evil = 'x\\"); alert(1); ("';
		$dp = $display->get_slow_endpoints_24h($log->(map { { time => $t, template => $evil, duration_ms => 5 } } 1 .. $CONFIG{'slow_min_samples'}), 'x');
		is($dp->[0][0], $evil, 'label passed through for HTML::D3 to escape');

		my @junk = ('not a hash', undef, { time => $t, duration_ms => 'abc' }, { time => $t, duration_ms => -1 }, { time => $t, duration_ms => 0 }, { duration_ms => 5 });
		warnings_are { $dp = $display->get_slow_endpoints_24h($log->(@junk), 'x') } [], 'junk rows skipped quietly';
		is_deeply($dp, [], 'nothing ranked');
	};

	subtest '_utc_offset' => sub {
		require Time::Local;
		my $now = CORE::time();
		my $offset = Web::VWF::Display::meta_data::_utc_offset();
		returns_ok($offset, { type => 'integer' }, 'integer');
		is($offset, Time::Local::timegm(localtime($now)) - $now, 'matches the system time zone');
		is($offset % $CONFIG{'seconds_per_minute'}, 0, 'whole minutes');
	};
};

# ===========================================================================
subtest 'Web::VWF::Display::table' => sub {
	fresh();
	my $dir = tempdir(CLEANUP => 1);
	my $databases = File::Spec->catdir($dir, 'databases');
	File::Path::make_path(File::Spec->catdir($databases, 'My'));
	my $file = File::Spec->catfile($databases, 'people');
	open(my $out, '>', $file) or die "$file: $!";
	print $out "key!name\n# a comment\n\nk1!Alice\nk2!Bob\n";
	close($out);
	open($out, '>', File::Spec->catfile($databases, 'My', 'Table')) or die;
	print $out "key!v\nz!1\n";
	close($out);

	local $ENV{'DOCUMENT_ROOT'};
	local $ENV{'HOME'} = $dir;

	my $table = sub { return bless({ _config => { root_dir => $dir }, _info => Local::Info->new(), @_ }, 'Web::VWF::Display::table') };

	subtest 'new' => sub {
		my @calls;
		mock 'Config::Auto::parse' => sub { push @calls, [@_]; return { root_dir => $dir } };
		my $t = Web::VWF::Display::table->new(info => Local::Info->new(), table => 'people');
		returns_ok($t, { type => 'object', isa => 'Web::VWF::Display::table' }, 'object');
		is_deeply($calls[0], [$CONFIG{'domain'}, path => File::Spec->catdir($dir, 'lib', 'conf')], 'site file from ~/lib/conf');
		memory_cycle_ok($t, 'no cycles');
		local $ENV{'DOCUMENT_ROOT'} = '/var/www/html';
		Web::VWF::Display::table->new({ info => Local::Info->new() });
		is($calls[1][2], File::Spec->catdir('/var/www/html', File::Spec->updir(), 'lib', 'conf'), 'beside the document root');
		restore_all();

		mock 'Config::Auto::parse' => sub { die "unparsable\n" };
		throws_ok { Web::VWF::Display::table->new(info => Local::Info->new()) } qr/\AConfiguration error: unparsable\n/, 'parse failure';
		restore_all();
	};

	subtest 'get_file_path' => sub {
		is($table->(_table => 'people')->get_file_path(), $file, 'named table');
		is($table->(_table => 'My::Table')->get_file_path(), File::Spec->catfile($databases, 'My', 'Table'), ':: becomes /');
		throws_ok { $table->(_table => 'nobody')->get_file_path() } qr/\ACan't open \Q$databases\E\/nobody/, 'missing table';

		# The table name becomes a path: it must not reach outside databases/
		foreach my $bad ('../../../etc/passwd', '..', 'My/../../people', '/etc/passwd', '..::..::etc::passwd') {
			throws_ok { $table->(_table => $bad)->get_file_path() } qr/\AInvalid table name /, "'$bad' refused";
		}
	};

	subtest 'load_data / fetch / columns / fetch_as_hash' => sub {
		my $t = $table->(_table => 'people');
		is($t->load_data(), $t, 'load_data chains');
		is_deeply([sort @{$t->columns()}], ['key', 'name'], 'columns');
		is_deeply($t->fetch(key => 'k1'), { name => 'Alice' }, 'one row, keyed by its key column');
		is_deeply($t->fetch({ key => 'nobody' }), undef, 'unknown key');
		is_deeply([map { $_->{'name'} } @{$t->fetch()}], ['Alice', 'Bob'], 'every row, comments and blanks skipped');
		is_deeply([sort keys %{$t->fetch_as_hash()}], ['k1', 'k2'], 'keyed by key');

		# Loaded once
		mock 'Web::VWF::Display::table::get_file_path' => sub { die 'must not re-read' };
		lives_ok { $t->fetch(key => 'k2') } 'cached';
		restore_all();

		throws_ok { $table->(_table => 'nobody')->fetch() } qr/\ACan't open /, 'missing table propagates';
	};
};

done_testing();
