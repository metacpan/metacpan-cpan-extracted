#!perl -T

# Test all class methods

use Test::More;
use File::Slurp;
use_ok( 'WWW::Phanfare::Class' );
use lib 't';
use_ok( 'FakeAgent' );

my $class;
if ( $ENV{SITE} ) {
  # Create test object on live site
  my %config;
  eval '
    use Config::General;
    use File::HomeDir;
    use WWW::Phanfare::API;
    my $rcfile = File::HomeDir->my_home . "/.phanfarerc";
    %config = Config::General->new( $rcfile )->getall;
    die unless $config{api_key}
           and $config{private_key}
           and $config{email_address}
           and $config{password};
  ';
  plan skip_all => "Local config not found: $@" if $@;
  $class = new_ok( 'WWW::Phanfare::Class' => [ %config ] );

} else { 
  # Create an fake test object
  $class = new_ok( 'WWW::Phanfare::Class' => [ 
    api_key       => 'secret',
    private_key   => 'secret',
    email_address => 's@c.et',
    password      => 'secret',
  ] );
  $class->api( FakeAgent->new() );
}

isa_ok( $class, 'WWW::Phanfare::Class' );

# Verify there is account
ok( my $account = $class->account(), "Class has account" );
isa_ok( $account, 'WWW::Phanfare::Class::Account' );

# Verify there is a site
ok( my($sitename) = $account->names, "Class has sites" );
ok( my $site = $account->$sitename, "Class has site object" );
isa_ok( $site, 'WWW::Phanfare::Class::Site' );

# Verify there are years
ok( my($yearname) = $site->names, "Class has years" );
ok( my $year = $site->$yearname, "Class has year object" );
isa_ok( $year, 'WWW::Phanfare::Class::Year' );

# Verify there are albums
ok( my($albumname) = $year->names, "Class has an album" );
ok( my $album = $year->$albumname, "Class has album object" );
isa_ok( $album, 'WWW::Phanfare::Class::Album' );

# Verify there are sections
ok( my($sectionname) = $album->names, "Class has sections" );
ok( my $section = $album->$sectionname, "Class has section object" );
isa_ok( $section, 'WWW::Phanfare::Class::Section' );

# Verify there are renditions
ok( my($renditionname) = $section->names, "Class has renditions" );
ok( my $rendition = $section->$renditionname, "Class has section object" );
isa_ok( $rendition, 'WWW::Phanfare::Class::Rendition' );

# Verify there are images
ok( my @imagenames = $rendition->names, "Class has images" );
my $imagename = shift @imagenames;
ok( my $image = $rendition->$imagename, 'Class has image object' );
isa_ok( $image, 'WWW::Phanfare::Class::Image' );

diag "Test Year: $yearname\n";
diag "Test Album: $albumname\n";
diag "Test Section: $sectionname\n";
diag "Test Image: $imagename\n";

# Make sure all image filenames are different
my %U;
my @uniqnames = grep { ! $U{$_}++ } @imagenames;
ok( scalar @uniqnames == scalar @imagenames, "All image names are unique: @imagenames" );

# Create, read and delete a year
my $newyear = '1999';
ok( ! grep(/$newyear/, $site->names), "Year $newyear doesn't yet exist" );
ok( $site->add( $newyear ), "Year $newyear created" );
ok( grep(/$newyear/, $site->names), "Year $newyear now exists" );
ok( $site->remove( $newyear ), "Year $newyear removed" );
ok( ! grep(/$newyear/, $site->names), "Year $newyear no longer exists" );

# Verify that a year with albums cannot be deleted
ok( ! $site->remove( $yearname ), "Year $yearname removed" );

# Create, read and delete an album
my $newalbum = "New Album";
ok( ! grep(/$newalbum/, $year->names), "Album $newalbum doesn't yet exist" );
$year->add( $newalbum );
ok( grep(/$newalbum/, $year->names), "Album $newalbum now exists" );
$year->remove( $newalbum );
ok( ! grep(/$newalbum/, $year->names), "Album $newalbum no longer exists" );

# Create, read and delete a section
my $newsection = 'New Section';
ok( ! grep(/$newsection/, $album->names), "Section $newsection doesn't yet exist" );
ok( $album->add( $newsection ), "Adding section $newsection" );
ok( grep(/$newsection/, $album->names), "Section $newsection now exists" );
$album->remove( $newsection );
ok( ! grep(/$newsection/, $album->names), "Section $newsection no longer exists" );

# Create, read and delete an image
$rendition = $section->WebLarge;
$renditionname = $rendition->name;
my $newimage = 'testimage.png';
my $imagedata = read_file('t/data/testimage.png', binmode => ':raw');
ok( length $imagedata, "Read image file" );

ok( ! grep(/$newimage/, $rendition->names), "Image $newimage doesn't yet exist" );
ok( ! $rendition->add( $newimage, $imagedata ), "Cannot add to $renditionname rendition" );
$rendition = $section->Full;
$renditionname = $rendition->name;
ok( $rendition->add( $newimage, $imagedata, '2009-09-15T00:00:00' ), "Added $newimage to $renditionname rendition" );
ok( grep(/$newimage/, $rendition->names), "Image $newimage now exists" );
$rendition->remove( $newimage );
ok( ! grep(/$newimage/, $rendition->names), "Image $newimage no longer exists" );
ok( ! $rendition->add( $newimage, 'invalid data', '2009-09-15T00:00:00' ), "Invalid added to $renditionname rendition" );

# Some nodes have attributes - some don't
ok(   $account->attributes,   "Album has attributes"     );
ok( ! $site->attributes,      "Site has attributes"      );
ok( ! $year->attributes,      "Year has attributes"      );
ok(   $album->attributes,     "Album has attributes"     );
ok(   $section->attributes,   "Section has attributes"   );
ok( ! $rendition->attributes, "Rendition has attributes" );
ok(   $image->attributes,     "Image has attributes"     );

# Account attributes cannot be set
ok( ! $account->attribute('key', 'new value'), "Account sets key attribute" ) ;

# Album attributes
my $attrkey = 'album_type';
my $attrval = 'Timeless';
ok( my $prevattr =  $album->attribute($attrkey), "Album has $attrkey attribute" ) ;
ok( $album->attribute($attrkey, $attrval ), "Album sets $attrkey attribute" ) ;
ok( $album->attribute($attrkey) eq $attrval , "Album $attrkey attribute is set" ) ;
ok( $album->attribute($attrkey, $prevattr ), "Album restores $attrkey attribute" ) ;
ok( $album->attribute($attrkey) eq $prevattr , "Album $attrkey attribute is restored" ) ;
ok( ! $album->attribute('key'), "Album key attribute is set" ) ;

# Section attributes
$attrkey = 'section_descr';
$attrval = 'Short Description';
$prevattr = $section->attribute($attrkey);
ok ( defined $prevattr, "Section has $attrkey attribute" ) ;
ok( $section->attribute($attrkey, $attrval), "Section sets $attrkey attribute" ) ;
ok( $section->attribute($attrkey) eq $attrval , "Section $attrkey attribute is set" ) ;
ok( defined $section->attribute($attrkey, $prevattr), "Section restores $attrkey attribute" ) ;
ok( $section->attribute($attrkey) eq $prevattr , "Section $attrkey attribute is restored" ) ;
ok( ! $section->attribute('key'), "Section key attribute is set" ) ;

# Image attributes
ok( ! $image->attribute('key'), "Image attribute key does not exist" );
ok( ! $image->attribute('key', 'value'), "Image attribute key cannot be set" );
($attrkey) = grep !/(hidden|caption)/, $image->attributes;
$attrval = $image->attribute( $attrkey );
ok( defined $attrval, "Previous image attribute defined" );
ok( ! $image->attribute( $attrkey, 42 ), "Cannot set any attributes" );
ok( $image->attribute( 'caption', $image->attribute('caption') ), "Set image attribute caption");
ok( defined $image->attribute( 'hidden', $image->attribute('hidden') ), "Set image attribute hidden");

# Create, read and delete a caption
my $caption = "New Caption";
my $prevcap = $image->_caption;
ok( defined $prevcap, "Previous image caption exists" );
ok( $image->_caption( $caption ), "Set new image caption" );
ok( $caption eq $image->_caption, "Read new image caption" );
ok( $image->_caption( $prevcap ), "Restore image caption" );
ok( $prevcap eq $image->_caption, "Image caption is restored" );

# Create, read and delete hide flag
my $prevhide = $image->_hidden;
ok( defined $prevhide, "Previous hide flag exists" );
ok( 1 == $image->_hidden( 1 ), "Set image hide flag 1" );
ok( $image->_hidden == 1, "Get image hide flag 1" );
ok( 0 ==  $image->_hidden( 0 ), "Set image hide flag 0" );
ok( $image->_hidden == 0, "Get image hide flag 0" );
ok( defined $image->_hidden( $prevhide ), "Restore image hide" );
ok( $prevhide == $image->_hidden, "Hide flag resoted" );

# Hide and Caption are really just attributes
ok( $image->attribute('hidden') == $image->_hidden, "Image hide attribute" );
ok( $image->attribute('caption') eq $image->_caption, "Image caption attribute" );

# Image attributes from imageinfo
for $attrkey ( qw(filename image_date is_video) ) {
  ok( defined $image->attribute($attrkey), "Image has image attribute $attrkey" );
}

# Image attributes from rendition
ok( 'http://' eq substr $image->attribute('url'), 0, 7, "url starts with http" );
for $attrkey ( qw(created_date filesize height media_type quality width) ) {
  ok( defined $image->attribute($attrkey), "Image has rendition $attrkey" );
}

done_testing(); exit;
