use inc::Module::Install 0.87;

name('Time-NT');
abstract('Convert NT System Time to Unix Timestamp and vice versa');
author('Jason Fried <fried@cpan.org>');
version_from('lib/Time/NT.pm');
license('perl');
test_requires 'Test::More' => '0.47';
repository 'http://github.com/fried/Time-NT';
WriteAll;
