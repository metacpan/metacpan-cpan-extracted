package Tk::AppWindow::PluginsForm;

=head1 NAME

Tk::AppWindow::PluginsForm - Load and unload plugins.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.07';

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'PluginsForm';

require Tk::LabFrame;
require Tk::Pane;
use Data::Compare;

=head1 DESCRIPTION

This package is a L<Tk::Frame> based megawidget.
It provides a for for loading and unloading plugins
to a L<Tk::AppWindow> based application.

=head1 OPTIONS

=over 4

=item Switch: B<-pluginsext>

A reference to the B<Plugins> extension. Mandatory!

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	my $ext = delete $args->{'-pluginsext'};
	die 'Please specify -pluginsext' unless defined $ext;
	
	$self->SUPER::Populate($args);

	my $lf = $self->LabFrame(
		-label => 'Available plugins',
		-labelside => 'acrosstop',
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	my $pane = $lf->Scrolled('Pane',
		-height => 200,
		-scrollbars => 'oe',
		-sticky => 'nsew',
	)->pack(-expand => 1, -fill => 'both');

	my %plugins = ();
	for ($ext->AvailablePlugins) {
		my $plug = $_;
		my $val = $ext->plugExists($plug);
		$plugins{$plug} = \$val;
		my $f = $pane->Frame(
			-borderwidth => 2,
			-relief => 'groove',
		)->pack(-fill => 'x', -padx => 2, -pady => 2);
		$f->Checkbutton(
# TODO reinstate this after bugfix with plug loading after main loop
			-command => sub {
				if ($val) {
					$ext->plugLoad($plug);
					$self->after(10, sub { $val = '' unless $ext->plugExists($plug) });
				} else {
					$ext->plugUnload($plug);
					$self->after(10, sub { $val = '' if $ext->plugExists($plug) });
				}
			},
			-variable => \$val,
			-text => $plug
		)->pack(-padx => 2, -pady => 2, -anchor => 'w');
		$f->Label(
			-text => $ext->plugDescription($plug),
			-justify => 'left',
		)->pack(-padx => 2, -pady => 2, -anchor => 'w');
	}
	$self->{PLUGINS} = \%plugins;

	my $bf = $self->Frame->pack(-fill => 'x');
	$bf->Button(
		-text => 'Select all',
		-command => ['LoadAll', $self],
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Select none',
		-command => ['UnloadAll', $self],
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$self->ConfigSpecs(
		-pluginsext => ['PASSIVE', undef, undef, $ext],
		DEFAULT => [ $self ],
	);
}

#sub Apply {
#	my $self = shift;
#	my $ext = $self->cget('-pluginsext');
#	my @current = $ext->plugList;
#	my @new = ();
#	my $plugs = $self->{PLUGINS};
#	for (sort keys %$plugs) {
#		my $var = $plugs->{$_};
#		push @new, $_ if $$var;
#	}
#	unless (Compare(\@current, \@new)) {
#		$ext->SavePlugList(@new);
#		my $name = $ext->configGet('-appname');
#		$ext->popMessage("Please restart $name", 'dialog-warning');
#	}
#}

sub LoadAll {
	my $self = shift;
	my $ext = $self->cget('-pluginsext');
	my $plugins = $self->{PLUGINS};
	for (sort keys %$plugins) {
		my $plug = $_;
#		my $val = $plugins->{$plug};
#		$$val = 1;
# TODO reinstate this after bugfix with plug loading after main loop
		$ext->plugLoad($plug);
		$self->after(10, sub {
			my $v = $plugins->{$plug};
			if ($ext->plugExists($plug)) {
				$$v = 1
			} else {
				$$v = ''
			}
		});
	}
}

sub UnloadAll {
	my $self = shift;
	my $ext = $self->cget('-pluginsext');
	my $plugins = $self->{PLUGINS};
	for (sort keys %$plugins) {
		my $plug = $_;
#		my $val = $plugins->{$plug};
#		$$val = '';
# TODO reinstate this after bugfix with plug loading after main loop
		$ext->plugUnload($plug);
		$self->after(10, sub {
			my $v = $plugins->{$plug};
			if ($ext->plugExists($plug)) {
				$$v = 1
			} else {
				$$v = ''
			}
		});
	}
}

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::Ext::Plugins>

=back

=cut

1;



