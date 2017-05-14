#!/usr/local/bin/perl -w

use strict;
use English;
use Tk;

use lib '../.';

use Tk::Graph;


my $Main = MainWindow->new(-title => "Test", -background => "white" );
my $pollsec = 3;

###############################################################################

sub linegraph {
	my $target      = shift  or return undef;

	my $f1 = $target->Frame()->pack( -side => "left",-fill => "both", -expand => 1);
	my $g1 = $f1->Graph(
		-type           => "Line",
		-legend         => 0,
		-headroom       => 0,
		-foreground     => "black",
		-debug          => 0,
		-borderwidth    => 2,
		-titlecolor     => '#435d8d',
		-yformat        => '%g',
                -ylabel         => "Mb",
		-xformat        => "%g",
                -xlabel         => "Requests",
		-barwidth       => 15,
		-padding        => [50,20,-30,50],      # Padding [top, right, buttom, left]
		-printvalue     => '%s',           # Name: Wert
		-linewidth      => 2,
		-shadow         => '#435d8d',
		-shadowdepth     => 3,
		-dots           => 1,
		-look           => 20, 
		-wire           => "#d2e8e4",
		-max		=> 1024,
		-ytick		=> 8,
		-xtick		=> 5,
		-config         => { Used => { -color => "#2db82a" } },
	);

	update_system_memory( $g1, $pollsec*1000 );

	return $g1->pack(
		-side           => "bottom",
		-expand         => 1,
		-fill           => 'both',
	);
}

sub update_system_memory {
        my $wid = shift or return undef;
        my $ms  = shift or return undef;
	my $data = {};
	
	my $total = $data->{Total} = 1024;
	my $free  = $data->{Free}  = int rand(1024);

        my $used        = $total - $free;
        my $percent     = 100*$used/$total;

        my $title = sprintf "\nSystem Memory\nMax: %d %s\nUsed: %d %s",
                calc_unit_from_kb($total*1024,"Mb"),
                calc_unit_from_kb($used*1024,"MB");

        $wid->configure(
                -title  => $title,
                -config => { Used => { -color => ( $percent>=50 ? (  $percent>=90 ? "#ff3333" : "#ffb200" ) : "#2db82a" ) } },
        );

        printf "used=%s\n", $used;

        $wid->set({
                Used    => $used,
        });

        $wid->after($ms, [ \&update_system_memory => $wid, $ms ] );

}

sub calc_unit_from_kb {
        my $value = shift;      # Uebergabe in Kb!
        return (-0,"?") unless defined $value;

        my $unit = shift;
           $unit = uc $unit if defined $unit;

        my $u = "";
        foreach ( qw/Kb Mb Gb Tb Pb/ ) {
                $u = $_;
                last if defined $unit and uc($u) eq $unit;
                last if $value < 1024 and not defined $unit;
                $value = $value / 1024;
        }
        return ($value, $u);
}

###############################################################################

linegraph($Main);

MainLoop;

exit(99);
