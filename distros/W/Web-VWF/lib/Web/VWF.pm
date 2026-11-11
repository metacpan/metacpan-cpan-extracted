package Web::VWF;

# njh@nigelhorne.com

use strict;
use warnings;
# use diagnostics;

use version; our $VERSION = version->declare('0.001.0');

# TODO: Try Log::Any::Adapter::Abstraction instead of Log::Any

BEGIN {
	# Sanitize environment variables
	delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
	$ENV{'PATH'} = '/usr/local/bin:/bin:/usr/bin';	# For insecurity
}

no lib '.';

use Log::WarnDie 0.09;
use Carp::Always;
use CGI::ACL 0.06;	# For deny_cloud
use CGI::Carp qw(fatalsToBrowser);
use CGI::Info 0.94;	# Gets all messages
use CGI::Lingua 0.61;
use CHI;
use Class::Simple;
use Config::Abstraction;
use Database::Abstraction;
# use Devel::Confess;
use File::Basename;
# use CGI::Alert $ENV{'SERVER_ADMIN'} || 'you@example.com';
use FCGI;
use FCGI::Buffer;
use File::HomeDir;
use HTTP::Status;
use Log::Abstraction;
use Error qw(:try);
use File::Spec;
use Params::Get;
use POSIX qw(strftime);
use Readonly;
use Module::Runtime qw(require_module);	# Safe dynamic module loading; avoids string eval
use Timer::Simple;
use Time::HiRes;

# FIXME: Sometimes gives Insecure dependency in require while running with -T switch in Module/Runtime.pm
# use Taint::Runtime qw($TAINT taint_env);
use autodie qw(:all);

# Where to find the site's own page modules and configuration.  The framework
# modules themselves are installed by HTTP-VWF, so this only needs to point at
# the site's own lib directory when the site has page subclasses of its own.
# use lib '/usr/lib/example.com/lib';
# use lib '../lib';
use lib CGI::Info::script_dir() . '/../lib';
# use lib File::HomeDir->my_home() . '/lib/perl5';

use Web::VWF::Allow;
use Web::VWF::Blacklist;
use Web::VWF::Config;
use Web::VWF::Utils;

# Where the server keeps the configuration of the sites it serves: one directory
# per site, named after the site, read when the site has no conf/ of its own
# beside cgi-bin/.  A site whose host keeps them elsewhere changes this line and
# nothing else - it is passed to Web::VWF->new() below, and to the page modules,
# so that both read the site's configuration from the same place.
Readonly my $SERVER_CONF_DIR => '/usr/lib/vwf';

# $TAINT = 1;
# taint_env();

# Soft rate-limit: present a CAPTCHA challenge when a client exceeds this
# many requests within $TIME_WINDOW.  Overridable via the config file.
Readonly my $MAX_REQUESTS => 100;
Readonly my $TIME_WINDOW => '60s';	# CHI-style duration string

Readonly my @suffixlist => ('.pl', '.fcgi');

# Set up by _init() on the first call to run(), not when the module is loaded.
# Loading a module should do no work: reading configuration here meant that
# anything that executed the page script while it was still compiling - such as
# a configuration reader that took the script for its own configuration file -
# ran the framework again inside itself, with any errors silently swallowed.
my $info;
my $script_name;
my $tmpdir;

# $vwflog holds the path to the CSV access log; resolved from config on first request.
my $vwflog;

# These caches are created lazily on the first request and reused across the
# FCGI accept loop to amortise the cost of cache initialisation.
my $info_cache;
my $lingua_cache;
my $buffercache;

# Also set by _init()
my $script_dir;
my $env_prefix;
my $config_abstraction;
my $logger;

# True while run() is executing, so that a nested call can be refused
our $RUNNING;

# my $pagename = "Web::VWF::Display::$script_name";
# eval "require $pagename";

# Loaded later, only when needed
# use Web::VWF::Display::index;
# use Web::VWF::Display::upload;
# use Web::VWF::Display::editor;
# use Web::VWF::Display::meta_data;

# ── What a site declares, and what it gets if it declares nothing ───────────
# The directory its databases are in, the data modules it loads, the languages
# it offers and the addresses it allows or trusts are all site settings, read
# from the domain's configuration file - see "Site Settings" in Web::VWF's
# documentation.  What is below is what this script used to hardcode, so a site
# that says nothing behaves exactly as it did before.  The settings are resolved
# by _site_setup() on the first request, because the configuration cannot be read
# until the domain is known.
Readonly my $DEFAULT_DATABASE_DIR => 'data';		# beside cgi-bin/
Readonly my @DEFAULT_DATA_MODULES => qw(Web::VWF::Data::index);
Readonly my @DEFAULT_SUPPORTED_LANGUAGES => qw(en-gb);
# One site's own address, kept so that a site that came from this script and says
# nothing keeps working; a site that wants a different list sets allow_ips.
#
# It is not called allowed_ips because that is a CGI::ACL constructor argument,
# and CGI::ACL's new() runs the site's configuration through
# Object::Configure::configure(), which hands a key of that name straight to it
# as a string where a hash is expected, breaking the ACL outright.
Readonly my @DEFAULT_ALLOW_IPS => qw(108.44.193.70 127.0.0.1);
# Loopback and private addresses are exempt from rate limiting.
Readonly my @DEFAULT_RATE_LIMIT_TRUSTED_IPS => qw(127.0.0.1 192.168.1.1);

# The access log is the one data module this script builds itself, because which
# log to read comes from the vwflog setting; its class is loaded here so that
# doit() can construct it without a compile-time use.
require_module('Web::VWF::Data::vwf_log');
Web::VWF::Data::vwf_log->import() if(Web::VWF::Data::vwf_log->can('import'));

# Resolved from the configuration by _site_setup(): the directory holding the
# site's databases, and the data handles it declared, by the name each is passed
# to a page under (index, say).
my $database_dir;
my %data;

# The lists from the configuration, likewise.
my @supported_languages;
my @rate_limit_trusted_ips;

# $config is populated lazily inside doit() so that per-domain configuration
# is loaded after the FCGI request has been accepted and the domain is known.
my $config;

# The pages that may be loaded; worked out in doit() since it needs $config
my @valid_pages;

# FastCGI signal handling: the FCGI process lives across many requests so we
# cannot exit immediately on SIGTERM/SIGUSR1 - we set a flag and exit cleanly
# after the current request finishes.  See http://fastcgi.com/docs/faq.html#PerlSignals
my $requestcount = 0;
my $handling_request = 0;	# 1 while inside doit(), 0 between requests
my $exit_requested = 0;		# set to 1 by sig_handler; checked after each request

# In-memory set of IPs that have been permanently blacklisted this process
# lifetime (e.g. for sending SQL-injection strings).
my %blacklisted_ip;

# Per-IP request counter cache; created lazily on first request.
my $rate_limit_cache;

# The CGI::ACL object is built on the first request, once $config is loaded,
# because the country blacklist (Web::VWF::Blacklist) can come from the config file.
my $acl;

