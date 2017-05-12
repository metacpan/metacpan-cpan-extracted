package Test::FIT;
$VERSION = '0.11';
@EXPORT = qw(attribute);
use strict;
use base 'Exporter';

sub attribute {
    my $attribute = shift;
    my $pkg = caller;
    no strict 'refs';
    *{"${pkg}::$attribute"} = 
      sub {
          my $self = shift;
          return $self->{$attribute} unless @_;
          $self->{$attribute} = shift;
          return $self;
      };
}

1;

__END__

=head1 NAME

Test::FIT - A FIT Test Framework for Perl

=head1 SYNOPSIS

    http://fit.c2.com

=head1 DESCRIPTION

FIT stands for "Framework for Interactive Testing". It is a testing
methodology invented by Ward Cunningham, and is fully described at
http://fit.c2.com.

Test::FIT is a Perl implementation of this methodology. It provides a
web based test harness that lets you run FIT test pages against Test
Fixture Classes which you write as simple Perl modules. The Fixture
modules are generally simple to write because they inherit functionality
from Test::FIT::Fixture.

=head1 SETUP

Test::FIT requires a web server. For the purposes of this explanation,
I'll assume you want to install your FIT tests in C</usr/local/fit> and
that you are using the Apache web server. We'll also assume you are
running on a Unix variant operating system.

=head2 Creating a FIT directory

To make the FIT web directory, do this:

    mkdir /usr/local/fit

You can put your various FIT test suites into various subdirectories
under this directory. For simplicity, FIT-Test comes with an example FIT
test directory. We'll install this as:

    /usr/local/fit/example/

=head2 Installing the example code

After installing Test-FIT follow these steps:

    # You should have already done the first two steps :)
    # tar xvzf Test-FIT-#.##.tar.gz
    # cd Test-FIT-#.##
    cp -r example /usr/local/fit
    cd /usr/local/fit/example
    mv MathFixture.pm.xxx MathFixture.pm
    mv SampleFixture.pm.xxx SampleFixture.pm 
    fit-run.cgi --setup

=head2 Apache Configuration

Put this block into your C<httpd.conf> and (re)start your Apache server:

    Alias /fit/ /usr/local/fit/
    <Directory /usr/local/fit/>
        Order allow,deny
        Allow from all
        Options ExecCGI FollowSymLinks Indexes
        AddHandler cgi-script .cgi
        DirectoryIndex index.html
    </Directory>

=head2 Trying it out

Point you browser at http://your-domain-name/fit/example/

You should see the test page with the fixture tables. Click on the
hyperlink to run the tests. You should see the table cells turn
different colors depending on the test results.

If you are having trouble installing the example and just want to see what
it really should look like, I have the example installed at:

http://fit.freepan.org/Test-FIT/example/

NOTE: I am providing this link as a convenience. I may decide not to run
      it at some point. This link may not exist anymore by the time you
      read this. Please do NOT email me if it doesn't work!

=head1 The Test Document

FIT Tests are specified in HTML tables. You can create them with any
program that can produce HTML with tables (including, of course, a plain
text editor). I personally use the Mozilla Composer wysiwyg editor that
comes for free with Mozilla. You can also create Test Documents in
spreadsheet applications that export to HTML.

Possibly, the simplest way to do this is to use wiki software that
allows you to create simple html tables. I plan on writing something to
do this soon. Ward Cunningham has also set up L<http://fit.c2.com> to do
this, but it is currently a password protected site.

There is plenty of information on how to set up Test Documents at
L<http://fit.c2.com>.

The file <example/index.html> is a sample Test Document to get you started.

=head1 Creating Fixture Modules

A Fixture is just FIT terminology for a Perl class (or module). The
Fixture is designed to perform certain tests. The Fixture must be a
subclass of Test::FIT::Fixture. 

Generally a Fixture will contain a method for each named test in a Test
Document table.

Here is a sample HTML table (in a wiki/ascii representation):

    == My Simple Math Test ==
    
    | MathFixture          |
    | x  | y  | sum | diff |
    | 1  | 2  | 3   | -1   |
    | -8 | 12 | 4   | -4   |
    
    Click [[fit-run.cgi here]] to run the tests.

The first row names the Fixture to be used. In this case,
C<MathFixture>. The second row lists all of the methods that will be
called. The implementation of C<MathFixture.pm> might look like this:

    package MathFixture;
    use base 'Test::FIT::ColumnFixture';
    use Test::FIT;
 
    attribute('x');
    attribute('y');
 
    sub sum {
        my $self = shift;
        $self->eq_num($self->x + $self->y);
    }
 
    sub diff {
        my $self = shift;
        $self->eq_num($self->x - $self->y);
    }
 
    1;

If you were to run this test, you would see that three of the table
cells would turn green (passed), and one would turn red (failed). The
cells under C<x> and C<y> would remain white, because they are just
data values.

=head1 The CGI program

When you installed Test::FIT you also installed a small perl script
called C<fit-run.cgi>. This script should be in your Perl C<sitebin>
directory, which should be in your path. 

Generally you will symlink to this script from whatever test directory you are using. The easy way is:

    cd /usr/local/fit/mytest
    fit-run.cgi --setup

The C<--setup> option will create the symlink for you. If this doesn't
work properly just do:

    cd /usr/local/fit/mytest
    ln -s `which fit-run.cgi` fit-run.cgi

All you need to do to run this CGI is to link to it from your HTML Test
Document. C<fit-run.cgi> will look at the C<referer> and read in the
Test Document, process it against the fixtures, and markup the original
HTML with colors and possibly error messages. 

Simply brilliant, Mr. Cunningham!

=head1 SEE ALSO

See Also:

=over 4

=item * fit-run.cgi

The cgi program for running fit tests.

=item * Test::FIT::Fixture

The base class for all Fixture classes. This documentation explains all
of the methods that you inherit into your Fixture Class.

=item * Test::FIT::ColumnFixture

The base class for your column oriented test fixtures. Inherits from
Text::FIT::Fixture. This documentation will show you how to create a
Column Fixture Class.

=item * http://fit.c2.com

The FIT homepage.

=back

=head1 BUGS & DEFICIENCIES

This is the maiden voyage of Test::FIT. Use it. Have fun. Look at the
pretty colors. But EXPECT CHANGE. FIT itself is still being designed.
THINGS WILL CHANGE.

This version of Test::FIT only has a ColumnFixture. The RowFixture and
ActionFixture will be added soon.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

The FIT architecture was invented by Ward Cunningham <ward@c2.com>

=head1 COPYRIGHT NOTE

The FIT project requests that all implementations be licensed under the
GPL version 2 or higher. Test-FIT respects that request by shipping
under "The same terms as Perl itself" which includes your choice of
either the Artistic or GPL licenses.

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.gnu.org/licenses/gpl.html>

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
