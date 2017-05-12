use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Auction::Bid',
    'VERSION_FROM'      => 'Bid.pm', # finds $VERSION
    'PREREQ_PM'         => {
                             'Test::More'   => 0.17,
                             'Date::Simple' => 1.03,
                             'Auction::Lot' => 1.00,
                             'Class::DBI'   => 0.27,
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Bid.pm', # retrieve abstract from module
       AUTHOR     => 'mwk <coder@stray-toaster.co.uk>') : ()),
);

