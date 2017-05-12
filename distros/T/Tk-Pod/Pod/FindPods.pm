# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2001,2003,2004,2005,2007,2009,2012 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Tk::Pod::FindPods;

=head1 NAME

Tk::Pod::FindPods - find Pods installed on the current system


=head1 SYNOPSIS

    use Tk::Pod::FindPods;

    my $o = Tk::Pod::FindPods->new;
    $pods = $o->pod_find(-categorized => 1, -usecache => 1);

=head1 DESCRIPTION

=cut

use base 'Exporter';
use strict;
use vars qw($VERSION @EXPORT_OK $init_done %arch $arch_re);

@EXPORT_OK = qw/%pods $has_cache pod_find/;

$VERSION = '5.16';

BEGIN {  # Make a DEBUG constant very first thing...
  if(defined &DEBUG) {
  } elsif(($ENV{'TKPODDEBUG'} || '') =~ m/^(\d+)/) { # untaint
    my $debug = $1;
    *DEBUG = sub () { $debug };
  } else {
    *DEBUG = sub () {0};
  }
}

use File::Find;
use File::Spec;
use File::Basename;
use Config;

sub new {
    my($class) = @_;
    my $self = bless {}, $class;
    $self->init;
    $self;
}

sub init {
    return if $init_done;
    %arch = guess_architectures();
    $arch_re = "(" . join("|", map { quotemeta $_ } ("mach", keys %arch)) . ")";
    $init_done++;
}

=head2 pod_find

The B<pod_find> method scans the current system for available Pod
documentation. The keys of the returned hash reference are the names
of the modules or Pods (C<::> substituted by C</> --- this makes it
easier for Tk::Pod::Tree, as the separator may only be of one
character). The values are the corresponding filenames.

If C<-categorized> is specified, then the returned hash has an extra
level with four categories: B<perl> (for core language documentation),
B<pragma> (for pragma documentation like L<var|var> or
L<strict|strict>), B<mod> (core or CPAN modules), and B<script> (perl
scripts with embedded Pod documentation). Otherwise, C<-category> may
be set to force the Pods into a category.

By default, C<@INC> is scanned for Pods. This can be overwritten by
the C<-directories> option (specify as an array reference).

If C<-usecache> is specified, then the list of Pods is cached (see
L<cache directory|/Cache directory>). C<-usecache> is disabled if
C<-categorized> is not set or C<-directories> is set.

=cut

