package WebService::Kaolabo;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

use LWP::UserAgent;
use HTTP::Request;
use Data::Average;
use Imager;
use File::Spec;
our $errstr;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors( qw( socks_proxy proxy target_file convert_file uri apikey imager request_content response_xml face_data area face_area unface_area ave_face_width ave_face_height error));

sub new {
    my $self = shift->SUPER::new(@_);

    my $target_file = $self->target_file;

    $self->uri('https://kaolabo.com/api/detect?apikey=')
      unless ( $self->uri );

    my $imager = Imager->new;
    if ( $target_file && $target_file !~ /(jpg|jpeg)$/ ) {
        $errstr = 'Target file is not jpeg';
        return;
    }
    unless ( $imager->read( file => $target_file ) ) {
        $errstr = 'Cannot read target file ' . $imager->errstr();
        return;
    }

    $self->area([]);
    $self->face_area([]);
    $self->unface_area([]);
    $self->imager($imager);
    $self;
}

sub scale {
    my $self   = shift;
    my $imager = $self->imager;

    unless ( $imager ) {
        $errstr = 'Not found Imager object';
        return;
    }

    unless ( @_ ) {
        $errstr = 'Not found scale param';
        return;
    }

    my $imager_s = $imager->scale(@_);
    $self->imager($imager_s);

    return $imager_s;
}

sub write {
    my $self         = shift;
    my $convert_file = shift;
    $convert_file ||= $self->convert_file;
    my $imager = $self->imager;
    $imager->write( file => $convert_file, jpegquality => 100 )
      or die $imager->errstr;
    return;
}

sub access {
    my $self = shift;
    if ( $self->socks_proxy ) {
        if ( eval { require LWP::Protocol::https::SocksChain } ) {
            LWP::Protocol::implementor(
                https => 'LWP::Protocol::https::SocksChain' );
            @LWP::Protocol::https::SocksChain::EXTRA_SOCK_OPTS = (
                Chain_Len       => 1,
                Debug           => 0,
                Chain_File_Data => $self->socks_proxy,
                Random_Chain    => 1,
                Auto_Save       => 1,
                Restore_Type    => 1
            );
        }
    }

    my $uri = $self->uri . $self->apikey;

    my $request_content;
    my $imager = $self->imager;
    $imager->write( type => 'jpeg', data => \$request_content );

    my $request = HTTP::Request->new( 'POST' => $uri );
    $request->header( 'Content-Type' => 'image/jpeg' );

    $request->content($request_content)
      if ( $request_content );

    my $ua = LWP::UserAgent->new;
    $ua->proxy( [ 'http', 'ftp' ], $self->proxy ) if ( $self->proxy );

    my $response = $ua->request($request);
    unless ( $response->is_success ) {
        $errstr = 'Failed access ' . $response->status_line;
    }
    else {
        $self->response_xml( $response->content );
        $self->_parser();
        $self->_area_score();
    }
    return $response;
}

sub _parser {
    my $self = shift;

    my $content    = $self->response_xml();
    my $face_data  = [];
    my $ave_width  = Data::Average->new;
    my $ave_height = Data::Average->new;
    while ( $content =~ s/<face(.+?)<\/face// ) {
        my $node = $1;
        my ( $height, $score, $width, $face_x, $face_y, $left_eye_x, $left_eye_y, $right_eye_x, $right_eye_y)
          = ( 0, 0, 0, 0, 0, 0, 0, 0, 0 );

        ( $height, $score, $width, $face_x, $face_y ) = ( $1, $2, $3, $4, $5 )
          if ( $node =~
            /height="(\d+)" score="(\d+)" width="(\d+)" x="(\d+)" y="(\d+)"/ );

        ( $left_eye_x, $left_eye_y ) = ( $1, $2 )
          if ( $node =~ /left\-eye x="(\d+)" y="(\d+)"/i );

        ( $right_eye_x, $right_eye_y ) = ( $1, $2 )
          if ( $node =~ /right\-eye x="(\d+)" y="(\d+)"/i );

        my $center_x = $width / 2 + $face_x;
        my $center_y = $height / 2 + $face_y;

        # Maybe API bugs ??
        if ( $left_eye_x == $right_eye_x ) {
            $right_eye_y = $right_eye_y<$left_eye_y?$right_eye_y:$left_eye_y;
            $left_eye_y  = $right_eye_y<$left_eye_y?$right_eye_y:$left_eye_y;
        }

        $ave_width->add($width);
        $ave_height->add($height);
        push @{$face_data},
          {
            height      => $height,
            score       => $score,
            width       => $width,
            face_x      => $face_x,
            face_y      => $face_y,
            left_eye_x  => $left_eye_x,
            left_eye_y  => $left_eye_y,
            right_eye_x => $right_eye_x,
            right_eye_y => $right_eye_y,
#            left_eye_x  => $left_eye_x,
#            left_eye_y  => $left_eye_y,
#            right_eye_x => $right_eye_x,
#            right_eye_y => $right_eye_y,
            center_x    => $center_x,
            center_y    => $center_y,
          };
    }
    $self->ave_face_width( $ave_width->avg );
    $self->ave_face_height( $ave_height->avg );
    $self->face_data($face_data);
    return;
}

