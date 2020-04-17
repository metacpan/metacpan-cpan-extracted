package urpm::args;


use strict;
use warnings;
no warnings 'once';
use Getopt::Long;
use urpm::download;
use urpm::msg;
use urpm::util 'file2absolute_file';
use Exporter;

our @ISA = 'Exporter';
our @EXPORT = '%options';

# The program that invokes us
(my $tool = $0) =~ s!.*/!!;

# Configuration of Getopt. urpmf is a special case, because we need to
# parse non-alphanumerical options (-! -( -))
my @configuration = qw(bundling no_ignore_case permute);
push @configuration, 'pass_through'
    if $tool eq 'urpmf' || $tool eq 'urpmi.addmedia';
Getopt::Long::Configure(@configuration);

# global urpm object to be passed by the main program
my $urpm;

# stores the values of the command-line options
our %options = (verbose => 0);

# used by urpmf
sub add_param_closure {
    my (@tags) = @_;
    return sub { $::qf .= join $::separator, '', map { "%$_" } @tags };
}

# debug code to display a nice message when exiting, 
# to ensure f*cking code (eg: Sys::Syslog) won't exit and break graphical interfaces
END { $::debug_exit and print STDERR "EXITING (pid=$$)\n" }

sub set_debug { 
    my ($urpm) = @_;
    $::debug_exit = 1;
    $options{verbose}++;
    $urpm->{debug} = $urpm->{debug_URPM} = sub { print STDERR "$_[0]\n" };
}

sub set_verbose {
    $options{verbose} += $_[0];
}

# options specifications for Getopt::Long

my %options_spec_all = (
	'debug' => sub { set_debug($urpm) },
	'debug-librpm' => sub { URPM::setVerbosity(7) }, # 7 == RPMLOG_DEBUG
	'q|quiet' => sub { set_verbose(-1) },
	'v|verbose' => sub { set_verbose(1) },
	'urpmi-root=s' => sub { urpm::set_files($urpm, $_[1]) },
	'wait-lock' => \$options{wait_lock},
	'use-copied-hdlist' => sub { $urpm->{options}{use_copied_hdlist} = 1 },
	'tune-rpm=s' => sub { urpm::set_tune_rpm($urpm, $_[1]) },
	"no-locales" => sub { $urpm::msg::no_translation = 1 },
	"version" => sub { require urpm; print "$tool $urpm::VERSION\n"; exit(0) },
	"help|h" => sub {
	    if (defined &::usage) { ::usage() } else { die "No help defined\n" }
	},
);