sub pod_find {
    my $self = shift;
    my(@args) = @_;
    my %args;
    if (ref $args[0] eq 'HASH') {
	%args = %{ $args[0] };
    } else {
	%args = @args;
    }

    $self->{has_cache} = 0;

    if ($args{-usecache}) {
	if (!$args{-categorized} || $args{-directories}) {
	    DEBUG and warn "Disabling -usecache";
	} else {
	    my $perllocal_site = File::Spec->catfile($Config{'installsitearch'},'perllocal.pod');
	    my $perllocal_lib  = File::Spec->catfile($Config{'installarchlib'},'perllocal.pod');
	    my $cache_file = _cache_file();
	VALIDATE_CACHE: {
		if (!-r $cache_file) {
		    DEBUG and warn "Cache file $cache_file does not exist or is not readable\n";
		    last VALIDATE_CACHE;
		}
		if (-e $perllocal_site && -M $perllocal_site < -M $cache_file) {
		    DEBUG and warn "$perllocal_site is more recent than cache file $cache_file\n";
		    last VALIDATE_CACHE;
		}
		if (-e $perllocal_lib  && -M $perllocal_lib < -M $cache_file) {
		    DEBUG and warn "$perllocal_lib is more recent than cache file $cache_file\n";
		    last VALIDATE_CACHE;
		}

		$self->LoadCache;
		if ($self->{pods}) {
		    $self->{has_cache} = 1;
		    return $self->{pods};
		}
	    }
	}
    }

    my(@dirs, @script_dirs);
    if ($args{-directories}) {
	@dirs = @{ $args{-directories} };
	@script_dirs = ();
    } else {
	@dirs = sort { length($b) <=> length($a) } grep { $_ ne '.' } @INC; # ignore current directory
	@script_dirs = ($Config{'scriptdir'});
    }

    my %seen_dir = ();
    my $curr_dir;
    undef $curr_dir;
    my %pods = ();

    if ($args{-category}) {
	$pods{$args{-category}} = {};
    }

    my $duplicate_warning_header_seen = 0;

    # Assume $_ and $File::Find::name are set
    my $ignore_directory = sub {
	return 1 if m{^(RCS|CVS|\.svn|\.git|blib)$};
    };

    my $wanted = sub {
	if (-d) {
	    if ($ignore_directory->()) {
		$File::Find::prune = 1;
		return;
	    } elsif ($seen_dir{$File::Find::name}) {
		$File::Find::prune = 1;
		return;
	    } else {
		$seen_dir{$File::Find::name}++;
	    }
	}

	if (-f && /\.(pod|pm)$/) {
	    my $curr_dir_rx = quotemeta $curr_dir;
	    (my $name = $File::Find::name) =~ s|^$curr_dir_rx/?||;
	    $name = simplify_name($name);

	    my $hash;
	    if ($args{-categorized}) {
		my $type = type($name);
		$hash = $pods{$type} || do { $pods{$type} = {} };
	    } elsif ($args{-category}) {
		$hash = $pods{$args{-category}};
	    } else {
		$hash = \%pods;
	    }

	    if (exists $hash->{$name}) {
		if ($hash->{$name} =~ /\.pod$/ && $File::Find::name =~ /\.pm$/) {
		    return;
		}
		my($ext1) = $hash->{$name}    =~ /\.(.*)$/;
		my($ext2) = $File::Find::name =~ /\.(.*)$/;
		if ($ext1 eq $ext2) {
		    (my $modname = $name) =~ s{/}{::}g;
		    if (!$duplicate_warning_header_seen) {
			$duplicate_warning_header_seen = 1;
			warn "*** Pod(s) with same name at different locations found: ***\n";
		    }
		    (my $hash_name_without_scheme = $hash->{$name}) =~ s{^file:}{};
		    warn "  $modname:\n    $hash_name_without_scheme\n    $File::Find::name\n";
		    return;
		}
	    }
	    $hash->{$name} = "file:" . $File::Find::name;
	}
    };

    my $wanted_scripts = sub {
	if (-d) {
	    if ($ignore_directory->()) {
		$File::Find::prune = 1;
		return;
	    } elsif ($seen_dir{$File::Find::name}) {
		$File::Find::prune = 1;
		return;
	    } else {
		$seen_dir{$File::Find::name}++;
	    }
	}

	if (-T && open(SCRIPT, $_)) {
	    my $has_pod = 0;
	    {
		local $_;
		while(<SCRIPT>) {
		    if (/^=(head\d+|pod)/) {
			$has_pod = 1;
			last;
		    }
		}
	    }
	    close SCRIPT;
	    if ($has_pod) {
		my $name = $_;

		my $hash;
		if ($args{-categorized}) {
		    my $type = 'script';
		    $hash = $pods{$type} || do { $pods{$type} = {} };
		} elsif ($args{-category}) {
		    $hash = $pods{$args{-category}};
		} else {
		    $hash = \%pods;
		}

		if (exists $hash->{$name}) {
		    return;
		}
		$hash->{$name} = "file:" . $File::Find::name;
	    }
	}
    };

    my %opts;
    if ($^O ne "MSWin32") {
	$opts{follow}      = 1;
	$opts{follow_skip} = 2;
    }

    foreach my $inc (reverse @dirs) {
	next unless -d $inc;
	$curr_dir = $inc;
	find({ %opts, wanted => $wanted }, $inc);
    }

    foreach my $inc (reverse @script_dirs) {
	find({ %opts, wanted => $wanted_scripts }, $inc);
    }

    if ($duplicate_warning_header_seen) {
	warn "*** This was the list of Pod(s) with same name at different locations. ***\n";
    }

    $self->{pods} = \%pods;
    $self->{pods};
}

sub simplify_name {
    my $f = shift;
    $f =~ s|^\d+\.\d+\.\d+/?||; # strip perl version
    $f =~ s|^$arch_re/|| if defined $arch_re; # strip machine
    $f =~ s/\.(pod|pm)$//;
    $f =~ s|^pod/||;
    # Workaround for case insensitive systems --- the pod directory contains
    # general pod documentation as well as Pod::* documentation:
    if ($^O =~ /^cygwin/) {
	$f =~ s|^pods/||; # "pod" is "pods" on cygwin
    } elsif ($^O =~ /^darwin/) {
	$f =~ s|^pods/||; # ... and on MacOSX
    } elsif ($^O eq 'MSWin32') {
	# oldstyle:
	$f =~ s|^pod/perl|perl|i;
	$f =~ s|^pod/Win32|Win32|i;
	# newstyle:
	$f =~ s|^pods/||;
    }
    $f;
}

