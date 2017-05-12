package Asterisk::Astman;

require 5.004;

=head1 NAME

Asterisk::Astman - Interface to the astman port

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;

use Net::Telnet;

$VERSION = '0.01';

$DEBUG = 5;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'configfile'} = undef;
	$self->{'PORT'} = undef;
	$self->{'USER'} = undef;
	$self->{'SECRET'} = undef;
	$self->{'vars'} = {};
	$self->{'telnet'} = new Net::Telnet;

	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub port {
	my ($self, $port) = @_;

	if (defined($port)) {
		$self->{'PORT'} = $port;
	} else {
		$self->{'PORT'} = 5038 if (!defined($self->{'PORT'}));
	}

	return $self->{'PORT'};
}

sub host {
	my ($self, $host) = @_;

	if (defined($host)) {
		$self->{'HOST'} = $host;
	} else {
		$self->{'HOST'} = 'localhost' if (!defined($self->{'HOST'}));
	}

	return $self->{'HOST'};
}

sub user {
	my ($self, $user) = @_;

	if (defined($user)) {
		$self->{'USER'} = $user;
	}

	return $self->{'USER'};
}		

sub secret {
	my ($self, $secret) = @_;

	if (defined($secret)) {
		$self->{'SECRET'} = $secret;
	}

	return $self->{'SECRET'};
}

sub connect {
	my ($self) = @_;

	my $res;

	my $telnet = $self->{'telnet'};
	my $host = $self->host();
	$telnet->port( $self->port() );
	

	$res = $telnet->open($host);

	$telnet->errmode('return');
	my $header = $telnet->getline();
	print STDERR "HEADER $header\n";
	$telnet->input_record_separator( "\n\n" );


	return $res;
}

sub authenticate {
	my ($self) = @_;

	my $username = $self->user();
	my $secret = $self->secret();
	my $telnet = $self->{'telnet'};
	my $command = "Action: Login\n";
	$command .= "Username: $username\n";
	$command .= "Secret: $secret\n";

	print $self->execute($command);


}

sub execute {
	my ($self, $string) = @_;

	my $result = '';
	my $telnet = $self->{'telnet'};
	if ($telnet->print($string)) {
		my @results = $telnet->getline();
		$result = arrtostr(@results);

	}

	return $result;
}

sub defaultevent {
	my ($self, $string) = @_;
	
	print STDERR "MYEvent: $string\n" if ($DEBUG>2);
}

sub setevent {
	my ($self, $callback) = @_;

	if (defined($callback)) {
		$self->{'callback'} = $callback;
	} else {
		$self->{'callback'} = \$self->defaultevent if (!defined($self->{'callback'}));
	}

	return $self->{'callback'};
}

sub managerloop {
	my ($self) = @_;

	my $telnet = $self->{'telnet'};

	while (my $result = $telnet->getline()) {
#		my $result = arrtostr(@results);
#		print STDERR $result if ($DEBUG);
		if ($result =~ /Event/) {
#			print \$self->{'callback'};
			eval "&$self->{'callback'};";
#			eval ($self->{'callback'}('$result'); );
		}

	}	


}

sub arrtostr {
        my (@input) = @_;

        my $output = '';
        foreach (@input) {
                $output .= $_;
        }
        return $output;
}

	

sub configfile {
	my ($self, $configfile) = @_;

	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} else {
		$self->{'configfile'} = '/etc/asterisk/manager.conf' if (!defined($self->{'configfile'}));
	}

	return $self->{'configfile'};
}

sub setvar {
	my ($self, $context, $var, $val) = @_;

	$self->{'vars'}{$context}{$var} = $val;
}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';

	my $configfile = $self->configfile();

	open(CF, "<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
		chop($line);

		$line =~ s/;.*$//;
		$line =~ s/\s*$//;

		if ($line =~ /^;/) {
			next;
		} elsif ($line =~ /^\s*$/) {
			next;
		} elsif ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			print STDERR "Context: $context\n" if ($DEBUG>3);
		} elsif ($line =~ /^port\s*[=>]+\s*(\d+)/) {
			$self->port($1);
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}

	}
	close(CF);

return 1;
}

1;
