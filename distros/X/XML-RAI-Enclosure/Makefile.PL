use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'         => 'XML::RAI::Enclosure',
  'VERSION_FROM' => 'Enclosure.pm', 
  'AUTHOR'       => 'Josh McAdams <me at joshmcadams dot com>',
  'ABSTRACT'     => 'An extension to the XML::RAI suite of modules that adds support for enclosures',
  'PREREQ_PM'    => {
    'XML::RAI' => 0,
  },
);