my %options_spec = (

    # warning: for gurpm, urpm is _not_ a real urpmi object, only options should be altered:
    gurpmi => {
	'media|mediums=s' => sub { $urpm->{options}{media} = 1 },
	'searchmedia|search-media=s' => sub { $urpm->{options}{searchmedia} = 1 },
    },

    urpmi => {
	update => \$::update,
	'media|mediums=s' => \$::media,
	'excludemedia|exclude-media=s' => \$::excludemedia,
	'sortmedia|sort-media=s' => \$::sortmedia,
	'searchmedia|search-media=s' => \$::searchmedia,
	'synthesis=s' => \$options{synthesis},
	auto => sub { $urpm->{options}{auto} =  1 },
	'allow-medium-change' => \$::allow_medium_change,
	'auto-select' => \$::auto_select,
	'auto-update' => sub { $::auto_update = $::auto_select = 1 },
	'auto-orphans' => \$options{auto_orphans},
	'no-remove|no-uninstall' => \$::no_remove,
	'no-install|noinstall' => \$::no_install,
	'keep!' => sub { $urpm->{options}{keep} = $_[1] },
	'logfile=s' => \$::logfile,
	'split-level=s' => sub { $urpm->{options}{'split-level'} = $_[1] },
	'split-length=s' => sub { $urpm->{options}{'split-length'} = $_[1] },
	'fuzzy!' => sub { $urpm->{options}{fuzzy} = $_[1] },
	'src|s' => sub { $urpm->{error}("option --src is deprecated, use --buildrequires instead (nb: it doesn't download src.rpm anymore)");
			 $options{buildrequires} = 1 },
	'buildrequires' => \$options{buildrequires},
	'install-src' => \$::install_src,
	reinstall => sub { $urpm->{options}{reinstall} = 1 },
	clean => sub { $::clean = 1; $::noclean = 0 },
	noclean => sub {
	    $::clean = $urpm->{options}{'pre-clean'} = $urpm->{options}{'post-clean'} = 0;
	    $::noclean = 1;
	},
	'pre-clean!' => sub { $urpm->{options}{'pre-clean'} = $_[1] },
	'post-clean!' => sub { $urpm->{options}{'post-clean'} = $_[1] },
	'no-priority-upgrade' => sub {
	    #- keep this option which is passed by older urpmi.
	    #- since we can't know what the previous_priority_upgrade list was, 
	    #- just use a rubbish value which will mean list has changed
	    $options{previous_priority_upgrade} = 'list_has_changed';
	},
	'previous-priority-upgrade=s' => \$options{previous_priority_upgrade},
	force => \$::force,
	justdb => \$options{justdb},
	replacepkgs => \$options{replacepkgs},
	suggests => sub { 
	    $urpm->{fatal}(1, "Use --allow-recommends instead of --suggests");
	},
	'allow-suggests' => sub {
	    warn "WARNING: --allow-suggests is deprecated. Use --allow-recommends instead\n";
	    $urpm->{options}{'no-recommends'} = 0 },
	'allow-recommends' => sub { $urpm->{options}{'no-recommends'} = 0 },
	'no-recommends' => sub { $urpm->{options}{'no-recommends'} = 1 },
	'no-suggests' => sub { # COMPAT
	    warn "WARNING: --no-suggests is deprecated. Use --no-recommends instead\n";
	    $urpm->{options}{'no-recommends'} = 1;
	},
	'allow-nodeps' => sub { $urpm->{options}{'allow-nodeps'} = 1 },
	'allow-force' => sub { $urpm->{options}{'allow-force'} = 1 },
	'downgrade' => sub { $urpm->{options}{downgrade} = 1 },
	'parallel=s' => \$::parallel,

	'metalink!' => sub { $urpm->{options}{metalink} = $_[1] },
	'download-all:s' => sub { $urpm->{options}{'download-all'} = $_[1] },
	# deprecated in favor of --downloader xxx
	wget => sub { $urpm->{options}{downloader} = 'wget' },
	curl => sub { $urpm->{options}{downloader} = 'curl' },
	prozilla => sub { $urpm->{options}{downloader} = 'prozilla' },
	aria2 => sub { $urpm->{options}{downloader} = 'aria2' },
	'downloader=s' => sub { $urpm->{options}{downloader} = $_[1] },

	'curl-options=s' => sub { $urpm->{options}{'curl-options'} = $_[1] },
	'rsync-options=s' => sub { $urpm->{options}{'rsync-options'} = $_[1] },
	'wget-options=s' => sub { $urpm->{options}{'wget-options'} = $_[1] },
	'prozilla-options=s' => sub { $urpm->{options}{'prozilla-options'} = $_[1] },
	'aria2-options=s' => sub { $urpm->{options}{'aria2-options'} = $_[1] },
	'limit-rate=s' => sub { $urpm->{options}{'limit-rate'} = $_[1] },
	'resume!' => sub { $urpm->{options}{resume} = $_[1] },
	'retry=s' => sub { $urpm->{options}{retry} = $_[1] },
	'proxy=s' => sub {
	    my (undef, $value) = @_;
	    my ($proxy, $port) = urpm::download::parse_http_proxy($value)
		or die N("bad proxy declaration on command line\n");
	    $proxy .= ":1080" unless $port;
	    urpm::download::set_cmdline_proxy(http_proxy => "http://$proxy/");
	},
	'proxy-user=s' => sub {
	    my (undef, $value) = @_;
	    if ($value eq 'ask') { #- should prompt for user/password
		urpm::download::set_cmdline_proxy(ask => 1);
	    } else {
		$value =~ /(.+):(.+)/ or die N("bad proxy declaration on command line\n");
		urpm::download::set_cmdline_proxy(user => $1, pwd => $2);
	    }
	},
	'bug=s' => \$options{bug},
	'env=s' => \$::env,
	'verify-rpm!' => sub { $urpm->{options}{'verify-rpm'} = $_[1] },
	'strict-arch!' => sub { $urpm->{options}{'strict-arch'} = $_[1] },
	'norebuild!' => sub { $urpm->{options}{'build-hdlist-on-error'} = !$_[1] },
	'test!' => \$::test,
	'debug__do_not_install' => \$options{debug__do_not_install},
	deploops => \$options{deploops},
	'skip=s' => \$options{skip},
	'prefer=s' => \$options{prefer},
 	'root=s' => sub { set_root($urpm, $_[1]) },
	'use-distrib=s' => sub {
	    $options{usedistrib} = $_[1];
	    return if !$>;
	    $urpm->{cachedir} = $urpm->valid_cachedir;
	    $urpm->{statedir} = $urpm->valid_statedir;
	},
	'probe-synthesis' => sub { $options{probe_with} = 'synthesis' },
	'probe-hdlist' => sub { $options{probe_with} = 'synthesis' }, #- ignored, kept for compatibility
	'excludepath|exclude-path=s' => sub { $urpm->{options}{excludepath} = $_[1] },
	'excludedocs|exclude-docs' => sub { $urpm->{options}{excludedocs} = 1 },
	'ignoresize' => sub { $urpm->{options}{ignoresize} = 1 },
	'ignorearch' => sub { $urpm->{options}{ignorearch} = 1 },
	noscripts => sub { $urpm->{options}{noscripts} = 1 },
	replacefiles => sub { $urpm->{options}{replacefiles} = 1 },
	'more-choices' => sub { $urpm->{options}{morechoices} = 1 },
	'expect-install!' => \$::urpm::main_loop::expect_install,
	'nolock' => \$options{nolock},
	restricted => \$::restricted,
	'force-key' => \$::forcekey,
	a => \$::all,
	p => sub { $::use_provides = 1 },
	P => sub { $::use_provides = 0 },
	y => sub { $urpm->{options}{fuzzy} = 1 },
	z => sub { $urpm->{options}{compress} = 1 },
    },

    urpme => {
	a => \$options{matches},
	restricted => \$options{restricted},
    },

    #- see also below, autogenerated callbacks
    urpmf => {
	conffiles => add_param_closure('conf_files'),
	debug => \$::debug,
	'literal|l' => \$::literal,
	name => sub {
	    add_param_closure('name')->();
	    #- Remove default tag in front if --name is explicitly given
	    $::qf =~ s/^%default:?//;
	},
	'qf=s' => \$::qf,
	'uniq|u' => \$::uniq,
	m => add_param_closure('media'),
	i => sub { $::pattern = 'i' },
	I => sub { $::pattern = '' },
	f => sub { $::full = 1 },
	'F=s' => sub { $::separator = $_[1] },
	'e=s' => sub { $::expr .= "($_[1])" },
	a => sub { add_urpmf_binary_op('&&', '-a') },
	o => sub { add_urpmf_binary_op('||', '-o') },
	'<>' => sub {
	    my $p = shift;
	    if ($p =~ /^-?([!()])$/) {
		# This is for -! -( -)
		my $op = $1;
		$op eq ')' ? add_urpmf_close_paren() : add_urpmf_unary_op($op);
	    }
	    elsif ($p =~ /^--?(.+)/) {
		# unrecognized option
		die "Unknown option: $1\n";
	    }
	    else {
		# This is for non-option arguments.
		add_urpmf_parameter($p);
	    }
	},
    },

    urpmq => {
	update => \$options{update},
	'media|mediums=s' => \$options{media},
	'excludemedia|exclude-media=s' => \$options{excludemedia},
	'sortmedia|sort-media=s' => \$options{sortmedia},
	'searchmedia|search-media=s' => \$options{searchmedia},
	'auto-select' => sub {
	    $options{deps} = $options{upgrade} = $options{auto_select} = 1;
	},
	'fuzzy|y' => sub { $urpm->{options}{fuzzy} = 1; $options{all} = 1 },
	'not-available' => \$options{not_available},
	keep => \$options{keep},
	list => \$options{list},
	changelog => \$options{changelog},
	conflicts => \$options{conflicts},
	obsoletes => \$options{obsoletes},
	provides => \$options{provides},
	sourcerpm => \$options{sourcerpm},
	'summary|S' => \$options{summary},
	recommends => sub {
	    $options{recommends} = 1;
	},
	suggests => sub { 
	    $urpm->{error}("--suggests now displays the suggested packages, see --allow-suggests for previous behaviour");
	    $urpm->{error}("You should now use --recommends.");
	    $options{recommends} = 1;
	},
	'list-media:s' => sub { $options{list_media} = $_[1] || 'all' },
	'list-url' => \$options{list_url},
	'list-nodes' => \$options{list_nodes},
	'list-aliases' => \$options{list_aliases},
	'ignorearch' => \$options{ignorearch},
	'dump-config' => \$options{dump_config},
	'src|s' => \$options{src},
	sources => \$options{sources},
	force => \$options{force},
	'parallel=s' => \$options{parallel},
	'env=s' => \$options{env},
	requires => sub {
	    $urpm->{error}("--requires behaviour changed, use --requires-recursive to get the old behaviour");
	    $options{requires} = 1;
	},
	'requires-recursive|d' => \$options{deps},
	u => \$options{upgrade},
	a => \$options{all},
	'm|M' => sub { $options{deps} = $options{upgrade} = 1 },
	c => \$options{complete},
	g => \$options{group},
	'whatprovides|p' => \$options{use_provides},
	P => sub { $options{use_provides} = 0 },
	R => sub { $urpm->{error}($options{what_requires} ?
				    "option -RR is deprecated, use --whatrequires-recursive instead" : 
				    "option -R is deprecated, use --whatrequires instead");
	           $options{what_requires} and $options{what_requires_recursive} = 1; 
		   $options{what_requires} = 1 },
	whatrequires => sub { $options{what_requires} = 1 },
	'whatrequires-recursive' => sub { $options{what_requires_recursive} = $options{what_requires} = 1 },
	Y => sub { $urpm->{options}{fuzzy} = 1; $options{all} = $options{caseinsensitive} = 1 },
	i => \$options{info},
	l => \$options{files},
	r => sub {
	    $options{version} = $options{release} = 1;
	},
	f => sub {
	    $options{version} = $options{release} = $options{arch} = 1;
	},
	'<>' => sub {
	    my $x = $_[0];
	    if ($x =~ /\.rpm$/) {
		if (-r $x) { push @::files, $x }
		else {
		    print STDERR N("urpmq: cannot read rpm file \"%s\"\n", $x);
		    $urpm::postponed_code = 1;
	        }
	    } elsif ($x =~ /^--?(.+)/) { # unrecognized option
		die "Unknown option: $1\n";
	    } else {
		if ($options{src}) {
		    push @::src_names, $x;
		} else {
		    push @::names, $x;
		}
		$options{src} = 0; #- reset switch for next package.
	    }
	},
    },

    'urpmi.update' => {
	a => \$options{all},
	c => sub {}, # obsolete
	f => sub { ++$options{force}; $options{probe_with} = 'rpms' if $options{force} == 2 },
	z => sub { ++$options{compress} },
	update => \$options{update},
	'ignore!' => sub { $options{ignore} = $_[1] },
	'force-key' => \$options{forcekey},
	'no-md5sum' => \$options{nomd5sum},
	'noa|d' => \my $_dummy, #- default, kept for compatibility
	'norebuild!' => sub { $urpm->{options}{'build-hdlist-on-error'} = !$_[1]; $options{force} = 0 },
	'probe-rpms' => sub { $options{probe_with} = 'rpms' },
	'<>' => sub {
	    my ($p) = @_;
	    if ($p =~ /^--?(.+)/) { # unrecognized option
		die "Unknown option: $1\n";
	    }
	    push @::cmdline, $p;
	},
    },

    'urpmi.addmedia' => {
	'xml-info=s' => \$options{'xml-info'},
	'no-probe' => sub { $options{probe_with} = undef },
	distrib => sub { $options{distrib} = 1 },
	'mirrorlist:s' => sub { $options{mirrorlist} = $_[1] || '$MIRRORLIST' },
	zeroconf => sub { $options{zeroconf} = 1 },
        interactive => sub { $options{interactive} = 1 },
        'all-media' => sub { $options{allmedia} = 1 },
	virtual => \$options{virtual},
	nopubkey => \$options{nopubkey},
	raw => \$options{raw},
	'verify-rpm!' => sub { ${options}{'verify-rpm'} = $_[1] },
    },

);

