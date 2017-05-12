# Authenticate
# Create new album
# Upload image to new album
# Delete image from album
# Delete album

use strict;
use warnings;
use File::Slurp;

use Test::More;

# Make sure we have the auth values to perform a test
#
my %config;
eval '
  use Config::General;
  use File::HomeDir;
  use WWW::Phanfare::API;

  my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
  %config = Config::General->new( $rcfile )->getall;
  die unless $config{api_key} and $config{private_key}
         and $config{email_address} and $config{password};
';
plan skip_all => "Modules or config not found: $@" if $@;

# Create agent
#
my $api = new_ok ( 'WWW::Phanfare::API' => [
  api_key     => $config{api_key},
  private_key => $config{private_key},
] );

# Login
#
my $session = $api->Authenticate(
  email_address => $config{email_address},
  password      => $config{password},
);
ok ( $session->{'stat'} eq 'ok',  'Authenticate: ' . ( $session->{code_value} || '' ) );
ok ( $session->{session}{uid},  'Get target_uid: ' . ( $session->{code_value} || '' ) );
my $target_uid = $session->{session}{uid};
diag "target_uid: $target_uid";

# Create New Album
#
my $album = $api->NewAlbum(
  target_uid => $target_uid,
);
ok ( $album->{'stat'} eq 'ok',  'Create new album: ' . ( $album->{code_value} || '' ) );
ok ( $album->{album}{album_id},  'Get album_id: ' . ( $album->{code_value} || '' ) );
my $album_id = $album->{album}{album_id};
ok ( $album->{album}{sections}{section}{section_id},  'Get section_id: ' . ( $album->{code_value} || '' ) );
my $section_id = $album->{album}{sections}{section}{section_id};
diag "album_id: $album_id";
diag "section_id: $section_id";

# Upload an image to newly created album
#
my $rawimage = read_file('t/testimage.png', binmode => ':raw');
my $image = $api->NewImage(
  target_uid => $target_uid,
  album_id   => $album_id,
  section_id => $section_id,
  filename   => 'testimage.png',
  caption    => 'WWW::Phanfare::API Test Image',
  content    => $rawimage,
  image_date => undef,
  hidden     => 1,
);
ok ( $image->{'stat'} eq 'ok',  'Upload new image ' . ( $image->{code_value} || '' ) );
ok ( $image->{imageinfo}{image_id},  'Get image_id: ' . ( $image->{code_value} || '' ) );
my $image_id = $image->{imageinfo}{image_id};
diag "image_id: $image_id";

# Fetch the image that was uploaded
my $renditions = $image->{imageinfo}{renditions}{rendition};
for my $rendition ( @$renditions ) {
  if ( $rendition->{rendition_type} eq 'Full' ) {
    ok( my $url = $rendition->{url}, "Download url" );
    #diag "image url: $url";
    ok( my $imagefull = $api->geturl( $url ), "Download image from $url" );
    ok( $rawimage eq $imagefull, 'Uploaded and downloaded image is same' );
    last;
  }
}

# Verify that Hide flags are set correctly
# Set Hidden flag
my $hide_image = $api->HideImage(
  target_uid => $target_uid,
  album_id   => $album_id,
  section_id => $section_id,
  image_id   => $image_id,
  hidden       => 1,
);
ok ( $hide_image->{'stat'} eq 'ok',  'Hide image ' . ( $hide_image->{code_value} || '' ) );

# Verify image is hidden
my $hidden = $api->GetAlbum(
  target_uid => $target_uid,
  album_id   => $album_id,
)->{album}{sections}{section}{images}{imageinfo}{hidden};
ok( $hidden == 1, 'Image is Hidden' );

# Set Unset flag
$hide_image = $api->HideImage(
  target_uid => $target_uid,
  album_id   => $album_id,
  section_id => $section_id,
  image_id   => $image_id,
  hidden       => 0,
);
ok ( $hide_image->{'stat'} eq 'ok',  'Hide image ' . ( $hide_image->{code_value} || '' ) );

# Verify image is unhidden
$hidden = $api->GetAlbum(
  target_uid => $target_uid,
  album_id   => $album_id,
)->{album}{sections}{section}{images}{imageinfo}{hidden};
ok( $hidden == 0, 'Image is Unhidden' );

# Delete Image
#
my $del_image = $api->DeleteImage(
  target_uid => $target_uid,
  album_id   => $album_id,
  section_id => $section_id,
  image_id   => $image_id,
);
ok ( $del_image->{'stat'} eq 'ok',  'Delete image ' . ( $del_image->{code_value} || '' ) );

# Delete Album
#
my $del_album = $api->DeleteAlbum(
  target_uid => $target_uid,
  album_id => $album_id,
);
ok ( $del_album->{'stat'} eq 'ok',  'Delete album ' . ( $del_album->{code_value} || '' ) );

done_testing();
