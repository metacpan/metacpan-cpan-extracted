# Copyright (c) 2014 Gavin Brown. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself. 
package X11::WMCtrl;
use vars qw($VERSION);
use strict;

our $VERSION = '0.03';

=pod

=head1 NAME

X11::WMCtrl - a Perl wrapper for the C<wmctrl> program.

=head1 SYNOPSIS

	use X11::WMCtrl;
	use strict;

	my $wmctrl = X11::WMCtrl->new;

	printf("window manager is %s\n", $wmctrl->get_window_manager->{name});

	my @windows = $wmctrl->get_windows;

	my $workspaces = $wmctrl->get_workspaces;

	$wmctrl->switch(1);

	my $app = $windows[0]->{title};

	$wmctrl->maximize($app);
	$wmctrl->unmaximize($app);
	$wmctrl->shade($app);
	$wmctrl->unshade($app);

	$wmctrl->close($app);

=head1 DESCRIPTION

The C<wmctrl> program is a command line tool to interact with an EWMH/NetWM compatible X Window Manager.

It provides command line access to almost all the features defined in the EWMH specification. Using it, it's possible to, for example, obtain information about the window manager, get a detailed list of desktops and managed windows, switch and resize desktops, change number of desktops, make windows full-screen, always-above or sticky, and activate, close, move, resize, maximize and minimize them.

The X11::WMCtrl module provides a simple wrapper to this program.

The C<wmctrl> program can be downloaded from L<http://sweb.cz/tripie/utils/wmctrl/>.

=head1 CONSTRUCTOR

	my $wmctrl = X11::WMCtrl->new;

This returns a new X11::WMCtrl object. It will fail if an executable C<wmctrl> program can't be found.

=cut

sub new {
	my $self = {};
	$self->{package} = shift;
	bless($self, $self->{package});
	chomp($self->{wmctrl} = `which wmctrl 2> /dev/null`);
	die("can't find the wmctrl program") if (! -x $self->{wmctrl});
	return $self;
}

=pod

	my $wm = $wmctrl->get_window_manager;

This returns a hashref of information about the current window manager. The contents of the hash will vary depending on which one is in use - about the only one you can rely on is C<name>.

=cut

sub get_window_manager {
	my $self = shift;
	my $data = $self->wmctrl('-m');
	my $wm = {};
	foreach my $line (split(/\n/, $data)) {
		my ($name, $value) = split(/:/, $line, 2);
		$value =~ s/^\s+//g;
		$value =~ s/\s+$//g;
		$value = ($value =~ 'OFF' ? undef : 1);
		$name = ($name =~ /showing the desktop/i ? 'show_desktop' : $name);
		$wm->{lc($name)} = $value;
	}
	return $wm;
}

=pod

	my @windows = $wmctrl->get_windows;

This method returns an array of hash references with information about the currently managed windows. Each element will contain these keys:

=over

=item * C<id> - the internal ID of the window

=item * C<workspace> - the workspace number of the window. Workspaces are zero indexed. If the workspace value is -1, then the window is 'sticky'.

=item * C<host> - the hostname of the X client drawing the window.

=item * C<title> - the title of the window.

=back

=cut

sub get_windows {
	my $self = shift;
	my $data = $self->wmctrl('-l');
	my @windows;
	foreach my $line (split(/\n/, $data)) {
		my ($id, $strand) = split(/ +/, $line, 2);
		my ($workspace, $host, $title);
		if ($strand =~ /^-1/) {
			$strand =~ s/^-1//;
			$workspace = -1;
			($host, $title) = split(/ /, $strand, 2);
		} else {
			($workspace, $host, $title) = split(/ /, $strand, 3);
		}
		push(@windows, {
			id		=> $id,
			workspace	=> $workspace,
			host		=> $host,
			title		=> $title,
		});
	}
	return @windows;
}

=pod

	my $workspaces = $wmctrl->get_workspaces;

This methods returns a hash ref. The keys are the workspaces IDs, and the values are their names.

=cut

sub get_workspaces {
	my $self = shift;
	my $data = $self->wmctrl('-d');
	my $workspaces = {};
	foreach my $line (split(/\n/, $data)) {
		my ($workspace, $strand) = split(/ /, $line, 2);
		my ($name, undef) = split(/  /, reverse($strand), 2);
		$name = reverse($name);
		$workspaces->{$workspace} = $name;
	}
	return $workspaces;
}

=pod

	$wmctrl->switch($workspace);

Switch to workspace C<$workspace>.

=cut

sub switch {
	my ($self, $workspace) = @_;
	$self->wmctrl('-s', $workspace);
	return 1;
}

=pod

	$wmctrl->activate($window);

Activate the window with the title C<$window> by switching to its workspace and raising it.

=cut

