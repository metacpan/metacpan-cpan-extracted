package SextaXML;


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
    
    my $base = 'http://www.lasexta.com/';
    my $base_videos = $base . '/videos/';
    
    ###print $self->{URL},"\n";
    
    my @data = split(/\n/, get("$self->{URL}"));
    
    $self->{MULTIMEDIA} = [];

    foreach my $l (@data)
      {
      chop $l;
# 	###print $l,"\n";
      if ($l =~ /.*player_capitulo.xml=/)
	{
	my (undef, $xml) = split(/=/, $l);
	$self->{urlXML} = $base . $xml;
	$self->{urlXML} =~ s/('|;)//g;
	last;
	}
      }
    
    ###print "Url del XML: [ $self->{urlXML} ]\n";
    
    $self->{XMLData} = get($self->{urlXML}) or die "No se ha podido obtener $self->{urlXML}" unless defined $self->{XMLData};

    $self->{XMLin} = XMLin("$self->{XMLData}");
    
#     ###print Dumper $self->{XMLin};
    
    my ($content_type, $document_length, undef, undef, undef) = head($self->{XMLin}->{url}->{urlHttpVideo} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimedia}->{archivo});
    my $tamanyo = ($document_length / 1024)/1024;

    $self->{SECCION} = $self->{XMLin}->{multimedias}->{multimedia}->{seccion};
    $self->{NOMBRE} = $self->{XMLin}->{multimedias}->{multimedia}->{nombre};
    $self->{INFO} = $self->{XMLin}->{multimedias}->{multimedia}->{info};
    $self->{DESCRIPCION} = $self->{XMLin}->{multimedias}->{multimedia}->{descripcion};
    $self->{RTMP} = $self->{XMLin}->{url}->{urlVideoMp4} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimedia}->{archivo};

    push $self->{MULTIMEDIA}, {
			      VIDEO => $self->{XMLin}->{url}->{urlHttpVideo} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimedia}->{archivo},
			      IMAGEN => $self->{XMLin}->{url}->{urlImg} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimediaMaxi}->{archivo},
			      MIMETYPE => "$content_type",
			      TAMANYO => sprintf("%.2f", $tamanyo)
			      };
    
    if ($self->{XMLin}->{multimedias}->{relacionados}->{multimedia})
      {
      foreach my $n (0..@{$self->{XMLin}->{multimedias}->{relacionados}->{multimedia}} - 1)
	{
	my ($content_type, $document_length, undef, undef, undef) = head($self->{XMLin}->{url}->{urlHttpVideo} . @{$self->{XMLin}->{multimedias}->{relacionados}->{multimedia}}[$n]->{archivoMultimedia}->{archivo});
	my $tamanyo = ($document_length / 1024)/1024;
	push $self->{MULTIMEDIA}, {
				  VIDEO => $self->{XMLin}->{url}->{urlHttpVideo} . @{$self->{XMLin}->{multimedias}->{relacionados}->{multimedia}}[$n]->{archivoMultimedia}->{archivo},
				  IMAGEN => $self->{XMLin}->{url}->{urlImg} . @{$self->{XMLin}->{multimedias}->{relacionados}->{multimedia}}[$n]->{archivoMultimediaMaxi}->{archivo},
				  MIMETYPE => "$content_type",
				  TAMANYO => sprintf("%.2f", $tamanyo) 
				  };
	}
      }
    
    bless $self, $clase;
    
    return $self;
    
    }

sub nombre {
    my $self = shift;
    return $self->{NOMBRE}
    }
    
sub seccion {
    my $self = shift;
    return $self->{SECCION}
    }
    
sub info {
    my $self = shift;
    return $self->{INFO}
    }

sub descripcion {
    my $self = shift;
    return $self->{DESCRIPCION}
    }

sub rtmp {
    my $self = shift;
    return $self->{RTMP}
    }

sub multimedia {
  my $self = shift;
  return $self->{MULTIMEDIA};
  }


    
1;

__END__


#     ###print  $self->{XMLin}->{multimedias}->{multimedia}->{seccion}, "\n";
#     ###print  $self->{XMLin}->{multimedias}->{multimedia}->{nombre}, "\n";;
#     ###print  $self->{XMLin}->{multimedias}->{multimedia}->{info}, "\n";
#     ###print  $self->{XMLin}->{multimedias}->{multimedia}->{descripcion}, "\n";
#     ###print  $self->{XMLin}->{url}->{urlImg} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimediaMaxi}->{archivo}, "\n";;
#     ###print  $self->{XMLin}->{url}->{urlHttpVideo} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimedia}->{archivo}, "\n";;
#     ###print  $self->{XMLin}->{url}->{urlVideoMp4} . $self->{XMLin}->{multimedias}->{multimedia}->{archivoMultimedia}->{archivo}, "\n";;
#     ###print  $self->{XMLin}->{multimedias}->{multimedia}->{aspecto}, "\n";=pod

=encoding utf8

=head1 NOMBRE

B<DownVideos::SextaXML> - Un módulo para obtener rutas a los vídeos de los programas de La Sexta

=head1 SINOPSIS

 use DownVideos::SextaXML

 my $xml = SextaXML->new(URL => $$capitulos[0]->{URL});

 print "\n\n\nObteniendo datos del primer capítulo de Tiempo:\n\n";

 print "\tNombre:\t\t" . $xml->nombre . "\n";
 print "\tSección:\t" . $xml->seccion . "\n";
 print "\tInfo:\t\t" . $xml->info . "\n";
 print "\tDescripción:\t" . $xml->descripcion . "\n";
 print "\tImagen:\t\t" . $xml->imagen . "\n";
 print "\tVídeo:\t\t" . $xml->video . "\n";
 print "\tRTMP:\t\t" . $xml->rtmp . "\n";
 print "\tTipo:\t\t" . $xml->mime . "\n";
 print "\tTamaño:\t\t" . $xml->tamanyo . " Megas\n\n\

