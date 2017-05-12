use ExtUtils::MakeMaker;

# Write the makefile
WriteMakefile(
    'NAME'      => 'XML::Table2XML',
    'VERSION_FROM' => 'Table2XML.pm', # finds $VERSION

    'PREREQ_PM' => {
        Encode => 0,
        Test::More => 0,
        Test::XML => 0,
        Test::Exception => 0,
       },
    'dist'      => { COMPRESS => "gzip -9f" },
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'Table2XML.pm',
         AUTHOR     => 'Roland Kapl') : ()),
);