# generate urpmf options callbacks
sub add_urpmf_cmdline_tags {
    foreach my $k (@_) {
	$options_spec{urpmf}{$k} ||= add_param_closure($k);
    }
}

sub _current_urpmf_left_expr() {
    my $left = $::left_expr || $::expr && "$::expr || "  || '';
    $::left_expr = $::expr = undef;
    $left;
}

sub add_urpmf_binary_op {
    my ($op, $cmdline) = @_;
    $::left_expr and $urpm->{fatal}(1, N("unexpected expression %s", $::left_expr));
    $::expr or $urpm->{fatal}(1, N("missing expression before %s", $cmdline));

    ($::expr, $::left_expr) = (undef, $::expr . " $op ");
}
sub add_urpmf_unary_op {
    my ($op) = @_;
    $::expr and $urpm->{fatal}(1, N("unexpected expression %s (suggestion: use -a or -o ?)", $::expr));
    ($::expr, $::left_expr) = (undef, $::left_expr . $op);
}
sub add_urpmf_close_paren() {
    $::expr or $urpm->{fatal}(1, N("no expression to close"));
    $::expr .= ')';
}
sub add_urpmf_parameter {
    my ($p) = @_;

    if ($::literal) {
	$p = quotemeta $p;
    } else {
	$p =~ /\([^?|]*\)$/ and $urpm->{error}(N("by default urpmf awaits a regexp. you should use option \"--literal\"")); 
	push @::raw_non_literals, $p;
	# quote "+" chars for packages with + in their names
	$p =~ s/\+/\\+/g;
    }
    $::expr = _current_urpmf_left_expr() . "m{$p}" . $::pattern;
}

