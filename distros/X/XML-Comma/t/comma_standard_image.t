use strict;

use lib ".test/lib/";
use XML::Comma;

#make sure to override the image cache!
XML::Comma::Configuration->_set("tmp_directory", ".test/tmp");

use Test::More;
eval {
  require Imager;
}; if($@) {
  my $mod = $@;
  $mod =~ s/^Can't locate (\S+)\.pm in.*/$1/;
  $mod =~ s/\//::/g;
  chomp($mod);
  $mod ||= "Imager";
  plan skip_all => "$mod not installed";
} else {
  if($Imager::formats{png} && $Imager::formats{jpeg}) {
    plan 'no_plan';
  } else {
    plan skip_all => "I need Imager built with libjpeg and libpng support";
  }
}

#some trivial image specs: $width, $height, @rgb
#TODO: the averages we get here are not necessarily right or 
#  always the same across different versions of libjpeg, giflib, etc.
#  think of a better way to test this stuff...
#TODO: test a more complicated image such that truecolor vs. indexed
#  makes a difference...
#TODO: test bmp
#TODO: test high-quality vs. low quality jpeg thumbnails somehow
my @images = (
  {
    spec => "2,2,255,255,255,0,0,0,255,0,0,0,0,255",
    format => "png",
    avg_color => "128,64,128",
    thumb_format => "png",
  },
  {
    spec => "2,2,255,255,255,0,0,0,255,0,0,0,0,255",
    format => "png",
    avg_color => "128,63,127", #jpeg is different from png here!
  },
  {
    spec => "2,2,255,255,255,0,0,0,255,0,0,0,0,255",
    format => "bmp",
    avg_color => "128,64,128",
    thumb_format => "png",
  },
  {
    spec => "1,3,255,255,255,255,255,255,255,255,255",
    format => "png",
    avg_color => "255,255,255",
    thumb_format => "png",
  },
  {
    spec => "1,3,255,255,255,255,255,255,255,255,255",
    format => "png",
    avg_color => "255,255,255", #jpeg gets this right
    thumb_format => "jpeg",
  },
);
if($Imager::formats{gif}) {
  push @images, {
    spec => "1,3,255,255,255,255,255,255,255,255,255",
    format => "png",
    avg_color => "255,255,255",
    thumb_format => "gif",
  },
} else {
  warn "Imager was build without giflib support, skipping gif tests\n";
}

my $tmp_img_path = ".test/tmp_image";
foreach my $img_spec (@images) {
  #build image in memory
  my @spec = split(/,/, $img_spec->{spec});
  my $width  = shift(@spec);
  my $height = shift(@spec);
  die "invalid spec" unless($width * $height * 3 == scalar @spec);
  my $img = Imager->new(xsize=>$width, ysize=>$height);
  foreach my $x (0..$img->getwidth-1) {
    foreach my $y (0..$img->getheight-1) {
      my $color = Imager::Color->new(shift(@spec), shift(@spec), shift(@spec));
      $img->setpixel(x=>$x, y=>$y, color => $color) or die $img->errstr;
    }
  }
  my $raw;
  $img->write(data => \$raw, type => $img_spec->{format}) or die $img->errstr;
  open(my $f, ">$tmp_img_path") || die "can't open tmp image $tmp_img_path for write: $!";
  print $f $raw;
  close($f);
  open(my $img_fh, $tmp_img_path) || die "can't open tmp image $tmp_img_path for read: $!";

  #generate checksum
  my $md5 = Digest::MD5->new();
  $md5->add ( $raw );
  my $checksum = $md5->hexdigest();

  # test set with a scalar, and set_from_file with a filename or filehandle
  for my $set_method qw ( set:raw set_from_file:tmp_img_path set_from_file:img_fh ) {
    my $d = XML::Comma::Doc->new(type => "Comma_Standard_Image");
    ok($d);

    #set up the image
    my ($method, $data) = split(/:/, $set_method);
    $d->element("image")->$method(eval '$'.$data);
    ok($d->image);

    #make sure everything is as expected
    ok($d->image->image_dimensions eq "${width}x${height}");
    ok($d->image->image_content_type eq "image/".$img_spec->{format});
    ok($d->image->image_checksum eq $checksum);
    ok($d->image->image_extension eq '.' . $img_spec->{format});

    #make sure checksums are the same when called with specs that are
    #the same...
    ok($d->image->image_checksum eq
         $d->image->get_thumb(width => $width,
           format => $img_spec->{format})->image->image_checksum);
    ok($d->image->image_checksum eq
         $d->image->get_thumb(height => $height,
           format => $img_spec->{format})->image->image_checksum);
    ok($d->image->image_checksum eq
         $d->image->get_thumb(scale => 1,
           format => $img_spec->{format})->image->image_checksum);

    #TODO: test max_dim, scale arguments to get_thumb as well
    #set up arguments for ->get_thumb call
    my %args = ( width => 1, height => 1 );
    $args{format} = $img_spec->{thumb_format} if($img_spec->{thumb_format});

    #expected format and content types to get from get_thumb's result
    my $expected_thumb_fmt = $img_spec->{thumb_format} || "jpeg";
    my $expected_thumb_ct = "image/$expected_thumb_fmt";
    #munge to the format that will come out of CSI->image_extension
    $expected_thumb_fmt = "jpg" if($expected_thumb_fmt eq "jpeg");

    #call get_thumb, make sure something valid comes back
    my $one_px_thumb_doc = $d->image->get_thumb(%args);
    ok($one_px_thumb_doc);
    ok($one_px_thumb_doc->isa("XML::Comma::Doc"));

    my $one_px_thumb_blob = $one_px_thumb_doc->image->get();

    #make sure we got the right type of image back (usu. jpeg), and
    #check the corresponding content_type (via Def->method calls)
    my $extension = XML::Comma::Def->Comma_Standard_Image->
      image_extension($one_px_thumb_blob);
    ok( $extension eq ('.' . $expected_thumb_fmt) );
    #sanity check we get the same extension from the blob as the image doc
    ok( $extension eq $one_px_thumb_doc->image->image_extension);
    #check the content type
    ok( XML::Comma::Def->Comma_Standard_Image->
        image_content_type($extension) eq $expected_thumb_ct );
    #sanity check the content type
    ok( XML::Comma::Def->Comma_Standard_Image->
        image_content_type($extension) eq
        $one_px_thumb_doc->image->image_content_type );

    #pull this image into Imager so we can see what the average color is
    my $one_px_thumb_img = Imager->new();
    $one_px_thumb_img->read(data => $one_px_thumb_blob);
    ok($one_px_thumb_img->getwidth);

    my $got = join(",", ($one_px_thumb_img->getpixel(x=>0, y=>0)->rgba())[0..2]);
    my $expected = $img_spec->{avg_color};
    warn "thumbnail error: got: $got, expected: $expected" if($got ne $expected);
    ok($got eq $expected);

    #and of course test the width and height of the one pixel image
    ok($one_px_thumb_img->getwidth  == 1);
    ok($one_px_thumb_img->getheight == 1);

    undef $d;
  }
  close($img_fh);
}


