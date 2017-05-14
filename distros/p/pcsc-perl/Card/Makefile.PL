use ExtUtils::MakeMaker;
# See ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Chipcard::PCSC::Card',
    'VERSION_FROM' => 'Card.pm', # finds $VERSION
);

