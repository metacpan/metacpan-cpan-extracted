package urpm::cfg;


use strict;
use warnings;
use urpm::util qw(any cat_ partition output_safe quotespace unquotespace);
use urpm::msg 'N';

=head1 NAME

urpm::cfg - routines to handle the urpmi configuration files

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item load_config($file)

Reads an urpmi configuration file and returns its contents in a hash ref :

    {
	media => [
         {
            name => 'medium name 1',
	    url => 'http://...',
	    option => 'value',
	    ...
	 },
        ],
	global => {
	    # global options go here
	},
    }

Returns undef() in case of parsing error (and sets C<$urpm::cfg::err> to the
appropriate error message.)

=item dump_config($file, $config)

Does the opposite: write the configuration file, from the same data structure.
Returns 1 on success, 0 on failure.

=cut

#- implementations of the substitutions. arch and release are mdk-specific.
#- XXX this is fragile code, it's an heuristic that depends on the format of
#- /etc/release

my ($arch, $release);
sub _init_arch_release () {
    if (!$arch && !$release) {
	my $l = cat_('/etc/release') or return undef;
	($release, $arch) = $l =~ /release (\d+\.?\d?).*for (\w+)/;
	$release = 'cauldron' if $l =~ /cauldron/i;
    }
    1;
}

sub get_arch () { _init_arch_release(); $arch }

sub get_release () { _init_arch_release(); $release }

sub get_host () {
    my $h = cat_('/proc/sys/kernel/hostname') || $ENV{HOSTNAME} || `/bin/hostname`;
    chomp $h;
    $h;
}

our $err;

sub _syntax_error () { $err = N("syntax error in config file at line %s", $.) }

sub substitute_back {
    my ($new, $old) = @_;
    return $new if !defined($old);
    return $old if expand_line($old) eq $new;
    return $new;
}

my %substitutions;
sub expand_line {
    my ($line) = @_;
    unless (scalar keys %substitutions) {
	%substitutions = (
	    HOST => get_host(),
	    ARCH => get_arch(),
	    RELEASE => get_release(),
	);
    }
    foreach my $sub (keys %substitutions) {
	$line =~ s/\$$sub\b/$substitutions{$sub}/g;
    }
    return $line;
}

my $no_para_option_regexp = 'update|ignore|synthesis|noreconfigure|no-recommends|no-suggests|no-media-info|static|virtual|disable-certificate-check';

sub load_config_raw {
    my ($file, $b_norewrite) = @_;
    my @blocks;
    my $block;
    $err = '';
    -r $file or do { 
	$err = N("unable to read config file [%s]", $file); 
	return;
    };
    foreach (cat_($file)) {
	chomp;
	next if /^\s*#/; #- comments
	s/^\s+//; s/\s+$//;
	$_ = expand_line($_) unless $b_norewrite;
	if ($_ eq '}') { #-{
	    if (!defined $block) {
		_syntax_error();
		return;
	    }
	    push @blocks, $block;
	    undef $block;
	} elsif (defined $block && /{$/) { #-}
	    _syntax_error();
	    return;
	} elsif ($_ eq '{') { 
	    #-} Entering a global block
	    $block = { name => '' };
	} elsif (/^(.*?[^\\])\s+(?:(.*?[^\\])\s+)?{$/) { 
	    #- medium definition
	    my ($name, $url) = (unquotespace($1), unquotespace($2));
	    if (any { $_->{name} eq $name } @blocks) {
		#- hmm, somebody fudged urpmi.cfg by hand.
		$err = N("medium `%s' is defined twice, aborting", $name);
		return;
	    }
	    $block = { name => $name, $url ? (url => $url) : @{[]} };
	} elsif (/^(hdlist
	  |list
	  |with_hdlist
	  |with_synthesis
	  |with-dir
          |mirrorlist
	  |media_info_dir
	  |removable
	  |md5sum
	  |limit-rate
	  |nb-of-new-unrequested-pkgs-between-auto-select-orphans-check
	  |xml-info
	  |excludepath
	  |split-(?:level|length)
	  |priority-upgrade
	  |prohibit-remove
	  |downloader
	  |retry
	  |default-media
	  |download-all
	  |tune-rpm
	  |(?:curl|rsync|wget|prozilla|aria2)-options
	  )\s*:\s*['"]?(.*?)['"]?$/x) {
	    #- config values
	    $block->{$1} = $2;
	} elsif (/^key[-_]ids\s*:\s*['"]?(.*?)['"]?$/) {
	    $block->{'key-ids'} = $1;
	} elsif (/^(hdlist|synthesis)$/) {
	    # ignored, kept for compatibility
	} elsif (/^($no_para_option_regexp)$/) {
	    my $opt = $1;
	    if ($opt =~ s/no-suggests/no-recommends/) { # COMPAT
	        warn "WARNING: --no-suggests is deprecated. Use --no-recommends instead\n" if s/no-suggests/no-recommends/; # COMPAT
	    }
	    #- positive flags
	    $block->{$opt} = 1;
	} elsif (my ($no, $k, $v) =
          /^(no-)?(
	    verify-rpm
	    |norebuild
	    |fuzzy
	    |allow-(?:force|nodeps)
	    |(?:pre|post)-clean
	    |excludedocs
	    |compress
	    |keep
	    |ignoresize
	    |auto
	    |strict-arch
	    |nopubkey
	    |resume)(?:\s*:\s*(.*))?$/x
	) {
	    #- boolean options
	    my $yes = $no ? 0 : 1;
	    $no = $yes ? 0 : 1;
	    $v = '' unless defined $v;
	    $block->{$k} = $v =~ /^(yes|on|1|)$/i ? $yes : $no;
	} elsif ($_ eq 'modified') {
	    #- obsolete
	} else {
	    warn "unknown line '$_'\n" if $_;
	}
    }
    \@blocks;
}

sub load_config {
    my ($file) = @_;

    my $blocks = load_config_raw($file);
    my ($media, $global) = partition { $_->{name} } @$blocks;
    ($global) = @$global;
    delete $global->{name};

    { global => $global || {}, media => $media };
}

sub dump_config {
    my ($file, $config) = @_;

    my %global = (name => '', %{$config->{global}});

    dump_config_raw($file, [ %global ? \%global : @{[]}, @{$config->{media}} ]);
}

sub dump_config_raw {
    my ($file, $blocks) = @_;

    my $old_blocks = load_config_raw($file, 1);
    my $substitute_back = sub {
	my ($m, $field) = @_;
	my ($prev_block) = grep { $_->{name} eq $m->{name} } @$old_blocks;
	substitute_back($m->{$field}, $prev_block && $prev_block->{$field});
    };

    my @lines;
    foreach my $m (@$blocks) {
	my @l = map {
	    if (/^($no_para_option_regexp)$/) {
		$_;
	    } elsif ($_ ne 'priority') {
		"$_: " . $substitute_back->($m, $_);
	    }
	} sort grep { $_ && $_ ne 'url' && $_ ne 'name' } keys %$m;

        my $name_url = $m->{name} ? 
	  join(' ', map { quotespace($_) } $m->{name}, $substitute_back->($m, 'url')) . ' ' : '';

	push @lines, join("\n", $name_url . '{', (map { "  $_" } @l), "}\n");
    }

    output_safe($file, join("\n", @lines)) or do {
	$err = N("unable to write config file [%s]", $file);
	return 0;
    };

    1;
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
