#!/usr/bin/perl 

use strict; 
use warnings; 

use Test::More; 
use WebService::Face::Client; 
use JSON;

unless ( $ENV{FACE_API_KEY} && $ENV{FACE_API_SECRET}) {
    warn("\n\nSet FACE_API_KEY, FACE_API_SECRET for testing\n\n");
    plan skip_all => ' Set environment vars for API access';
}

plan tests => 42;

my $client;
eval { $client = WebService::Face::Client->new() };
ok( !$@, "new()" );

isa_ok( $client, 'WebService::Face::Client' );

########################################################################
#                   Tag API
########################################################################

# Check for lowlevel API methods availability
can_ok( $client, "faces_detect" );
my @tags = $client->faces_detect(
        { urls => "http://face.com/img/faces-of-the-festival-no-countries.jpg" }
   );
is( $#tags, 15, "16 tags retrieved" );
my $tag = shift @tags;

isa_ok( $tag, 'WebService::Face::Response::Tag' );
can_ok( $tag, "width" );
is( $tag->width, '11.09', 'check for width value' );
can_ok( $tag, "height" );
is( $tag->height, '11.13', 'check for height value' );
can_ok( $tag, "center" );
is_deeply(
    $tag->center,
    { y => '90.05', x => '5.91' },
    'check for center value'
);
can_ok( $tag, "eye_left" );
is_deeply(
    $tag->eye_left,
    { y => '87.15', x => '3.43' },
    'check for eye_left value'
);
can_ok( $tag, "eye_right" );
is_deeply(
    $tag->eye_right,
    { y => '87.56', x => '7.88' },
    'check for eye_right value'
);
can_ok( $tag, "mouth_left" );
is_deeply(
    $tag->mouth_left,
    { y => '92.91', x => '2.77' },
    'check for mouth_left value'
);
can_ok( $tag, "mouth_center" );
is_deeply(
    $tag->mouth_center,
    { x => '4.23', y => '93.06' },
    'check for center value'
);
can_ok( $tag, "mouth_right" );
is_deeply(
    $tag->mouth_right,
    { x => '6.42', y => '93.21' },
    'check for mouth_right value'
);
can_ok( $tag, "nose" );
is_deeply( $tag->nose, { x => '4.05', y => '90.29' }, 'check for nose value' );
can_ok( $tag, "yaw" );
is( $tag->yaw, '19.14', 'check for yaw value' );
can_ok( $tag, "pitch" );
is( $tag->pitch, '-1.68', 'check for pitch value' );
can_ok( $tag, "roll" );
is_deeply( $tag->roll, '7.92', 'check for roll value' );
can_ok( $tag, "attributes" );

is_deeply(
    $tag->attributes,
    {
        'face'    => { 'value' => 'true',  'confidence' => 97 },
        'smiling' => { 'value' => 'false', 'confidence' => 90 },
        'glasses' => { 'value' => 'false', 'confidence' => 98 },
        'gender'  => { 'value' => 'male',  'confidence' => 89 }
    },
    'check for attributes value'
);
can_ok( $tag, "gender" );
is( $tag->gender, undef, 'check for gender value' );
can_ok( $tag, "smiling" );
is( $tag->smiling, undef, 'check for smiling value' );
can_ok( $tag, "mood" );
is( $tag->mood, undef, 'check for mood value' );
can_ok( $tag, "lips" );
is( $tag->lips, undef, 'check for lips value' );
can_ok( $tag, "face" );
is( $tag->face, undef, 'check for face value' );
can_ok( $tag, "tid" );
