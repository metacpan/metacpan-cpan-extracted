package Tk::AppWindow::BaseClasses::PluginJobs;

=head1 NAME

Tk::AppWindow::BaseClasses::PluginJobs - Baseclass for plugins using background jobs.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.07";
use Carp;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 SYNOPSIS

 #This is useless
 my $plug = Tk::AppWindow::BaseClasses::PluginJobs->new($frame);

 #This is what you should do
 package My::App::Path::Plugins::MyPlugin
 use base(Tk::AppWindow::BaseClasses::PluginJobs);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=head1 DESCRIPTION

This is a base class for plugins using the B<Daemons> extension for background jobs.
Make sure you have loaded the B<Daemons> extension.

All job names are made unique to Daemons by adding the name of the plugin at the end of the I<$name> you see in this document.

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'Daemons');
	return undef unless defined $self;
	
	$self->{INTERVAL} = 100;

	return $self;
}

sub _daem {
	return $_[0]->extGet('Daemons')
}

=item B<interval>I(?$interval?>

Sets and gets the interval for jobs. Default value 100. To clarify, in miliseconds
that would be 100 times the interval value of the B<Daemons> extension.

=cut

sub interval {
	my $self = shift;
	$self->{INTERVAL} = shift if @_;
	return $self->{INTERVAL}
}

=item B<jobEnd>I<($name)>

=cut

sub jobEnd {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$name = $name . $self->Name;
	$self->_daem->jobRemove($name);
}

=item B<jobExists>I<($name)>

=cut

sub jobExists {
	my ($self, $name) = @_;
	$name = $name . $self->Name;
	return $self->_daem->jobExists($name)
}

=item B<jobList>

=cut

sub jobList {
	my $self = shift;
	my @l = $self->_daem->jobList;
	my @o = ();
	my $xt = $self->Name;
	for (@l) {
		my $n = $_;
		push @o, $n if $n =~ s/$xt!//
	}
	return @o;
}

=item B<jobPause>I<($name)>

=cut

sub jobPause {
	my ($self, $name) = @_;
	$name = $name . $self->Name;
	$self->_daem->jobPause($name);
}

=item B<jobRestart>I<($name)>

=cut

sub jobRestart {
	my ($self, $name) = @_;
	$name = $name . $self->Name;
	$self->_daem->jobEnd($name);
	$self->_daem->jobStart($name, $self->interval, @_);
}

=item B<jobResume>I<($name)>

=cut

sub jobResume {
	my ($self, $name) = @_;
	$name = $name . $self->Name;
	$self->_daem->jobResume($name);
}

=item B<jobStart>I<($name)>

=cut

sub jobStart {
	my $self = shift;
	my $name = shift;
	croak 'Name not defined' unless defined $name;
	$name = $name . $self->Name;
	$self->_daem->jobAdd($name, $self->interval, @_);
}

sub Unload {
	my $self = shift;
	for ($self->jobList) { $self->jobEnd($_) };
	return $self->SUPER::Unload
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::BaseClasses::Plugin>

=item L<Tk::AppWindow>

=back

=cut

1;