sub activate {
	my ($self, $window) = @_;
	$self->wmctrl('-a', $window);
	return 1;
}

=pod

	$wmctrl->close($window);

Tell the window with the title C<$window> to close.

=cut

sub close {
	my ($self, $window) = @_;
	$self->wmctrl('-c', $window);
	return 1;
}

=pod

	$wmctrl->move_activate($window);

Activate the window with the title C<$window> by moving it to the current workspace and raising it.

=cut

sub move_activate {
	my ($self, $window) = @_;
	$self->wmctrl('-R', $window);
	return 1;
}

=pod

	$wmctrl->move_to($window, $workspace);

Moves the window with the title C<$window> to the workspace C<$workspace>.

=cut

sub move_to {
	my ($self, $window, $workspace) = @_;
	$self->wmctrl('-r', $window, '-t', $workspace);
	return 1;
}

=pod

	$wmctrl->maximize($window);

Maximize C<$window>.

=cut

sub maximize {
	my ($self, $window) = @_;
	$self->modify_state($window, 'add', 'maximized_vert', 'maximized_horz');
	return 1;
}

=pod

	$wmctrl->unmaximize($window);

Unaximize C<$window>.

=cut

sub unmaximize {
	my ($self, $window) = @_;
	$self->modify_state($window, 'remove', 'maximized_vert', 'maximized_horz');
	return 1;
}

=pod

	$wmctrl->minimize($window);

Minimize C<$window>.

=cut

sub minimize {
	my ($self, $window) = @_;
	$self->unmaximize($window);
	$self->modify_state($window, 'add', 'hidden');
	return 1;
}

=pod

	$wmctrl->unminimize($window);

Unminimize C<$window>.

=cut

sub unminimize {
	my ($self, $window) = @_;
	$self->modify_state($window, 'remove', 'hidden');
	return 1;
}

=pod

	$wmctrl->shade($window);

Shade C<$window>.

=cut

sub shade {
	my ($self, $window) = @_;
	$self->modify_state($window, 'add', 'shaded');
	return 1;
}

=pod

	$wmctrl->unshade($window);

Unshade C<$window>.

=cut

sub unshade {
	my ($self, $window) = @_;
	$self->modify_state($window, 'remove', 'shaded');
	return 1;
}

=pod

	$wmctrl->sticky($window);

Make the window C<$window> sticky.

=cut

sub stick {
	my ($self, $window) = @_;
	$self->modify_state($window, 'add', 'sticky');
	return 1;
}

=pod

	$wmctrl->unstick($window);

Removes the 'sticky' property from C<$window>.

=cut

sub unstick {
	my ($self, $window) = @_;
	$self->modify_state($window, 'remove', 'sticky');
	return 1;
}

=pod

	$wmctrl->fullscreen($window);

Make C<$window> full-screen.

=cut

sub fullscreen {
	my ($self, $window) = @_;
	$self->modify_state($window, 'add', 'fullscreen');
	return 1;
}

=pod

	$wmctrl->unfullscreen($window);

Restore C<$window> from full-screen mode.

=cut

sub unfullscreen {
	my ($self, $window) = @_;
	$self->modify_state($window, 'remove', 'fullscreen');
	return 1;
}

=pod

	$wmctrl->wmctrl(@args);

This methods allows you to send instructions directly to wmctrl. This is used by X11::WMCtrl internally, but if you want to do something that the module doesn't support, this is the easiest way.

=cut

sub wmctrl {
	my $self = shift;
	my @args = @_;
	open(WMCTRL, sprintf('%s %s|', $self->{wmctrl}, join(' ', @args)));
	my $data;
	while (<WMCTRL>) {
		$data .= $_;
	}
	close(WMCTRL);
	return $data;
}

=pod

	$wmctrl->modify_state($window, $mod, @params);

This is another low-level function for sending state modifications to windows. The value of C<$mod> can be either C<add> or C<remove>. C<@params> may have either one or two elements. They may be any of the following:

	modal, sticky, maximized_vert, maximized_horz,
        shaded, skip_taskbar, skip_pager, hidden,
        fullscreen, above, below

=cut

sub modify_state {
	my ($self, $window, $mod, @params) = @_;
	die("invalid modifier '$mod'") if ($mod !~ /^(add|remove)$/i);
	die("invalid number of params") if (scalar(@params) > 2);
	$self->wmctrl('-r', $window, '-b', join(',', $mod, @params));
	return 1;
}

=pod

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 BUGS

Currently C<stick()>, C<unstick()>, C<minimize()> and C<unminimize()> don't work. This appears to be a problem with C<wmctrl> itself since.

=head1 AUTHOR

Gavin Brown (L<gavin.brown@uk.com>).

=head1 COPYRIGHT

Copyright (c) 2014 Gavin Brown. This program is free software, you can use it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<wmctrl>

=cut
1;