=head1 NAME

Web::VWF - Versatile Web Framework - easily build a website to support different languages and client platforms

=head1 VERSION

Version 0.001.0

=head1 DESCRIPTION

Web::VWF is L<VWF|https://github.com/nigelhorne/vwf>, the Versatile Web
Framework, packaged as a CPAN distribution.  It is an MVC framework for
building responsive websites that adapt to the client's language, to the kind
of client (web, mobile, robot, search engine or AI crawler) and to whichever
database back end the site uses.

This module is the distribution's front door: it holds the version number, this
overview, and the one thing a site builds by hand - L</new>, the site's
configuration and the directory the server keeps it in.  Working the framework
does these modules:

=over 4

=item L<Web::VWF::Display>

The page renderer.  Given the configuration, the browser's language and the
kind of client it is, it finds the right template for a page and renders it.
A site subclasses it for each of its pages.

=item L<Web::VWF::Config>

Reads the site's XML configuration.

=item L<Web::VWF::Allow>

Access control and rate limiting.

=item L<Web::VWF::Blacklist>

The country blacklist, shared by the page script, L<Web::VWF::Allow> and
L<Web::VWF::Display>.

=item L<Web::VWF::Utils>

Cache initialisation and the Haversine distance calculation.

=item L<Web::VWF::CAPTCHA>

reCAPTCHA integration and the bypass that follows a solved challenge.

=item L<Web::VWF::Data::E<lt>sourceE<gt>>

The data access layer: CSV, XML and SQLite, through Database::Abstraction.

=back

C<cgi-bin/page.fcgi> in this distribution is a working page script to copy and
adapt into a site's own C<cgi-bin>; C<templates/>, C<conf/example.com> and
C<data/> beside it are the small site it serves, and the starting point for a
new one.  F<examples/basic-site/> is that site laid out on its own - the script,
the configuration, the templates and the data - and its F<README.md> documents
it as an example to copy: where a site's configuration is read from, what
C<root_dir> is, and how to run it before it is deployed.  F<examples/links.nigelhorne.com/>
is the other kind of site: one page of its own, a C<Web::VWF::Display>
subclass whose answer is a redirect rather than a rendering of a template, and
whose own script it keeps - the example documents the four changes to this one
that it takes, and why.

A site's templates sit under a path built from the page's class name,
so the file to change when the page module is C<Web::VWF::Display::index> is
F<templates/en/web/HTTP/VWF/Display/index.tmpl> - see L<Web::VWF::Display>
for the rest of the search order.  F<CLAUDE.md> records how a request is handled
once it arrives.

A site that used to carry a renamed copy of VWF of its own deletes that copy,
installs this distribution, renames C<VWF::> to C<Web::VWF::> in its own code,
and moves its templates from C<.../VWF/Display/> to C<.../HTTP/VWF/Display/>.

=head1 SUBROUTINES/METHODS

=head2 new

The configuration of a site, and the directory the server keeps it in.

B<Parameters:>

=over 4

=item * C<directory> - The directory the server keeps the configuration of the
sites it serves in: one directory per site, named after the site, so that a site
reached as F<example.com> is configured from F</usr/lib/vwf/example.com>.  Any
other root can be named here - F</etc/vwf>, F</usr/local/etc/vwf> - and the
default is F</usr/lib/vwf>.  Optional.

=item * C<info>, C<logger>, C<config_directory>, C<config_file>, C<config> -
handed to L<Web::VWF::Config>, which describes them.

=back

=cut

sub new
{
	my $proto = shift;
	my $params = Params::Get::get_params(undef, @_) // {};

	my $class = ref($proto) || $proto;

	if(defined($params->{'directory'}) && ref($params->{'directory'})) {
		Carp::croak('directory must be a string');
	}

	return bless {
		directory => $params->{'directory'},
		params => $params,
	}, $class;
}

=head2 directory

The directory the server keeps this site's configuration in: what C<new()> was
given, or F</usr/lib/vwf>.  L<Web::VWF::Config> adds the site's own name to it.

=cut

sub _directory
{
	my $self = shift;

	return $self->{'directory'} // $ENV{root_dir} // $Web::VWF::Config::DEFAULT_DIRECTORY;
}

=head2 config

The site's configuration, read once and kept: a site that has no F<conf/> of its
own beside F<cgi-bin/> is configured from the server's directory for it, and
L<Web::VWF::Config> describes the rest of the search.

=cut

sub _config
{
	my $self = shift;

	return $self->{'config'} ||= Web::VWF::Config->new({
		%{$self->{'params'}},
		directory => $self->_directory(),
	});
}

# Deferred shutdown handler: set the exit flag and, if we are between requests,
# flush caches and exit immediately.  If we are mid-request, the flag is checked
# after doit() returns so the in-flight response is sent cleanly.
sub sig_handler {
	$exit_requested = 1;
	$logger->trace('In sig_handler') if($logger);
	if(!$handling_request) {
		local $SIG{TERM} = local $SIG{USR1} = 'IGNORE';
		$logger->info('Shutting down') if($logger);
		# Flush the page-level response cache to disk before we exit.
		if($buffercache) {
			$buffercache->purge();
		}
		CHI->stats->flush();
		# Detach the dispatcher so that Log::WarnDie does not try to log
		# after the logger object has been destroyed.
		Log::WarnDie->dispatcher(undef);
		exit(0);
	}
}


