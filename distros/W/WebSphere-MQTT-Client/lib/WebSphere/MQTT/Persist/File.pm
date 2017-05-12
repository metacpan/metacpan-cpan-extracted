package WebSphere::MQTT::Persist::File;

################
#
# MQTT: WebSphere MQ Telemetry Transport persistence object
#
# Re-written in Perl since the IBM C source (mspfp.c) is not in
# the list of redistributable files.
#
# Brian Candler
# B.Candler@pobox.com
#

use strict;
use Carp;
use Fcntl qw(SEEK_END SEEK_SET);

sub new {
	my $class = shift;
	my $basedir = shift;
	$basedir = '/tmp/wmqtt' unless defined $basedir;

	# Store parameters
	my $self = {
		'basedir'	=> $basedir,
	};
    
	# Bless the hash into an object
	bless $self, $class;

	return $self;
}

sub open {
	my ($self, $clientid, $broker, $port) = @_;

	$self->{'sentdir'} = sprintf("%s/%s/%s_%s/sent",
		$self->{'basedir'}, $clientid, $broker, $port);
	$self->{'rcvddir'} = sprintf("%s/%s/%s_%s/rcvd",
		$self->{'basedir'}, $clientid, $broker, $port);
	mkdir_p($self->{'sentdir'}, 0740);
	mkdir_p($self->{'rcvddir'}, 0740);
	0;
}

sub mkdir_p {
	my ($name, $mode) = @_;
	$mode = 0777 unless defined $mode;

	my @dirs = split('/', $name);
	my $path = '';
	while(@dirs) {
		$path .= shift(@dirs).'/';
		next if $path eq '/';
		next if mkdir($path, $mode) || $!{EEXIST} || $!{EISDIR};
		croak("mkdir_p: $!");
	}
}

sub close {
	0;
}

# Called if clean_start=1 on connect. Delete all files in
# the sent and rcvd directories

sub reset {
	my $self = shift;
	forallfiles($self->{'sentdir'}, sub { unlink $_[0] });
	forallfiles($self->{'rcvddir'}, sub { unlink $_[0] });
	0;
}

# Run the passed function for all files in a directory
# (can you tell I prefer Ruby? :-)

sub forallfiles {
	my $dir = shift;
	my $callback = shift;
	opendir(DIR,$dir) || croak("opendir $dir: $!");
	while (my $f = readdir(DIR)) {
		next if ($f eq '.' || $f eq '..');
		$callback->("$dir/$f");
	}
	closedir(DIR);
}

# Called if clean_start=0 on connect. Load all received messages found on
# disk into an array of [id,message,id,message,...]

sub getAllReceivedMessages {
	my $self = shift;

	my @res = ();
	forallfiles($self->{'rcvddir'}, sub { BLOCK: {
		last BLOCK unless $_[0] =~ /\/(\d+)$/;
		my $key = $1;
		unless (CORE::open(F, '<', $_[0])) {
			warn("open $_[0]: $!\n");
			last BLOCK;
		}
		my @stat = stat(F);
		unless (@stat) {
			warn("stat $_[0]: $!\n");
			CORE::close(F);
			last BLOCK;
		}
		my $len = $stat[7];
		my $data = "";
		if (sysread(F, $data, $len) != $len) {
			warn("sysread $_[0]: $!\n");
                	CORE::close(F);
			last BLOCK;
		}
		push @res, $key, $data;
		CORE::close(F);
	}});
	@res;
}

# Called if clean_start=0 on connect. Load all received messages found on
# disk into an array of [id,message,id,message,...]. Note that the library
# may not actually attempt to send these messages until 'retry_interval'
# seconds have passed.
#
# When recovering sent messages we need to ensure that we only restore the
# latest message associated with a particular key. When updSentMessage is
# called to replace a PUBLISH with a PUBREL there is a small overlap where
# both files (NNN and NNNu) are present. Failure at this point would result
# in both messages be available for recovery, which would result in
# duplication. So if both a PUBLISH and PUBREL are found for the same key,
# we need to ensure that only the PUBREL is recovered.