sub type {
    local $_ = shift;
    if    (/^(?:perl|activeperl)/) { return "perl" }
    elsif (/^a2p$/) { return "script" }
    elsif (/^[a-z]/ && !/^(mod_perl|lwpcook|lwptut|cgi_to_mod_perl|libapreq)/)
	            { return "pragma" }
    else            { return "mod" }
}

# It's not possible to just use $Config{archname} --- it is necessary
# to get the names of all the installated archnames. This may be
# something like i386-freebsd vs. i386-freebsd-64int.
sub guess_architectures {
    my %arch;
    my @configs;
    foreach my $inc (@INC) {
	next unless -d $inc;
	if (!opendir(DIR, $inc)) {
	    warn "Can't opendir $inc: $!";
	    next;
	}
	while(defined(my $base = readdir DIR)) {
	    # Skip . and .., and some obviously wrong directories
	    # containing a Config.pm file. This is not strictly necessary,
	    # but so we avoid to scan the file itself.
	    next if $base =~ /^(\.|\.\.|CPANPLUS|Encode|Prima|Tk|PDL|Template|Net|App)$/;
	    next if !-d File::Spec->catdir($inc, $base);
	    my $cfgpm = File::Spec->catfile($inc, $base, "Config.pm");
	    if (-r $cfgpm) {
		push @configs, $cfgpm;
	    }
	}
	closedir DIR;
    }

    # Scan the Config.pm file to see if it's really a perl Config.pm
    # file.
    foreach my $config (@configs) {
	my($arch) = $config =~ m|[\\/]([^/\\]+)[\\/]Config.pm|;
	if (open(CFG, $config)) {
	    while(<CFG>) {
		/archname.*$arch/ && do {
		    $arch{$arch}++;
		    last;
		};
	    }
	    close CFG;
	} else {
	    warn "cannot open $config: $!";
	}
    }
    %arch;
}

sub module_location {
    my $mod = shift;
    my($type, $path) = $mod =~ /^([^:]+):(.*)/;
    if ($type eq 'cpan') {
	'cpan';
    } elsif (is_site_module($path)) {
	'site';
    } elsif (is_vendor_module($path)) {
	'vendor';
    } else {
	'core';
    }
}

sub is_site_module {
    my $path = shift;
    if ($^O eq 'MSWin32') {
	return $path =~ m|[/\\]site[/\\]lib[/\\]|;
    }
    $path =~ /^(
                \Q$Config{'installsitelib'}\E
               |
		\Q$Config{'installsitearch'}\E
	       )/x;
}

sub is_vendor_module {
    my $path = shift;
    return 0 if (!defined $Config{'installvendorlib'}  ||
		 $Config{'installvendorlib'}  eq ''    ||
		 !defined $Config{'installvendorarch'} ||
		 $Config{'installvendorarch'} eq ''
		);
    $path =~ /^(
                \Q$Config{'installvendorlib'}\E
               |
		\Q$Config{'installvendorarch'}\E
	       )/x;
}

sub _cache_file {
    (my $ver = $])                  =~ s/[^a-z0-9]/_/gi;
    (my $os  = $Config{'archname'}) =~ s/[^a-z0-9]/_/gi;
    my $uid  = $<;

    my $cache_file_pattern = $ENV{TKPODCACHE};
    if (!defined $cache_file_pattern) {
	my $cache_root;
	if ($^O =~ m{^(darwin|MSWin32)} && eval { require File::HomeDir; 1 }) {
	    $cache_root = File::Spec->catfile(File::HomeDir->my_data, ".tkpod_cache");
	} elsif ($ENV{HOME} && -d $ENV{HOME}) {
	    $cache_root = "$ENV{HOME}/.tkpod_cache";
	} else {
	    $cache_root = File::Spec->can('tmpdir') ? File::Spec->tmpdir : $ENV{TMPDIR}||"/tmp";
	}
	$cache_file_pattern = File::Spec->catfile
	    ($cache_root,
	     join('_', 'pods',"%v","%o","%u")
	    );
    }
    $cache_file_pattern =~ s/%v/$ver/g;
    $cache_file_pattern =~ s/%o/$os/g;
    $cache_file_pattern =~ s/%u/$uid/g;
    $cache_file_pattern;
}

sub pods      { shift->{pods} }
sub has_cache { shift->{has_cache} }