# Everything the framework needs before the first request: the bootstrap
# CGI::Info, the script's name and temporary directory, the configuration and the
# logger.  Called once, from run().  The handlers for warnings and fatal errors
# are installed first, so that a failure while setting up is reported rather
# than lost.
sub _init
{
	my $self = shift;

	return if($self->{initialised});
	$self->{initialised} = 1;

	# USR1 and TERM both trigger a clean shutdown; PIPE is silenced because a
	# broken client connection mid-response should not kill the worker.
	$SIG{USR1} = \&sig_handler;
	$SIG{TERM} = \&sig_handler;
	$SIG{PIPE} = 'IGNORE';

	# Catch all Perl warnings and mirror them to the per-script stderr log file
	# as well as to the structured logger.
	$SIG{__WARN__} = sub {
		my $msg = join '', @_;
		if($tmpdir && open(my $fout, '>>', File::Spec->catfile($tmpdir, "$script_name.stderr"))) {
			print {$fout} (($info ? $info->domain_name() : undef) // '(unknown host)'), ": $msg";
			close $fout;
		}
		$logger->warn($msg) if($logger);
	};

	# Catch fatal errors.  The $^S guard prevents this handler from interfering
	# with Error.pm's try/catch blocks which use eval internally.
	$SIG{__DIE__} = sub {
		return if $^S;	# inside an eval - let the caller handle it
		my $msg = join '', @_;
		# Detach Log::WarnDie first so a logger error cannot cause infinite recursion.
		Log::WarnDie->dispatcher(undef);
		if($tmpdir && open(my $fout, '>>', File::Spec->catfile($tmpdir, "$script_name.stderr"))) {
			print {$fout} (($info ? $info->domain_name() : undef) // '(unknown host)'), ": $msg";
			close $fout;
		}
		$logger->fatal($msg) if($logger);
		CORE::die @_;	# re-throw so the original die location is preserved
	};

	# Bootstrap CGI::Info before the FCGI accept loop so we can derive the script
	# name and temp directory for logging even before the first real request.
	$info = CGI::Info->new();
	$script_name = $self->{script_name} = basename($info->script_name(), @suffixlist);
	$tmpdir = $info->tmpdir();

	# When running under a real HTTP server, redirect STDERR to a per-script log
	# file in the temp directory so that die/warn messages are captured.
	if($ENV{'HTTP_USER_AGENT'}) {
		close STDERR;
		open(STDERR, '>>', File::Spec->catfile($tmpdir, "$self->{script_name}.stderr"));
	}

	# Register the log filter that suppresses known-harmless warnings.
	Log::WarnDie->filter(\&filter);

	# Derive the environment-variable prefix from the hostname (e.g. MY_SITE_)
	# so that per-domain config overrides can be passed as environment variables.
	$script_dir = $info->script_dir();
	$env_prefix = uc($info->host_name()) . '_';
	$env_prefix =~ tr/\./_/;	# dots in hostnames become underscores in env var names
	# Config::Abstraction returns nothing, rather than an object, when no file
	# matches the domain: a vhost that has not been given a config file yet, the
	# command line test in the POD, or CI, where the hostname is a container id.
	# That is not fatal, so the logger is built with no configuration and the
	# framework carries on with its defaults - dying here would take the site down
	# over a configuration file that is only there to describe it.  The reason is
	# reported once rather than on every request.
	$config_abstraction = Config::Abstraction->new(env_prefix => $env_prefix, flatten => 0, config_file => $info->domain_name(), config_dirs => ["$script_dir/../conf/", "$script_dir/../../conf"]);
	$logger = Log::Abstraction->new($config_abstraction ? $config_abstraction->all() : {});
	Log::WarnDie->dispatcher($logger);

	unless($config_abstraction) {
		$logger->warn('No configuration file for ', ($info->domain_name() // '(unknown host)'), " in $script_dir/../conf/ or $script_dir/../../conf; using the defaults");
	}
}

sub run
{
	my $self = shift;

	# A nested call means something has executed the page script again while
	# it was running or still compiling - for example a configuration reader
	# that took the script for its own configuration file and evaluated it.
	# Refuse, loudly, on STDERR: a die here would be swallowed by that reader's
	# eval, and carrying on would consume the server's requests.
	if($RUNNING || (${^GLOBAL_PHASE} ne 'RUN')) {
		print STDERR __PACKAGE__, '::run() called re-entrantly or during compilation (phase ',
			${^GLOBAL_PHASE}, '); is the script being read as its own configuration file?', "\n";
		return;
	}
	local $RUNNING = 1;

	$self->_init();

	# my $request = FCGI::Request($stdin, $stdout, $stderr);
	my $request = FCGI::Request();

	# ─── Main FCGI request loop ───────────────────────────────────────────────────
	# Accept() blocks until the web server sends a new request.  It returns a
	# negative value when the server wants this worker to exit (e.g. graceful
	# shutdown), which breaks the loop naturally.
	while($handling_request = ($request->Accept() >= 0)) {
		# REMOTE_ADDR is absent when running from the command line for testing.
		# Switch to a verbose debug logger and single-shot mode in that case.
		unless($ENV{'REMOTE_ADDR'}) {
			my $timer = Timer::Simple->new();

			# Disable all caching so every run reflects the current templates.
			$ENV{'NO_CACHE'} = 1;

			# Map the LANG shell variable to the HTTP Accept-Language header so
			# that language detection works the same way it does in production.
			if((!defined($ENV{'HTTP_ACCEPT_LANGUAGE'})) && defined($ENV{'LANG'})) {
				my $lang = $ENV{'LANG'};
				$lang =~ s/\..*$//;	# strip encoding suffix (e.g. .UTF-8)
				$lang =~ tr/_/-/;	# POSIX uses _, HTTP uses -
				$ENV{'HTTP_ACCEPT_LANGUAGE'} = lc($lang);
			}

			Database::Abstraction::init({ logger => $logger });

			# Replace the production logger with a simple STDOUT printer.
			$logger = Log::Abstraction->new(logger => sub { print join(', ', @{$_[0]->{'message'}}), "\n" }, level => 'debug');
			Log::WarnDie->dispatcher($logger);
			$info->set_logger($logger);
			$self->_set_data_loggers($logger);

			# Enable full stack traces in Error.pm for command-line debugging.
			$Error::Debug = 1;
			try {
				$self->_doit(debug => 1);
			} catch Error with {
				my $msg = shift;
				warn "$msg\n", $msg->stacktrace();
				$logger->error($msg);
			};

			# Report wall-clock time taken for this command-line invocation.
			my @elapsed_time = $timer->hms();
			my $timetaken = int($elapsed_time[2] * 1000);
			$logger->info("$self->{script_name} completed in ${timetaken}ms");

			last;	# command-line mode is single-shot; exit the accept loop
		}

		# ── Live HTTP request ──────────────────────────────────────────────────
		$requestcount++;
		$logger->info("Request $requestcount: ", $ENV{'REMOTE_ADDR'});

		# Propagate the current logger to all data-access objects that may emit
		# log messages during this request.
		$info->set_logger($logger);
		$self->_set_data_loggers($logger);

		# Dispatch the request.  Any unhandled Error.pm exception is caught here
		# so a single bad request cannot kill the FCGI worker process.
		try {
			$self->_doit(debug => 0);
		} catch Error with {
			my $msg = shift;
			$logger->error("$msg: ", $msg->stacktrace());
			# Invalidate the response cache on error so a stale error page is
			# never served to subsequent clients.
			if($buffercache) {
				$buffercache->clear();
				$buffercache = undef;
			}
		};

		$request->Finish();

		$handling_request = 0;
		if($exit_requested) {
			last;
		}
		if($ENV{SCRIPT_FILENAME}) {
			if(-M $ENV{SCRIPT_FILENAME} < 0) {
				last;
			}
		}
	}
}

# ─── doit() — per-request handler ────────────────────────────────────────────
# Called once per FCGI iteration.  Handles security checks, language detection,
# template dispatch, response caching, and access logging.
sub _doit
{
	my $self = shift;

	# Record the wall-clock start time so we can report request duration later.
	my $request_start = Timer::Simple->new();

	# CGI::Info caches state between calls; reset it so this request gets a
	# fresh view of the environment rather than stale values from the last one.
	CGI::Info->reset();

	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# $config is built once per process and reused.  We cannot build it before
	# the first Accept() because the domain name is not known until then.
	# So don't pass $info in since it was created before the connection
	$config ||= Web::VWF::Config->new({
		directory => $self->_directory(),
		logger => $logger,
		debug => $params{'debug'},
		# A throwaway CGI::Lingua is used here only to satisfy Web::VWF::Config;
		# the real, cache-backed instance is created further below.  It has to be
		# given the default languages rather than the site's configured ones:
		# this call is what reads the configuration, so the site's list is not
		# known yet.
		lingua => CGI::Lingua->new({ supported => [ @DEFAULT_SUPPORTED_LANGUAGES ], info => $info, logger => $logger })
	});

	# The site's own settings - its database directory, data modules, languages
	# and trusted addresses - are read from that configuration, once per process.
	$self->_site_setup($config);

	# deny_cloud() blocks all known cloud provider address ranges (AWS, GCP,
	# Azure) which generate almost no legitimate human traffic but are a
	# common origin for automated scanning.  Geo-blocking is a blunt
	# instrument but effective at reducing noise.  It is also why an address a
	# site allows here is still refused if its reverse DNS says it is in a cloud.
	$acl ||= CGI::ACL->new()
		->deny_cloud()
		->deny_country(country => Web::VWF::Blacklist->new(countries => $config->{'blacklist_countries'})->countries());

	foreach my $ip ($self->_config_list($config, 'allow_ips', @DEFAULT_ALLOW_IPS)) {
		$acl->allow_ip($ip);
	}

	@valid_pages = $self->_valid_pages($config) unless(@valid_pages);

	# The CGI::Info disc cache stores parsed request data across FCGI restarts.
	$info_cache ||= create_disc_cache(config => $config, logger => $logger, namespace => 'CGI::Info');

	my $options = {
		cache => $info_cache,
		logger => $logger
	};

	# If syslog is configured, normalise the 'server' key to 'host' (the
	# Sys::Syslog convention) and pass the stanza to CGI::Info.
	my $syslog;
	if($syslog = $config->syslog()) {
		if($syslog->{'server'}) {
			$syslog->{'host'} = delete $syslog->{'server'};
		}
		$options->{'syslog'} = $syslog;
	}
	# Rebuild $info now that we have a cache and the domain is known.
	$info = CGI::Info->new($options);
	$logger->debug('In doit - domain is ', $info->domain_name());

	# Lazily initialise the in-memory rate-limit counter store.
	$rate_limit_cache ||= create_memory_cache(config => $config, logger => $logger, namespace => 'rate_limit');

	# Use the real remote IP as the rate-limit key; fall back to 'unknown'
	# only in the unlikely event that REMOTE_ADDR is absent.
	my $client_ip = $ENV{'REMOTE_ADDR'} || 'unknown';

	# A successful CAPTCHA solve stores a short-lived bypass token in the cache.
	# While the token is present the client is exempt from rate-limit checks.
	my $captcha_bypass_key = "$self->{script_name}:captcha_bypass:$client_ip";
	my $has_captcha_bypass = $rate_limit_cache->get($captcha_bypass_key);

	# Read the current request count for this IP from the sliding-window cache.
	my $request_count = $rate_limit_cache->get("$self->{script_name}:rate_limit:$client_ip") || 0;

	# Allow the thresholds to be tuned via the config file; fall back to the
	# compile-time constants if the stanza is missing.
	my $max_requests = $config->{'security'}->{'rate_limiting'}->{'max_requests'} || $MAX_REQUESTS;
	my $max_requests_hard = $config->{'security'}->{'rate_limiting'}->{'max_requests_hard'} || ($max_requests * 1.5);

	# The rate-limit window, as a CHI duration for the counter's TTL, and in
	# seconds for the Retry-After header (RFC 9110 section 10.2.3)
	my $time_window = $config->{'security'}->{'rate_limiting'}->{'time_window'} || $TIME_WINDOW;
	my $retry_after = duration_seconds($time_window);

	# Check if this is a CAPTCHA verification attempt
	if ($info->param('g-recaptcha-response')) {
		unless(Web::VWF::CAPTCHA->can('new')) {
			require Web::VWF::CAPTCHA;
			Web::VWF::CAPTCHA->import();
		}

		my $recaptcha_config = $config->recaptcha();
		if ($recaptcha_config && $recaptcha_config->{enabled}) {
			my $captcha = Web::VWF::CAPTCHA->new(
				site_key => $recaptcha_config->{site_key},
				secret_key => $recaptcha_config->{secret_key},
				logger => $logger
			);

			if ($captcha->verify($info->param('g-recaptcha-response'), $client_ip)) {
				# CAPTCHA verified - grant bypass
				my $bypass_duration = $config->{'security'}->{'rate_limiting'}->{'captcha_bypass_duration'} || '300s';
				$rate_limit_cache->set($captcha_bypass_key, 1, $bypass_duration);
				$rate_limit_cache->set("$self->{script_name}:rate_limit:$client_ip", 0, '60s'); # Reset counter

				$logger->info("CAPTCHA verified for $client_ip - rate limit bypass granted");
				$has_captcha_bypass = 1;

				# Redirect the client back to the page they were trying to reach.
				# SECURITY - CRLF / header-injection defence:
				#   Both the page name and SCRIPT_NAME are interpolated into the
				#   Location header.  A raw %0d%0a sequence in either value would
				#   let an attacker inject arbitrary HTTP response headers
				#   (response-splitting / header-injection).
				#   Strip $redirect_page to a strict allowlist (word chars and
				#   hyphens only), and remove any embedded CR or LF from the
				#   server-supplied SCRIPT_NAME before building the header.
				my $redirect_page = $info->param('page') || 'index';
				$redirect_page =~ s/[^A-Za-z0-9_-]//g;

				# Also sanitize the server variable - it is attacker-influenced
				# in some reverse-proxy configurations.
				my $script = $ENV{SCRIPT_NAME} // '/cgi-bin/page.fcgi';
				$script =~ s/[\r\n]//g;

				$info->status(302);
				print "Status: 302 Found\r\n",
					"Location: ${script}?page=${redirect_page}\r\n\r\n";
				return;
			} else {
				$logger->warn("CAPTCHA verification failed for $client_ip");
				# Fall through to show CAPTCHA again
			}
		}
	}

	$vwflog ||= $config->vwflog() || File::Spec->catfile($info->logdir(), 'vwf.log');
	# Reader for the CSV access log, used by the meta_data page.
	# Created from the same path that vwflog() writes to, which needs $config.
	$self->{vwf_log} ||= Web::VWF::Data::vwf_log->new({
		directory => dirname($vwflog),
		filename => basename($vwflog),
		no_entry => 1,
		logger => $logger,
	});
	my $log = Class::Simple->new();

	# Stores things for a month or longer
	$lingua_cache ||= create_disc_cache(config => $config, logger => $logger, namespace => 'CGI::Lingua');

	# Language negotiation, offering the languages this site offers
	my $lingua = CGI::Lingua->new({
		supported => \@supported_languages,
		cache => $lingua_cache,
		info => $info,
		logger => $logger,
		debug => $params{'debug'},
		syslog => $syslog,
	});

	my $cachedir = $params{'cachedir'} || $config->{disc_cache}->{root_dir} || File::Spec->catfile($tmpdir, 'cache');

	# Rate limit by IP (unless bypassed)
	unless($has_captcha_bypass || grep { $_ eq $client_ip } @rate_limit_trusted_ips) {
		if ($request_count >= $max_requests_hard) {
			# Hard limit exceeded - show CAPTCHA with warning
			my $recaptcha_config = $config->recaptcha();

			if ($recaptcha_config && $recaptcha_config->{enabled}) {
				$logger->warn("Hard rate limit exceeded for $client_ip ($request_count requests)");
				$info->status(429);

				unless(Web::VWF::Display::captcha->can('new')) {
					require Web::VWF::Display::captcha;
					Web::VWF::Display::captcha->import();
				}
				my $display = Web::VWF::Display::captcha->new({
					cachedir => $cachedir,
					info => $info,
					logger => $logger,
					lingua => $lingua,
					config => $config,
				});

				print 'Status: 429 ', HTTP::Status::status_message(429), "\n";
				print $display->as_string({
					'Retry-After' => $retry_after,
					Retry_After => $retry_after,
					hard_block => 1,
					request_count => $request_count,
				});

				$self->_vwflog($vwflog, $info, $lingua, $syslog, 'Hard rate limit - CAPTCHA shown', $log, $request_start);
				return;
			}

			# No CAPTCHA to offer, so block until the window expires
			$logger->warn("Hard rate limit exceeded for $client_ip ($request_count requests)");
			send_error(status => 429, body => "Too many requests - try again later\n", headers => "Retry-After: $retry_after\n");
			$self->_vwflog($vwflog, $info, $lingua, $syslog, 'Hard rate limit', $log, $request_start);
			return;
		} elsif ($request_count >= $max_requests) {
			# Soft limit exceeded - show CAPTCHA
			my $recaptcha_config = $config->recaptcha();

			if ($recaptcha_config && $recaptcha_config->{enabled}) {
				$logger->info("Soft rate limit exceeded for $client_ip ($request_count requests) - CAPTCHA challenge issued");
				$info->status(429);

				unless(Web::VWF::Display::captcha->can('new')) {
					require Web::VWF::Display::captcha;
					Web::VWF::Display::captcha->import();
				}
				my $display = Web::VWF::Display::captcha->new({
					cachedir => $cachedir,
					info => $info,
					logger => $logger,
					lingua => $lingua,
					config => $config,
				});

				print $display->as_string({
					'Retry-After' => $retry_after,
					Retry_After => $retry_after,
					hard_block => 0,
					request_count => $request_count,
				});

				$self->_vwflog($vwflog, $info, $lingua, $syslog, 'Soft rate limit - CAPTCHA shown', $log, $request_start);
				return;
			}
		}
	}

	# Commit the incremented request count back to the sliding-window cache.
	# The TTL is the rate-limit window; the counter expires automatically.
	$rate_limit_cache->set("$self->{script_name}:rate_limit:$client_ip", $request_count + 1, $time_window);

	# A request with no page parameter cannot be dispatched; send a 300
	# response listing the known valid pages instead.
	if(!defined($info->param('page'))) {
		$logger->info('No page given in ', $info->as_string());
		choose();
		return;
	}

	# ── Multi-layer access control ─────────────────────────────────────────
	# Three independent checks are run in order of cheapness:
	#   1. CGI::ACL — cloud ranges, country blocks, explicit IP allow/deny.
	#   2. blacklisted() — in-process IP set built from prior SQL-injection attempts.
	#   3. Web::VWF::Allow — DShield feed, user-agent blacklist, throttler, IDS.
	if(my $remote_addr = $ENV{'REMOTE_ADDR'}) {
		my $reason;
		if($acl->all_denied(lingua => $lingua)) {
			$reason = 'Denied by CGI::ACL';
		} elsif(blacklisted($info)) {
			$reason = 'Blacklisted for attempting to break in';
		} else {
			# Web::VWF::Allow may throw an Error object when it blocks a request.
			# Catch it here so the 403 response is sent rather than propagating.
			try {
				unless(Web::VWF::Allow::allow({
					info   => $info,
					lingua => $lingua,
					logger => $logger,
					cache  => $rate_limit_cache,
					config => $config,
				})) {
					$reason = 'Blocked by Web::VWF::Allow';
				}
			} catch Error with {
				$reason = shift;
			};
		}
		if($reason) {
			# Return a minimal plain-text 403 - no template rendering so that
			# a blocked attacker receives no information about site structure.
			send_error(status => 403, body => "Access Denied\n");
			$logger->info("$remote_addr: access denied: $reason");
			$info->status(403);
			$self->_vwflog($vwflog, $info, $lingua, $syslog, $reason, $log, $request_start);
			return;
		}
	}

	# ── FCGI::Buffer setup ────────────────────────────────────────────────
	# FCGI::Buffer post-processes the output: compresses it, generates an ETag
	# and Last-Modified header, and serves a 304 Not Modified when appropriate.
	my $args = {
		generate_etag => 1,
		generate_last_modified => 1,
		compress_content => 1,
		generate_304 => 1,
		info => $info,
		optimise_content => 1,
		logger => $logger,
		# lint_content runs HTML::Tidy on the output; enable in debug mode or
		# when explicitly requested via the lint_content query parameter.
		lint_content => $info->param('lint_content') // $params{'debug'},
		lingua => $lingua
	};

	if((!$info->is_search_engine()) && $config->root_dir() &&
	   ($info->param('page') ne 'home') &&
	   ((!defined($info->param('action'))) || ($info->param('action') ne 'send'))) {
		$args->{'save_to'} = {
			directory => File::Spec->catfile($config->root_dir(), 'save_to'),
			ttl => 3600 * 24,
			create_table => 1
		};
	}

	my $fb = FCGI::Buffer->new()->init($args);

	if($fb->can_cache()) {
		my $cache_key = join('/',
			'FCGI::Buffer',
			$info->browser_type(),
			$info->domain_name(),
			$self->{script_name},
			$info->as_string(),
			$lingua->language()
		);
		$cache_key =~ s/;string=%5Bobject%20HTMLInputElement%5D//;
		$cache_key =~ s/;string=\[object HTMLInputElement\]//;
		if($info->param('location')) {
			$cache_key .= '/' . $info->param('location');
		}
		$logger->debug("enabling cache key $cache_key");

		$buffercache ||= create_disc_cache(config => $config, logger => $logger, namespace => $self->{script_name}, root_dir => $cachedir);
		$fb->init(
			cache_key => $cache_key,
			cache => $buffercache,
			# generate_304 => 0,
			cache_duration => '1 day',
		);
		if($fb->is_cached()) {
			return;
		}
	}

	# $display holds the instantiated Web::VWF::Display subclass when the page is
	# found; $invalidpage is set when the page name is invalid or unloadable.
	my $display;
	my $invalidpage;

	# Arguments forwarded to every Web::VWF::Display subclass constructor.  The
	# server's directory is among them because a page reads its configuration for
	# itself, and has to look where this script did.
	$args = {
		cachedir => $cachedir,
		info => $info,
		logger => $logger,
		lingua => $lingua,
		config => $config,
		server_directory => $SERVER_CONF_DIR,
		log => $log
	};

	# ── Page dispatch ──────────────────────────────────────────────────────
	# The outer block eval catches any exception thrown during module loading
	# or display-object construction, setting $@ for inspection below.
	eval {
		my $page = $info->param('page');

		# Strip URL fragment identifiers - the server never needs them.
		$page =~ s/#.*$//;

		# Reject backslashes: no legitimate page name contains one, and
		# they have historically been used to probe Windows path traversal.
		$page =~ s/\\//g;

		if($page =~ /\//) {
			# A slash in the page name indicates an attempt to traverse
			# directories (e.g. page=/etc/passwd or page=http://evil.com).
			$logger->info("Blocking '/' in $page");
			$info->status(403);
			$log->status(403);
			$invalidpage = 1;
		} else {
			# Strip every non-word character so that the page name can only
			# contain [A-Za-z0-9_] - safe to use as a Perl package suffix.
			$page =~ s/\W//g;
			$page =~ s/\s//g;
		}

		if($invalidpage) {
			# Already rejected above
		} elsif(!grep { $_ eq $page } @valid_pages) {
			# Only pages on the allow-list are loaded, so that no other
			# Web::VWF::Display::* module that happens to be on @INC (e.g. under
			# ~/lib/perl5) can be reached from the query string.
			$logger->info("Unknown page $page");
			$invalidpage = 1;
			if($info->status() == 200) {
				$info->status(404);
			}
		} else {
			my $display_module = "Web::VWF::Display::$page";

			$logger->debug("doit(): Loading module $display_module from @INC");
			unless($display_module->can('new')) {
				# String-eval elimination:
				#   The original code used eval "require $display_module" which is a
				#   string eval on a user-derived value.  Although $page has been
				#   stripped of \W characters, a Unicode or locale edge-case could
				#   allow a bypass.  Module::Runtime::require_module() loads a module
				#   by name using a block eval internally, with no string-eval surface.
				eval { require_module($display_module) };
				$display_module->import() unless $@;
			}
			if($@) {
				$logger->debug("Failed to load module $display_module: $@");
				$logger->info("Unknown page $page");
				$invalidpage = 1;
				if($info->status() == 200) {
					$info->status(404);
				}
			} else {
				# use Class::Inspector;
				# my $methods = Class::Inspector->methods($display_module);
				# print "$display_module exports ", join(', ', @{$methods}), "\n";
				$display = do {
					eval { $display_module->new($args) };
				};
				if(!defined($display)) {
					if($@) {
						$logger->warn("$display_module->new(): $@");
					} else {
						$logger->notice("Can't instantiate page $page");
					}
					$invalidpage = 1;
					if($info->status() == 200) {
						$info->status(404);
					}
				} elsif(!$display->can('as_string')) {
					$logger->warn("Problem understanding $page");
					undef $display;
				}
			}
		}
	};

	my $error = $@;
	if($error) {
		if($info->status() == 429) {
			$logger->notice($error);
		} else {
			$logger->error($error);
		}
		$display = undef;
	}

	if(defined($display)) {
		# Pass in handles to the databases: the site's own data handles, under
		# the name each was declared with, and the access log, which the
		# framework reads from the log it writes.
		print $display->as_string({
			cachedir => $cachedir,
			config => $config,
			databasedir => $database_dir,
			database_dir => $database_dir,
			%data,
			vwf_log => $self->{vwf_log},
		});
		$self->_vwflog($vwflog, $info, $lingua, $syslog, '', $log, $request_start);
	} elsif($invalidpage) {
		if($info->status() == 429) {
			# Throttled by Web::VWF::Display
			my $interval = $config->{'throttle'}->{'interval'} // 90;
			send_error(status => 429, body => "Too many requests - try again later\n", headers => "Retry-After: $interval\n", buffered => 1);
			$self->_vwflog($vwflog, $info, $lingua, $syslog, 'Throttled', $log, $request_start);
		} else {
			choose();
			$self->_vwflog($vwflog, $info, $lingua, $syslog, 'Unknown page', $log, $request_start);
		}
		return;
	} else {
		$logger->debug('disabling cache');
		$fb->init(
			cache => undef,
		);
		# Handle errors gracefully
		my ($status, $body);
		if($error eq 'Unknown page to display') {
			($status, $body) = (400, "I don't know what you want me to display.\n");
		} elsif($error =~ /Can\'t locate .* in \@INC/) {
			$logger->error($error);
			($status, $body) = (500, "Software error - contact the webmaster\n");
		} elsif(($info->status() == 200) || ($info->status() == 403)) {
			# No permission to show this page
			($status, $body) = (403, "Access Denied\n");
		} else {
			$status = $info->status();
			$body = "Page unavailable - something is wrong at your end, please fix and try again\n";
		}
		send_error(status => $status, body => $body, buffered => 1);
		$log->status($status);
		$self->_vwflog($vwflog, $info, $lingua, $syslog, $error ? $error : 'Access denied', $log, $request_start);
		throw Error::Simple($error ? $error : $info->as_string());
	}
}

# Send a 300 Multiple Choices response listing the pages this site serves.
# Called when the ?page= parameter is absent or the requested page is unknown.
sub choose
{
	$logger->info('Called with no page to display');

	my $status = $info->status();

	# If the status is already non-200 (e.g. 404 set by the caller), relay
	# that status rather than overriding it with a 300.  That only happens
	# for an invalid page, after FCGI::Buffer has been set up, and it sends
	# the Status line from $info->status() itself.
	return if($status != 200);

	print "Status: 300 Multiple Choices\n",
		"Content-type: text/plain\n";

	$info->status(300);

	# Include a Last-Modified header based on the script's mtime so that
	# caches and conditional-GET clients can revalidate efficiently.
	if(my $path = $info->script_path()) {
		require HTTP::Date;
		HTTP::Date->import();

		my @statb = stat($path);
		my $mtime = $statb[9];
		print 'Last-Modified: ', HTTP::Date::time2str($mtime), "\n";
	}

	print "\n";

	# RFC 7231 §4.3.2: a HEAD response must not include a body.
	unless($ENV{'REQUEST_METHOD'} && ($ENV{'REQUEST_METHOD'} eq 'HEAD')) {
		# The same list that doit() allows, so the two cannot differ
		print map { "/cgi-bin/page.fcgi?page=$_\n" } @valid_pages;
	}
}

# Send a short plain-text error response, and record its status in $info.
#	status - the HTTP status code
#	body - the text to send (not sent for HEAD)
#	headers - optional extra header lines, each ending in "\n", e.g. Retry-After
#	buffered - true once FCGI::Buffer is capturing the output.  It sends the
#		Status line from $info->status(), so it mustn't be printed here too.
sub send_error
{
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;
	my $status = $args{'status'};

	$info->status($status);

	print 'Status: ', $status, ' ', HTTP::Status::status_message($status), "\n" unless($args{'buffered'});
	print $args{'headers'} // '',
		"Content-type: text/plain\n",
		"Pragma: no-cache\n\n";

	# RFC 9110 §9.3.2: a HEAD response must not include a body.
	my $is_head = $ENV{'REQUEST_METHOD'} && ($ENV{'REQUEST_METHOD'} eq 'HEAD');
	print $args{'body'} if(defined($args{'body'}) && !$is_head);

	return 1;
}

# A list-valued setting: what the configuration file says about it, or the
# caller's defaults when it says nothing about it.  A list can be written as one
# string of values separated by commas or spaces, which is what the plain form
# of a configuration file gives, or as an element with one child per value,
# which is what an XML file gives; both are read, so an XML file can hold a list
# in whichever of the two ways reads better.  The values are returned as they
# were written and in the order they were written, with repetitions dropped, and
# a setting that is present but empty means no values at all - so that a site can
# say "none" as well as saying nothing.
sub _config_list
{
	# The invocant is not used: the setting and its defaults are all this needs.
	my (undef, $config, $key, @defaults) = @_;

	my $value = $config->{$key};
	return @defaults unless(defined($value));

	my @values;
	if(ref($value) eq 'HASH') {
		# One child per value; the names of the children are not used
		foreach my $child (values %{$value}) {
			push(@values, ref($child) eq 'ARRAY' ? @{$child} : $child);
		}
	} elsif(ref($value) eq 'ARRAY') {
		@values = @{$value};
	} else {
		@values = split /[\s,]+/, $value;
	}

	my %seen;
	return grep { defined($_) && length($_) && !$seen{$_}++ } @values;
}

# The pages that ?page= may load.  Sites can list them in the config file
# (<pages>index, meta_data</pages>); otherwise every ../lib/HTTP/VWF/Display/*.pm
# next to this script is allowed, except captcha, which only the rate limiter
# shows.
sub _valid_pages
{
	my $self = shift;
	my $config = shift;

	my @pages = $self->_config_list($config, 'pages');
	return grep { /\A\w+\z/ } @pages if(@pages);

	# FIXME: Remove the hard coding
	my $dir = File::Spec->catdir($script_dir, File::Spec->updir(), 'lib', 'Web', 'VWF', 'Display');
	return sort(grep { $_ ne 'captcha' } map { basename($_, '.pm') } glob(File::Spec->catfile($dir, '*.pm')));
}

# Read the settings this site declares, once per process, and act on them: open
# the database directory it names, load the data modules it names and give the
# pages the languages and addresses it names.  Everything left unsaid keeps the
# default it had when these values were written into this script.
sub _site_setup
{
	my $self = shift;
	my $config = shift;

	return if($self->{site_ready});
	# The configuration, the database directory, the
	# data handles and these lists last for the life of the process, not for one
	# request.

	$self->{site_ready} = 1;

	# Where the site's own databases are.  Database::Abstraction reads them, and
	# the pages are told the directory as databasedir and database_dir.
	$database_dir = $config->{'database_dir'}
		|| File::Spec->catdir($script_dir, File::Spec->updir(), $DEFAULT_DATABASE_DIR);
	$logger->debug('Reading databases from ', $database_dir);

	Database::Abstraction::init({
		cache => CHI->new(driver => 'Memory', datastore => {}),
		cache_duration => '1 day',
		directory => $database_dir,
		logger => $logger
	});

	# The languages the site offers.  CGI::Lingua negotiates within this list, so
	# listing a language is what makes that language's templates reachable.
	@supported_languages = $self->_config_list($config, 'supported_languages', @DEFAULT_SUPPORTED_LANGUAGES);

	# Addresses exempt from rate limiting
	@rate_limit_trusted_ips = $self->_config_list($config, 'rate_limit_trusted_ips', @DEFAULT_RATE_LIMIT_TRUSTED_IPS);

	# The site's data modules.  Each is loaded, constructed with ->new() and
	# given to every page under the last part of its name, lower-cased:
	# HTTP::VWF::Data::index arrives at a page as index, and a site's own
	# Bands::Data::bands as bands.
	foreach my $module ($self->_config_list($config, 'data_modules', @DEFAULT_DATA_MODULES)) {
		my $handle;
		eval {
			require_module($module);
			$module->import() if($module->can('import'));
			$handle = $module->new();
		};
		if(!defined($handle)) {
			# A module the site named that cannot be loaded is reported and
			# skipped rather than taking the site down: it is a setting now, so
			# getting it wrong should not stop the pages that do not need it.
			$logger->error("Can't load data module $module: $@");
			next;
		}

		my $name = lc((split(/::/, $module))[-1]);
		$handle->set_logger($logger) if($handle->can('set_logger'));
		$data{$name} = $handle;
		$logger->debug("Data module $module is available to pages as \$$name");
	}

	return 1;
}

# Give the current logger to every data handle.  This runs before each request,
# since command-line mode replaces the logger; the handles themselves are made
# once, by _site_setup().
sub _set_data_loggers
{
	my $self = shift;
	my $logger = shift;

	foreach my $handle (values %data) {
		$handle->set_logger($logger) if($handle->can('set_logger'));
	}
	$self->{vwf_log}->set_logger($logger) if($self->{vwf_log});
}

# Convert a CHI-style duration ('60s', '2 minutes', '90') to whole seconds
sub duration_seconds
{
	my $duration = shift;

	return $duration if($duration =~ /\A\d+\z/);

	require Time::Duration::Parse;

	my $seconds = eval { Time::Duration::Parse::parse_duration($duration) };
	if(!defined($seconds)) {
		$logger->warn("Can't parse duration '$duration', using 60 seconds");
		return 60;
	}
	return int($seconds);
}

# Check whether the current request looks like a SQL injection attempt.
# IPs that trigger a match are added to the in-process %blacklisted_ip set so
# that subsequent requests from the same IP are rejected without re-scanning.
sub blacklisted
{
	if(my $remote = $ENV{'REMOTE_ADDR'}) {
		my $info = shift;

		# Fast path: this IP was already blacklisted earlier in this process
		# lifetime; no need to re-scan the request string.
		if($blacklisted_ip{$remote}) {
			$info->status(403);
			return 1;
		}

		if(my $string = $info->as_string()) {
			# Hard length cap: skip pattern matching entirely on absurdly long
			# inputs.  Even bounded quantifiers like {1,200} iterate many times
			# across a 1 MB string, so cap before we run any regex.
			return 0 if length($string) > 8192;

			# SECURITY - ReDoS defence:
			#   The original patterns used greedy .+ between SQL keywords, which
			#   causes catastrophic (exponential) backtracking when an attacker
			#   sends a string that contains the opening keyword but not the
			#   closing one (e.g. thousands of chars after SELECT with no AND).
			#   All .+ quantifiers are replaced with the bounded class [^;]{0,N}:
			#     - the semicolon is a natural SQL statement terminator so it is
			#       a safe anchor that real SQL injection never crosses, and
			#     - the explicit upper bound caps backtracking to O(N) steps.
			#   Word-boundary assertions (\b) also eliminate false positives on
			#   ordinary words that happen to contain the substring.
			if(   ($string =~ /SELECT\b[^;]{0,500}\bAND\b/i)
			   || ($string =~ /ORDER\s+BY\s/i)
			   || ($string =~ /\bOR\s+NOT\b/i)
			   || ($string =~ /\bAND\s+\d+=\d+/i)
			   || ($string =~ /\bTHEN\b[^;]{0,200}\bELSE\b[^;]{0,200}\bEND\b/i)
			   || ($string =~ /\bAND\b[^;]{0,200}\bSELECT\b/i)
			   || ($string =~ /\sAND\s[^;]{0,100}\sAND\s/i)
			   || ($string =~ /\bAND\s+CASE\s+WHEN\b/i)) {
				$blacklisted_ip{$remote} = 1;
				$info->status(403);
				return 1;
			}
		}
	}
	return 0;
}

# False positives we don't need in the logs
sub filter
{
	# return 0 if($_[0] =~ /Can't locate Net\/OAuth\/V1_0A\/ProtectedResourceRequest.pm in /);
	# return 0 if($_[0] =~ /Can't locate auto\/NetAddr\/IP\/InetBase\/AF_INET6.al in /);
	# return 0 if($_[0] =~ /S_IFFIFO is not a valid Fcntl macro at /);

	return 0 if $_[0] =~ /Can't locate (Net\/OAuth\/V1_0A\/ProtectedResourceRequest\.pm|auto\/NetAddr\/IP\/InetBase\/AF_INET6\.al) in |S_IFFIFO is not a valid Fcntl macro at /;
	return 1;
}

# Escape a single value for safe inclusion in a double-quoted CSV field.
# Follows RFC 4180 §2.7 and additionally neutralises spreadsheet formulas.
sub _csv_escape
{
	my $v = shift // '';

	# RFC 4180: a double-quote inside a quoted field is represented by two
	# double-quote characters.  Without this, one embedded " would break the
	# column boundary and corrupt every subsequent field on the row.
	$v =~ s/"/""/g;

	# SECURITY - CSV formula injection defence:
	#   Spreadsheet applications (Excel, LibreOffice Calc) interpret cell values
	#   that begin with = + - @ TAB or CR as formulas.  An attacker who controls
	#   a logged field (e.g. the page parameter) could inject =cmd|'/C calc'!A0.
	#   Prefix such values with a single-quote to force literal interpretation.
	$v =~ s/^([=+\-@\t\r])/'$1/;

	return $v;
}

# Write one access record to vwf.log (CSV format) and optionally to syslog.
# All user-influenced fields are escaped through _csv_escape before output.
sub _vwflog
{
	my $self = shift;

	my ($vwflog, $info, $lingua, $syslog, $message, $log, $request_start) = @_;

	# Calculate request duration in milliseconds if a start timer was supplied.
	# $request_start is a Timer::Simple, so ask it for the seconds that have
	# passed: its numeric overload yields elapsed(), so subtracting it from the
	# clock gave an epoch's worth of seconds (about 1.8e12 ms per request).  A
	# plain epoch is still accepted for callers that pass one.
	my $duration_ms = '';
	if($request_start) {
		my $seconds = ref($request_start) ? $request_start->elapsed() : Time::HiRes::time() - $request_start;
		$duration_ms = int($seconds * 1000);
	}

	# Determine which template was rendered for this request (may be empty on error).
	my $template;
	if($log) {
		$template = $log->template();
	}
	if(!defined($template)) {
		$template = '';
	}
	$message ||= '';

	# Create the log file with a header row on first use.
	if(!-e $vwflog) {
		open(my $fout, '>', $vwflog);
		print $fout '"domain_name","time","IP","country","type","language","http_code","template","args","messages","error","duration_ms"',
			"\n";
		close $fout;
	}

	# Collect any warn/notice-level messages emitted during this request.
	my $warnings;
        if(my $messages = $info->messages()) {
                $warnings = join('; ',
                        grep defined, map { (($_->{'level'} eq 'warn') || ($_->{'level'} eq 'notice')) ? $_->{'message'} : undef } @{$messages}
                        )
        }
	$warnings ||= '';

	my $country = $lingua->country() || 'unknown';

	# Open the log in append mode.  If the open fails we skip logging silently
	# so that a disk-full or permissions error does not crash the live request.
	if(open(my $fout, '>>', $vwflog)) {
		# SECURITY — CSV injection defence:
		#   Every user-visible field is passed through _csv_escape so that
		#   embedded double-quotes cannot break the CSV column structure, and
		#   leading formula characters cannot trigger code execution when the
		#   file is opened in a spreadsheet application.
		print $fout
			'"', _csv_escape($info->domain_name()), '",',
			'"', strftime('%F %T', localtime), '",',
			'"', _csv_escape($ENV{REMOTE_ADDR} // ''), '",',
			'"', _csv_escape($country), '",',
			'"', _csv_escape($info->browser_type()), '",',
			'"', _csv_escape($lingua->language() // ''), '",',
			$info->status(), ',',
			'"', _csv_escape($template), '",',
			'"', _csv_escape($info->as_string(raw => 1)), '",',
			'"', _csv_escape($warnings), '",',
			'"', _csv_escape($message), '",',
			$duration_ms,
			"\n";
		close($fout);
	}

	# Optionally mirror the record to syslog (configured via the syslog stanza).
	if($syslog) {
		unless(Sys::Syslog->can('openlog')) {
			require Sys::Syslog;
			Sys::Syslog->import();
		}

		# Configure the socket transport if a hash of options was provided.
		if(ref($syslog) eq 'HASH') {
			Sys::Syslog::setlogsock($syslog);
		}
		Sys::Syslog::openlog($self->{script_name}, 'cons,pid', 'user');
		# Use positional %s/%d format args so that special characters in the
		# values cannot be interpreted as syslog format directives.
		Sys::Syslog::syslog('info|local0', '%s %s %s %s %s %d %s %s %d %s %s',
			$info->domain_name() || '',
			$ENV{REMOTE_ADDR} || '',
			$country,
			$info->browser_type() || '',
			$lingua->language() || '',
			$info->status() || '',
			$template || '',
			$info->as_string(raw => 1) || '',
			$duration_ms,
			$warnings,
			$message
		);
		Sys::Syslog::closelog();
	}
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}

	# Clean up resources before shutdown
	$logger->info('Shutting down') if(defined($logger));
	if($buffercache && !$exit_requested) {
		$buffercache->purge();
	}
	if($rate_limit_cache) {
		# Memcached can't purge().
		# I don't like this hardwired code, it would be better if I could find a way to determine if a driver can run purge()
		$rate_limit_cache->purge() if($rate_limit_cache->short_driver_name() ne 'Memcached');
	}
	if($info_cache) {
		$info_cache->purge();
	}
	if($lingua_cache) {
		$lingua_cache->purge();
	}
	CHI->stats->flush();
	Log::WarnDie->dispatcher(undef);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
