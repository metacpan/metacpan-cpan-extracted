package X11::Motif::URLChooser::File;

use strict;
use vars qw($VERSION @ISA);

use X11::Motif::URLChooser;

$VERSION = 1.0;
@ISA = qw();

sub menu_name () { 'Local File' }
sub menu_order () { '0' }
sub storage_name () { 'file' }

X11::Motif::URLChooser::add_storage_type('file', 'X11::Motif::URLChooser::File');

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my($c) = @_;

    $self = {
	'host' => undef,
	'dir' => undef,
	'history' => [],
	'visible_history' => []
    };

    bless $self, $class;

    $c->{'storage'} = $c->{'inactive_storage'}{'file'} = $self;

    $self;
}

sub activate {
    my $self = shift;
    my($c) = @_;

    $c->{'host'} = $self->{'host'};
    $c->{'dir'} = $self->{'dir'};
    @{$c->{'visible_history'}} = @{$self->{'visible_history'}};
}

sub deactivate {
    my $self = shift;
    my($c) = @_;

    $self->{'host'} = $c->{'host'};
    $self->{'dir'} = $c->{'dir'};
    @{$self->{'visible_history'}} = @{$c->{'visible_history'}};

    @{$c->{'visible_history'}} = ();
}

sub shutdown {
    my $self = shift;
    my($c) = @_;
}

sub format {
    my $self = shift;
    my($c) = @_;

    if ($c->{'dir'} eq '/') {
	return $self->storage_name . '://' . $c->{'host'} . $c->{'dir'} . $c->{'selection'};
    }
    else {
	return $self->storage_name . '://' . $c->{'host'} . $c->{'dir'} . '/' . $c->{'selection'};
    }
}

sub go_back {
    my $self = shift;
    my($c, $pos) = @_;

    my $dir = $self->{'history'}[$pos];

    splice(@{$self->{'history'}}, $pos + 1);
    splice(@{$c->{'visible_history'}}, $pos + 1);

    $c->{'dir'} = $dir;
}

sub go_forward {
    my $self = shift;
    my($c, $pos) = @_;

    my $dir = $self->{'dir_list'}[$pos];

    push @{$self->{'history'}}, $dir;
    push @{$c->{'visible_history'}}, $c->{'visible_dir_list'}[$pos];

    $c->{'dir'} = $dir;
}

sub switch_to_host {
    my $self = shift;
    my($c, $new_host, $new_port) = @_;

    if (defined $new_host) {
	$c->{'host'} = $new_host;
    }
}

sub switch_to_dir {
    my $self = shift;
    my($c, $new_dir) = @_;

    $new_dir = (defined $new_dir) ? $self->csh_style_expand($c->{'dir'}, $new_dir) : $c->{'dir'};

    my @path = ();

    foreach my $entry (split('/', $new_dir)) {
	if ($entry eq '..') {
	    pop @path;
	}
	elsif ($entry ne '.' && $entry ne '') {
	    push @path, $entry;
	}
    }

    @{$c->{'visible_history'}} = @{$self->{'history'}} = ( '/' );

    my $canonical_dir = '';

    foreach my $entry (@path) {
	$canonical_dir .= '/' . $entry;
	push @{$self->{'history'}}, $canonical_dir;
	push @{$c->{'visible_history'}}, $entry;
    }

    $c->{'dir'} = $canonical_dir || '/';
}

sub reload {
    my $self = shift;
    my($c) = @_;

    my $dir = $c->{'dir'};
    my $host = $c->{'host'};
    my @dir_list = ();
    my @file_list = ();

    if (opendir(FILE_DIALOG_DIR, $dir)) {
	my $entry;
	my $fullpath;

	$dir = '' if ($dir eq '/');

	while (defined($entry = readdir(FILE_DIALOG_DIR))) {
	    next if ($entry eq '.' || $entry eq '..');

	    $fullpath = $dir . '/' . $entry;

	    if (-d $fullpath) {
		push @dir_list, [$entry, $fullpath];
	    }
	    else {
		push @file_list, [$entry, $fullpath];
	    }
	}
	closedir(FILE_DIALOG_DIR);
    }

    @dir_list = sort { $a->[0] cmp $b->[0] } @dir_list;
    @{$c->{'visible_dir_list'}} = map { $_->[0] } @dir_list;
    @{$self->{'dir_list'}} = map { $_->[1] } @dir_list;

    @file_list = sort { $a->[0] cmp $b->[0] } @file_list;
    @{$c->{'visible_file_list'}} = map { $_->[0] } @file_list;
    @{$self->{'file_list'}} = map { $_->[1] } @file_list;
}

sub csh_style_expand {
    my $self = shift;
    my($cwd, $path) = @_;

    $path =~ s|\${([^\}]+)}|$ENV{$1}|eg;
    $path =~ s|\$(\w+)|$ENV{$1}|eg;

    if ($path =~ s|^~([^/]*)||) {
	if ($1 ne '') {
	    $path = (getpwnam $1)[7] . $path;
	}
	else {
	    $path = $ENV{'HOME'} . $path;
	}
    }

    if ($path !~ m|^/|) {
	if ($cwd =~ m|/$|) {
	    $path = $cwd . $path;
	}
	else {
	    $path = $cwd . '/' . $path;
	}
    }

    $path;
}

1;
