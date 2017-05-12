package Asterisk::Conf::Zapata;

require 5.004;

=head1 NAME

Asterisk::Config::Zapata - Zapata configuration stuff

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;
use Asterisk::Conf;
@ISA = ('Asterisk::Conf');

$VERSION = '0.01';

$DEBUG = 5;

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'name'} = 'Zapata';
	$self->{'description'} = 'Zaptel Channel Driver Configuration';
	$self->{'configfile'} = '/etc/asterisk/zapata.conf';
	$self->{'config'} = {};
	$self->{'configtemp'} = {};
	$self->{'contextorder'} = ( 'channels' );
	$self->{'channelgroup'} = {};

	$self->{'variables'} = { 
		'language' => { 'default' => 'en', 'type' => 'text', 'regex' => '^\w\w$' },
		'context' => { 'default' => 'default', 'type' => 'text', 'regex' => '^\w*$' },
		'switchtype' => { 'default' => 'national', 'type' => 'one',  'values' => [ 'national', 'dms100', '4ess', '5ess', 'euroisdn'] },
		'signalling' => { 'default' => 'fxo_ls', 'type' => 'one', 'values' => ['em', 'em_w', 'featd', 'featdmf', 'featb', 'fxs_ls', 'fxs_gs', 'fxs_ks', 'fxo_ls', 'fxo_gs', 'gxo', 'ks', 'pri_cpe', 'pri_net'] },
		'prewink' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'preflash' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'wink' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'flash' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'start' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'rxwink' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'rxflash' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'debounce' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'rxwink' => { 'default' => '300', 'type' => 'text', 'regex' => '^\d*$' },
		'usecallerid' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },	
		'hidecallerid' => { 'default' => 'no', 'type' => 'one', 'values' => ['yes', 'no'] },
		'callwaiting' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'callwaitingcallerid' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'threewaycalling' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'transfer' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'cancallforward' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'mailbox' => { 'default' => undef, 'type' => 'text',	'regex' => '^\d*$' },
		'echocancel' => { 'default' => 'yes', 'type' => 'one', 'values' => ['yes', 'no'] },
		'echocancelwhenbridged' => { 'default' => 'no', 'type' => 'one', 'values' => ['yes', 'no'] },
		'rxgain' => { 'default' => '0.0', 'type' => 'text', 'regex' => '^[\d\.]*$' },
		'txgain' => { 'default' => '0.0', 'type' => 'text', 'regex' => '^[\d\.]*$' },
		'group' => { 'default' => '1', 'type' => 'text', 'regex' => '^\d*$' },
		'immediate' => { 'default' => undef, 'type' => 'one', 'values' => ['yes', 'no'] },
		'callerid' => { 'default' => undef, 'type' => 'text',	'regex' => '^.*$' },
		'amaflags' => { 'default' => undef, 'type' => 'one', 'values' => ['default', 'omit', 'billing', 'documentation'] },
		'accountcode' => { 'default' => undef, 'type' => 'text', 'regex' => '^\w*$' },
		'adsi' => { 'default' => undef, 'type' => 'one', 'values' => ['yes', 'no'] },
		'musiconhold' => { 'default' => undef, 'type' => 'text', '^\w*$' },

		'idledial' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'idleext' => { 'default' => undef, 'type' => 'text', 'regex' => '^\w*$' },
		'minunused' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },
		'minidle' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' },

		'channel' => { 'default' => undef, 'type' => 'text',	'regex' => '^[\d\,\-]*$' },
		'stripmsd' => { 'default' => undef, 'type' => 'text', 'regex' => '^\d*$' }
	};


	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub _setvar {
	my ($self, $context, $var, $val, $order, $precomment, $postcomment) = @_;

	$self->{'configtemp'}{$context}{$var}{val} = $val;
	$self->{'configtemp'}{$context}{$var}{precomment} = $precomment;
	$self->{'configtemp'}{$context}{$var}{postcomment} = $postcomment;
	$self->{'configtemp'}{$context}{$var}{order} = $order;

}

sub _group {
	my ($self, $context, $channels) = @_;

	if ($channels) {
		push(@{$self->{channelgroup}{$context}}, $channels);
	} else {
		return @{$self->{channelgroup}{$context}};
	}
}

