use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Test::WWW::Mechanize::HSS',
    'VERSION_FROM'  => 'lib/Test/WWW/Mechanize/HSS.pm', # finds $VERSION
    'PREREQ_PM'    => {
                       'parent' => 0.218,
		       'HTTP::Server::Simple' => 0.00,
		       'Test::WWW::Mechanize' => 1.16, # for submit_form_ok
		       'WWW::Mechanize' => 1.50,  # because of changes to authentication
		       'LWP::UserAgent' => 5.815, # because of changes to authentication
                      },
    'ABSTRACT_FROM' => 'lib/Test/WWW/Mechanize/HSS.pm', # retrieve abstract from module
    'AUTHOR'        => 'Max Maischein <corion@cpan.org>',
);

# To make Test::Prereq happy
1;
