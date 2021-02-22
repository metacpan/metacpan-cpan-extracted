package Trav::Dir;
use warnings;
use strict;
use Carp;
use utf8;
our $VERSION = '0.02';

sub op
{
    my ($o, $options, $name) = @_;
    if ($options->{$name}) {
	$o->{$name} = $options->{$name};
	delete $options->{$name};
    }
}

sub new
{
    my ($class, %op) = @_;
    my $o = {};
    $o->{minsize} = 0;
    $o->{maxsize} = 'inf';
    for my $name (qw!
	verbose

	callback
	data
	maxsize
	minsize
	no_dir
	no_trav
	only
	preprocess
	rejfile
    !) {
	op ($o, \%op, $name);
    }
    # $o->{size} is a flag which tells find_files whether to check the
    # size.
    if ($o->{minsize} || $o->{maxsize}) {
	$o->{size} = 1;
    }
    for my $k (keys %op) {
	carp "Unknown option $k";
	delete $op{$k};
    }
    bless $o, $class;
}

sub find_files
{
    my ($o, $dir, $f) = @_;
    if (! $f && ! $o->{callback}) {
	# There is no work for us to do
	carp "No file list and no callback";
	return;
    }
    my $dh;
    if (! opendir ($dh, $dir)) {
	warn "opendir $dir failed: $!";
	return;
    }
    my @files = readdir ($dh);
    closedir ($dh);
    if ($o->{preprocess}) {
	&{$o->{preprocess}} ($o->{data}, $dir, \@files);
    }
    for my $file (@files) {
	if ($file eq '.' || $file eq '..') {
	    next;
	}
	if ($o->{rejfile} && $file =~ $o->{rejfile}) {
	    if ($o->{verbose}) {
		print "Skipping $file\n";
	    }
	    next;
	}
	my $dfile = "$dir/$file";
	if ($o->{verbose}) {
	    print "$dir $file\n";
	}
	my $is_dir = 0;
	if (-d $dfile) {
	    if (! $o->{no_trav} || $dfile !~ $o->{no_trav}) {
		if (-l $dfile) {
		    # Skip symbolic links
		    if ($o->{verbose}) {
			print "Skipping symbolic link '$dfile'.\n";
		    }
		    next;
		}
		find_files ($o, $dfile, $f);
	    }
	    if ($o->{no_dir}) {
		next;
	    }
	    $is_dir = 1;
	}
	if (-l $dfile) {
	    # Skip symbolic links
	    if ($o->{verbose}) {
		print "Skipping symbolic link '$dfile'.\n";
	    }
	    next;
	}
	if (! $is_dir && $o->{size}) {
	    my $size = -s $dfile;
	    if ($size > $o->{maxsize} || $size < $o->{minsize}) {
		if ($o->{verbose}) {
		    print "Skipping $file due to size $size > $o->{maxsize} or < $o->{minsize}\n";
		}
		next;
	    }
	}
	if (! $o->{only} || $file =~ $o->{only}) {
	    $o->save ($dfile, $f);
	}
    }
}

sub save
{
    my ($o, $dfile, $f) = @_;
    if ($f) {
	push @$f, $dfile;
    }
    if ($o->{callback}) {
	&{$o->{callback}} ($o->{data}, $dfile);
    }
}

1;