# common options setup

foreach my $k ('allow-medium-change', 'auto', 'auto-select', 'clean', 'download-all:s', 'force', 'expect-install!', 'justdb', 'no-priority-upgrade', 'noscripts', 'replacefiles', 'p', 'P', 'previous-priority-upgrade=s', 'root=s', 'test!', 'verify-rpm!', 'update',
	       'split-level=s', 'split-length=s')
{
    $options_spec{gurpmi}{$k} = $options_spec{urpmi}{$k};
}
$options_spec{gurpmi2} = $options_spec{gurpmi};

foreach my $k ("test!", "force", "root=s", "use-distrib=s", 'env=s',
    'noscripts', 'auto', 'auto-orphans', 'justdb',
    "parallel=s")
{
    $options_spec{urpme}{$k} = $options_spec{urpmi}{$k};
}
foreach my $k ("root=s", "nolock", "use-distrib=s", "skip=s", "prefer=s", "synthesis=s", 'no-recommends', 'no-suggests', 'allow-recommends', 'allow-suggests', 'auto-orphans')
{
    $options_spec{urpmq}{$k} = $options_spec{urpmi}{$k};
}

foreach my $k ("update", "media|mediums=s",
    "excludemedia|exclude-media=s", "sortmedia|sort-media=s", "use-distrib=s",
    "synthesis=s", "env=s")
{
    $options_spec{urpmf}{$k} = $options_spec{urpmi}{$k};
}

