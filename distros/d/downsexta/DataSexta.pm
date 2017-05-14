package DataSexta;


use warnings;
use strict;
use utf8;
use encoding 'utf8';
use open 'locale';
use Encode;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;

sub new {

    my $clase = shift;
    my $self = {@_};
    my @array = ();
    $self->{URL} = 'http://www.lasexta.com';
    $self->{SALON} = $self->{URL} . '/videos';
    $self->{SERIES}->{URL} = $self->{SALON} . '/series.html';
    $self->{NOTICIAS}->{URL} = $self->{SALON} . '/noticias.html';
    $self->{PROGRAMAS}->{URL} = $self->{SALON} . '/programas.html';
    $self->{PROGRAMAS}->{NOMBRES} = [];
    $self->{SERIES}->{NOMBRES} = [];
    $self->{NOTICIAS}->{NOMBRES} = [];
    $self->{NOTICIAS}->{PROGRAMAS} = [];
    
    bless $self, $clase;
    return $self;
    
    }
    
sub get_programas {
  use LWP::Simple;
  my $self = shift;
  my @nombre_programa;

  my $response = get($self->{PROGRAMAS}->{URL});
  die "No puedo conectar a $self->{PROGRAMAS}->{URL}" unless defined $response;

  my @content = split(/\n/, $response);
  
  for my $l (@content)
    {
    chop $l;
    if ($l =~ /^\s+<a  title="Vídeos de.*PROGRAMAS TV - LA SEXTA" href="\/videos\/.*\.html" >/)
      {
      $l =~ s/^\s+<a  title="Vídeos de //;
      $l =~ s/ - PROGRAMAS TV - LA SEXTA" //;
      $l =~ s/" >//;
      $l =~ s/href="/::/;
      my ($a, $b) = split(/::/, $l);
      ###print "$a --> $b\n";
      push $self->{PROGRAMAS}{NOMBRES}, {$a, $b};
      }
    }
  ###print "\n";
  return $self->{PROGRAMAS}->{NOMBRES};
  }

sub get_series {
  use LWP::Simple;
  my $self = shift;
  my @nombre_series;

  my $response = get($self->{SERIES}->{URL});
  die "No puedo conectar a $self->{SERIES}->{URL}" unless defined $response;

  my @content = split(/\n/, $response);
  
  for my $l (@content)
    {
    chop $l;
    if ($l =~ /^\s+<a title="Vídeos de .* - Capítulos Completos - SERIES LA SEXTA" href="\/videos\/.*.html">/)
      {
      $l =~ s/^\s+<a title="Vídeos de //;
      $l =~ s/ - Capítulos Completos.*" //;
      $l =~ s/">//;
      $l =~ s/href="/::/;
      my ($a, $b) = split(/::/, $l);
      ###print "$a --> $b\n";
      push $self->{SERIES}->{NOMBRES}, {$a, $b};
      }
    }
  ###print "\n";
  return $self->{SERIES}->{NOMBRES};
  }
  
sub get_noticias {
  use LWP::Simple;
  my $self = shift;
  my @nombre_noticias;
  
  my $response = get($self->{NOTICIAS}->{URL});
  die "No puedo conectar a $self->{NOTICIAS}->{URL}" unless defined $response;

  my @content = split(/\n/, $response);
  
  for my $l (@content)
    {
    chop $l;
    if ($l =~ /^\s+<a  title="NOTICIAS - Vídeos de .* - LA SEXTA" href="\/videos\/.*.html"\s+>/)
      {
      $l =~ s/^\s+<a  title="NOTICIAS - Vídeos de //;
      $l =~ s/ - LA SEXTA" href="/::/;
      $l =~ s/"\s+>//;
      my ($a, $b) = split(/::/, $l);
      ###print "$a --> $b\n";
      push $self->{NOTICIAS}->{NOMBRES}, { $a => "$b" };
      }
    }
    
  ###print "\n";
  return $self->{NOTICIAS}->{NOMBRES};
  } 
 

