use strict;
use Test::More;

use XML::LibXML;
use WebService::Riya;

my $api_key   = '';
my $user_name = '';
my $password  = '';

unless ($api_key and $user_name and $password) {
    Test::More->import(skip_all => "requires user_name, password and api_key, skipped.");
    exit;
}

plan tests => 28;

my $xml = XML::LibXML->new();

my $api = WebService::Riya->new(
    api_key   => $api_key,
    user_name => $user_name,
    password  => $password,
);

$api->debug(0);

my $response;
my $image_id;

SKIP: {
skip 'an error of Invalid API Key always occurred.';
$response = $api->call_method('riya.photos.upload.UploadPhoto', {
    photo  => ['t/me.jpg'],
    access => 'private-access',  # public-access/private-access
});
is $api->status, 1;
diag $response;

my $doc = $xml->parse_string($response);
$image_id = $doc->findvalue("//*[local-name()='image_id']");

skip 'an error of Invalid API Key always occurred.';
$response = $api->call_method('riya.photos.ChangePhotoPermission', {
    image_id => $image_id,
    access   => 'public-access',
});
is $api->status, 1;
diag $response;
};

$response = $api->call_method('riya.photos.DeletePhoto', {
    image_id => $image_id,
});
SKIP: {
skip 'Does riya.photos.DeletePhoto work fine?';
is $api->status, 1;
diag $response;
};

$response = $api->call_method('riya.photos.faces.AddFace', {
    image_id => $image_id,
    x => '0',
    y => '25',
    w => '50',
    h => '50',
});
is $api->status, 1;

my $doc = $xml->parse_string($response);
my $face_id = $doc->findvalue("//*[local-name()='face']/\@id");

$response = $api->call_method('riya.photos.faces.GetFaceList', {
    image_id => $image_id,
});
is $api->status, 1;

$response = $api->call_method('riya.photos.faces.IdentifyFace', {
    image_id => $image_id,
    face_id   => $face_id,
    full_name => 'Foo Bar',
});
SKIP: {
skip 'Does riya.photos.faces.IdentityFace work fine?';
is $api->status, 1;
};
is $response, '';

$response = $api->call_method('riya.photos.faces.RemoveFace', {
    image_id => $image_id,
    face_id   => $face_id,
});
SKIP: {
skip 'Does riya.photos.faces.RemoveFace work fine?';
is $api->status, 1;
diag $response;
};
is $response, '';

$response = $api->call_method('riya.photos.overlays.AddOverlay', {
    image_id => $image_id,
    x => '0',
    y => '0',
    w => '50',
    h => '50',
});
is $api->status, 1;

$response = $api->call_method('riya.photos.overlays.GetOverlayList', {
    image_id => $image_id,
});
is $api->status, 1;

$doc = $xml->parse_string($response);
my @nodes = $doc->findnodes("//*[local-name()='overlay']");

$response = $api->call_method('riya.photos.overlays.EditOverlay', {
    image_id => $image_id,
    overlay_id => $nodes[0]->findvalue("\@id"),
    tag        => 'DogTag',
});
SKIP: {
skip 'Does riya.photos.overlays.EditOverlay work fine?';
is $api->status, 1;
diag $response;
};
is $response, '';

$response = $api->call_method('riya.photos.overlays.RemoveOverlay', {
    image_id => $image_id,
    overlay_id => $nodes[0]->findvalue("\@id"),
});
SKIP: {
skip 'Does riya.photos.overlays.RemoveOverlay work fine?';
is $api->status, 1;
diag $response;
};
is $response, '';

$response = $api->call_method('riya.photos.tags.AddTag', {
    image_id => $image_id,
    tag      => 'Fun',
});
is $api->status, 1;

$doc = $xml->parse_string($response);
my $tag_id = $doc->findvalue("//*[local-name()='tag']/\@id");

$response = $api->call_method('riya.photos.tags.GetTagList', {
    image_id => $image_id,
});
is $api->status, 1;

$response = $api->call_method('riya.photos.tags.RemoveTag', {
    image_id => $image_id,
    tag_id   => $tag_id,
});
SKIP: {
skip 'riya.photos.tags.RemoveTag is NOT work? Response is empty.';
is $api->status, 1;
diag $response;
};
is $response, '';

$response = $api->call_method('riya.photos.comments.AddComment', {
    image_id => $image_id,
    comment  => 'this is good',
});
is $api->status, 1;

$doc = $xml->parse_string($response);
my $comment_id = $doc->findvalue("//*[local-name()='comment']/\@id");

$response = $api->call_method('riya.photos.comments.GetCommentList', {
    image_id => $image_id,
});
is $api->status, 1;

$response = $api->call_method('riya.photos.comments.RemoveComment', {
    image_id => $image_id,
    comment_id  => $comment_id,
});
SKIP: {
skip 'riya.comments.RemoveComment is NOT work? Response is empty.';
is $api->status, 1;
diag $response;
};
is $response, '';

$response = $api->call_method('riya.contacts.GetContactList');
is $api->status, 1;

TODO: {
local $TODO = 'riya.contacts.GetFaceShots is hard.';
$response = $api->call_method('riya.contacts.GetFaceShots', {
#    full_name => 'Takatsugu Shigeta',
}); 
is $api->status, 1;
};

$response = $api->call_method('riya.albums.GetAlbums');
is $api->status, 1;

$doc = $xml->parse_string($response);
my @albums = $doc->findnodes("//*[local-name()='album']");

$response = $api->call_method('riya.albums.GetPhotosInAlbum', {
    album_id => $albums[0]->findvalue("\@id"),
});
is $api->status, 1;

$response = $api->call_method('riya.photos.search.SearchPublic', {
    tags => 'hatena',
});
is $api->status, 1;

$response = $api->call_method('riya.photos.search.Search', {
    tags   => 'feedburner',
    bucket => 'my-photos',
});
is $api->status, 1;
