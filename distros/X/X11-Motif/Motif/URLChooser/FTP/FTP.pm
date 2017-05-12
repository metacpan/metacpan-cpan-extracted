package X11::Motif::URLChooser::FTP;

use strict;
use vars qw($VERSION @ISA);

use X11::Motif::URLChooser::File;
use Net::FTP;
use File::Listing;

$VERSION = 1.0;
@ISA = qw(X11::Motif::URLChooser::File);

sub menu_name () { 'FTP' }
sub menu_order () { '1' }
sub storage_name () { 'ftp' }

X11::Motif::URLChooser::add_storage_type('ftp', 'X11::Motif::URLChooser::FTP');

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my($c) = @_;

    $self = {
	'host' => undef,
	'dir' => undef,
	'ftp' => undef,
	'history' => [],
	'visible_history' => []
    };

    bless $self, $class;

    $c->{'storage'} = $c->{'inactive_storage'}{'ftp'} = $self;

    $self;
}

sub deactivate {
    my $self = shift;
    my($c) = @_;

    $self->shutdown($c);
    $self->SUPER::deactivate($c);
}

sub shutdown {
    my $self = shift;
    my($c) = @_;

    my $ftp = $self->{'ftp'};
    if (defined $ftp) {
	$ftp->quit;
	$self->{'ftp'} = undef;
    }
}

sub switch_to_host {
    my $self = shift;
    my($c, $new_host, $new_port) = @_;

    if (defined $new_host) {
	$self->shutdown();
	$c->{'host'} = $new_host;
    }
}

sub reload {
    my $self = shift;
    my($c) = @_;

    my $dir = $c->{'dir'};
    my $host = $c->{'host'};
    my $ftp = $self->{'ftp'};
    my @dir_list = ();
    my @file_list = ();

    #print "reload FTP: ${host}:$dir\n";

    if (!defined $ftp) {
	$ftp = Net::FTP->new($host);
	if (defined $ftp && $ftp->login) {
	    $self->{'ftp'} = $ftp;
	}
	else {
	    undef $ftp;
	}
    }

    my @default_directories = ( '/pub', '/tmp', '/' );

    while (defined $ftp) {
	if ($ftp->cwd($dir)) {
	    my $ftp_output = $ftp->dir();

	    #print "FTP: defined(ftp_output) = ", defined($ftp_output), "\n";

	    if (defined($ftp_output) && defined($ftp_output->[0])) {
		my $entry;
		my $fullpath;

		#print "FTP: ftp_output len = ", scalar(@{$ftp_output}), "\n";
		#print "FTP: ftp_output = ", join(', ', @{$ftp_output}), "\n";

		$dir = '' if ($dir eq '/');

		foreach $entry (parse_dir($ftp_output)) {
		    next if ($entry->[0] eq '.' || $entry->[0] eq '..');

		    $fullpath = $dir . '/' . $entry->[0];

		    if ($entry->[1] eq 'd') {
			push @dir_list, [$entry->[0], $fullpath]
		    }
		    else {
			push @file_list, [$entry->[0], $fullpath];
		    }
		}

		last;
	    }
	}

	$dir = shift @default_directories;
	if (defined $dir) {
	    $self->switch_to_dir($c, $dir);
	    $dir = $c->{'dir'};
	}
	else {
	    last;
	}
    }

    @dir_list = sort { $a->[0] cmp $b->[0] } @dir_list;
    @{$c->{'visible_dir_list'}} = map { $_->[0] } @dir_list;
    @{$self->{'dir_list'}} = map { $_->[1] } @dir_list;

    @file_list = sort { $a->[0] cmp $b->[0] } @file_list;
    @{$c->{'visible_file_list'}} = map { $_->[0] } @file_list;
    @{$self->{'file_list'}} = map { $_->[1] } @file_list;
}

1;
