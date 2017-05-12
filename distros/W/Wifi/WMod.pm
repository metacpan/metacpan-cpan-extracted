package Wifi::WMod;
use strict;

sub new{
	my($class,$ref) = @_;
	my($self) = {
		WMod => $ref,
	};
	bless($self,$class);
	
	return $self;
}

sub checkWMod{
	my($self) = shift;

	
}

sub load{
	my($self) = shift;
	my($line,$pid);


	checkWMod($self);

	$pid = open(PIPE, "$self->{WMod}{CONFIGMOD}{INSMOD} $self->{WMod}{CONFIGMOD}{MODULE} debug=$self->{WMod}{CONFIGMOD}{DEBUG} firmware_dir=$self->{WMod}{CONFIGMOD}{FIRMWARE} |") || die "Impossible d'ouvrir $self->{WMod}{CONFIGMOD}{INSMOD} : $!";
	(kill 0, $pid) || die "$self->{WMod}{CONFIGMOD}{INSMOD} invocation failed";

	print "+ Chargement module $self->{WMod}{CONFIGMOD}{MODULE}\n";
	
	while (defined($line = <PIPE>)){
  	#	print "LIGNE $line\n";
  	}
  	
	close(PIPE);
}

sub unload{
	my($self) = shift;
	my($line,$pid);
	my($found) = 0;

	$_ = $self->{WMod}{CONFIGMOD}{MODULE};
	my(@tmp) = split(/\./);

	$pid = open(PIPE,"$self->{WMod}{CONFIGMOD}{LSMOD} |") || die "Impossible d'ouvrir $self->{WMod}{CONFIGMOD}{LSMOD} : $!";
	(kill 0,$pid) || die "$self->{WMod}{CONFIGMOD}{LSMOD} invocation failed";
	while(defined($line = <PIPE>) && $found == 0){
		if($line =~ /^$tmp[0]/){
	#		print "LINE $line";
			$found = 1;
		}
	}
	close(PIPE);

	if($found == 1){
	
	print "+ Module $self->{WMod}{CONFIGMOD}{MODULE} Trouve\n";
	print "- Dechargement en cours ....\n";

	$pid = open(PIPE,"$self->{WMod}{CONFIGMOD}{RMMOD} $tmp[0] |") || die "Impossible d'ouvrir $self->{WMod}{CONFIGMOD}{RMMOD} : $!";
	(kill 0,$pid) || die "$self->{WMod}{CONFIGMOD}{RMMOD} invocation failed";
	while(defined($line = <PIPE>)){
	#	print "LINE $line";
	}
	close(PIPE);

	print "- Dechargement $self->{WMod}{CONFIGMOD}{MODULE} fini\n";
	}
	
}
1;

__END__

=head1 NAME 

Wifi::WMod - A class for loading linux kernel module wifi for Texas Instruments chips(http://acx100.sourceforge.net/)

=head1 SYNOPSIS

use Wifi::WMod;

$mod = Wifi::WMod->new(REFERENCE Wifi::WFile);

$mod->load;

=head1 DESCRIPTION

Wifi::WMod is used by Wifi::Manage for loading LKM wifi.

=head1 METHOD DESCRIPTIONS 

This sections contains only the methods in WMod.pm itself.

=over

=item *

load();

Load the module

=item *

unload();

Unload the module

=over

=back

=head1 AUTHORS

=over

=item *

Developed by Shy <shy@cpan.org>.

=back

=cut
