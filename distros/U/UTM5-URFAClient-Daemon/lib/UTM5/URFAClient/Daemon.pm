package UTM5::URFAClient::Daemon;

use warnings;
use strict;

use RPC::XML::Server;
use RPC::XML::Function;
use XML::Writer;

=head1 NAME

UTM5::URFAClient::Daemon - Daemon for L<UTM5::URFAClient>

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use UTM5::URFAClient::Daemon;

    my $foo = UTM5::URFAClient::Daemon->new(<options>);
    ...

=head1 SUBROUTINES/METHODS

=head2 new

	Starts daemon

	Params:

		port
		path
		user
		pass

=cut

sub new {
	my ($class, $self) = @_;

	bless $self, $class;

	my $methods = { 'query' => sub { $self->_query(@_) } };

	# TODO: Add local/remote checking

	# Check params
	$self->{port} ||= '39238';
	$self->{path} ||= '/netup/utm5';
	$self->{user} ||= 'init';
	$self->{pass} ||= 'init';

	warn "Starting URFA XML-RPC daemon at port $self->{port}...\n";

	my $query = RPC::XML::Function->new({
		name	=> 'query',
		code	=> sub {
			return $self->_query(@_)
		}
	});

	my $server = RPC::XML::Server->new(port => $self->{port})
		or die "Couldn't start HTTP server: $!";
	$server->add_method($query);

	return ($server, $server->server_loop);
}

# Calculate array dimensions
sub _t {
	return $_[1] if ref $_[0] ne 'ARRAY';
	t($_[0]->[0], ++$_[1]);
}

# Creating temporary XML file for UTM5
sub _create_xml {
	my ($self, $cmd, $params, $data) = @_;

	# Open temporary action xml file
	$self->{_fname} = 'tmp'.int((time * (rand() * 10000)) / 1000);
	open FILE, ">".$self->{path}."/xml/".$self->{_fname}.".xml";

	# Init XML writer
	my $writer = new XML::Writer(OUTPUT => \*FILE, ENCODING => 'utf-8');
	$writer->startTag('urfa');

	# Generate param nodes
	if(!$params) {
		$writer->emptyTag('call', function => $cmd);
	} else {
		$writer->startTag('call', function => $cmd);

		while(my ($key, $value) = each %$params) {
		    $writer->emptyTag('parameter', name => $key, value => $value);
		}

		$writer->endTag('call');
    }

	$writer->endTag('urfa');
	$writer->end();

	# Close temp action xml file
	close FILE;


	# Generate datafile if data received
	if($data) {
		# Open temporary data file
		$self->{_dname} = 'dat'.int((time * (rand() * 10101)) / 1000);
		open DATA, ">".$self->{path}."/xml/".$self->{_dname}.".xml";

		print DATA $data;

		close DATA;
	}

	return ($self->{_fname}, $self->{_dname});
}

sub _query {
	my ($self, $cmd, $params, $data) = @_;
	my $stdout;
	warn " * Query received: $cmd\n";

	my ($action, $datafile) = $self->_create_xml($cmd, $params, $data);
	warn "\tPATH: $self->{path}\n";
	warn "\tUSER: $self->{user}\n";
	warn "\tPASS: $self->{pass}\n";
	warn "\tFNME: $self->{_fname}\n";
	warn "\tCMND: $cmd\n";
	warn "\tACTN: $action\n\n";
	my $run = "$self->{path}/bin/utm5_urfaclient -l '$self->{user}' -P '$self->{pass}' -a $action ".($data ? " -datafile $self->{path}/xml/$datafile.xml" : '');
	print "\nDEBUG: $run\n\n";
	$stdout = `$run`;

	print "="x77;
	print "\n\n".$stdout."\n\n";
	print "="x77, "\n";
	unlink $self->{path}.'/xml/'.$self->{_fname}.'.xml';

	return $stdout;
}

=head1 AUTHOR

Nikita Melikhov, C<< <ver at 0xff.su> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-utm5-urfaclient-daemon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=UTM5-URFAClient-Daemon>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc UTM5::URFAClient::Daemon


You can also look for information at:

=over 4

=item * Netup official site

L<http://www.netup.ru/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=UTM5-URFAClient-Daemon>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Nikita Melikhov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of UTM5::URFAClient::Daemon