sub channels {
	my ($self, $context, $channels, $order, $precomment, $postcomment) = @_;

	my @chans = ();
	my $channel = '';
	my $x;

	$self->_group($context, $channels);
	if ($channels =~ /(\d+)\-(\d+)/) {
		my $beg = $1; my $end = $2;
		if ($end > $beg) {
			for ($x = $beg; $x <= $end; $x++) {
				push(@chans, $x);
			}
		}
	} elsif ($channels =~ /^(\d*)$/) {
		push(@chans, $channels);
	} elsif ($channels =~ /^\d*,/) {
		push(@chans, split(/,/, $channels));
	} else {
		print STDERR "channels got here: $channels\n" if ($DEBUG);
	}	
@chans = ( $channels );
	foreach $channel (@chans) {

#		$self->{'config'}{$context}{$channel}{'channel'} = $channel;
		foreach $var (keys %{$self->{'configtemp'}{$context}}) {
			$self->{'config'}{$context}{$channel}{$var}{precomment} = $self->{'configtemp'}{$context}{$var}{precomment};
			$self->{'config'}{$context}{$channel}{$var}{postcomment} = $self->{'configtemp'}{$context}{$var}{postcomment};
			$self->{'config'}{$context}{$channel}{$var}{val} = $self->{'configtemp'}{$context}{$var}{val};
			$self->{'config'}{$context}{$channel}{$var}{order} = $self->{'configtemp'}{$context}{$var}{order};
		}
	}

}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';
	my $precomment = '';
	my $postcomment = '';

	my $configfile = $self->configfile();
	my $contextorder = 0;
	my $order = 0;

	open(CF, "<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
#		chop($line);


		#deal with comments
		if ($line =~ /^;/) {
			$precomment .= $line;
			next;
		} elsif ($line =~ /^;ACZ(\w*):\s*(.*)/) {
			print STDERR "ACZ Variable $1 = $2\n";
			next;
		} elsif ($line =~ /(;.*)$/) {
			$postcomment .= $1;
			$line =~ s/;.*$//;
		} elsif ($line =~ /^\s*$/) {
			$precomment = '';
			$postcomment = '';
			next;
		}

		chop($line);
		#strip off whitespace at the end of the line
		$line =~ s/\s*$//;


		if ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			$self->_addcontext($context, $contextorder);
			$contextorder++;
		} elsif ($line =~ /^channel\s*[=>]+\s*(.*)$/) {
			$channel = $1;
			$self->channels($context, $1, $order, $precomment, $postcomment);
			$precomment = '';
			$postcomment = '';
			$order++;
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->_setvar($context, $1, $2, $order, $precomment, $postcomment);
			$precomment = '';
			$postcomment = '';
			$order++;
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}

	}
	close(CF);

return 1;
}

sub writeconfig {
        my ($self, $fh) = @_;

	if (!$fh) {
	        $fh = \*STDERR;
	}

	foreach $context ($self->_contextorder()) {
		print $fh "[$context]\n";

		foreach $channelgroup ($self->_group($context)) {
			print $fh ";ACZGroup: $channelgroup\n";
		}

	        foreach $channel (sort {$a <=> $b} keys %{$self->{config}{$context}}) {
			foreach $key (keys %{$self->{config}{$context}{$channel}}) {
				next if ($key eq 'channel');
				if ($self->{config}{$context}{$channel}{$key}{val}) {
					print $fh $self->{config}{$context}{$channel}{$key}{'precomment'};
					print $fh "$key => " . $self->{config}{$context}{$channel}{$key}{val};
					if ($self->{config}{$context}{$channel}{$key}{postcomment}) {
						print $fh ' ' . $self->{config}{$context}{$channel}{$key}{postcomment};
					} else {
						print $fh "\n";
					}
				}
			}
			print $fh "channel => $channel\n";
			print $fh "\n";
		}
	}
}

sub deletechannel {
	my ($self, $context, $channel) = @_;

#	if (defined($self->{config}{$context}{$channel})) {
#		$self->{config}{$context}{$channel} = {};
#	}

	delete($self->{config}{$context}{$channel});
	return 1;
}

sub setvariable {
	my ($self, $context, $channel, $var, $val) = @_;

	$self->{config}{$context}{$channel}{$var}{val} = $val;
	$self->{config}{$context}{$channel}{$var}{precomment} = ";Modified by Asterisk::Config::Zapata\n";

}

