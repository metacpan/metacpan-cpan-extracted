package urpm::parallel_ka_run;


#- Copyright (C) 2002, 2003, 2004, 2005 MandrakeSoft SA
#- Copyright (C) 2005-2010 Mandriva SA
#- Copyright (C) 2011-2020 Mageia

use strict;
use urpm::util 'find';
use urpm::msg;
use urpm::parallel;

our @ISA = 'urpm::parallel';

our $mput_command = $ENV{URPMI_MPUT_COMMAND};
our $rshp_command = $ENV{URPMI_RSHP_COMMAND};

if (!$mput_command) {
    ($mput_command) = find { -x $_ } qw(/usr/bin/mput2 /usr/bin/mput);
}
$mput_command ||= 'mput';
if (!$rshp_command) {
    ($rshp_command) = find { -x $_ } qw(/usr/bin/rshp2 /usr/bin/rshp);
}
$rshp_command ||= 'rshp';

sub _rshp_urpm {
    my ($parallel, $urpm, $rshp_option, $cmd, $para) = @_;

    # it doesn't matter for urpmq, and previous version of urpmq didn't handle it:
    $cmd ne 'urpmq' and $para = "--no-locales $para";

    my $command = "$rshp_command $rshp_option $parallel->{options} -- $cmd $para";
    $urpm->{log}("parallel_ka_run: $command");
    $command;
}
sub _rshp_urpm_popen {
    my ($parallel, $urpm, $cmd, $para) = @_;

    my $command = _rshp_urpm($parallel, $urpm, '-v', $cmd, $para);
    open(my $fh, "$command |") or $urpm->{fatal}(1, "Can't fork $rshp_command: $!");
    $fh;
}

sub urpm_popen {
    my ($parallel, $urpm, $cmd, $para, $do) = @_;

    my $fh = _rshp_urpm_popen($parallel, $urpm, $cmd, $para);

    while (my $s = <$fh>) {
	chomp $s;
	my ($node, $s_) = _parse_rshp_output($s) or next;

	$urpm->{debug}("parallel_ka_run: $node: received: $s_") if $urpm->{debug};
	$do->($node, $s_) and last;
    }
    close $fh or $urpm->{fatal}(1, N("rshp failed, maybe a node is unreacheable"));
    ();
}

sub run_urpm_command {
    my ($parallel, $urpm, $cmd, $para) = @_;
    system(_rshp_urpm($parallel, $urpm, '', $cmd, $para)) == 0;
}

sub copy_to_dir { &_run_mput }

sub propagate_file {
    my ($parallel, $urpm, $file) = @_;
    _run_mput($parallel, $urpm, $file, $file);
}

sub _run_mput {
    my ($parallel, $urpm, @para) = @_;

    my @l = (split(' ', $parallel->{options}), '--', @para);
    $urpm->{log}("parallel_ka_run: $mput_command " . join(' ', @l));
    system $mput_command, @l;
    $? == 0 || $? == 256 or $urpm->{fatal}(1, N("mput failed, maybe a node is unreacheable"));
}    

sub _parse_rshp_output {
    my ($s) = @_;
    #- eg of output of rshp2: <tata2.mageia.org> [rank:2]:@removing@mpich-1.2.5.2-10mlcs4.x86_64

    if ($s =~ /<([^>]*)>.*:->:(.*)/ || $s =~ /<([^>]*)>\s*\[[^]]*\]:(.*)/) {
	($1, $2);
    } else { 
	warn "bad rshp output $s\n";
	();
    }
}

#- allow to bootstrap from urpmi code directly (namespace is urpm).

package urpm;

no warnings 'redefine';

sub handle_parallel_options {
    my (undef, $options) = @_;
    my ($media, $ka_run_options) = $options =~ /ka-run(?:\(([^\)]*)\))?:(.*)/;
    if ($ka_run_options) {
	my ($flush_nodes, %nodes);
	foreach (split ' ', $ka_run_options) {
	    if ($_ eq '-m') {
		$flush_nodes = 1;
	    } else {
		$flush_nodes and $nodes{/host=([^,]*)/ ? $1 : $_} = undef;
		undef $flush_nodes;
	    }
	}
	return bless {
	    media   => $media,
	    options => $ka_run_options,
	    nodes   => \%nodes,
	}, "urpm::parallel_ka_run";
    }
    return undef;
}

1;
