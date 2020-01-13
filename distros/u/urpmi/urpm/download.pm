package urpm::download;


use strict;
use urpm::msg;
use urpm::util qw(cat_ basename dirname file_size max member output_safe reduce_pathname);
use bytes ();
use Cwd;
use Exporter;
# perl_checker: require urpm

# help perl_checker:
sub getcwd { goto &Cwd::getcwd }

our @ISA = 'Exporter';
our @EXPORT = qw(get_proxy
	propagate_sync_callback
	sync_file sync_rsync sync_ssh
	set_proxy_config dump_proxy_config
);

#- proxy config file.
our $PROXY_CFG = '/etc/urpmi/proxy.cfg';
my $proxy_config;

#- Timeout for curl connection and wget operations
our $CONNECT_TIMEOUT = 60; #-  (in seconds)


=head1 NAME

urpm::download - download routines for the urpm* tools

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut


sub ftp_http_downloaders() { qw(curl wget prozilla aria2) }

sub available_ftp_http_downloaders() {
    my %binaries = (
	curl => 'curl', 
	wget => 'wget', 
	prozilla => 'proz',
	aria2 => 'aria2c',
    );
    grep { -x "/usr/bin/$binaries{$_}" || -x "/bin/$binaries{$_}" } ftp_http_downloaders();
}

sub metalink_downloaders() { qw(aria2) }

sub available_metalink_downloaders() {
    my %binaries = (
	aria2 => 'aria2c',
    );
    grep { -x "/usr/bin/$binaries{$_}" || -x "/bin/$binaries{$_}" } metalink_downloaders();
}

sub use_metalink {
    my ($urpm, $medium) = @_;

    $medium->{allow_metalink} //= do {
	my $use_metalink = 1;
	preferred_downloader($urpm, $medium, \$use_metalink);
	$use_metalink;
    };
}

my %warned;
sub preferred_downloader {
    my ($urpm, $medium, $use_metalink) = @_;

    my @available = urpm::download::available_ftp_http_downloaders();
    my @metalink_downloaders = urpm::download::available_metalink_downloaders();
    my $metalink_disabled = !$$use_metalink && $medium->{disable_metalink};

    if ($$use_metalink && !$metalink_disabled) {
	#- If metalink is used, only aria2 is available as other downloaders doesn't support metalink
	unshift @available, @metalink_downloaders;
    }
	    
    #- first downloader of @available is the default one
    my $preferred = $available[0];
    my $requested_downloader = requested_ftp_http_downloader($urpm, $medium);
    if ($requested_downloader) {
	if (member($requested_downloader, @available)) {
	    #- use user default downloader if provided and available
	    $preferred = $requested_downloader;
	} elsif ($warned{webfetch_not_available}++ == 0) {
	    $urpm->{log}(N("%s is not available, falling back on %s", $requested_downloader, $preferred));
	}
    }

    if ($$use_metalink && !member($preferred, @metalink_downloaders)) {
	$warned{not_using_metalink}++ or 
	  $urpm->{log}($requested_downloader eq $preferred ? 
		       "not using metalink since requested downloader does not handle it" :
		       "not using metalink since no downloaders handling metalink are available");
	$$use_metalink = 0;
    }
    $preferred;
}

