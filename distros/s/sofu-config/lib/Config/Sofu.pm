package Config::Sofu;
use Data::Sofu;
use strict;
use warnings;
require Exporter;
use vars qw/$VERSION @EXPORT @ISA %CONFIG $file $Sofu $Comment $wasbinary/;
use Carp;

$VERSION="0.5";
@ISA = qw(Exporter);
@EXPORT=qw/%CONFIG/;
%CONFIG=();
$Sofu="";
$file="";
$Comment="";
$wasbinary="";
sub import {
	my $class=shift;
	my $file=shift;
	die "Usage: use Config::Sofu \"file\"" if ref $file or not -e $file;
	$Config::Sofu::file=$file;
	$Config::Sofu::Sofu=Data::Sofu->new;
	%Config::Sofu::CONFIG=$Config::Sofu::Sofu->read($file);
	$Config::Sofu::Comment=$Config::Sofu::Sofu->comment if $Data::Sofu::VERSION ge "0.23";
	$Config::Sofu::wasbinary=$Config::Sofu::Sofu->{BINARY} if $Config::Sofu::Sofu->{BINARY};
	Config::Sofu->export_to_level(1, '%CONFIG',@_);
}
sub save {
	my $class=shift if @_ and $_[0] eq "Config::Sofu";
	die "Arguments to save() must be empty or hash" if scalar @_ % 2;
	die "No imports. Please \"use\" this module first" unless $Sofu;
	#warn "Usage: Config::Sofu::save(%CONFIG)" and return 0 if not @_ or scalar @_ % 2;
	my %CONF=%main::CONFIG;
	%CONF=@_ if @_;
	if ($Data::Sofu::VERSION ge "0.23") {
		if ($Config::Sofu::wasbinary) {
			$Config::Sofu::Sofu->writeBinary($Config::Sofu::file,\%CONF,$Config::Sofu::Comment);
		}
		else {
			$Config::Sofu::Sofu->write($Config::Sofu::file,\%CONF,$Config::Sofu::Comment);
		}
	}
	else {
		$Config::Sofu::Sofu->write($Config::Sofu::file,\%CONF);
	}
}
1;

=head1 NAME

Config::Sofu - Easy interface to configuration files in .sofu format

=head1 SYNOPSIS

	use vars qw/%CONFIG/; 
	use Config::Sofu "config.sofu"; 
	if ($CONFIG{FOOBAR}) {
		...
	}
	if ($CONFIG{Bar}->[7]->{Foo} eq "Foobar") {
		...
	}
	
Save the new configuration:

	$CONFIG{FOOBAR}="Bar times Foo";
	Config::Sofu::save;
	
or

	Config::Sofu::save(%CompletlyNewConfig)

=head1 SYNTAX

This class exports the hash %CONFIG by default which contains all the information of the file given to the use statement.

=head1 DESCRIPTION

This module does just one thing: It loads data from a .sofu file and puts it into %CONFIG.

=head1 FUNCTIONS AND METHODS

=head2 save()

Save the new configuration of to the same file again.

If the file was binary sofu it is saved again in binary sofu.

=head1 BUGS

The comments in the sofu-file will only be saved again if Data::Sofu >= 0.2.3 is installed.

Can only read binary sofu files if Data::Sofu >= 0.2.8 is installed.

=head1 SEE ALSO

L<Data::Sofu>,perl(1),L<http://sofu.sf.net>

=cut

1;