sub _area_score {
    my $self = shift;

    my $w   = $self->imager->getwidth();
    my $h   = $self->imager->getheight();
    my $ddx = $w / 3;
    my $ddy = $h / 3;

    my @area;
    my $area_number = 0;
    for my $i ( 1 .. 3 ) {
        $area_number++;
        push @area,
          {
            area_number => $area_number,
            min_x       => $ddx * ( $i - 1 ),
            min_y       => 0,
            max_x       => $ddx * $i,
            max_y       => $ddy,
            point       => 0
          };
    }
    for my $i ( 1 .. 3 ) {
        $area_number++;
        push @area,
          {
            area_number => $area_number,
            min_x       => $ddx * ( $i - 1 ),
            min_y       => $ddy,
            max_x       => $ddx * $i,
            max_y       => $ddy * 2,
            point       => 0
          };
    }
    for my $i ( 1 .. 3 ) {
        $area_number++;
        push @area,
          {
            area_number => $area_number,
            min_x       => $ddx * ( $i - 1 ),
            min_y       => $ddy * 2,
            max_x       => $ddx * $i,
            max_y       => $ddy * 3,
            point       => 0
          };
    }

    my $face_data = $self->face_data();

    for my $f ( @{$face_data} ) {
        for my $a (@area) {
            if ( $a->{max_x} > $f->{center_x} && $a->{max_y} > $f->{center_y} ) {
                $a->{point}++;
                last;
            }
        }
    }
    $self->area( \@area );

    my @unface_area = grep( { $_->{point} == 0 } @area );
    $self->unface_area( \@unface_area );

    my @face_area = grep( { $_->{point} != 0 } @area );
    $self->face_area( \@face_area );
    return;
}

sub effect_face {
    my $self   = shift;
    my $args   = shift;
    my $effect = $args->{type} || 'line';
    my $color  = $args->{color} || '#000000';
    my $imager = $self->imager;

    my $face_data = $self->face_data || [];
    for my $f ( @{$face_data} ) {
        $imager->box(
            xmin   => $f->{face_x},
            ymin   => $f->{face_y},
            xmax   => $f->{face_x} + $f->{width},
            ymax   => $f->{face_y} + $f->{height},
            color  => $color,
            filled => 1,
        ) if ( $effect eq "box" );

        my $border_h = $f->{height} * 0.1;

        my $ymin = 0;
        my $ymax = 0;
        my $i    = abs( $f->{right_eye_y} - $f->{left_eye_y} );
        if ( $f->{left_eye_y} < $f->{right_eye_y} ) {
            $ymin = $f->{left_eye_y} - $border_h;
            $ymax = $f->{right_eye_y} + $border_h;
        }
        else {
            $ymin = $f->{right_eye_y} - $border_h;
            $ymax = $f->{left_eye_y} + $border_h;
        }

        $imager->box(
            xmin   => $f->{face_x},
            ymin   => $ymin,
            xmax   => $f->{face_x} + $f->{width},
            ymax   => $ymax,
            color  => $color,
            filled => 1,
        ) if ( $effect eq "line" );
    }
    return;
}

1;
__END__

=head1 NAME

WebService::Kaolabo - This module call Kaolabo API (http://kaolabo.com/).


=head1 SYNOPSIS

  use WebService::Kaolabo;
  $kaolab = WebService::Kaolabo->new({
                                       target_file  => 'sample.jpg',
                                       apikey       => 'hogefuga'
                                    });

  unless ( $kaolab->scale( xpixels => 50, ypixels => 50, type => 'max') ) {
      warn "Failed scale $WebService::Kaolabo::errstr";
  }

  my $res = $kaolab->access();
  if ( $res->is_success ) {
      warn "Success ";
  }
  
  #$kaolab->unface_area();
  for my $k ( @{$kaolab->face_area()} ){
      $k->{area_number}
      $k->{min_x};
      $k->{min_y};
      $k->{max_x};
      $k->{max_y};
      $k->{point};
  }
  
  my $face_data = $kaolab->face_data;
  for my $f ( @{$face_data} ){
      $f->{face_x};
      $f->{face_y};
      $f->{height};
      $f->{width};
      $f->{right_eye_y};
      $f->{left_eye_y};
  }
  
  $kaolab->effect_face({type=>'box', color=>'#FF0000'});
  $kaolab->write('output.jpg');
  #my $imager = $kaolab->imager;
  #$imager->write(type=>'jpeg', file=>'output.jpg');


=head1 METHODS


=over 4

=item new({target_file  => '...', apikey => '....'})

The image file and api_key are passed. And Create new instance.
The image should be JPEG.

=item access

Call The Kaolab API . The return value is a response object.
See L<HTTP::Response>. 

=item scale 

Call L<Imager> scale method. See L<Imager::Transformations/scale>.

=item effect_face 

This method draws the line or box on the face. 

The line is drawn on eyes. 

  $kaolab->effect_face({type=>'line', color=>'#FF0000'});

The box is drawn on faces. 

  $kaolab->effect_face({type=>'box', color=>'#FF0000'});

=item write('...') 

Write an image to a file.

=item imager 

The L<Imager> instance is returned.

=item face_area 

The image file is delimited to nine areas. Return face area.

=item unface_area

Return no face area.

=item ave_face_width

Return average width of all faces.

=item ave_face_height

Return average height of all faces.

=item errstr 

Error message.

  warn "$WebService::Kaolabo::errstr";

=back

=head1 SEE ALSO

Kaolab API L<http://kaolabo.com/webapi>
Kaolab L<http://kaolabo.com/>

=head1 AUTHOR

Akihito Takeda  C<< <takeda.akihito@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Akihito Takeda C<< <takeda.akihito@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