foreach my $k ("wget", "curl", "prozilla", "aria2", 'downloader=s', "proxy=s", "proxy-user=s",
    'limit-rate=s', 'metalink!',
    "wget-options=s", "curl-options=s", "rsync-options=s", "prozilla-options=s", "aria2-options=s")
{
    $options_spec{'urpmi.addmedia'}{$k} = 
    $options_spec{'urpmi.update'}{$k} =
    $options_spec{urpmq}{$k} = $options_spec{urpmi}{$k};
}

foreach my $k ("f", "z", "update", "norebuild!", "probe-rpms", '<>')
{
    $options_spec{'urpmi.addmedia'}{$k} = $options_spec{'urpmi.update'}{$k};
}

foreach my $k ("no-md5sum")
{
    $options_spec{urpmi}{$k} = $options_spec{'urpmi.addmedia'}{$k} = $options_spec{'urpmi.update'}{$k};
}

foreach my $k ("a", '<>') {
    $options_spec{'urpmi.removemedia'}{$k} = $options_spec{'urpmi.update'}{$k};
}
foreach my $k ("y") {
    $options_spec{'urpmi.removemedia'}{$k} = $options_spec{urpmi}{$k};
}

foreach my $k ("probe-synthesis", "probe-hdlist") # probe-hdlist is obsolete
{
    $options_spec{'urpmi.addmedia'}{$k} = 
      $options_spec{urpme}{$k} = 
	$options_spec{urpmq}{$k} = $options_spec{urpmi}{$k};
}

