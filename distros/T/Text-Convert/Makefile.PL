use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'        => 'Simple Text to Image Conversion Tool',
    NAME              => 'Text::Convert::ToImage',
    VERSION_FROM      => 'lib/Text/Convert/ToImage.pm', # finds $VERSION
    PREREQ_PM         => 
        {
            "Image::Magick" => 5.44,
        }, # e.g., Module::Name => 1.1
    ($] >= 5.006 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Harry Jackson <harry@hjackson.org>') : ()),
);
