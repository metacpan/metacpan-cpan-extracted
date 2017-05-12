# MMDS::Common.pm -- common routines

package MMDS::Common;

# $RCS_Id = '$Id: Common.pm,v 2.30 2003-01-10 22:58:37+01 jv Exp jv $ ';
# Author          : Johan Vromans
# Created On      : Thu Feb  7 11:36:04 1991
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr  1 14:57:03 2003
# Update Count    : 139
# Status          : OK
# Based On        : common.pl,v 2.22 2002-11-25 22:22:48+01

use strict;
use warnings;

sub ::grease_tty {
    # Speed up throughput by avoiding unbuffered IO.
    if ( -t STDOUT && -t STDERR ) {
	open (STDERR, ">&STDOUT");
	select (STDERR); $| = 1;
	select (STDOUT);
    }
}

$::my_package = "Squirrel/MMDS X2.0";

sub ::ident_msg {
    warn("This is $::my_package "."[$::my_name $::my_version]\n");
}

sub ::phase_msg {
    my ($tag) = @_;
    my $exit;
    my @tm = localtime (time);
    my $vers;
    $tag = "Normal Termination", $exit = 0 if $tag eq "0";
    if ( $tag =~ /^\d+$/ ) {
	$exit = $tag;
	$tag = "Aborted ($tag)";
    }
    if ( defined $::my_version || defined $::my_name ) {
	$vers = "[";
	$vers .= $::my_name if defined $::my_name;
	$vers .= ' ' if defined $::my_name && defined $::my_version;
	$vers .= $::my_version if defined $::my_version;
	$vers .= "]";
	$vers = ('-' x (58 - length($vers) - length($tag))) . $vers;
    }
    else {
	$vers = '-' x (58 - length($tag));
    }

    warn(sprintf("-- %s --%s-- %02d:%02d:%02d --\n",
		 $tag, $vers, $tm[2], $tm[1], $tm[0]));
    if ( defined $exit ) {
	&main::exit($exit) if defined &main::exit;
	CORE::exit($exit);
    }
}

sub ::debug_msg {
    my (@args) = @_;
    s/^(.{30})....*$/$1.../ foreach @args;
    warn("=> ", shift(@args), "(\"", join('","',@args), "\")\n");
}

sub ::dpstr {
    my ($str, $len) = @_;

    # Treat string for display purposes.

    return "" unless $str ne "";
    $len = 40 unless $len;
    $str = substr($str,0,$len-3) . "..." if length($str) > $len-3;
    "\"" . $str . "\"";
}

# Native Language Support

my $nls_table;

sub ::nls {
    $nls_table->[$_[0]] ||
	CORE::die("Internal NLS error: missing entry $_[0]\n");
}

sub ::nls_init {
    $nls_table = shift;
}

sub ::enum {		# courtesy LWall & TNeff
    @_[$[..$#_] = ($[+$_[0])..($#_+$_[0]);
}

# Load a package relative to our own package hierarchy, and using the
# standard search path.

sub ::loadpkg {
    my ($pkg, $package) = @_;
    $package ||= caller;
    $pkg = $package . "::" . $pkg unless $pkg =~ /::/;
    $pkg =~ s/::::/::/g;
    warn("Loading: $pkg\n") if $::trace;
    my $ok = eval("require $pkg");
    die(@$) if @$;
    die("Error loading $pkg\n") unless $ok;
}

# Configuration and properties.

use MMDS::Properties;

# This is the normal way to get the properties.
# Strategy:
#  - Load the system wide mmds.prp
#  - If config files are passed: load these and finish
#    So if you're pass config files, pass them all.
#  - Otherwise, if a local file mmds.prp exists, load it and finish.
#    So if you want local + home, load the home prp from local.
#  - Otherwise, load a $HOME/mmds.prp if it exists.

sub get_config {
    my ($self, $config) = @_;
    my $cfg = MMDS::Properties->new;
    my $add = sub {
	my ($file, $optional) = @_;
	$file =~ s/$/.prp/ unless $file =~ /\.\w+$/;
	unless ( -s $file ) {
	    warn("Skipping properties: $file\n") unless $optional;
	    return;
	}
	warn("Parsing properties: $file\n") if $::trace;
	$cfg->parsefile($file);
    };

    # Strategy:
    #  - load the system wide mmds.prp
    $add->($::MMDSLIB.  "/mmds.prp", 0);

    # Strategy:
    #  - if config files are passed: load these and finish
    if ( $config ) {
	foreach my $cf ( split(/[:,]/, $config) ) {
	    $add->($cf, 0);
	}
    }
    # Strategy:
    #  - otherwise, if a local file mmds.prp exists, load it and finish.
    elsif ( -f "mmds.prp" ) {
	$add->("mmds.prp", 1);
    }
    # Strategy:
    #  - otherwise, load a $HOME/mmds.prp if it exists.
    else {
	$add->($ENV{HOME}."/mmds.prp", 1);
    }

    # Make sure this is always set to the right value.
    $cfg->set_property("config.mmdslib", $::MMDSLIB);
    $cfg;
}

sub ::cfg_gps {
    my ($root, $target, $path, $default) = @_;
    $root .= ".";
    $path = [ $path ] unless ref($path);
    foreach ( @$path, "" ) {
	my $pe = $_;
	$pe .= "." if $pe ne "";
	my $r = $::cfg->gps($root.$pe.$target, undef);
	return $r if defined $r;
    }
    $default;
}

1;
