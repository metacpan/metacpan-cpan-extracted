#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Differences;
use WWW::Mediawiki::Client;
use Data::Dumper;
chdir "t/files";
if (-e WWW::Mediawiki::Client->CONFIG_FILE) {
    plan tests => 23;
} else {
    plan skip_all => 'Must configure a local Mediawiki server '
                   . 'to run server tests';
}

# To run these tests you should get a copy of Mediawiki and set it up under
# Apache running locally.  Then copy t/files/example.mediawiki to
# t/files/.mediawiki and edit it with your host name, login and password.

# Our test Wiki page
my $WIKIDATA = q{==Test Page==

This is a test page created by WWW::Mediawiki::Client, the Perl client
library for Mediawiki servers.

Should this page appear on a real live Mediawiki installation it is usually
safe to delete.

For more info on WWW::Mediawiki::Client see [http://www.wikitravel.org/User:Mark/WWW-Mediawiki-Client].  The Client library is available for download at CPAN.};

# load the test data
undef $/;
open(IN, WWW::Mediawiki::Client->CONFIG_FILE);
my $Conf = <IN>;
close IN;
$/= "\n";

# Make a test directory
my $Testdir = '/tmp/mvsservertest.' . time;
mkdir $Testdir
        or die "Could not make $Testdir.  Check the permissions on /tmp.";
my $Alttestdir = '/tmp/altmvsservertest.' . time;
mkdir $Alttestdir
        or die "Could not make $Alttestdir.  Check the permissions on /tmp.";
my $Cleantestdir = '/tmp/cleanmvsservertest.' . time;
mkdir $Cleantestdir
        or die "Could not make $Cleantestdir.  Check the permissions on /tmp.";
chdir $Testdir;
# Copy the conf file
open(OUT, '>' . WWW::Mediawiki::Client->CONFIG_FILE) 
        or die "Cannot open conf file for writing";
print OUT $Conf;
close OUT;

# create a client and load the conf file
my $mvs = WWW::Mediawiki::Client->new();
$mvs->load_state;
my $host = $mvs->host;
my $path = $mvs->wiki_path;
my $username = $mvs->username;
my $password = $mvs->password;

# Make a User test dir
my $Testuser = $mvs->username;
my $Userdir = "User:$Testuser";
my $Testuserdir = "$Userdir/Test";
mkdir "$Testdir/$Userdir" or die "Cannot make directory $Userdir";
mkdir "$Testdir/$Testuserdir" or die "Cannot make directory $Testuserdir";
my $Testfile = "$Testuserdir/Test_page" . time . ".wiki";
open (OUT, ">$Testdir/$Testfile") or die "Cannot open $Testfile for writing.";
print OUT $WIKIDATA;
close OUT;


# FUNCTION TESTS:
# Test do_login for the correct cookie file
ok(eval { $mvs->do_login }, 'Am able to login to the configured server.');
if ($@ && UNIVERSAL::isa($@, 'WWW::Mediawiki::Client::LoginException')) {
    diag("Error Message:\n" . $@->error);
    diag("\nServer Response:\n" . Dumper($@->res));
    diag("\nCookies\n:" . $@->cookie_jar->as_string);
};
ok(eval { $mvs->do_li }, '... and the alias works');
$mvs->host('www.example.com');
eval { $mvs->do_login };
isa_ok($@, 'WWW::Mediawiki::Client::LoginException', 
        '... and login throws an exception if the host is not a Mediawiki host');
$mvs->host($host);
ok(eval { $mvs->do_li }, '... and we can set it back again, and it works.');
$mvs->username('');
$mvs->password('foo');
eval { $mvs->do_login };
isa_ok($@, 'WWW::Mediawiki::Client::LoginException', 
        '... and login throws an exception if the username and password are bad');

# Test with a file that does not exist, either here or on the server
$mvs = WWW::Mediawiki::Client->new();
$mvs->load_state;
eval { $mvs->do_login };
my $nosuchfile = 'apoaijselknaeroinqweproiuqwrehasdfnfuwreg.wiki';
is($mvs->do_update($nosuchfile)->{$nosuchfile}, 
        WWW::Mediawiki::Client::STATUS_UNKNOWN,
        'Update returns correct status for totally new file');

# Test do_update with new local file
$mvs = WWW::Mediawiki::Client->new();
$mvs->load_state;
eval { $mvs->do_login };
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_LOCAL_ADDED,
        'Update returns correct status for new local file');

# Test do_commit with same new local file
eval { $mvs->do_commit($Testfile) };
isa_ok($@, 'WWW::Mediawiki::Client::CommitMessageException',
       'Do we get an exception trying to commit without a message?'); 
$mvs->commit_message('testing commit with new page');
ok($mvs->do_commit($Testfile), '... and does it work after we supply one?');
# Test get_server_page to see if we get the same data back
my $pagename = $mvs->filename_to_pagename($Testfile);
eq_or_diff($mvs->get_server_page($pagename), $WIKIDATA,
        '... and did it really result in the right data going onto the page?');

# do_update with a new file and then delete it
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_UNCHANGED,
        '... and when we do update with the same file, the status should be
        unchanged');

unlink $Testfile;
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_SERVER_MODIFIED,
        '... then after deleting the file it should show up as server modified');

