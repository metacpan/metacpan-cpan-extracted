#
# status reporter
#
package Xymon::Plugin::Server::Status;

use strict;

use Carp;

use Xymon::Plugin::Server;

=head1 NAME

Xymon::Plugin::Server::Status - Xymon status reporter

=head1 SYNOPSIS

    use Xymon::Plugin::Server::Status qw(:colors);
    my $status = Xymon::Plugin::Server::Status->new("myhostname", "test");

    $status->add_status(GREEN, "this entry is OK");
    $status->add_status(RED, "this entry is NOT OK");
    $status->add_message("Hello! world");

    $status->add_devmon($devmon); # see Xymon::Plugin::Server::Devmon

    $status->add_graph("disk");

    $status->report;  # send status to Xymon server

=head1 EXPORT

Color names

  GREEN YELLOW RED CLEAR PURPLE BLUE

are exported with tag ':colors'

=cut

use base qw(Exporter);

my @colors = qw(GREEN YELLOW RED CLEAR PURPLE BLUE);

our @EXPORT_OK = @colors;
our %EXPORT_TAGS = (colors => \@colors);

use constant {
    GREEN => 'green',
    YELLOW => 'yellow',
    RED => 'red',
    CLEAR => 'clear',
    PURPLE => 'purple',
    BLUE => 'blue',
};

=head1 SUBROUTINES/METHODS

=head2 new(hostname, testname, attr)

Create status object for hostname and testname.

attr is optional hashref to change actions of object.
Currently, following parameter is defined.

=over

=item EscapeMessage

=over

=item 0 - nochange (default) 

Make no change to message.

=item 1 - replace to '_' 

Some characters (<, >, &) are replaced to '_'.

=item 2 - html escape

'<', '>, '&' are replaced to '&lt;', '&gt;', '&amp' respectively.

=back

=back

=cut

sub new {
    my $class = shift;
    my $host = shift;
    my $test = shift;
    my $attr = shift;

    my $self = {
	_host => $host,
	_test => $test,
	_color => 'clear',
	_message => '',
	_devmon => undef,
	_graph => [],
	_attr => $attr || {}
    };

    bless $self, $class;
}

#
# CLEAR, BLUE, GREEN, PURPLE, YELLOW, RED
#
my %order = (CLEAR	, 0,
	     BLUE	, 1,
	     GREEN	, 2,
	     PURPLE	, 3,
	     YELLOW	, 4,
	     RED	, 5,
	     );

sub _set_color {
    my $self = shift;
    my $color = shift;

    my $cur = $order{$self->{_color}};
    my $new = $order{$color};

    carp "Unknown color: $color" unless (defined($new));

    # if purple is selected, this report will be eliminated by Xymon.
    # so we change color.
    if ($color eq PURPLE) {
	$color = YELLOW;
	$new = $order{$color};
    }
    
    if ($cur < $new) {
	$self->{_color} = $color;
    }

    return $self->{_color};
}

=head2 add_status(color, msg)

Add status and its short message.

=cut

sub add_status {
    my $self = shift;
    my ($color, $msg) = @_;

    if (defined($msg)) {
	$msg .= "\n" if ($msg !~ /\n$/);
	my $m = $self->_escape_string($msg);

	$self->{_message} .= "&$color $m";
    }

    $self->_set_color($color);
}

=head2 add_message(msg)

Add message shown in Xymon status page.

=cut

sub add_message {
    my $self = shift;
    my ($msg) = @_;

    $msg .= "\n" if ($msg !~ /\n$/);

    $self->{_message} .= $self->_escape_string($msg);
}

=head2 add_devmon(devmon)

Add devmon data. See Xymon::Plugin::Server::Devmon

=cut

sub add_devmon {
    my $self = shift;
    my $devmon= shift;

    $self->{_devmon} = $devmon;
}

=head2 add_graph(testname)

Add graph shown in Xymon status page.
"test" name must be defined in graph definition file.
(named hobbitgraph.cfg in Xymon 4.2, graphs.cfg in Xymon 4.3)

=cut

sub add_graph {
    my $self = shift;
    my $test= shift;

    push (@{$self->{_graph}}, $test);
}

