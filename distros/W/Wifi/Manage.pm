package Wifi::Manage;

our $VERSION = '0.01';

use Wifi::WFile;
use Wifi::WMod;
use Wifi::WDevIw;
use Wifi::WDevIf;
use Wifi::WRoute;

use strict;

sub new{
	my($class,$file) = @_;
	my($self) = {
		FICHIER => $file,
	};
	bless($self,$class);
	
	return $self;
}

sub start{
	my($self) = shift;
	my ($conf,$deviw,$devif,$route);

	$conf = Wifi::WFile->new(
		file => $self->{FICHIER}
		);
	$conf->load;
  
	$deviw = Wifi::WDevIw->new($conf);
	$deviw->start;

	$devif = Wifi::WDevIf->new($conf);
	$devif->start;

	$route = Wifi::WRoute->new($conf);
	$route->start;
}										

sub start_with_module{
	my($self) = shift;
	my ($conf,$mod,$deviw,$devif,$route);

	$conf = Wifi::WFile->new(
		file => $self->{FICHIER}
		);

	$conf->load;

	if($conf->{CONFIGMOD}{MODULE} ne undef){
		$mod = Wifi::WMod->new($conf);
		$mod->load;
	}
	
	$deviw = Wifi::WDevIw->new($conf);
	$deviw->start;

	$devif = Wifi::WDevIf->new($conf);
	$devif->start;

	$route = Wifi::WRoute->new($conf);
	$route->start;
}

sub stop{
	my($self) = shift;
	my($conf,$devif);

	$conf = Wifi::WFile->new(
		file => $self->{FICHIER}
		);
	$conf->load;

	$devif = Wifi::WDevIf->new($conf);
	$devif->stop;
}

sub stop_with_module{
	my($self) = shift;
	my ($conf,$mod,$deviw,$devif,$route);

	$conf = Wifi::WFile->new(
		file => $self->{FICHIER}
		);
	$conf->load;

	$devif = Wifi::WDevIf->new($conf);
	$devif->stop;

       if($conf->{CONFIGMOD}{MODULE} ne undef){
		$mod = Wifi::WMod->new($conf);
		$mod->unload;
	}
}
1;

__END__

=head1 NAME 

Wifi::Manage - A class for managing wifi connection

=head1 SYNOPSIS

use Wifi::Manage;

$manager = Wifi::Manage->new("PATH_FILE");

$manage->start;

=head1 DESCRIPTION

Welcome to Wifi::Manage , a work in progress.It's a quick module to switch quickly wifi connection.All module use Wifi::WFile to configure the connection.

=over

=item *

Wifi::WFile

See Wifi::WFile documentation.

=item *

Wifi::WDevIw

See Wifi::WDevIw documentation.

=item *

Wifi::WDevIf

See Wifi::WDevIf documentation.

=item *

Wifi::WMod

See Wifi::WMod documentation.

=head1 METHOD DESCRIPTIONS 

This sections contains only the methods in Manage.pm itself.

=over

=item *

start();

Start the connection.

=item *

start_with_module();

Start the connection with loading module.

=item *

stop();

Stop the connection.

=item *

stop_with_module();

Stop the connection with unloading module.

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