sub get_capitulos {
  my ($self, $prog) = @_;
  my @master = (@{$self->{PROGRAMAS}->{NOMBRES}}, @{$self->{SERIES}->{NOMBRES}}, @{$self->{NOTICIAS}->{NOMBRES}});
  my $i = 0;

  my $numprogs = scalar(@{$self->{PROGRAMAS}->{NOMBRES}});
  my $numser = scalar(@{$self->{SERIES}->{NOMBRES}});
  my $numnot = scalar(@{$self->{NOTICIAS}->{NOMBRES}});
    
  ###print ">>> " . scalar(@{$self->{PROGRAMAS}->{NOMBRES}}) . " programas\n";
  ###print ">>> " . scalar(@{$self->{SERIES}->{NOMBRES}}) . " series\n";
  ###print ">>> " . scalar(@{$self->{NOTICIAS}->{NOMBRES}}) . " noticias\n";
  
  foreach $i (0..@master-1)
	{
	for my $hash ( $master[$i] ) {
	    for my $nom ( keys %$hash ) {
		if ($nom eq $prog)
		  {
		  
		  if ( $i <= $numprogs - 1) 
		    { 
		    ###print "Se ha encontrado un PROGRAMA\n"; 
		    my $url = $self->{URL} . $hash->{$nom};
    
		    my ($titulos, $descripcion, $urls, $thums) = &get_data_capitulos($self, $nom, $url);

		    for my $nnot (0..@$titulos - 1)
				  {
				  @{$self->{PROGRAMAS}->{PROGRAMAS}}[$nnot] = (
									  {
									  "TITULO"	=>	@$titulos[$nnot],
									  "DESCRIPCION"	=>	@$descripcion[$nnot],
									  "URL"		=>	@$urls[$nnot],
									  "IMAGEN"	=>	@$thums[$nnot]
									  }
									);
				  }
		    return $self->{PROGRAMAS}->{PROGRAMAS};
		    }		    
		    
		    
		  if ( ($i >= $numprogs) && ($i <= $numprogs + $numser - 1) ) 
		    { 
		    ###print "Se ha encontrado una SERIE\n"; 
		    my $url = $self->{URL} . $hash->{$nom};
    
		    my ($titulos, $descripcion, $urls, $thums) = &get_data_capitulos($self, $nom, $url);

		    for my $nnot (0..@$titulos - 1)
				  {
				  @{$self->{SERIES}->{PROGRAMAS}}[$nnot] = (
									  {
									  "TITULO"	=>	@$titulos[$nnot],
									  "DESCRIPCION"	=>	@$descripcion[$nnot],
									  "URL"		=>	@$urls[$nnot],
									  "IMAGEN"	=>	@$thums[$nnot]
									  }
									);
				  }
		    return $self->{SERIES}->{PROGRAMAS};
		    }
		    
		  if ( ($i >= $numprogs + $numser) && ($i <= $numprogs + $numser + $numnot - 1) ) 
		    {
		    ###print "Se ha encontrado un NOTICIERO\n";
		    my $url = $self->{URL} . $hash->{$nom};
    
		    my ($titulos, $descripcion, $urls, $thums) = &get_data_capitulos($self, $nom, $url);

		    for my $nnot (0..@$titulos - 1)
				  {
				  @{$self->{NOTICIAS}->{PROGRAMAS}}[$nnot] = (
									  {
									  "TITULO"	=>	@$titulos[$nnot],
									  "DESCRIPCION"	=>	@$descripcion[$nnot],
									  "URL"		=>	@$urls[$nnot],
									  "IMAGEN"	=>	@$thums[$nnot]
									  }
									);
				  }
		    return $self->{NOTICIAS}->{PROGRAMAS};
		    }
		  }
	      }
	  $i++;
	  }
	}
  return;
  }
  
#   
sub get_data_capitulos {
  my ($self, $prog, $url) = @_;
  ###print "Obteniendo datos de los capítulos de [$prog]: $url\n";
  my $html = get("$url");
  my (@titulos, @descripcion, @urls, @thums);
  my $sf = 0;
  my @div;
  my @html = split(/\n/, $html);
  
  for my $l (@html)
    {
    $l =~ s/\t//g;
    $l =~ s/^\s+//;
    $sf = 1 if ($l =~ /<div class="grid_12 carruContentDoble">/);
    $sf = 0 if ($l =~ /<!-- fin clase grid_12 carruContentDoble -->/);
    next if ($sf eq '0');
    if ($sf eq '1')
      {
      push @div, $l;
      }
    }

    for my $l (@div)
      {
      chop $l;
      if ($l =~ /<a\s+title="/)
	{
	$l =~ s/<a\s+title.*Vídeos de //;
	$l =~ s/ - ANTENA 3 TV//;
	$l =~ s/"//;
# 	###print "Título: $l\n";
	push @titulos, $l;
	}
      elsif ($l =~ /<h2><p>/)
	{
	$l =~ s/<h2><p>//;
	$l =~ s/<\/p><\/h2>//;
# 	###print "Descripción: $l\n";
	push @descripcion, $l;
	}
      elsif ($l =~ /^href.*>/)
	{
	$l =~ s/^href="/$self->{URL}/;
	$l =~ s/">//;
# 	###print "URL: $l\n";
	push @urls, $l;
	}
      elsif ($l =~ /^src.*jpg/)
	{
	$l =~ s/^src="/$self->{URL}/;
	$l =~ s/"//;
# 	###print "Imágen: $l\n";
	push @thums, $l;
	}
      else { next; }
      }
    
  return (\@titulos, \@descripcion, \@urls, \@thums);
  }



1;

__END__


=pod

=encoding utf8

=head1 NOMBRE

B<DownVideos::DataSexta> - Un módulo para obtener rutas a los capítulos de los programas de La Sexta

=head1 SINOPSIS

use DownVideos::DataSexta

my $sexta =  DataSexta->new();

my $series = $sexta->get_series;

for my $p (@$series)
  {
  for my $k (keys $p)
    {
    ###print "$k\n";
    }
 }

my $capitulos = $sexta->get_capitulos("$nombre_serie");

=head1 DESCRIPCIÓN

Un módulo para obtener rutas a los capítulos de los programas de B<La Sexta>, que junto con B<DownVideos::SextaXML> proporciona la URL de los archivos de video tanto de sus series, como de sus noticieros y programas.

=head1 MÉTODOS

=head2 CONSTRUCTOR

=over

=item new()

=over 

=item B<$sexta = DataSexta-E<gt>new();>

=back

=over

Crea el objeto. No requiere opciones.

=back

=over 4

=item * $sexta (Objeto DataSexta=HASH)

=back

=back

=head2 ACCESORES

=over

=item get_series()

=over 

=item B<$series = $sexta-E<gt>get_series();>

=back

=over

Obtiene un listado de las series y la URL a los capítulos. No requiere argumentos.

=back

=over 4

=item * $series (Array de hashes)

=back

=over

$series = [
            {
              'Serie foo' => '/videos/sfoo.html'
            },
            {
              'Serie bar' => '/videos/sbar.html'
            }
          ];

=back

=back

=over

=item get_programas()

=over 

=item B<$programas = $sexta-E<gt>get_series();>

=back

=over

Obtiene un listado de los programas y la URL a los capítulos. No requiere argumentos.

=back

=over 4

=item * $programas (Array de hashes)

=back

=over

$programas = [
               {
                 'Programa foo' => '/videos/pfoo.html'
               },
               {
                 'Programa bar' => '/videos/pbar.html'
               }
             ];

=back

=back

=over

=item get_noticias()

=over 

=item B<$noticias = $sexta-E<gt>get_noticias();>

=back

=over

Obtiene un listado de los noticieros y la URL a los capítulos. No requiere argumentos.

=back

=over 4

=item * $noticias (Array de hashes)

=back

=over

=begin perl

$noticias = [
              {
                'Noticiero foo' => '/videos/nfoo.html'
              },
              {
                'Noticiero bar' => '/videos/nbar.html'
              }
            ];

=end perl

=back

=back

=over

=item get_capitulos()

=over 

=item B<$capitulos = $sexta-E<gt>get_capitulos($nombre);>

=back

=over

Obtiene un hash con información acerca de todos los capitulos del título (la clave de $series, $programas o $noticias) de la serie, el programa o el noticiero indicado en $nombre.

=back

=over 4

=item * $nombre (Cadena de texto)

=item * $capitulos (Array de hashes)

=back

=over

$capitulos = [
               {
                 'URL' => 'http://www.lasexta.com/videos/seriefoo/temporada-2/capitulo-2.html',
                 'DESCRIPCION' => "Capítulo 2",
                 'TITULO' => "Serie foo - Capítulo 2 - Temporada 1",
                 'IMAGEN' => 'http://www.lasexta.com/clipping/2013/05/02/00047/10.jpg'
               },
               {
                 'URL' => 'http://www.lasexta.com/videos/seriefoo/temporada-2/capitulo-1.html',
                 'DESCRIPCION' => "Capítulo 1",
                 'TITULO' => "Serie foo - Capítulo 1 - Temporada 1",
                 'IMAGEN' => 'http://www.lasexta.com/clipping/2013/04/25/00069/10.jpg'
               }
             ];

=back

=back

=head1 EJEMPLO

=over

=item Ejemplo de obtención de información sobre tres capítulos del noticiero Deportes:

 #!/usr/bin/perl

 use warnings;
 use strict;
 use utf8;
 use encoding 'utf8';
 use open 'locale';
 use Encode;
 use DataSexta;

 my $sexta = DataSexta->new();
 my $noticias = $sexta->get_noticias;
 
 ###print "Obtenemos los programas de la sección noticias\n";

 for my $p (0..@$noticias - 1)
    {
        for my $k (keys @$noticias[$p])
            {
            ###print "Título $p: $k\n";
            ###print "URL $p: " . @{$noticias}[$p]->{$k} . "\n\n";
            }
    }

 # Obtenemos los capítulos del noticiero "Deportes";
 my $capitulos = $sexta->get_capitulos("Deportes");

 ###print "Mostramos información de los 3 últimos capítulos\n";

 for my $c (0..2)
    {
        for my $k (keys @$capitulos[$c])
            {
            ###print "($c) $k:";
            ###print " " . @{$capitulos}[$c]->{$k} . "\n";
            }
    ###print "\n";
    }

=back

=head1 AUTOR

Hugo Morago Martín <morago@ono.com>

=head1 LICENCIA

Copyright © 2013 Hugo Morago Martín <morago@ono.com>

Este programa se distribuye bajo los términos de la GPL v3 del 29 de enero de 2007. Puede encontrar una copia de la misma en http://www.gnu.org/licenses/gpl-3.0.html

=cut
















