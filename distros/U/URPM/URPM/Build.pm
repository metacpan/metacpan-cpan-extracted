package URPM;


use strict;
use warnings;

# perl_checker: require URPM

sub _get_tmp_dir () {
    my $t = $ENV{TMPDIR};
    $t && -w $t or $t = '/tmp';
    "$t/.build_hdlist";
}

# DEPRECATED. ONLY USED BY MKCD
#
#- prepare build of an hdlist from a list of files.
#- it can be used to start computing depslist.
#- parameters are :
#-   rpms     : array of all rpm file name to parse (mandatory)
#-   dir      : directory which will contain headers (defaults to /tmp/.build_hdlist)
#-   callback : perl code to be called for each package read (defaults pack_header)
#-   clean    : bool to clean cache before (default no).
#-   packing  : bool to create info (default is weird)
#
# deprecated
sub parse_rpms_build_headers {
    my ($urpm, %options) = @_;
    my ($dir, %cache, @headers);

    #- check for mandatory options.
    if (@{$options{rpms} || []} > 0) {
	#- build a working directory which will hold rpm headers.
	$dir = $options{dir} || _get_tmp_dir();
	$options{clean} and system($ENV{LD_LOADER} ? $ENV{LD_LOADER} : @{[]}, "rm", "-rf", $dir);
	-d $dir or mkdir $dir, 0755 or die "cannot create directory $dir\n";

	#- examine cache if it contains any headers which will be much faster to read
	#- than parsing rpm file directly.
	unless ($options{clean}) {
	    my $dirh;
	    opendir $dirh, $dir;
	    while (defined (my $file = readdir $dirh)) {
		my ($fullname, $filename) = $file =~ /(.+?-[^:\-]+-[^:\-]+\.[^:\-\.]+)(?::(\S+))?$/ or next;
		my @stat = stat "$dir/$file";
		$cache{$filename || $fullname} = {
		    file => $file,
		    size => $stat[7],
		    'time' => $stat[9],
		};
	    }
	    closedir $dirh;
	}

	foreach (@{$options{rpms}}) {
	    my ($key) = m!([^/]*)\.rpm$! or next; #- get rpm filename.
	    my ($id, $filename);

	    if ($cache{$key} && $cache{$key}{time} > 0 && $cache{$key}{time} >= (stat $_)[9]) {
		($id, undef) = $urpm->parse_hdlist("$dir/$cache{$key}{file}", packing => $options{packing}, keep_all_tags => $options{keep_all_tags});
		unless (defined $id) {
		  if ($options{dontdie}) {
		    print STDERR "bad header $dir/$cache{$key}{file}\n";
		    next;
		  } else {
		    die "bad header $dir/$cache{$key}{file}\n";
		  }
		}

		$options{callback} and $options{callback}->($urpm, $id, %options, (file => $_));

		$filename = $cache{$key}{file};
	    } else {
		($id, undef) = $urpm->parse_rpm($_, keep_all_tags => $options{keep_all_tags});
		unless (defined $id) {
		    if ($options{dontdie}) {
			print STDERR "bad rpm $_\n";
			next;
		    } else {
			die "bad rpm $_\n";
		    }
		}
		
		my $pkg = $urpm->{depslist}[$id];

		$filename = $pkg->fullname;

		unless (-s "$dir/$filename") {
		    open my $fh, ">$dir/$filename" or die "unable to open $dir/$filename for writing\n";
		    $pkg->build_header(fileno $fh);
		    close $fh;
		}
		-s "$dir/$filename" or unlink("$dir/$filename"), die "can create header $dir/$filename\n";

		#- make smart use of memory (no need to keep header in memory now).
		if ($options{callback}) {
		    $options{callback}->($urpm, $id, %options, (file => $_));
		} else {
			$pkg->pack_header;
		}

		# Olivier Thauvin <thauvin@aerov.jussieu.fr>
		# isn't this code better, but maybe it will break some tools:
		# $options{callback}->($urpm, $id, %options, (file => $_)) if ($options{callback});
		# $pkg->pack_header;
	    }

	    #- keep track of header associated (to avoid rereading rpm filename directly
	    #- if rereading has been made neccessary).
	    push @headers, $filename;
	}
    }
    @headers;
}