sub getAllSentMessages {
	my $self = shift;

	my @res = ();
	my %seen = ();
	forallfiles($self->{'sentdir'}, sub { BLOCK: {
		last BLOCK unless $_[0] =~ /\/(\d+)(u?)$/;
		my ($key, $u) = ($1, $2);
		# This is NNN and we've already seen NNNu? Ignore it
		last BLOCK if ($u eq '' && $seen{$key});
		# Read in the file
		unless (CORE::open(F, '<', $_[0])) {
			warn("open $_[0]: $!");
			last BLOCK;
		}
		my @stat = stat(F);
		unless (@stat) {
			warn("stat $_[0]: $!\n");
			CORE::close(F);
			last BLOCK;
		}
		my $len = $stat[7];
		my $data = "";
		if (sysread(F, $data, $len) != $len) {
			warn("sysread $_[0]: $!\n");
                	CORE::close(F);
			last BLOCK;
		}
		CORE::close(F);
		# This is NNNu and we've already seen NNN? Replace it
		if ($u eq 'u' && $seen{$key}) {
			$res[$seen{$key}] = $data;
			last BLOCK;
		}
		push @res, $key, $data;
		$seen{$key} = $#res;
	}});
	@res;
}

# The actual writing of a message file. We take a bit of care here
# to ensure only whole messages are left in the filesystem

sub addMessage {
	my ($self, $key, $data, $dir, $suffix) = @_;
	my $tmp = "$dir/tmp$key${suffix}_$$";
	CORE::open(F,'>',$tmp) || return 1;
	binmode(F);
	goto FAIL unless syswrite(F, $data) == length($data);
	goto FAIL2 unless CORE::close(F);
	goto FAIL2 unless rename($tmp,"$dir/$key$suffix");
	return 0;
FAIL:
	CORE::close(F);
FAIL2:
	unlink($tmp);
	return 1;
}

sub addSentMessage {
	my ($self, $key, $data) = @_;
	$self->addMessage($key,$data,$self->{'sentdir'}, '');
}

sub updSentMessage {
	my ($self, $key, $data) = @_;
	my $rc = $self->addMessage($key,$data,$self->{'sentdir'}, 'u');
        unlink("$self->{'sentdir'}/$key") if $rc == 0;
        $rc;
}

sub delSentMessage {
	my $self = shift;
	my $key = shift;
	return 1 if (unlink("$self->{'sentdir'}/$key") == 0 && ! $!{ENOENT});
	return 1 if (unlink("$self->{'sentdir'}/${key}u") == 0 && ! $!{ENOENT});
	0;
}

sub addReceivedMessage {
	my ($self, $key, $data) = @_;
	$self->addMessage($key,$data,$self->{'rcvddir'}, '');
}

# This is the weird one. We have to OR the last byte of the file with 0x01

sub updReceivedMessage {
	my $self = shift;
	my $key = shift;

	CORE::open(F,'+<',"$self->{'rcvddir'}/$key") || return 1;
	binmode(F);
	my $pos = sysseek(F, -1, Fcntl::SEEK_END);
	goto FAIL unless defined $pos && $pos >= 0;
	my $d = '';
	goto FAIL unless sysread(F, $d, 1) == 1;
	$d = chr(ord($d)|0x01);
	my $pos2 = sysseek(F, $pos, Fcntl::SEEK_SET);
	goto FAIL unless $pos2 == $pos;
	goto FAIL unless syswrite(F, $d, 1) == 1;
	return 1 unless CORE::close(F);
	return 0;
FAIL:
	CORE::close(F);
	1;
}

sub delReceivedMessage {
	my $self = shift;
	my $key = shift;
	return unlink("$self->{'rcvddir'}/$key") != 1;
}

1;

__END__

=pod

=head1 NAME

WebSphere::MQTT::Persist::File - filesystem persistence object for MQTT

=head1 SYNOPSIS

  use WebSphere::MQTT::Client;
  use WebSphere::MQTT::Persist::File;

  my $mqtt = WebSphere::MQTT::Client->new(
      Hostname => 'localhost',
      Persist => WebSphere::MQTT::Persist::File->new('/tmp/wmqtt'),
      Async = 1,
  );

  $mqtt->connect();
  $mqtt->publish("mydata", "mytopic", 1);    # QOS 1/2 data is persisted


=head1 DESCRIPTION

WebSphere::MQTT::Persist::File

This is a Perl implementation of a persistence object for MQTT

For details of the API, see doc/ia93.pdf, Chapter 3, "WMQTT Persistence
Interface"

WARNING: THIS IS NOT IBM CODE AND HAS NOT BEEN HEAVILY TESTED. USE AT YOUR
OWN RISK. YOU ARE ADVISED NOT TO ENTRUST CRITICAL DATA TO THIS LAYER!

=head1 TODO

=over

=item add full POD documentation

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-websphere-mqtt-client@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHORS

Brian Candler, B.Candler@pobox.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Brian Candler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