sub _create_graph_html {
    my $self = shift;
    my $test = shift;

    my $type = "4.3";

    my ($major, $minor) = @{Xymon::Plugin::Server->version};
    $type = "4.2" if ($major == 4 && $minor == 2);

    my $host = $self->{_host};
    my $color = $self->{_color};
    my $width = $ENV{RRDWIDTH} || 576;
    my $height = $ENV{RRDHEIGHT} || 120;
    my $end_time = time;
    my $start_time = time - (60 * 60 * 48);

    if ($type eq "4.2") {
	my $cgi_url = $ENV{BBSERVERCGIURL} || "/xymon-cgi";

	my $html = << "_EOS";
<p>
<A HREF="$cgi_url/hobbitgraph.sh?host=$host&amp;service=$test&amp;graph_width=$width&amp;graph_height=$height&amp;disp=$host&amp;nostale&amp;color=$color&amp;action=menu">

<IMG BORDER=0 SRC="$cgi_url/hobbitgraph.sh?host=$host&amp;service=$test&amp;graph_width=$width&amp;graph_height=$height&amp;disp=$host&amp;nostale&amp;color=$color&amp;graph=hourly&amp;action=view">
</A>
</p>
_EOS
    }
    else {
	my $cgi_url = $ENV{XYMONSERVERCGIURL} || "/xymon-cgi";

	my $html = << "_EOS";
<p>
<A HREF="$cgi_url/showgraph.sh?host=$host&amp;service=$test&amp;graph_width=$width&amp;graph_height=$height&amp;disp=$host&amp;nostale&amp;color=$color&amp;graph_start=$start_time&amp;graph_end=$end_time&amp;action=menu">
<IMG BORDER=0 SRC="$cgi_url/showgraph.sh?host=$host&amp;service=$test&amp;graph_width=$width&amp;graph_height=$height&amp;disp=$host&amp;nostale&amp;color=$color&amp;graph_start=$start_time&amp;graph_end=$end_time&amp;graph=hourly&amp;action=view">
</A>
</p>
_EOS

    }
}

sub _escape_replace {
    my $s = shift;
    $s =~ s/[<>&]/_/g;
    return $s;
}

sub _escape_entity {
    my $s = shift;

    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    return $s;
}

sub _escape_string {
    my $self = shift;
    my $s = shift;

    if ($self->{_attr}->{EscapeMessage}) {
	my $n = $self->{_attr}->{EscapeMessage};
	if ($n == 1) {
	    return _escape_replace($s);
	}
	elsif ($n == 2) {
	    return _escape_entity($s);
	}

    }

    return $s;
}

sub _create_report_msg {
    my $self = shift;

    local $ENV{LANG} = 'C';
    my $datestr = scalar localtime time;
    my $statstr = '';

    if ($self->{_color} eq GREEN) {
	$statstr = ' - OK';
    }
    elsif ($self->{_color} eq YELLOW || $self->{_color} eq RED) {
	$statstr = ' - NOT OK';
    }

    my $msg = sprintf("status %s.%s %s %s %s%s\n",
		      $self->{_host},
		      $self->{_test},
		      $self->{_color},
		      $datestr,
		      $self->{_test},
		      $statstr);

    $msg .= "\n";
    $msg .= $self->{_message};

    if ($self->{_devmon}) {
	$msg .= "\n";
	$msg .= $self->{_devmon}->format;
    }

    if (@{$self->{_graph}} > 0) {
	$msg .= "</PRE></TD></TR></TABLE>\n";

	for my $g (@{$self->{_graph}}) {
	    $msg .= $self->_create_graph_html($g);
	}

	$msg .= "<TABLE><TR><TD><PRE>\n";
    }

    return $msg;
}

=head2 report

Report current status to Xymon server.

=cut

sub report {
    my $self = shift;

    my $msg = $self->_create_report_msg;

    print "$msg" if ($ENV{XYMON_PLUGIN_DEBUG});

    my $bb = Xymon::Plugin::Server->home . "/bin/bb";

    for my $bbh (Xymon::Plugin::Server->display_hosts) {
	print "send to $bbh\n" if ($ENV{XYMON_PLUGIN_DEBUG});
	open(my $fh, "|-", "$bb", $bbh, "@") or die "cannot execute $bb: $!";
	print $fh $msg;
    }
}

1;