# DEPRECATED. ONLY USED BY MKCD
#
#- allow rereading of hdlist and clean.
sub unresolved_provides_clean {
    my ($urpm) = @_;
    $urpm->{depslist} = [];
    $urpm->{provides}{$_} = undef foreach keys %{$urpm->{provides} || {}};
}

# DEPRECATED. ONLY USED BY MKCD
#
#- read a list of headers (typically when building an hdlist when provides have
#- been cleaned).
#- parameters are :
#-   headers  : array containing all headers filenames to parse (mandatory)
#-   dir      : directory which contains headers (defaults to /tmp/.build_hdlist)
#-   callback : perl code to be called for each package read (defaults to pack_header)
sub parse_headers {
    my ($urpm, %options) = @_;
    my ($dir, $start, $id);

    $dir = $options{dir} || _get_tmp_dir();
    -d $dir or die "no directory $dir\n";

    $start = @{$urpm->{depslist} || []};
    foreach (@{$options{headers} || []}) {
	#- make smart use of memory (no need to keep header in memory now).
	($id, undef) = $urpm->parse_hdlist("$dir/$_", packing => !$options{callback});
	defined $id or die "bad header $dir/$_\n";
	$options{callback} and $options{callback}->($urpm, $id, %options);
    }
    defined $id ? ($start, $id) : @{[]};
}

