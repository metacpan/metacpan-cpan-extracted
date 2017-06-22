package urpm::parallel_ssh;


#- Copyright (C) 2002, 2003, 2004, 2005 MandrakeSoft SA
#- Copyright (C) 2005-2010 Mandriva SA
#- Copyright (C) 2011-2017 Mageia

use strict;
use urpm::util 'dirname';
use urpm::msg;
use urpm::parallel;

our @ISA = 'urpm::parallel';

sub _localhost { $_[0] eq 'localhost' }
sub _ssh       { &_localhost ? '' : "ssh $_[0] " }
sub _host      { &_localhost ? '' : "$_[0]:" }

sub _scp {
    my ($urpm, $host, @para) = @_;
    my $dest = pop @para;

    $urpm->{log}("parallel_ssh: scp " . join(' ', @para) . " $host:$dest");
    system('scp', @para, _host($host) . $dest) == 0
      or $urpm->{fatal}(1, N("scp failed on host %s (%d)", $host, $? >> 8));
}

sub copy_to_dir {
    my ($parallel, $urpm, @para) = @_;
    my $dir = pop @para;

    foreach my $host (keys %{$parallel->{nodes}}) {
	if (_localhost($host)) {
	    if (my @f = grep { dirname($_) ne $dir } @para) {
		$urpm->{log}("parallel_ssh: cp @f $urpm->{cachedir}/rpms");
		system('cp', @f, $dir) == 0
		  or $urpm->{fatal}(1, N("cp failed on host %s (%d)", $host, $? >> 8));
	    }
	} else {
	    _scp($urpm, $host, @para, $dir);
	}
    }
}

sub propagate_file {
    my ($parallel, $urpm, $file) = @_;
    foreach (grep { !_localhost($_) } keys %{$parallel->{nodes}}) {
	_scp($urpm, $_, '-q', $file, $file);
    }
}

sub _ssh_urpm {
    my ($urpm, $node, $cmd, $para) = @_;

    $cmd ne 'urpme' && _localhost($node) and $para = "--nolock $para";

    # it doesn't matter for urpmq, and previous version of urpmq didn't handle it:
    $cmd ne 'urpmq' and $para = "--no-locales $para";

    $urpm->{log}("parallel_ssh: $node: $cmd $para");
    _ssh($node) . " $cmd $para";
}
sub _ssh_urpm_popen {
    my ($urpm, $node, $cmd, $para) = @_;

    my $command = _ssh_urpm($urpm, $node, $cmd, $para);
    open(my $fh, "$command |") or $urpm->{fatal}(1, "Can't fork ssh: $!");
    $fh;
}

sub urpm_popen {
    my ($parallel, $urpm, $cmd, $para, $do) = @_;

    my @errors;

    foreach my $node (keys %{$parallel->{nodes}}) {
	my $fh = _ssh_urpm_popen($urpm, $node, $cmd, $para);

	while (my $s = <$fh>) {
	    chomp $s;
	    $urpm->{debug}("parallel_ssh: $node: received: $s") if $urpm->{debug};
	    $do->($node, $s) and last;
	}
	close $fh or push @errors, N("%s failed on host %s (maybe it does not have a good version of urpmi?) (exit code: %d)", $cmd, $node, $? >> 8);
	$urpm->{debug}("parallel_ssh: $node: $cmd finished") if $urpm->{debug};
    }

    @errors;
}

sub run_urpm_command {
    my ($parallel, $urpm, $cmd, $para) = @_;

    foreach my $node (keys %{$parallel->{nodes}}) {
	system(_ssh_urpm($urpm, $node, $cmd, $para));
    }
}

#- allow to bootstrap from urpmi code directly (namespace is urpm).

package urpm;

no warnings 'redefine';

sub handle_parallel_options {
    my (undef, $options) = @_;
    my ($id, @nodes) = split /:/, $options;

    if ($id =~ /^ssh(?:\(([^\)]*)\))?$/) {
	my %nodes; @nodes{@nodes} = undef;
	return bless {
	    media   => $1,
	    nodes   => \%nodes,
	}, "urpm::parallel_ssh";
    }
    return undef;
}

1;
