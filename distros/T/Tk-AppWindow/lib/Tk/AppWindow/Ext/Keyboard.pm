package Tk::AppWindow::Ext::Keyboard;

=head1 NAME

Tk::AppWindow::Ext::Keyboard - adding easy keyboard bindings

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.15";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Keyboard'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-keyboardboardbindings>

Default value is an empty list.

Specify a paired list of keyboard bindings.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->addPreConfig(
		-keyboardbindings => ['PASSIVE', undef, undef, []],
	);

	$self->{BOUND} = {};
	$self->addPostConfig('ConfigureBindings', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<AddBinding>I<($command, $key)>

Adds a keyboard binding to the MainWindow object.

=cut

sub AddBinding {
	my ($self, $command, $key) = @_;
	my $bound = $self->{BOUND};
	my $w = $self->GetAppWindow;
	$key = $self->Convert2Tk($key);
	unless (exists $bound->{$command}) {
		$bound->{$command} = $key;
		$w->bind("<$key>", [$w, 'cmdExecute', $command]);
	}
}

sub ConfigureBindings {
	my $self = shift;
	my $bindings = $self->configGet('-keyboardbindings');
	my @b = @$bindings;
	while (@b) {
		my $command = shift @b;
		my $key = shift @b;
		$self->AddBinding($command, $key);
	}
}

=item B<Convert2Tk>I<($key)>

Converts the modern description of a keyboard to to the Tk version.
For example, 'CTRL+C' becomes 'Control-c'.

=cut

sub Convert2Tk {
	my ($self, $dkey) = @_;
	my $shift = 0;
	my $ctrl = 0;
	my $alt = 0;
	while ($dkey =~ s/^([^\+]+)\+//) {
		if ($1 eq 'SHIFT') {
			$shift = 1;
		} elsif ($1 eq 'CTRL') {
			$ctrl = 1;
		} elsif ($1 eq 'ALT') {
			$alt = 1;
		} else {
			die "Unrecognized key $1 in key conversion";
		}
	}
	if ((length($dkey) eq 1) and ($dkey ge 'A') and ($dkey le 'Z')) {
		$dkey = lc($dkey) unless $shift;
		$shift = 0;
	}
	my $tkkey = '';
	$tkkey = 'Control-' if $ctrl;
	$tkkey = $tkkey . 'Alt-' if $alt;
	$tkkey = $tkkey . 'Shift-' if $shift;
	$tkkey = $tkkey . $dkey;
	return $tkkey
}

sub ReConfigure {
	my $self = shift;
	my $bound = $self->{BOUND};
	my $w = $self->GetAppWindow;
	for (keys %$bound) {
		my $key = delete $bound->{$_};
		$w->bind("<$key>", '');
	}
	$self->ConfigureBindings
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=back

=cut

1;