sub parse_http_proxy {
    $_[0] =~ m!^(?:http://)?([^:/]+(:\d+)?)/*$!;
}

#- parses proxy.cfg (private)
sub load_proxy_config () {
    return if defined $proxy_config;
    $proxy_config = {};
    foreach (cat_($PROXY_CFG)) {
	chomp; s/#.*$//; s/^\s*//; s/\s*$//;
	if (/^(?:(.*):\s*)?(ftp_proxy|http_proxy)\s*=\s*(.*)$/) {
	    $proxy_config->{$1 || ''}{$2} = $3;
	    next;
	}
	if (/^(?:(.*):\s*)?proxy_user\s*=\s*([^:]*)(?::(.*))?$/) {
	    $proxy_config->{$1 || ''}{user} = $2;
	    $proxy_config->{$1 || ''}{pwd} = $3 if defined $3;
	    next;
	}
	if (/^(?:(.*):\s*)?proxy_user_ask/) {
	    $proxy_config->{$1 || ''}{ask} = 1;
	    next;
	}
    }
}

#- writes proxy.cfg
sub dump_proxy_config () {
    $proxy_config or return 0; #- hasn't been read yet

    my $has_password;

    open my $f, '>', $PROXY_CFG or return 0;
    foreach ('', sort grep { !/^(|cmd_line)$/ } keys %$proxy_config) {
	my $m = $_ eq '' ? '' : "$_:";
	my $p = $proxy_config->{$_};
	foreach (qw(http_proxy ftp_proxy)) {
	    if (defined $p->{$_} && $p->{$_} ne '') {
		print $f "$m$_=$p->{$_}\n";
		$has_password ||= hide_password($p->{$_}) ne $p->{$_};
	    }
	}
	if ($p->{ask}) {
	    print $f "${m}proxy_user_ask\n";
	} elsif (defined $p->{user} && $p->{user} ne '') {
	    print $f "${m}proxy_user=$p->{user}:$p->{pwd}\n";
	    $has_password ||= $p->{pwd};
	}
    }
    close $f;
    chmod 0600, $PROXY_CFG if $has_password;
    return 1;
}

#- deletes the proxy configuration for the specified media
sub remove_proxy_media {
    defined $proxy_config and delete $proxy_config->{$_[0] || ''};
}

sub get_proxy_ {
    my ($urpm) = @_;

    -e $PROXY_CFG && !-r $PROXY_CFG and $urpm->{error}(N("can not read proxy settings (not enough rights to read %s)", $PROXY_CFG));

    get_proxy($urpm);
}

=item get_proxy($media)

Reads and loads the proxy.cfg file ;
Returns the global proxy settings (without arguments) or the
proxy settings for the specified media (with a media name as argument)

=cut

sub get_proxy (;$) {
    my ($o_media) = @_; $o_media ||= '';
    load_proxy_config();
    my $p = $proxy_config->{cmd_line}
	|| $proxy_config->{$o_media}
	|| $proxy_config->{''}
	|| {
	    http_proxy => undef,
	    ftp_proxy => undef,
	    user => undef,
	    pwd => undef,
	};
    if ($p->{ask} && ($p->{http_proxy} || $p->{ftp_proxy}) && !$p->{user}) {
	our $PROMPT_PROXY;
	unless (defined $PROMPT_PROXY) {
	    require urpm::prompt;
	    $PROMPT_PROXY = new urpm::prompt(
		N("Please enter your credentials for accessing proxy\n"),
		[ N("User name:"), N("Password:") ],
		undef,
		[ 0, 1 ],
	    );
	}
	($p->{user}, $p->{pwd}) = $PROMPT_PROXY->prompt;
    }
    $p;
}

#- copies the settings for proxies from the command line to media named $media
#- and writes the proxy.cfg file (used when adding new media)
sub copy_cmd_line_proxy {
    my ($media) = @_;
    return unless $media;
    load_proxy_config();
    if (defined $proxy_config->{cmd_line}) {
	$proxy_config->{$media} = $proxy_config->{cmd_line};
	dump_proxy_config();
    } else {
	#- use default if available
	$proxy_config->{$media} = $proxy_config->{''};
    }
}

=item set_cmdline_proxy(%h)

Overrides the config file proxy settings with values passed via command-line

=cut

sub set_cmdline_proxy {
    my (%h) = @_;
    load_proxy_config();
    $proxy_config->{cmd_line} ||= {
	http_proxy => undef,
	ftp_proxy => undef,
	user => undef,
	pwd => undef,
    };
    $proxy_config->{cmd_line}{$_} = $h{$_} foreach keys %h;
}

=item set_proxy_config($key, $value, $o_media)

Changes permanently the proxy settings

=cut

sub set_proxy_config {
    my ($key, $value, $o_media) = @_;
    $proxy_config->{$o_media || ''}{$key} = $value;
}

#- set up the environment for proxy usage for the appropriate tool.
#- returns an array of command-line arguments for wget or curl.
sub set_proxy {
    my ($proxy) = @_;

    my $p = $proxy->{proxy};
    defined $p->{http_proxy} || defined $p->{ftp_proxy} or return;

    my @res;
    if ($proxy->{type} =~ /\bwget\b/) {
	if (defined $p->{http_proxy}) {
	    $ENV{http_proxy} = $p->{http_proxy} =~ /^http:/
	      ? $p->{http_proxy} : "http://$p->{http_proxy}";
	}
	$ENV{ftp_proxy} = $p->{ftp_proxy} if defined $p->{ftp_proxy};
	@res = ("--proxy-user=$p->{user}", "--proxy-passwd=$p->{pwd}")
	  if defined $p->{user} && defined $p->{pwd};
    } elsif ($proxy->{type} =~ /\bcurl\b/) {
	push @res, ('-x', $p->{http_proxy}) if defined $p->{http_proxy};
	push @res, ('-x', $p->{ftp_proxy}) if defined $p->{ftp_proxy};
	push @res, ('-U', "$p->{user}:$p->{pwd}")
	  if defined $p->{user} && defined $p->{pwd};
	push @res, '-H', 'Pragma:' if @res;
    } elsif ($proxy->{type} =~ /\baria2\b/) {
	if (my ($http_proxy) = $p->{http_proxy} && parse_http_proxy($p->{http_proxy})) {
	    my $allproxy = $p->{user}; 
	    $allproxy .= ":" . $p->{pwd} if $p->{pwd}; 
	    $allproxy .= "@" if $p->{user};
	    $allproxy .= $http_proxy;
	    @res = ("--all-proxy=http://$allproxy");
	}
    } else { 
	die N("Unknown webfetch `%s' !!!\n", $proxy->{type});
    }
    @res;
}

sub _error_msg {
    my ($name) = @_;

    my $msg = $? & 127 ? N("%s failed: exited with signal %d", $name, $? & 127) :
                         N("%s failed: exited with %d", $name, $? >> 8);
    "$msg\n";
}

sub _error {
    my ($name) = @_;
    die _error_msg($name);
}

sub hide_password {
    my ($url) = @_;
    $url =~ s|([^:]*://[^/:\@]*:)[^/:\@]*(\@.*)|$1xxxx$2|; #- if needed...
    $url;
}

sub propagate_sync_callback {
    my $options = shift;
    if (ref($options) && $options->{callback}) {
	my $mode = shift;
	if ($mode =~ /^(?:start|progress|end)$/) {
	    my $file = shift;
	    return $options->{callback}($mode, hide_password($file), @_);
	} else {
	    return $options->{callback}($mode, @_);
	}
    }
}

sub sync_file {
    my $options = shift;
    foreach (@_) {
	propagate_sync_callback($options, 'start', $_);
	require urpm::util;
	urpm::util::copy($_, ref($options) ? $options->{dir} : $options)
	    or die N("copy failed");
	propagate_sync_callback($options, 'end', $_);
    }
}

sub sync_wget {
    -x "/usr/bin/wget" or die N("wget is missing\n");
    my $options = shift;
    $options = { dir => $options } if !ref $options;
    #- force download to be done in cachedir to avoid polluting cwd.
    (my $cwd) = getcwd() =~ /(.*)/;
    chdir $options->{dir};
    my ($buf, $total, $file) = ('', undef, undef);
    my $wget_command = join(" ", map { "'$_'" }
	#- construction of the wget command-line
	"/usr/bin/wget",
	($options->{'limit-rate'} ? "--limit-rate=$options->{'limit-rate'}" : @{[]}),
	($options->{resume} ? "--continue" : "--force-clobber"),
	($options->{proxy} ? set_proxy({ type => "wget", proxy => $options->{proxy} }) : @{[]}),
	($options->{retry} ? ('-t', $options->{retry}) : @{[]}),
	($options->{callback} ? ("--progress=bar:force", "-o", "-") :
	    $options->{quiet} ? "-q" : @{[]}),
	"--retr-symlinks",
	($options->{"no-certificate-check"} ? "--no-check-certificate" : @{[]}),
	"--timeout=$CONNECT_TIMEOUT",
	(defined $options->{'wget-options'} ? split /\s+/, $options->{'wget-options'} : @{[]}),
	'-P', $options->{dir},
	@_
    ) . " |";
    $options->{debug} and $options->{debug}($wget_command);
    local $ENV{LC_ALL} = 'C';
    my $wget_pid = open(my $wget, $wget_command);
    local $/ = \1; #- read input by only one char, this is slow but very nice (and it works!).
    local $_;
    while (<$wget>) {
	$buf .= $_;
	if ($_ eq "\r" || $_ eq "\n") {
	    if ($options->{callback}) {
		if ($buf =~ /^--(\d\d\d\d-\d\d-\d\d )?\d\d:\d\d:\d\d--\s+(\S.*)\n/ms) {
		    my $file_ = $2;
		    if ($file && $file ne $file_) {
			propagate_sync_callback($options, 'end', $file);
			undef $file;
		    }
		    ! defined $file and propagate_sync_callback($options, 'start', $file = $file_);
		} elsif (defined $file && ! defined $total && ($buf =~ /==>\s+RETR/ || $buf =~ /200 OK$/)) {
		    $total = '';
		} elsif ($buf =~ /^Length:\s*(\d\S*)/) {
		    $total = $1;
		} elsif (defined $total && $buf =~ m!^\s*(\d+)%.*\s+(\S+/s)\s+((ETA|eta)\s+(.*?)\s*)?[\r\n]$!ms) {
		    my ($percent, $speed, $eta) = ($1, $2, $5);
		    if (propagate_sync_callback($options, 'progress', $file, $percent, $total, $eta, $speed) eq 'canceled') {
			kill 15, $wget_pid;
			close $wget;
			return;
		    }
		    if ($_ eq "\n") {
			propagate_sync_callback($options, 'end', $file);
			($total, $file) = (undef, undef);
		    }
		}
	    } else {
		$options->{quiet} or print STDERR $buf;
	    }
	    $buf = '';
	}
    }
    $file and propagate_sync_callback($options, 'end', $file);
    chdir $cwd;
    close $wget or _error('wget');
}

sub sync_curl {
    -x "/usr/bin/curl" or die N("curl is missing\n");
    my $options = shift;
    $options = { dir => $options } if !ref $options;
    if (defined $options->{'limit-rate'} && $options->{'limit-rate'} =~ /\d$/) {
	#- use bytes by default
	$options->{'limit-rate'} .= 'B';
    }
    #- force download to be done in cachedir to avoid polluting cwd,
    #- however for curl, this is mandatory.
    (my $cwd) = getcwd() =~ /(.*)/;
    chdir($options->{dir});
    my (@ftp_files, @other_files);
    foreach (@_) {
	my ($proto, $nick, $rest) = m,^(http|ftp)://([^:/]+):(.*),,;
	if ($nick) { #- escape @ in user names
	    $nick =~ s/@/%40/;
	    $_ = "$proto://$nick:$rest";
	}
	if (m|^ftp://.*/([^/]*)$| && file_size($1) > 8192) { #- manage time stamp for large file only
	    push @ftp_files, $_;
	} else {
	    push @other_files, $_;
	}
    }
    if (@ftp_files) {
	my ($cur_ftp_file, %ftp_files_info);
	local $_;

	eval { require Date::Manip };

	#- prepare to get back size and time stamp of each file.
	my $cmd = join(" ", map { "'$_'" } "/usr/bin/curl",
	    "-q", # don't read .curlrc; some toggle options might interfer
	    ($options->{'limit-rate'} ? ("--limit-rate", $options->{'limit-rate'}) : @{[]}),
	    ($options->{proxy} ? set_proxy({ type => "curl", proxy => $options->{proxy} }) : @{[]}),
	    ($options->{retry} ? ('--retry', $options->{retry}) : @{[]}),
	    "--stderr", "-", # redirect everything to stdout
	    "--disable-epsv",
	    "--connect-timeout", $CONNECT_TIMEOUT,
	    "-s", "-I",
	    "--anyauth",
	    (defined $options->{'curl-options'} ? split /\s+/, $options->{'curl-options'} : @{[]}),
	    @ftp_files);
	$options->{debug} and $options->{debug}($cmd);
	open my $curl, "$cmd |";
	while (<$curl>) {
	    if (/Content-Length:\s*(\d+)/) {
		!$cur_ftp_file || exists($ftp_files_info{$cur_ftp_file}{size})
		    and $cur_ftp_file = shift @ftp_files;
		$ftp_files_info{$cur_ftp_file}{size} = $1;
	    }
	    if (/Last-Modified:\s*(.*)/) {
		!$cur_ftp_file || exists($ftp_files_info{$cur_ftp_file}{time})
		    and $cur_ftp_file = shift @ftp_files;
		eval {
		    $ftp_files_info{$cur_ftp_file}{time} = Date::Manip::ParseDate($1);
		};
	    }
	}
	close $curl or _error('curl');

	#- now analyse size and time stamp according to what already exists here.
	if (@ftp_files) {
	    #- re-insert back shifted element of ftp_files, because curl output above
	    #- has not been parsed correctly, so in doubt download them all.
	    push @ftp_files, keys %ftp_files_info;
	} else {
	    #- for that, it should be clear ftp_files is empty...
	    #- elsewhere, the above work was useless.
	    foreach (keys %ftp_files_info) {
		my ($lfile) = m|/([^/]*)$| or next; #- strange if we can't parse it correctly.
		my $ltime = eval { Date::Manip::ParseDate(scalar gmtime((stat $1)[9])) };
		$ltime && -s $lfile == $ftp_files_info{$_}{size} && $ftp_files_info{$_}{time} eq $ltime
		    or push @ftp_files, $_;
	    }
	}
    }
    # Indicates whether this option is available in our curl
    our $location_trusted;
    if (!defined $location_trusted) {
	$location_trusted = `/usr/bin/curl -h` =~ /location-trusted/ ? 1 : 0;
    }
    #- http files (and other files) are correctly managed by curl wrt conditional download.
    #- options for ftp files, -R (-O <file>)*
    #- options for http files, -R (-O <file>)*
    my $result;
    if (my @all_files = (
	    (map { ("-O", $_) } @ftp_files),
	    (map { m|/| ? ("-O", $_) : @{[]} } @other_files)))
    {
	my @l = (@ftp_files, @other_files);
	my $cmd = join(" ", map { "'$_'" } "/usr/bin/curl",
	    "-q", # don't read .curlrc; some toggle options might interfer
	    ($options->{'limit-rate'} ? ("--limit-rate", $options->{'limit-rate'}) : @{[]}),
	    ($options->{resume} ? ("--continue-at", "-") : @{[]}),
	    ($options->{proxy} ? set_proxy({ type => "curl", proxy => $options->{proxy} }) : @{[]}),
	    ($options->{retry} ? ('--retry', $options->{retry}) : @{[]}),
	    ($options->{quiet} ? "-s" : @{[]}),
	    ($options->{"no-certificate-check"} ? "-k" : @{[]}),
	    $location_trusted ? "--location-trusted" : @{[]},
	    "-R",
	    "-f",
	    "--disable-epsv",
	    "--connect-timeout", $CONNECT_TIMEOUT,
	    "--anyauth",
	    (defined $options->{'curl-options'} ? split /\s+/, $options->{'curl-options'} : @{[]}),
	    "--stderr", "-", # redirect everything to stdout
	    @all_files);
	$options->{debug} and $options->{debug}($cmd);
	$result = _curl_action($cmd, $options, @l);
    }
    chdir $cwd;
    $result;
}

sub _curl_action {
    my ($cmd, $options, @l) = @_;
    
	my ($buf, $file); $buf = '';
	my $curl_pid = open(my $curl, "$cmd |");
	local $/ = \1; #- read input by only one char, this is slow but very nice (and it works!).
	local $_;
	while (<$curl>) {
	    $buf .= $_;
	    if ($_ eq "\r" || $_ eq "\n") {
		if ($options->{callback}) {
		    unless (defined $file) {
			$file = shift @l;
			propagate_sync_callback($options, 'start', $file);
		    }
		    if (my ($percent, $total, $eta, $speed) = $buf =~ /^\s*(\d+)\s+(\S+)[^\r\n]*\s+(\S+)\s+(\S+)\s*[\r\n]$/ms) {
			$speed =~ s/^-//;
			if (propagate_sync_callback($options, 'progress', $file, $percent, $total, $eta, $speed) eq 'canceled') {
			    kill 15, $curl_pid;
			    close $curl;
			    die N("curl failed: download canceled\n");
			}
			#- this checks that download has actually started
			if ($_ eq "\n"
			    && !($speed == 0 && $percent == 100 && index($eta, '--') >= 0) #- work around bug 13685
			) {
			    propagate_sync_callback($options, 'end', $file);
			    $file = undef;
			}
		    } elsif ($buf =~ /^curl:/) { #- likely to be an error reported by curl
			local $/ = "\n";
			chomp $buf;
			propagate_sync_callback($options, 'error', $file, $buf);
		    }
		} else {
		    $options->{quiet} or print STDERR $buf;
		}
		$buf = '';
	    }
	}
	close $curl or _error('curl');
}

sub _calc_limit_rate {
    my $limit_rate = $_[0];
    for ($limit_rate) {
	/^(\d+)$/     and $limit_rate = int $1/1024, last;
	/^(\d+)[kK]$/ and $limit_rate = $1, last;
	/^(\d+)[mM]$/ and $limit_rate = 1024*$1, last;
	/^(\d+)[gG]$/ and $limit_rate = 1024*1024*$1, last;
    }
    $limit_rate;
}

sub sync_rsync {
    -x "/usr/bin/rsync" or die N("rsync is missing\n");
    my $options = shift;
    $options = { dir => $options } if !ref $options;
    #- force download to be done in cachedir to avoid polluting cwd.
    (my $cwd) = getcwd() =~ /(.*)/;
    chdir($options->{dir});
    my $limit_rate = _calc_limit_rate($options->{'limit-rate'});
    foreach (@_) {
	my $count = 10; #- retry count on error (if file exists).
	my $basename = basename($_);
	my $file =  m!^rsync://([^/]*::.*)! ? $1 : $_;
	propagate_sync_callback($options, 'start', $file);
	do {
	    local $_;
	    my $buf = '';
	    my $cmd = join(" ", "/usr/bin/rsync",
		($limit_rate ? "--bwlimit=$limit_rate" : @{[]}),
		($options->{quiet} ? qw(-q) : qw(--progress -v --no-human-readable)),
		($options->{compress} ? qw(-z) : @{[]}),
		($options->{ssh} ? qq(-e $options->{ssh}) : 
		   ("--timeout=$CONNECT_TIMEOUT",
		    "--contimeout=$CONNECT_TIMEOUT")),
		qw(--partial --no-whole-file --no-motd --copy-links),
		(defined $options->{'rsync-options'} ? split /\s+/, $options->{'rsync-options'} : @{[]}),
		"'$file' '$options->{dir}' 2>&1");
	    $options->{debug} and $options->{debug}($cmd);
	    open(my $rsync, "$cmd |");
	    local $/ = \1; #- read input by only one char, this is slow but very nice (and it works!).
	    local $_;
	    while (<$rsync>) {
		$buf .= $_;
		if ($_ eq "\r" || $_ eq "\n") {
		    if ($options->{callback}) {
			if (my ($percent, $speed) = $buf =~ /^\s*\d+\s+(\d+)%\s+(\S+)\s+/) {
			    propagate_sync_callback($options, 'progress', $file, $percent, undef, undef, $speed);
			} else {
			    $options->{debug} and $options->{debug}($buf);
			}
		    } else {
			$options->{quiet} or print STDERR $buf;
			$options->{debug} and $options->{debug}($buf);
		    }
		    $buf = '';
		}
	    }
	    close $rsync;
	} while ($? != 0 && --$count > 0 && -e $options->{dir} . "/$basename");
	propagate_sync_callback($options, 'end', $file);
    }
    chdir $cwd;
    $? == 0 or _error('rsync');
}

our $SSH_PATH;
sub _init_ssh_path() {
    foreach (qw(/usr/bin/ssh /bin/ssh)) {
	-x $_ and $SSH_PATH = $_;
	next;
    }
}

#- Don't generate a tmp dir name, so when we restart urpmi, the old ssh
#- connection can be reused
our $SSH_CONTROL_DIR = $ENV{TMP} || $ENV{TMPDIR} || '/tmp';
our $SSH_CONTROL_OPTION;

sub sync_ssh {
    $SSH_PATH or _init_ssh_path();
    $SSH_PATH or die N("ssh is missing\n");
    my $options = shift;
    $options = { dir => $options } if !ref $options;
    unless ($options->{'rsync-options'} =~ /(?:-e|--rsh)\b/) {
	my ($server, $user) = ('', getpwuid($<));
	$_[0] =~ /((?:\w|\.)*):/ and $server = $1;
	$_[0] =~ /((?:\w|-)*)@/ and $user = $1;
	$SSH_CONTROL_OPTION = "-o 'ControlPath $SSH_CONTROL_DIR/ssh-urpmi-$$-%h_%p_%r' -o 'ControlMaster auto'";
	if (start_ssh_master($server, $user)) {
	    $options->{ssh} = qq("$SSH_PATH $SSH_CONTROL_OPTION");
	} else {
	    #- can't start master, use single connection
	    $options->{ssh} = $SSH_PATH;
	}
    }
    sync_rsync($options, @_);
}

sub sync_prozilla {
    -x "/usr/bin/proz" or die N("prozilla is missing\n");
    my $options = shift;
    $options = { dir => $options } if !ref $options;
    #- force download to be done in cachedir to avoid polluting cwd.
    (my $cwd) = getcwd() =~ /(.*)/;
    chdir $options->{dir};
    my $proz_command = join(" ", map { "'$_'" }
	"/usr/bin/proz",
	"--no-curses",
	(defined $options->{'prozilla-options'} ? split /\s+/, $options->{'prozilla-options'} : @{[]}),
	@_
    );
    my $ret = system($proz_command);
    chdir $cwd;
    if ($ret) {
	if ($? == -1) {
	    die N("Couldn't execute prozilla\n");
	} else {
	    _error('prozilla');
	}
    }
}

sub sync_aria2 {
    my ($urpm, $medium, $rel_files, $options) = @_;

    -x "/usr/bin/aria2c" or die N("aria2 is missing\n");

    #- force download to be done in cachedir to avoid polluting cwd.
    (my $cwd) = getcwd() =~ /(.*)/;
    chdir $options->{dir};

    my $stat_file = ($< ? $ENV{HOME} : '/root') . '/.aria2-adaptive-stats';

    my $aria2c_command = join(" ", map { "'$_'" }
	"/usr/bin/aria2c", $options->{debug} ? ('--log', "$options->{dir}/.aria2.log") : @{[]},
	'--auto-file-renaming=false',
	'--ftp-pasv',
	'--summary-interval=1',
	'--follow-metalink=mem',
      $medium->{mirrorlist} ? (
	'--metalink-enable-unique-protocol=true', # do not try to connect to the same server using the same protocol
	 '--metalink-preferred-protocol=http', # try http as first protocol as they're stateless and
	                                       # will put less strain on ie. the ftp servers which connections
	                                       # are statefull for, causing unhappy mirror admins complaining
	                                       # about increase of connections, increasing resource usage.
	'--max-tries=5', # nb: not using $options->{retry}
	'--lowest-speed-limit=20K', "--timeout", 3,
        '--split=3', # maximum number of servers to use for one download
        '--uri-selector=adaptive', "--server-stat-if=$stat_file", "--server-stat-of=$stat_file",
        $options->{is_versioned} ? @{[]} : '--max-file-not-found=9', # number of not found errors on different servers before aborting file download
        '--connect-timeout=6', # $CONNECT_TIMEOUT,
      ) : @{[]},
	'-Z', '-j1',
	($options->{'limit-rate'} ? "--max-download-limit=" . $options->{'limit-rate'} : @{[]}),
	($options->{resume} ? "--continue" : "--allow-overwrite=true"),
	($options->{proxy} ? set_proxy({ type => "aria2", proxy => $options->{proxy} }) : @{[]}),
	($options->{"no-certificate-check"} ? "--check-certificate=false" : @{[]}),
	(defined $options->{'aria2-options'} ? split /\s+/, $options->{'aria2-options'} : @{[]}),
        _create_metalink_($urpm, $medium, $rel_files, $options));

    $options->{debug} and $options->{debug}($aria2c_command);

    local $ENV{LC_ALL} = 'C';
    my $aria2_pid = open(my $aria2, "$aria2c_command |");

    _parse_aria2_output($options, $aria2, $aria2_pid, $medium, $rel_files);

    chdir $cwd;
    if (!close $aria2) {
	my $raw_msg = _error_msg('aria2');
	my $want_retry;
	if (!$options->{is_retry} & $options->{is_versioned}) {
	    $want_retry = 1;
	} else {
	    my $msg = N("Failed to download %s", $rel_files->[0]);
	    $want_retry = $options->{ask_retry} && $options->{ask_retry}($raw_msg, $msg);
	}
	if ($want_retry) {
	    $options->{is_retry}++;
	    $options->{debug} and $options->{debug}("retrying ($options->{is_retry})");
	    goto &sync_aria2;
	}
	die $raw_msg;
    }
}

sub _parse_aria2_output {
    my ($options, $aria2, $aria2_pid, $medium, $rel_files) = @_;

    my ($buf, $_total, $file) = ('', undef, undef);

    local $/ = \1; #- read input by only one char, this is slow but very nice (and it works!).
    local $_;    

    while (<$aria2>) {
	if ($_ eq "\r" || $_ eq "\n") {
	    $options->{debug}("aria2c: $buf") if $options->{debug};
		if ($options->{callback}) {
			if (!defined($file) && @$rel_files) {
				$file = $medium->{mirrorlist} ? 
				  $medium->{mirrorlist} . ': ' . $medium->{'with-dir'} . "/$rel_files->[0]" :
				  "$medium->{url}/$rel_files->[0]";
				propagate_sync_callback($options, 'start', $file)
				  if !$options->{is_retry};
			}

			# aria2c 1.16 and beyond:
			# parses aria2c: [#2c8dae 496KiB/830KiB(59%) CN:1 DL:84KiB ETA:3s]
			#
			# using multiline mode and comments for better readability:
			#
			if ($buf =~ m!
				^\[\#[\dA-Fa-f]+ # match #2c8dae
				\s+
				([\d\.]+\w*) # Match 496KiB
					/
				([\d\.]+\w*) # Match 830KiB
				\s* \( (\d+) % \) # Match (59%)
				\s+
				CN:(\S+) # Match CN:1
				\s+
				DL:(\S+) # Match DL:84KiB
				\s+
				ETA:(\w+)
				\]$
				!msx
			)
			{
			    my ($total, $percent, $speed, $eta) = ($2, $3, $5, $6);
			    #- $1 = current downloaded size, $4 = connections
		    if (propagate_sync_callback($options, 'progress', $file, $percent, $total, $eta, $speed) eq 'canceled') {
			kill 15, $aria2_pid;
			close $aria2;
			return;
			}
		    }
		    if ($buf =~ m!Download\scomplete:\s/!) {
			propagate_sync_callback($options, 'end', $file);
			shift @$rel_files;
			delete $options->{is_retry};
			$file = undef;			
		    } elsif ($buf =~ /ERR\|(.*)/) {
			propagate_sync_callback($options, 'error', $file, $1);
		    }
	    } else {
		$options->{quiet} or print STDERR "$buf\n";
	    }
	    $buf = '';
	} else {
	    $buf .= $_;
	}
    }
}

sub start_ssh_master {
    my ($server, $user) = @_;
    $server or return 0;
    if (!check_ssh_master($server, $user)) {
	system(qq($SSH_PATH -f -N $SSH_CONTROL_OPTION -M $user\@$server));
	return ! $?;
    }
    return 1;
}

sub check_ssh_master {
    my ($server, $user) = @_;
    system(qq($SSH_PATH -q -f -N $SSH_CONTROL_OPTION $user\@$server -O check));
    return ! $?;
}

END {
    #- remove ssh persistent connections
    foreach my $socket (glob "$SSH_CONTROL_DIR/ssh-urpmi-$$-*") {
	my ($server, $login) = $socket =~ /ssh-urpmi-\d+-([^_]+)_\d+_(.*)$/ or next;
	system($SSH_PATH, '-q', '-f', '-N', '-o', "ControlPath $socket", '-O', 'exit', "$login\@$server");
    }
}

#- get the width of the terminal
my $wchar = 79;
if (-t *STDOUT) {
  eval {
    require Term::ReadKey;
    ($wchar) = Term::ReadKey::GetTerminalSize();
    --$wchar;
  };
}

sub progress_text {
    my ($mode, $percent, $total, $eta, $speed) = @_;
    $mode eq 'progress' ?
      (defined $total && defined $eta ?
	 N("        %s%% of %s completed, ETA = %s, speed = %s", $percent, $total, $eta, $speed) :
	 N("        %s%% completed, speed = %s", $percent, $speed)) : '';
}

=item sync_logger($mode, $file, $percent, $_total, $_eta, $_speed)

Default logger (callback) suitable for sync operation on STDERR only.

=cut

sub sync_logger {
    my ($mode, $file, $percent, $total, $eta, $speed) = @_;
    if ($mode eq 'start') {
	print STDERR "    $file\n";
    } elsif ($mode eq 'progress') {
	my $text = progress_text($mode, $percent, $total, $eta, $speed);
	if (length($text) > $wchar) { $text = substr($text, 0, $wchar) }
	if (bytes::length($text) < $wchar) {
	    # clearing more than needed in case the terminal is not handling utf8 and we have a utf8 string
	    print STDERR $text, " " x ($wchar - bytes::length($text)), "\r";
	} else {
	    # clearing all the line first since we can't really know the "length" of the string
	    print STDERR " " x $wchar, "\r", $text, "\r";
	}
    } elsif ($mode eq 'end') {
	print STDERR " " x $wchar, "\r";
    } elsif ($mode eq 'error') {
	#- error is 3rd argument, saved in $percent
	print STDERR N("...retrieving failed: %s", $percent), "\n";
    }
}

=item requested_ftp_http_downloader($urpm, $medium)

Return the downloader program to use (whether it pas provided on the
command line or in the config file).

=cut

sub requested_ftp_http_downloader {
    my ($urpm, $medium) = @_;

    $urpm->{options}{downloader} || #- cmd-line switch
      $medium && $medium->{downloader} || 
	$urpm->{global_config}{downloader} || "";
}

sub parse_url_with_login {
    my ($url) = @_;
    $url =~ m!([^:]*)://([^/:]*)(:([^/:\@]*))?\@([^/]*)(.*)! && $1 ne 'ssh' &&
      { proto => $1, login => $2, password => $4, machine => $5, dir => $6 };
}
sub url_obscuring_password {
    my ($url) = @_;
    my $u = parse_url_with_login($url);
    if ($u && $u->{password}) {
	sprintf('%s://xxx:xxx@%s%s', $u->{proto}, $u->{machine}, $u->{dir});
    } else {
	$url;
    }
}

#- $medium can be undef
sub _all_options {
    my ($urpm, $medium, $options) = @_;

    my %all_options = ( 
	dir => "$urpm->{cachedir}/partial",
	proxy => get_proxy_($urpm),
	metalink => $medium->{mirrorlist},
	$medium->{"disable-certificate-check"} ? "no-certificate-check" : @{[]},
	$urpm->{debug} ? (debug => $urpm->{debug}) : @{[]},
	%$options,
    );
    foreach my $cpt (qw(compress limit-rate retry wget-options curl-options rsync-options prozilla-options aria2-options metalink)) {
	$all_options{$cpt} = $urpm->{options}{$cpt} if defined $urpm->{options}{$cpt};
    }
    \%all_options;
}

sub sync_rel {
    my ($urpm, $medium, $rel_files, %options) = @_;

    my @files = map { reduce_pathname("$medium->{url}/$_") } @$rel_files;

    my $files_text = join(' ', (use_metalink($urpm, $medium) ? ($medium->{mirrorlist}, $medium->{'with-dir'}) : url_obscuring_password($medium->{url})), @$rel_files);
    $urpm->{debug} and $urpm->{debug}(N("retrieving %s", $files_text));

    my $all_options = _all_options($urpm, $medium, \%options);
    my @result_files = map { $all_options->{dir} . '/' . basename($_) } @$rel_files;
    unlink @result_files if $all_options->{preclean};

    #- The files must be world-readable, else mgaapplet and urpm* commands run as
    #- a normal user won't be able to read them. We enforce umask here in the case
    #- where the msec security level is set to 'secure' (which means umask 077)
    #- or where we are run from a gdm-x-session (mga#24636)
    my $old_umask = umask 0022;

    (my $cwd) = getcwd() =~ /(.*)/;
    eval { _sync_webfetch_raw($urpm, $medium, $rel_files, \@files, $all_options) };
    my $err = $@;
    chdir $cwd;
    umask $old_umask;
    if (!$err) {
	$urpm->{log}(N("retrieved %s", $files_text));
	\@result_files;
    } else {
	$urpm->{log}("error: $err");
	# don't leave partial download
	unlink @result_files;
	undef;
    }
}

sub sync_rel_one {
    my ($urpm, $medium, $rel_file, %options) = @_;

    my $files = sync_rel($urpm, $medium, [$rel_file], %options) or return;
    $files->[0];
}

=item sync_url($urpm, $url, %options)

Retrieve a file from the network and return the local cached file path.

=cut

sub sync_url {
    my ($urpm, $url, %options) = @_;
    sync_rel_one($urpm, { url => dirname($url), disable_metalink => $options{disable_metalink} }, basename($url), %options);
}

sub sync_rel_to {
    my ($urpm, $medium, $rel_file, $dest_file, %options) = @_;

    my $files = sync_rel($urpm, $medium, [$rel_file], %options) or return undef;
    my $result_file = $files->[0];
    $result_file ne $dest_file or rename($result_file, $dest_file) or return;
    $result_file;
}

=item get_content($urpm, $url, %o_options)

Retrieve a file and return its content.

=cut

sub get_content {
    my ($urpm, $url, %o_options) = @_;

    my $file = sync_url($urpm, $url, %o_options, quiet => 1, preclean => 1) or return;

    my @l = cat_($file);
    unlink $file;

    wantarray() ? @l : join('', @l);
}
    

#- syncing algorithms.
#-
#- nb: $files is constructed from $rel_files using $medium
sub _sync_webfetch_raw {    
    my ($urpm, $medium, $rel_files, $files, $options) = @_;

    #- currently ftp and http protocols are managed by curl or wget,
    #- ssh and rsync protocols are managed by rsync *AND* ssh.
    my $proto = urpm::protocol_from_url($medium->{url}) or die N("unknown protocol defined for %s", $medium->{url});

    if ($proto eq 'file') {
	my @l = map { urpm::file_from_local_url($_) } @$files;
	eval { sync_file($options, @l) };
	$urpm->{fatal}(10, $@) if $@;
    } elsif ($proto eq 'rsync') {
	sync_rsync($options, @$files);
    } elsif (member($proto, 'ftp', 'http', 'https') || $options->{metalink}) {

	my $preferred = preferred_downloader($urpm, $medium, \$options->{metalink});
	if ($preferred eq 'aria2') {
	    sync_aria2($urpm, $medium, $rel_files, $options);
	} else {
	  my $sync = $urpm::download::{"sync_$preferred"} or die N("no webfetch found, supported webfetch are: %s\n", join(", ", urpm::download::ftp_http_downloaders()));

	  my @l = @$files;
	  while (@l) {
	    my $half_MAX_ARG = 131072 / 2;
	    # restrict the number of elements so that it fits on cmdline of curl/wget/proz/aria2c
	    my $n = 0;
	    for (my $len = 0; $n < @l && $len < $half_MAX_ARG; $len += length($l[$n++])) {}	    
	    $sync->($options, splice(@l, 0, $n));
	  }
	}
    } elsif ($proto eq 'ssh') {
	my @ssh_files = map { m!^ssh://([^/]*)(.*)! ? "$1:$2" : @{[]} } @$files;
	sync_ssh($options, @ssh_files);
    } else {
	die N("unable to handle protocol: %s", $proto);
    }
}

sub _take_n_elem {
    my ($n, @l) = @_;
    @l < $n ? @l : @l[0 .. $n-1];
}

sub _create_one_metalink_line {
    my ($medium, $mirror, $rel_file, $counter) = @_;

    my $type = urpm::protocol_from_url($mirror->{url});

    # If more than 100 mirrors, give all the remaining mirrors a priority of 0
    my $preference = max(0, 100 - $counter);

    my @options = (qq(type="$type"), qq(preference="$preference"));
    # Not supported in metalinks
    #if (@$list[$i]->{bw}) {
    #    push @options, 'bandwidth="' . @$list[$i]->{bw} . '"';
    #       }
    # Supported in metalinks, but no longer used in mirror list..?
    if ($mirror->{connections}) {
	push @options, qq(maxconnections="$mirror->{connections}");
    }
    push @options, 'location="' . lc($mirror->{zone}) . '"';
    my $base = urpm::mirrors::_add__with_dir($mirror->{url}, $medium->{'with-dir'});
    sprintf('<url %s>%s/%s</url>', join(' ', @options), $base, $rel_file);
}

sub _create_metalink_ {
    my ($urpm, $medium, $rel_files, $options) = @_;
    # Don't create a metalink when downloading mirror list
    $medium or return;

    # only use the 8 best mirrors, then we let aria2 choose
    require urpm::mirrors;
    my @mirrors = $medium->{mirrorlist} ? (map {
	# aria2 doesn't handle rsync
	my @l = grep { urpm::protocol_from_url($_->{url}) ne 'rsync' } @$_;
	_take_n_elem(8, @l);
    } urpm::mirrors::list_urls($urpm, $medium, '')) : { url => $medium->{url} };
    
    my $metalinkfile = "$urpm->{cachedir}/$options->{media}.metalink";
    # Even if not required by metalink spec, this line is needed at top of
    # metalink file, otherwise aria2 won't be able to autodetect it..
    my @metalink = (
      '<?xml version="1.0" encoding="utf-8"?>',
      '<metalink version="3.0" generator="URPMI" xmlns="http://www.metalinker.org/">',
      '<files>',
    );

    foreach my $rel_file (@$rel_files) {
	my $i = 0; 
	my @lines = map {
	    $i++;
	    _create_one_metalink_line($medium, $_, $rel_file, $i);
	} @mirrors;

	push @metalink, map { "\t$_" }
	  sprintf('<file name="%s"><resources>', basename($rel_file)),
	  (map { "\t$_" } @lines),
	  '</resources></file>';
    }
    push @metalink, '</files>', '</metalink>';
    
    output_safe($metalinkfile, join('', map { "$_\n" } @metalink));
    $metalinkfile;
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
