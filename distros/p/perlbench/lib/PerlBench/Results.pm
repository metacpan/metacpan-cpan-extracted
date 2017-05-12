package PerlBench::Results;

use strict;
use File::Find ();

sub new {
    my $class = shift;
    my $resdir = shift || "perlbench-results";
    return undef unless -d $resdir;
    my $self = bless {}, $class;
    $self->_scan($resdir);
    return $self;
}

sub _scan {
    my($self, $dir) = @_;
    $self->{dir} = $dir;

    # locate result files
    my @res;
    File::Find::find(sub {
       if (/\.pb$/) {
	   my $f = $File::Find::name;
	   $f = substr($f, length($dir) + 1);
	   $f =~ s,\\,/,g if $^O eq "MSWin32";
           push(@res, $f);
       }
    }, $dir);

    # read results
    for my $f (@res) {
	#print "$f\n";
	my($hostname, $perls, $perl, $tests) = split("/", $f);
	die unless $perls eq "perls";
	die unless $tests eq "tests";
	my $res = _read_pb_file("$dir/$f");
	push(@{$self->{h}{$hostname}{p}{$perl}{t}}, $res);
    }

    # fill in additional information about hosts and perls
    while(my($hostname, $hosthash) = each %{$self->{h} || {}}) {
	#print "host $hostname\n";
	while (my($perl, $perlhash) = each %{$hosthash->{p}}) {
	    #print " perl $perl\n";
	    my $perldir = "$dir/$hostname/perls/$perl";
	    my $version_txt = "$perldir/version.txt";
	    open(my $fh, "<", $version_txt) || die "Can't open $version_txt: $!";
	    local($_);
	    while (<$fh>) {
		if (/^This is perl, v(\S+)/) {
		    $perlhash->{version} = $1;
		    $perlhash->{name} = "perl-$1";
		}
		if (/^Binary build (\d+.*) provided by ActiveState/) {
		    $perlhash->{name} .= " build $1";
		    $perlhash->{name} =~ s/^perl/ActivePerl/;
		}
	    }
	    die "Can't determine perl version from $version_txt" unless $perlhash->{version};
	    close($fh);

	    if (open(my $fh, "<", "$perldir/config-summary.txt")) {
		while (<$fh>) {
		    if (/^Summary of/ && / patch\s+(\d+)/) {
			$perlhash->{version} .= "-p$1";
			$perlhash->{name} .= " patch $1";
		    }
		    elsif (/\bDEBUGGING\b/) {
			$perlhash->{name} .= " (DEBUGGING)";
		    }
		}
		close($fh);
	    }

	    $perlhash->{dir} = $perldir;
	    $perlhash->{host} = $hostname;
	}
    }
}

sub _read_pb_file {
    my $file = shift;
    open(my $fh, "<", $file) || die "Can't open '$file': $!";
    my %hash;
    local($_);
    while (<$fh>) {
	if (/^(\w[\w-]*)\s*:\s*(.*)/) {
	    my($k, $v) = ($1, $2);
	    $k = lc($k);
	    $k =~ s/-/_/g;
	    $hash{$k} = $v;
	}
	else {
	    warn "$file: $_";
	}
    }
    close($fh);
    #$hash{file} = $file;
    return \%hash;
}

sub hosts {
    my $self = shift;
    die unless wantarray;
    return sort keys %{$self->{h} || {}};
}

sub perls {
    my($self, @hosts) = @_;
    die unless wantarray;
    @hosts = $self->hosts unless @hosts;
    my @p;
    for my $h (@hosts) {
	push(@p, values %{$self->{h}{$h}{p}});
    }
    @p = sort { _vers_cmp($a->{version}, $b->{version}) } @p;
    return @p;
}

sub _vers_cmp {
    my($v1, $v2) = @_;
    return $v1 cmp $v2;
}

1;