sub helptext {
	my ($self, $helpname) = @_;


}

sub cgiform {
	my ($self, $action, $context, %vars) = @_;

#actions can be show, list, add, addform, modify, modifyform, delete, deleteform

	my $html = '';

	my $channel = $vars{'channel'};

	my $module = $self->{'name'};
	my $URL = $ENV{'REQUEST_URI'};
	if (!$context) {
		$html .= "<p>Context must be specified\n";
		return $html;
	}

	#if no action specified then default to list
	if (!$action) {
		$action = 'list';
	}

	if ($action =~ /(.*)form$/) {
		$html .= "<form method=\"post\">\n";
                $html .= "<input type=\"hidden\" name=\"module\" value=\"$module\"\n";
		$html .= "<input type=\"hidden\" name=\"channel\" value=\"$channel\">\n";
		$html .= "<input type=\"hidden\" name=\"context\" value=\"$context\">\n";
		$html .= "<input type=\"hidden\" name=\"action\" value=\"$1\">\n";
	}

		

	if ($action eq 'list') {
		foreach $channel ( sort keys %{$self->{config}{$context}} ) {
			$html .= "<a href=\"$URL?module=$module&action=show&context=$context&channel=$channel\">Channel $channel</a>\n";
		}
	}

	if ($action eq 'show' || $action =~ /^modify/ || $action =~ /^delete/ ) {
		if (!$channel || !$self->{'config'}{$context}{$channel}) {
			$html .= "<p>Channel not specified, or channel does not exist\n";
			return $html;
		}
	}

	if ($action eq 'deleteform') {
		$html .= "<br>Are you sure you want to delete channel $channel?\n";
		$html .= "<br><a href=\"$URL?module=$module&action=delete&context=$context&channel=$channel&doit=1\">Confirm</a>\n";

	} elsif ($action eq 'delete') {
		if ($vars{'doit'} == 1 && $self->deletechannel($context, $channel)) {
			$html .= "<br>Channel $channel has been deleted\n";
		} else {
			$html .= "<br>Unable to delete channel $channel\n";

		}
	} elsif ( $action eq 'show' || $action =~ /^modify/ || $action =~ /^add/ ) {


		if ($action eq 'show') {
			$html .= "<a href=\"$URL?module=$module&action=modify&context=$context&channel=$channel\">Modify</a>\n";
			$html .= "<a href=\"$URL?module=$module&action=delete&context=$context&channel=$channel\">Delete</a>\n";
		}

		#loop through allowed variables
		foreach $var ( sort keys %{$self->{'variables'}} ) {

			my $value = '';
			if ($self->{'config'}{$context}{$channel}{$var}{'val'}) {
				$value = $self->{'config'}{$context}{$channel}{$var}{'val'};
			} else {
				$value = $self->{'variables'}{$var}{'default'};
			}

			if ($action eq 'show') {
				$html .= "<br>$var: $value\n";
			} elsif ($action =~ /(.*)form$/) {
				my $subaction = $1;
				my $fieldtype = $self->{'variables'}{$var}{'type'};
				$html .= "<input type=\"hidden\" name=\"OLD$var\" value=\"$value\">\n";
				if ($fieldtype eq 'text') {
					$html .= "<br>$var: <input type=\"text\" name=\"$var\" value=\"$value\">\n";
				} elsif ($fieldtype eq 'one') {
					$html .= "<br>$var: \n";
					foreach $item (@{$self->{'variables'}{$var}{'values'}}) {
						my $checked = 'checked' if ($item eq $value);
						$html .= "<input type=\"radio\" name=\"$var\" value=\"$item\" $checked> $item\n";
					}
				}

			} elsif ($action eq 'modify' || $action eq 'add') {
				if ($action eq 'add' || ($vars{$var} ne $vars{"OLD$var"})) {
					my $newval = $vars{$var};
#need to check for valid value here
					if ($self->variablecheck($context, $var, $newval)) {
						$self->setvariable($context, $channel, $var, $newval);
					}
				}

			}

		}

	}

	if ($action =~ /form$/) {
		$html .= "</form>\n";
	}

	return $html;	
}	


1;