# DEPRECATED. ONLY USED BY MKCD
#- compute dependencies, result in stored in info values of urpm.
#- operations are incremental, it is possible to read just one hdlist, compute
#- dependencies and read another hdlist, and again.
#- parameters are :
#-   callback : callback to relocate reference to package id.
sub compute_deps {
    my ($urpm, %options) = @_;
    my %propagated_weight = (
	basesystem => 10000,
	msec       => 20000,
	filesystem => 50000,
    );
    my ($locales_weight, $step_weight, $fixed_weight) = (-5000, 10000, $propagated_weight{basesystem});

    #- avoid recomputing already present infos, take care not to modify
    #- existing entries, as the array here is used instead of values of infos.
    my $start = @{$urpm->{deps} ||= []};
    my $end = $#{$urpm->{depslist} || []};

    #- check if something has to be done.
    $start > $end and return;

    #- keep track of prereqs.
    my %prereqs;

    #- take into account in which hdlist a package has been found.
    #- this can be done by an incremental take into account generation
    #- of depslist.ordered part corresponding to the hdlist.
    #- compute closed requires, do not take into account choices.
    foreach ($start .. $end) {
	my $pkg = $urpm->{depslist}[$_];

	my %required_packages;
	my @required_packages;
	my %requires;

	foreach ($pkg->requires) {
	    my ($n, $prereq) = /^([^\s\[]*)(\[\*\])?/;
	    $requires{$n} = $prereq && 1;
	}
	my @requires = keys %requires;

	while (my $req = shift @requires) {
	    $req =~ /^basesystem/ and next; #- never need to requires basesystem directly as always required! what a speed up!
	    my $treq = (
		$req =~ /^\d+$/ ? [ $req ]
		: $urpm->{provides}{$req} ? [ keys %{$urpm->{provides}{$req}} ]
		: [ ($req !~ /NOTFOUND_/ ? "NOTFOUND_" : "") . $req ]
	    );
	    if (@$treq > 1) {
		#- this is a choice, no closure need to be done here.
		push @required_packages, $treq;
	    } else {
		#- this could be nothing if the provides is a file not found.
		#- and this has been fixed above.
		foreach (@$treq) {
		    my $pkg_ = /^\d+$/ && $urpm->{depslist}[$_];
		    exists $required_packages{$_} and $pkg_ = undef;
		    $required_packages{$_} ||= $requires{$req}; $pkg_ or next;
		    foreach ($pkg_->requires_nosense) {
			exists $requires{$_} or push @requires, $_;
			$requires{$_} ||= $requires{$req};
		    }
		}
	    }
	}
	#- examine choice to remove those which are not mandatory.
	foreach (@required_packages) {
	    unless (grep { exists $required_packages{$_} } @$_) {
		$required_packages{join '|', sort { $a <=> $b } @$_} = undef;
	    }
	}

	#- store a short representation of requires.
	$urpm->{requires}[$_] = join ' ', keys %required_packages;
	foreach my $d (keys %required_packages) {
	    $required_packages{$d} or next;
	    $prereqs{$d}{$_} = undef;
	}
    }

    #- expand choices and closure again.
    my %ordered;
    foreach ($start .. $end) {
	my @requires = $_;
	my ($dep, %requires);
	while (defined ($dep = shift @requires)) {
	    exists $requires{$dep} || /^[^\d\|]*$/ and next;
	    foreach ($dep, split ' ', (defined $urpm->{deps}[$dep] ? $urpm->{deps}[$dep] : $urpm->{requires}[$dep])) {
		if (/\|/) {
		    push @requires, split /\|/, $_;
		} else {
		    /^\d+$/ and $requires{$_} = undef;
		}
	    }
	}

	my $pkg = $urpm->{depslist}[$_];
	my $delta = 1 + $propagated_weight{$pkg->name};
	foreach (keys %requires) {
	    $ordered{$_} += $delta;
	}
    }

    #- some package should be sorted at the beginning.
    foreach (qw(basesystem msec rpm locales filesystem setup glibc sash bash libtermcap2 termcap readline ldconfig)) {
	foreach (keys %{$urpm->{provides}{$_} || {}}) {
	    /^\d+$/ and $ordered{$_} = $fixed_weight;
	}
	/locales/ and $locales_weight += $fixed_weight;
	$fixed_weight += $step_weight;
    }
    foreach ($start .. $end) {
	my $pkg = $urpm->{depslist}[$_];

	$pkg->name =~ /locales-[a-zA-Z]/ and $ordered{$_} = $locales_weight;
    }

    #- compute base flag, consists of packages which are required without
    #- choices of basesystem and are ALWAYS installed. these packages can
    #- safely be removed from requires of others packages.
    foreach (qw(basesystem glibc kernel)) {
	foreach (keys %{$urpm->{provides}{$_} || {}}) {
	    foreach ($_, split ' ', (defined $urpm->{deps}[$_] ? $urpm->{deps}[$_] : $urpm->{requires}[$_])) {
		/^\d+$/ and $urpm->{depslist}[$_] and $urpm->{depslist}[$_]->set_flag_base(1);
	    }
	}
    }

    #- give an id to each packages, start from number of package already
    #- registered in depslist.
    my %remap_ids; @remap_ids{sort {
	exists $prereqs{$b}{$a} && ! exists $prereqs{$a}{$b} ? 1 :
	  $ordered{$b} <=> $ordered{$a} or do {
	      my ($na, $nb) = map { $urpm->{depslist}[$_]->name } ($a, $b);
	      my ($sa, $sb) = map { /^lib(.*)/ ? $1 : '' } ($na, $nb);
	      $sa && $sb ? $sa cmp $sb : $sa ? -1 : $sb ? 1 : $na cmp $nb;
	  } } ($start .. $end)} = ($start .. $end);

    #- now it is possible to clean ordered and prereqs.
    %ordered = %prereqs = ();

    #- recompute requires to use packages id, drop any base packages or
    #- reference of a package to itself.
    my @depslist;
    foreach ($start .. $end) {
	my $pkg = $urpm->{depslist}[$_];

	#- set new id.
	$pkg->set_id($remap_ids{$_});

	my ($id, $base, %requires_id, %not_founds);
	foreach (split ' ', $urpm->{requires}[$_]) {
	    if (/\|/) {
		#- all choices are grouped together at the end of requires,
		#- this allow computation of dropable choices.
		my ($to_drop, @choices_base_id, @choices_id);
		foreach (split /\|/, $_) {
		    my ($id, $base) = (exists($remap_ids{$_}) ? $remap_ids{$_} : $_, $urpm->{depslist}[$_]->flag_base);
		    $base and push @choices_base_id, $id;
		    $base &&= ! $pkg->flag_base;
		    $to_drop ||= $id == $pkg->id || exists $requires_id{$id} || $base;
		    push @choices_id, $id;
		}

		#- package can safely be dropped as it will be selected in requires directly.
		$to_drop and next;

		#- if a base package is in a list, keep it instead of the choice.
		if (@choices_base_id) {
		    @choices_id = @choices_base_id;
		    $base = 1;
		}
		if (@choices_id == 1) {
		    $id = $choices_id[0];
		} else {
		    my $choices_key = join '|', sort { $a <=> $b } @choices_id;
		    $requires_id{$choices_key} = undef;
		    next;
		}
	    } elsif (/^\d+$/) {
		($id, $base) =  (exists($remap_ids{$_}) ? $remap_ids{$_} : $_, $urpm->{depslist}[$_]->flag_base);
	    } else {
		$not_founds{$_} = undef;
		next;
	    }

	    #- select individual package from choices or defined package.
	    $base &&= ! $pkg->flag_base;
	    $base || $id == $pkg->id or $requires_id{$id} = undef;
	}
	#- be smart with memory usage.
	delete $urpm->{requires}[$_];
	$urpm->{deps}[$remap_ids{$_}] = join ' ', ((sort { ($a =~ /^(\d+)/)[0] <=> ($b =~ /^(\d+)/)[0] } keys %requires_id),
						   keys %not_founds);
	$depslist[$remap_ids{$_}-$start] = $pkg;
    }

    #- remap all provides ids for new package position and update depslist.
    delete $urpm->{requires};
    @{$urpm->{depslist}}[$start .. $end] = @depslist;
    foreach my $h (values %{$urpm->{provides}}) {
	my %provided;
	foreach (keys %{$h || {}}) {
	    $provided{exists($remap_ids{$_}) ? $remap_ids{$_} : $_} = delete $h->{$_};
	}
	$h = \%provided;
    }
    $options{callback} and $options{callback}->($urpm, \%remap_ids, %options);

    ($start, $end);
}

# DEPRECATED. ONLY USED BY MKCD
#
#- build an hdlist from existing depslist, from start to end inclusive.
#- parameters are :
#-   hdlist   : hdlist file to use.
#-   dir      : directory which contains headers (defaults to /tmp/.build_hdlist)
#-   start    : index of first package (defaults to first index of depslist).
#-   end      : index of last package (defaults to last index of depslist).
#-   idlist   : id list of rpm to compute (defaults is start .. end)
#-   ratio    : compression ratio (default 4).
#-   split    : split ratio (default 400kb, see MDV::Packdrakeng).
sub build_hdlist {
    my ($urpm, %options) = @_;
    my ($dir, $ratio, @idlist);

    $dir = $options{dir} || _get_tmp_dir();
     -d $dir or die "no directory $dir\n";

    @idlist = $urpm->build_listid($options{start}, $options{end}, $options{idlist});

    #- compression ratio are not very high, sample for cooker
    #- gives the following (main only and cache fed up):
    #- ratio compression_time  size
    #-   9       21.5 sec     8.10Mb   -> good for installation CD
    #-   6       10.7 sec     8.15Mb
    #-   5        9.5 sec     8.20Mb
    #-   4        8.6 sec     8.30Mb   -> good for urpmi
    #-   3        7.6 sec     8.60Mb
    $ratio = $options{ratio} || 4;

    require MDV::Packdrakeng;
    my $pack = MDV::Packdrakeng->new(
	archive => $options{hdlist},
	compress => "gzip",
	uncompress => "gzip -d",
	block_size => $options{split},
	comp_level => $ratio,
    ) or die "Can't create archive";
    foreach my $pkg (@{$urpm->{depslist}}[@idlist]) {
	my $filename = $pkg->fullname;
	-s "$dir/$filename" or die "bad header $dir/$filename\n";
	$pack->add($dir, $filename);
    }
}

#- build synthesis file.
#- used by genhdlist2 and mkcd
#-
#- parameters are :
#-   synthesis : synthesis file to create (mandatory if fd not given).
#-   fd        : file descriptor (mandatory if synthesis not given).
#-   start     : index of first package (defaults to first index of depslist).
#-   end       : index of last package (defaults to last index of depslist).
#-   idlist    : id list of rpm to compute (defaults is start .. end)
#-   recommends: output recommends instead of suggest
#-   ratio     : compression ratio (default 9).
#-   filter    : program to filter through (default is 'gzip -$ratio').
#- returns true on success
sub build_synthesis {
    my ($urpm, %options) = @_;
    my ($ratio, $filter, @idlist);

    @idlist = $urpm->build_listid($options{start}, $options{end}, $options{idlist});

    $ratio = $options{ratio} || 9;
    $filter = $options{filter} || "gzip -$ratio";
    $options{synthesis} || defined $options{fd} or die "invalid parameters given";

    #- first pass: traverse provides to find files provided.
    my %provided_files;
    foreach (keys %{$urpm->{provides}}) {
	m!^/! or next;
	foreach my $id (keys %{$urpm->{provides}{$_} || {}}) {
	    push @{$provided_files{$id} ||= []}, $_;
	}
    }


    #- second pass: write each info including files provided.
    $options{synthesis} and open my $fh, "| " . ($ENV{LD_LOADER} || '') . " $filter >'$options{synthesis}'";
    foreach (@idlist) {
	my $pkg = $urpm->{depslist}[$_];
	my %files;

	if ($provided_files{$_}) {
	    @files{@{$provided_files{$_}}} = undef;
	    delete @files{$pkg->provides_nosense};
	}

	$pkg->build_info($options{synthesis} ? fileno $fh : $options{fd}, join('@', keys %files), $options{recommends});
    }
    close $fh; # returns true on success
}

# DEPRECATED. ONLY USED BY MKCD
#- write depslist.ordered file according to info in params.
#- parameters are :
#-   depslist : depslist.ordered file to create.
#-   provides : provides file to create.
#-   compss   : compss file to create.
sub build_base_files {
    my ($urpm, %options) = @_;

    if ($options{depslist}) {
	open my $fh, ">", $options{depslist} or die "Can't write to $options{depslist}: $!\n";
	foreach (0 .. $#{$urpm->{depslist}}) {
	    my $pkg = $urpm->{depslist}[$_];

	    printf $fh ("%s-%s-%s.%s%s %s %s\n", $pkg->fullname,
		      ($pkg->epoch ? ':' . $pkg->epoch : ''), $pkg->size || 0, $urpm->{deps}[$_]);
	}
	close $fh;
    }

    if ($options{provides}) {
	open my $fh, ">", $options{provides} or die "Can't write to $options{provides}: $!\n";
	while (my ($k, $v) = each %{$urpm->{provides}}) {
	    printf $fh "%s\n", join '@', $k, map { scalar $urpm->{depslist}[$_]->fullname } keys %{$v || {}};
	}
	close $fh;
    }

    if ($options{compss}) {
	my %p;

	open my $fh, ">", $options{compss} or die "Can't write to $options{compss}: $!\n";
	foreach (@{$urpm->{depslist}}) {
	    $_->group or next;
	    push @{$p{$_->group} ||= []}, $_->name;
	}
	foreach (sort keys %p) {
	    print $fh $_, "\n";
	    foreach (@{$p{$_}}) {
		print $fh "\t", $_, "\n";
	    }
	    print $fh "\n";
	}
	close $fh;
    }

    1;
}

our $MAKEDELTARPM = '/usr/bin/makedeltarpm';

#- make_delta_rpm($old_rpm_file, $new_rpm_file)
# Creates a delta rpm in the current directory.

# DEPRECATED. UNUSED
sub make_delta_rpm ($$) {
    @_ == 2 or return 0;
    -e $_[0] && -e $_[1] && -x $MAKEDELTARPM or return 0;
    my @id;
    my $urpm = new URPM;
    foreach my $i (0, 1) {
	($id[$i]) = $urpm->parse_rpm($_[$i]);
	defined $id[$i] or return 0;
    }
    my $oldpkg = $urpm->{depslist}[$id[0]];
    my $newpkg = $urpm->{depslist}[$id[1]];
    $oldpkg->arch eq $newpkg->arch or return 0;
    #- construct filename of the deltarpm
    my $patchrpm = $oldpkg->name . '-' . $oldpkg->version . '-' . $oldpkg->release . '_' . $newpkg->version . '-' . $newpkg->release . '.' . $oldpkg->arch . '.delta.rpm';
    !system($MAKEDELTARPM, @_, $patchrpm);
}

1;