# Parts stolen from Pod::Perldoc::search_perlfunc
# Return pod text for given function
sub function_pod {
    my($self, $func) = @_;

    my $pod = "";

    my $perlfunc = $self->{pods}{perl}{perlfunc};
    $perlfunc =~ s{^file:}{};
    open(PFUNC, "< $perlfunc") or die "Can't open $perlfunc: $!";

    # Functions like -r, -e, etc. are listed under `-X'.
    my $search_re = ($func =~ /^-[rwxoRWXOeszfdlpSbctugkTBMAC]$/)
                        ? '(?:I<)?-X' : quotemeta($func) ;

    # Skip introduction
    local $_;
    while (<PFUNC>) {
        last if /^=head2 Alphabetical Listing of Perl Functions/;
    }

    # Look for our function
    my $found = 0;
    my $inlist = 0;
    while (<PFUNC>) {  # "The Mothership Connection is here!"
        if ( m/^=item\s+$search_re\W/ )  {
            $found = 1;
        }
        elsif (/^=item/) {
            last if $found > 1 and not $inlist;
        }
        next unless $found;
        if (/^=over/) {
            ++$inlist;
        }
        elsif (/^=back/) {
            --$inlist;
        }
        $pod .= $_;
        ++$found if /^\w/;        # found descriptive text
    }
    if ($pod eq "") {
        warn sprintf "No documentation for perl function `%s' found\n", $func;
    } else {
	# Fix pod so no warnings are given:
	$pod = "=over\n\n$pod\n\n=back\n";
    }
    close PFUNC                or die "Can't open $perlfunc: $!";

    return $pod;
}

=head2 WriteCache

Write the Pod cache. The cache is written to the L<cache
directory|/Cache directory>. The file name is constructed from the
perl version, operation system and user id.

=cut

sub WriteCache {
    my $self = shift;

    require Data::Dumper;

    my $cache_dir = dirname _cache_file();
    if (!-d $cache_dir) {
	mkdir $cache_dir, 0777
	    or do {
		warn "Can't create cache directory $cache_dir: $!";
		return;
	    };
    }
    if (!open(CACHE, ">" . _cache_file())) {
	warn "Can't write to cache file " . _cache_file() . ": $!";
	return;
    }

    my $dd = Data::Dumper->new([$self->{pods}], ['pods']);
    $dd->Indent(0);
    print CACHE $dd->Dump;
    close CACHE;
}

=head2 LoadCache()

Load the Pod cache, if possible.

=cut

sub LoadCache {
    my $self = shift;
    my $cache_file = _cache_file();
    if (-r $cache_file) {
	return if $< != (stat($cache_file))[4];
	require Safe;
	my $c = Safe->new('Tk::Pod::FindPods::SAFE');
	$c->rdo($cache_file);
	if (keys %$Tk::Pod::FindPods::SAFE::pods) {
	    $self->{pods} = { %$Tk::Pod::FindPods::SAFE::pods };
	    return $self->{pods};
	}
    }
    return {};
}

return 1 if caller;

package main;

require Data::Dumper;
print Data::Dumper->Dumpxs([Tk::Pod::FindPods->new->pod_find(-categorized => 0, -usecache => 0)],[]);

__END__

=head2 Cache directory

By default the cache file is written to the directory
F<~/.tkpod_cache> (Unix systems), or the data directory as determined
by L<File::HomeDir> (Windows, MacOSX). If everything fails, then the
temporary directory (F</tmp> or the OS equivalent) is used.

If necessary, then the last path component will be created (that is,
F<.tkpod_cache> will be created if the directory does not exist).

To use another cache directory set the environment variable
L</TKPODCACHE>.

=head1 ENVIRONMENT

=over

=item TKPODCACHE

Use a custom cache file instead of a file in the L<cache directory|/Cache directory>.
The following placeholders are recognized:

=over

=item %v

The perl version.

=item %o

The OS (technically correct: the archname, which can include tokens
like "64int" or "thread").

=item %u

The user id.

=back

Example for using F</some/other/directory> for the cache file location:

	TKPODCACHE=/some/other/directory/pods_%v_%o_%u; export TKPODCACHE

or

	setenv TKPODCACHE /some/other/directory/pods_%v_%o_%u

depending on your shell (sh-like or csh-like).

=back

=head1 SEE ALSO

L<Tk::Tree>.

=head1 AUTHOR

Slaven ReziE<0x0107> <F<slaven@rezic.de>>

Copyright (c) 2001,2003,2004,2005,2007,2009 Slaven ReziE<0x0107>. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
