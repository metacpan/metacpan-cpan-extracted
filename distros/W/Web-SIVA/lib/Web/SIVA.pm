package Web::SIVA;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.6');

use Mojo::DOM;
use LWP::Simple;

our @provincias = qw(al ca ma gr se co hu ja);

our %provincias = map { $_ => 1 } @provincias;

our @meses = qw(ene feb mar abr may jun jul ago sep oct nov dic);

our $base_url = "http://www.juntadeandalucia.es/medioambiente/atmosfera/informes_siva/";

# Module implementation here
sub new {
  my $class = shift;
  my $province = shift || croak "Necesito una provincia";
  
  return bless { _province => $province}, $class;

}

sub day {
  my $self = shift;
  my ($dia, $mes, $year ) = @_;
  my $year_digits = substr($year,2,2);
  my $provincia = $self->{'_province'};
  if ( ! $provincias{$provincia} ) {
    croak "$provincia is not one of the 8 provinces";
  }
  my $date =  sprintf("%02d%02d%02d",$year_digits,$mes,$dia);
  my $fecha = sprintf("%04d-%02d-%02d", $year, $mes, $dia );
  my @datos;
  
  if ( ($year < 2004) || ( $year == 2004 && $mes == 1 && $dia < 11 ) ) {
    my $url = $base_url."$meses[$mes-1]$year_digits/n$provincia$date.txt";
    my $content = get( $url );
    if ( $content ) {
      my @tables;
      if ( $content =~ /Ambiental/ ) {
	@tables = ($content =~ /Ambiental\s+(.+?)\s+Nota/gs);
      } else {
	@tables = split(/\s+\n\s+\n\s+\n/, $content);
      }
      shift @tables; # unneeded first row
      for my $t (@tables) {
	my @lines = grep( /\S+/, split("\n", $t ) ); # Only non-empty
	next if $lines[$#lines] =~ /Fecha/; # No data
	if ( $lines[$#lines] =~ /unidades/ ) {
	  pop @lines;
	  pop @lines;
	}
	my $this_metadata = { date => $fecha."T00:00" };
	my @metadatos;
	push @metadatos, ( $lines[0] =~ /Provincia\s*:\s+(\w+)\s+Estacion\s*:\s+(.+)/ );
	push @metadatos, ( $lines[1] =~ /Municipio\s*:\s+(\w+)\s+Direccion\s*:\s+(.+)/ );
	for my $k (qw(provincia estacion municipio direccion)) {
	  $this_metadata->{$k} = shift @metadatos;
	}
	my (@cabeceras) = split( /\s+/, $lines[2]);
	shift @cabeceras; #Date goes first
	for (my $l =  3; $l <= $#lines; $l++ ) {
	  my %these_medidas = %{$this_metadata};
	  my @columnas;
	  if ( $lines[$l] =~ /:/ ) {		    
	    @columnas = split( /\t/, $lines[$l]);	    
	    my $fecha_hora = shift @columnas;
	    my ($hora) = ($fecha_hora =~ /(\d+:\d+)/);
	    if ( !$hora ) {
	      carp "Problemas con el formato en $l $lines[$l] $fecha";
	      next;
	    }
	    $these_medidas{'date'} =~ s/00:00/$hora/;
	  } else { #Different format
	    my ($fecha_hora, $resto) = ($lines[$l] =~ /(\S+  \d+)\s{3}(.+)/);
	    if ( !$resto ) {
	      carp "Problemas con formato en $l => $lines[$l]";
	    }
	    @columnas= split(/\s{7}/, $resto);
	    my ($this_date, $hour) = split(/\s+/, $fecha_hora);
	    my ($this_day,$mon,$year) = split("/", $this_date);
	    $these_medidas{'date'} = sprintf("%04d-%02d-%02dT%02d:00", $year+1900,$mon,$this_day,$hour);
	  }
	  for my $c ( @cabeceras ) {
	    $these_medidas{$c} = shift @columnas;
	    next if !$these_medidas{$c};
	    $these_medidas{$c} =~ s/\.//;
	    $these_medidas{$c} =~ s/,/./;
	    $these_medidas{$c} = 0 + $these_medidas{$c};
	  }
	  push @datos, \%these_medidas;
	}
      }
    }
  } else {
    my $url = $base_url."$meses[$mes-1]$year_digits/n$provincia$date.htm";
  
    my $content = get( $url );
    
    if  ( $content and $content =~ m{$year</title} )  {
      my $dom = Mojo::DOM->new( $content );
      
      my @tables = $dom->find('table')->each;
      
      shift @tables; #Primera tabla con leyenda
      
      while ( @tables ) {
	my $metadatos = shift @tables;
	next if !@tables;
	my $medidas = shift @tables;
	
	my @metadatos = ( $metadatos =~ /<b>.([A-Z][^<]+)/g);
	my $this_metadata = { date => $fecha };
	for my $k (qw(provincia municipio estacion direccion)) {
	  $this_metadata->{$k} = shift @metadatos;
	}
	
	my @filas = $medidas->find('tr')->each;
	
	shift @filas; #Cabecera
	pop @filas;
	for my $f (@filas) {
	  my @columnas = $f->find('td')->map('text')->each;
	  my %these_medidas = %{$this_metadata};
	  my $fecha_hora = shift @columnas;
	  my ($hora) = ($fecha_hora =~ /(\d+:\d+)/);
	  if ( !$hora ) {
	    carp "Problemas con el formato en $f $fecha";
	  }
	  $these_medidas{'date'} =~ s/00:00/$hora/;
	  for my $c (qw(SO2 PART NO2 CO O3)) {
	    $these_medidas{$c} = shift @columnas;
	  }
	  push @datos, \%these_medidas;
	}
      }
    }
  }
  return \@datos;
}

"We want air"; # Magic true value required at end of module
__END__

=head1 NAME

Web::SIVA - Scrapes information from the Air Quality web in Andalucia, Spain http://www.juntadeandalucia.es/medioambiente/site/portalweb/menuitem.7e1cf46ddf59bb227a9ebe205510e1ca/?vgnextoid=7e612e07c3dc4010VgnVCM1000000624e50aRCRD&vgnextchannel=3b43de552afae310VgnVCM2000000624e50aRCRD


=head1 VERSION

This document describes Web::SIVA version 0.0.4


=head1 SYNOPSIS

    use Web::SIVA;

    my $siva_provincia = new Web::SIVA "gr"; # two-letter acronym for provinces in Andalucia
    my $data_yesterday = $siva_provincia( 4, 3, 2017 ) # As in March 4th, 2017
      
  
=head1 DESCRIPTION

=head2 new $province

Creates an object with metadata for a single province.

=head2 day $day, $mont, $year

Downloads information for a single day from the web and returns it as a reference to array of hashes, with every element including information for a single measure. 

=head2 DIAGNOSTICS

=over

=item C<< Problemas con formato >>

Format problems. Something is wrong with the file. It happens from time to time.

=item C<< %s is not one of the 8 provinces >>

You are trying to instantiate the object for a province that does not exist in Andalucia. Correct ones are C<al>, C<ma>, C<se>, C<ja>, C<gr>, C<hu>, C<co>, C<ca>. 

=back


=head1 DEPENDENCIES

Depends on C<Mojo::DOM> for scraping and C<LWP::Simple> for downloading.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-web-siva@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org> or in Github at L<http://github.com/JJ/perl5-web-siva>


=head1 AUTHOR

JJ  C<< <JMERELO@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2017, JJ C<< <JMERELO@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
