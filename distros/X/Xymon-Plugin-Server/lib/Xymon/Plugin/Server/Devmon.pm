#
# Devmon data object
#
package Xymon::Plugin::Server::Devmon;

use strict;

use Xymon::Plugin::Server;

=head1 NAME

Xymon::Plugin::Server::Devmon - Devmon data object

=head1 SYNOPSIS

    my $devmon = Xymon::Plugin::Server::Devmon
        ->new(ds0 => 'GAUGE:600:0:U',
              ds1 => 'GAUGE:600:0:U');

    $devmon->add_data(device1 => { ds0 => 0, ds1 => 2 });
    $devmon->add_data(device2 => { ds0 => 0, ds1 => 2 });

    # add to data to be reported.
    my $status = Xymon::Plugin::Server::Status
                 ->new("localhost.localdomain", "test1");

    $status->add_devmon($devmon);

=head1 DESCRIPTION

This module handles data structure for Xymon 'devmon' module.
To store data into RRD database, add entry to TEST2RRD variable
 in server config.

(named hobbitserver.cfg in Xymon 4.2, xymonserver.cfg in Xymon 4.3)

 ex.
  TEST2RRD="cpu=la,disk,...(snipped)...,test1=devmon"


=head1 SUBROUTINES/METHODS

=head2 new(ds1 => dsdef1, ...)

Create devmon object with data store definition.
(To know meanings of dsdef field, please read document in RRDTool.)

=cut

sub new {
    my $class = shift;
    my @datadef = @_;	# key, def, key, def, ...

    my @dskeys;
    my %dsdefs;

    while (@datadef) {
	my $key = shift @datadef;
	push(@dskeys, $key);
	$dsdefs{$key} = shift @datadef;
    }

    my $format_method = "_format_4_3";
    my @ver = @{Xymon::Plugin::Server->version};
    if ($ver[0] == 4 && $ver[1] <= 2) {
	$format_method = "_format_4_2";
    }

    my $self = {
	_dskeys => \@dskeys,
	_dsdefs => \%dsdefs,
	_format_method => $format_method,
	_data => [],
    };

    bless $self, $class;
}

=head2 add_data(devname, { ds1 => ds1value, ...})

Set values for devname.

=cut

sub add_data {
    my $self = shift;
    my ($key, $values) = @_;

    push(@{$self->{_data}}, [$key, $values]);
}

=head2 format

Format data structure to report to Xymon.

=cut

sub format {
    my $self = shift;
    my @ver = @{Xymon::Plugin::Server->version};

    my $meth = $self->{_format_method};
    $self->$meth(@_);
}

sub _format_4_2 {
    my $self = shift;
    my @ret;

    my $n = 20;
    my @defs = ('GAUGE:600:0:U') x $n;

    my $ndefs = scalar @{$self->{_dskeys}};
    my %dsmap;

    for (my $i=0; $i<$ndefs; $i++) {
	my $key = $self->{_dskeys}->[$i];
	$dsmap{$key} = sprintf("ds%d", $i);
	$defs[$i] = $self->{_dsdefs}->{$key};
    }

    push(@ret, "<!--DEVMON RRD: ");
    my $dsline = join(" ",
		      map { join(':', 'DS', sprintf("ds%d", $_), $defs[$_]) }
		      0..($n-1));

    push(@ret, $dsline);

    for my $kv (@{$self->{_data}}) {
	my ($key, $values) = @$kv;
	my @vals = ('U') x $n;

	my $ndefs = scalar @{$self->{_dskeys}};
	for (my $i=0; $i<$ndefs; $i++) {
	    my $v = $values->{$self->{_dskeys}->[$i]};
	    $vals[$i] = defined($v) ? $v : 'U';
	}

	my $line = $key . " " . join(':', @vals);


	push(@ret, $line);
    }

    push(@ret, "-->\n");

    return join("\n", @ret); 
}

sub _format_4_3 {
    my $self = shift;
    my @ret;

    push(@ret, "<!--DEVMON RRD: ");
    my $dsline = join(" ",
		      map { join(':', 'DS', $_, $self->{_dsdefs}->{$_}) }
		      @{$self->{_dskeys}});

    push(@ret, $dsline);

    for my $kv (@{$self->{_data}}) {
	my ($key, $values) = @$kv;
	
	my $line = $key . " "
	    . join(":",
		   map { defined($values->{$_}) ? $values->{$_} : 'U'; }
		   @{$self->{_dskeys}});

	push(@ret, $line);
    }

    push(@ret, "-->\n");

    return join("\n", @ret); 
}

1;