# Test do_update again, this time to see if the file is downloaded correctly
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_UNCHANGED,
        '... and since the last update got the server version another one
        should report unchanged.');

# Modify the file with some text which is *not* going to be interpolated
open (OUT, ">>$Testfile");
print OUT qq{
==Local change test==

Testing the ability to detect local changes.
};
close OUT;
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_LOCAL_MODIFIED,
        '... then after changing the file it should show up as locally modified');

# do_commit to save the modifications
ok($mvs->do_commit($Testfile), '... and can we save our modifications?');
# Test do_update again, this time to see if the file is downloaded correctly
is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_UNCHANGED,
        '... and since the commit put our version on the server do_update
        should report unchanged.');

chdir $Alttestdir;
# Copy the conf file
open(OUT, '>' . WWW::Mediawiki::Client->CONFIG_FILE) 
        or die "Cannot open conf file for writing";
print OUT $Conf;
close OUT;

is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_SERVER_MODIFIED,
        'Starting in a new directory the test page should be server modified.');
open (OUT, ">>$Testfile");
print OUT qq{

==Server change test==

Testing the ability to detect server changes.
2
3
5
};
close OUT;
# do_commit to save the modifications
$mvs->commit_message('modifications from altdir');
ok($mvs->do_commit($Testfile), '... and can we save our modifications?');

# Let's test conflicts
chdir $Testdir;
open (OUT, ">>$Testfile");
print OUT qq{

==Server change test==

Resting with ability to detect conflicting server changes.
5
3
2
};
close OUT;
$mvs->commit_message('testing_conflicting_commit');
eval { $mvs->do_commit($Testfile) };
isa_ok($@, 'WWW::Mediawiki::Client::UpdateNeededException',
        '... in other dir, commit should refuse to work before update.');

is($mvs->do_update($Testfile)->{$Testfile}, WWW::Mediawiki::Client::STATUS_CONFLICT,
        '... and when we do the update there should be a conflict');


# See what happens if you try to commit a page in the Special namespace
my $special_page = 'Special:Shouldnotbeapage.wiki';
open (OUT, ">$special_page");
print OUT q{
This page should not exist, and should cause an error if we run do_commit
on it.
};
close OUT;
eval { $mvs->do_commit($special_page) };
isa_ok($@, 'WWW::Mediawiki::Client::ServerPageException',
        'do_commit should refuse to update a Special page, throwing an
        exception');

# let's start with a clean directory now and try to login from scratch and
# check some stuff out
chdir $Cleantestdir;
$mvs = WWW::Mediawiki::Client->new;
$mvs->host($host);
$mvs->wiki_path($path);
$mvs->username($username);
$mvs->password($password);
ok($mvs->do_login, 'Can log in with a new client without conf file.');
ok(-e WWW::Mediawiki::Client->CONFIG_FILE, 
        '... which results in a new conf file being written.');

1;

__END__

# vim:syntax=perl:
