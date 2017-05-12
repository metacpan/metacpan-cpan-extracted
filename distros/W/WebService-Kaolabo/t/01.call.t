
use Test::More qw(no_plan);

use WebService::Kaolabo;

my $kaolab = WebService::Kaolabo->new({target_file => 't/sample.jpg'});

is( ref $kaolab , 'WebService::Kaolabo', "new WebService::Kaolabo $WebService::Kaolabo::errstr" );
like( $kaolab->scale( xpixels => 50, ypixels => 50, type => 'max'), '/Imager/',
      "Imager $WebService::Kaolabo::errstr" );

if ( $ENV{KAO_API_KEY} ) {
    $kaolab = WebService::Kaolabo->new({
                                         target_file  => 't/sample.jpg',
                                         apikey       => $ENV{KAO_API_KEY}
                                      });
    ok(  $kaolab->access(), 'WebService::Kaolabo access' );
    $kaolab->face_area();
    $kaolab->unface_area();
    $kaolab->effect_face({type=>'line',color=>'#0000FF'});

    my $face_data = $kaolab->face_data;
    for my $f ( @{$face_data} ){
        ok( $f->{face_x} , 'face_x' );
        ok( $f->{face_y} , 'face_y' );
        ok( $f->{height} , 'height' );
        ok( $f->{width} , 'width' );
        ok( $f->{right_eye_y} , 'right_eye_y' );
        ok( $f->{left_eye_y} , 'left_eye_y' );
    }

    $kaolab->write('t/data.jpg');
}