sub set_root {
    my ($urpm, $root) = @_;

    $urpm->{root} = file2absolute_file($root);

	    if (!-d $urpm->{root}) {
		$urpm->{fatal}->(9, N("chroot directory doesn't exist"));
	    }
}

sub set_verbosity() {
    $options{verbose} >= 0 or $urpm->{info} = sub {};
    $options{verbose} > 0 or $urpm->{log} = sub {};
}

sub parse_cmdline {
    my %args = @_;
    $urpm = $args{urpm};
    foreach my $k (keys %{$args{defaults} || {}}) {
	$options{$k} = $args{defaults}{$k};
    }
    my $ret = GetOptions(%{$options_spec{$tool}}, %options_spec_all);

    set_verbosity();

    $urpm->{tune_rpm} and urpm::tune_rpm($urpm);

    if ($tool ne 'urpmi.addmedia' && $tool ne 'urpmi.update' &&
	  $options{probe_with} && !$options{usedistrib}) {
	die N("Can't use %s without %s", "--probe-$options{probe_with}", "--use-distrib");
    }
    if ($options{probe_with} && $options{probe_with} eq 'rpms' && $options{virtual}) {
	die N("Can't use %s with %s", "--probe-rpms", "--virtual");
    }
    if ($options{nolock} && $options{wait_lock}) {
	warn N("Can't use %s with %s", "--wait-lock", "--nolock") . "\n";
    }
    if ($tool eq 'urpmf' && @ARGV && $ARGV[0] eq '--') {
	if (@ARGV == 2) {
	    add_urpmf_parameter($ARGV[1]);
            $ret = 1;
	}
	else {
	    die N("Too many arguments\n");
	}
    }
    $ret;
}

sub copyright {
    my ($prog_name, @copyrights) = @_;
    N("%s version %s
%s
This is free software and may be redistributed under the terms of the GNU GPL.

usage:
", $prog_name, $urpm::VERSION,
      join("\n", map { N("Copyright (C) %s by %s", @$_) } @copyrights)
	);
}

1;


=head1 NAME

urpm::args - command-line argument parser for the urpm* tools

=head1 SYNOPSIS

    urpm::args::parse_cmdline();

=head1 DESCRIPTION

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=for vim:ts=8:sts=4:sw=4

=cut
