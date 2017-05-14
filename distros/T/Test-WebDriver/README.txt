Useful Perl style test functions for WebDriver!

Requires Selenium::Remote::Driver

To install: cpanm Test::WebDriver
Alternately: perl Makefile.PL ; make install

For Best Practice - I recommend subclassing Test::WebDriver for your application,
and then refactoring common or app specific methods into MyApp::WebDriver so that
your test files do not have much duplication.  As your app changes, you can update
MyApp::WebDriver rather than all the individual test files.