=head1 DESCRIPCIÓN

Un módulo para obtener rutas a los vídeos de capítulos concretos de programas de B<La Sexta>. Además proporciona información sobre el nombre, la sección, la descripción, el tipo mime y el tamaño del vídeo.

=head1 MÉTODOS

=head2 CONSTRUCTOR

=over

=item new()

=over 

=item B<$xml = DataSexta-E<gt>new( URL =E<gt> $url_del_capitulo );>

=back

=over

Crea el objeto. El argumento es un par clave-valor en el que la clave debe ser "URL" y el valor la ruta a la página que contiene el reproductor de vídeo. Este argumento puede obtenerse de un modo sencillo mediante el módulo B<DownVideos::DataSexta>.

=back

=over 4

=item * $sexta (Objeto SextaXML=HASH)

=back

=back

=head2 ACCESORES

=over

=item nombre()

=over 

=item B<$nombre = $xml-E<gt>nombre();>

=back

=over

Obtiene el nombre o título del programa, serie o noticiero. No requiere argumentos.

=back

=over 4

=item * $nombre (Cadena de texto)

=back

=over

    $nombre = "Capítulo 19"

=back

=back

=over

=item seccion()

=over 

=item B<$seccion = $xml-E<gt>seccion();>

=back

=over

Obtiene el nombre propio del programa. No requiere argumentos.

=back

=over 4

=item * $seccion (Cadena de texto)

=back

=over

    $seccion = "Buena gente"

=back

=back

=over

=item info()

=over 

=item B<$info = $xml-E<gt>info();>

=back

=over

Obtiene información acerca del capítulo concreto. No requiere argumentos.

=back

=over 4

=item * $info (Cadena de texto)

=back

=over

    $info = "Capítulo 19 Temporada: 1"

=back

=back

=over

=item descripcion()

=over 

=item B<$descripcion = $xml-E<gt>descripcion();>

=back

=over

Generalmente obtiene una descripcion del contenido del capítulo o información acerca del mismo.

=back

=over 4

=item * $descripcion (Cadena de texto)

=back

=over

    $descripcion = "Ana consigue el papel de su vida y decide irse a Miami"

=back

=back

=over

=item imagen()

=over 

=item B<$imagen = $xml-E<gt>imagen();>

=back

=over

Obtiene la URL a una imágen del capítulo.

=back

=over 4

=item * $imagen (Cadena de texto)

=back

=over

    $imagen = "http://www.lasexta.com/clipping/2013/07/17/00555/30.jpg"

=back

=back

=over

=item rtpm()

=over 

=item B<$rtpm = $xml-E<gt>rtpm();>

=back

=over

Obtiene la dirección rtpm para ver el vídeo con un reproductor.

=back

=over 4

=item * $rtpm (Cadena de texto)

=back

=over

    $rtpm = "rtmp://a3-lasextafs.fplive.net/a3-lasexta/mp_seriesh3/2013/07/17/00005/000.f4v"

=back

=back

=over

=item tipo()

=over 

=item B<$tipo = $xml-E<gt>tipo();>

=back

=over

Obtiene el tipo MIME del fichero de vídeo.

=back

=over 4

=item * $tipo (Cadena de texto)

=back

=over

    $tipo = "video/mp4"

=back

=back

=over

=item tamanyo()

=over 

=item B<$tamanyo = $xml-E<gt>tamanyo();>

=back

=over

Obtiene el tamaño en megas del fichero de vídeo.

=back

=over 4

=item * $tamanyo (Cadena de texto)

=back

=over

    $tamanyo = "629.76"

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
 use DownVideos::DataSexta;
 use DownVideos::SextaXML;

 my $sexta = DataSexta->new();

 my $series = $sexta->get_series;

 print "Programas de series:\n\n";
 for my $p (@$series)
   {
   for my $k (keys $p)
     {
     print "\t$k\n";
     }
   }

 my $capitulos = $sexta->get_capitulos("Buena gente");

 my $xml = SextaXML->new(URL => $$capitulos[0]->{URL});

 print "\n\n\nObteniendo datos del primer capítulo de Buena gente:\n\n";

 print "\tNombre:\t\t" . $xml->nombre . "\n";
 print "\tSección:\t" . $xml->seccion . "\n";
 print "\tInfo:\t\t" . $xml->info . "\n";
 print "\tDescripción:\t" . $xml->descripcion . "\n";
 print "\tImagen:\t\t" . $xml->imagen . "\n";
 print "\tVideo:\t\t" . $xml->video . "\n";
 print "\tRTMP:\t\t" . $xml->rtmp . "\n";
 print "\tTipo:\t\t" . $xml->mime . "\n";
 print "\tTamaño:\t\t" . $xml->tamanyo . " Megas\n\n\n";

=back

=head1 AUTOR

Hugo Morago Martín <morago@ono.com>

=head1 LICENCIA

Copyright © 2013 Hugo Morago Martín <morago@ono.com>

Este programa se distribuye bajo los términos de la GPL v3 del 29 de enero de 2007. Puede encontrar una copia de la misma en http://www.gnu.org/licenses/gpl-3.0.html

=cut
