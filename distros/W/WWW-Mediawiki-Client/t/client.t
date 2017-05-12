#!/usr/bin/perl -w

use strict;
use Test::More tests => 102;
use Test::Differences;

use utf8;

BEGIN {
    use_ok('WWW::Mediawiki::Client', ':options');
}

# test the constructor first
my $mvs;
ok($mvs = WWW::Mediawiki::Client->new(host => 'localhost/'), 
        'Can instanciate a WWW::Mediawiki::Client object');

# load the test data
undef $/;
ok(open(IN, "<:utf8", "t/files/paris.html"), 'Can open our test HTML');
my $HtmlData = <IN>;
ok(open(IN, "<:utf8", "t/files/paris.wiki"), 'Can open our test Wiki file');
my $WikiData = <IN>;
ok(open(IN, "<:utf8", "t/files/reference.wiki"), 'Can open the reference Wiki file');
my $RefData = <IN>;
ok(open(IN, "<:utf8", "t/files/local.wiki"), 'Can open the local Wiki file');
my $LocalData = <IN>;
ok(open(IN, "<:utf8", "t/files/server.wiki"), 'Can open the server Wiki file');
my $ServerData = <IN>;
ok(open(IN, "<:utf8", "t/files/merged.wiki"), 'Can open our merged Wiki file');
my $MergedData = <IN>;
close IN;
$MergedData =~ s/^.//;
$/= "\n";
chomp ($RefData, $ServerData, $LocalData, $MergedData);

# make a test repository
my $Testdir = '/tmp/mvstest.' . time;
mkdir $Testdir
        or die "Could not make $Testdir.  Check the permissions on /tmp.";

chdir $Testdir;

# Test the filename method
is($mvs->filename_to_url('San_Francisco.wiki', 'edit'),
        'http://localhost/wiki/index.php?action=edit&title=San_Francisco',
        'Can we convert the filename to the URL?');
$mvs->space_substitute('_');
is($mvs->filename_to_url('San_Francisco.wiki', 'submit'),
        'http://localhost/wiki/index.php?action=submit&title=San_Francisco',
        'Can we convert the filename to the URL?');
eval { $mvs->filename_to_url('/this/is/an/absolute/filename.wiki') };
isa_ok($@, 'WWW::Mediawiki::Client::AbsoluteFileNameException',
        'Does filename_to_url throw an exception for absolute filenames?');
eval { $mvs->filename_to_url('foo/bar.foo') };
isa_ok($@, 'WWW::Mediawiki::Client::FileTypeException',
        'Does filename_to_url throw an exception for non .wiki files?');


# Can we harvest the Wiki data from the HTML page?
eq_or_diff($mvs->_get_wiki_text($HtmlData), $WikiData, 
        'get_wiki_text returns the correct text');

# Test the conflict detection and separation
eq_or_diff( $mvs->_merge('Paris.wiki', $RefData, $ServerData, $LocalData), 
        $MergedData,
        'does a merge of our test files produce the expected result?');

# Test loading a configuration
my $conf_file = WWW::Mediawiki::Client::CONFIG_FILE;
open OUT, ">$conf_file" or die "Could not open conf file";
print OUT q{$VAR1 = {
    host            => 'www.somewiki.org',
    output_level    => 2,
    username        => 'foo',
    password        => 'bar',
}
};
close OUT;
undef $mvs;
$mvs = WWW::Mediawiki::Client->new();
ok($mvs = $mvs->load_state, 'can run load_state');
is($mvs->password, 'bar', 'retrieved correct password');
is($mvs->username, 'foo', 'retrieved correct username');
is($mvs->host, 'www.somewiki.org', 'retrieved correct host');
#cleanup
unlink $conf_file;


# Test saving configuration
undef $mvs;
$mvs = WWW::Mediawiki::Client->new();
$mvs->username('fred');
$mvs->password('3117p4sS');
$mvs->host('www.someotherwiki.org');
ok($mvs->save_state, 'can run save_state');
undef $mvs;
$mvs = WWW::Mediawiki::Client->new();
$mvs = $mvs->load_state;
is($mvs->password, '3117p4sS', 'retrieved correct password');
is($mvs->username, 'fred', 'retrieved correct username');
is($mvs->host, 'www.someotherwiki.org', 'retrieved correct host');
unlink $conf_file;

# test the Wikitravel defaults with new
$mvs = WWW::Mediawiki::Client->new(host => 'wikitravel.org');
is($mvs->wiki_path, 'wiki/__LANG__/index.php', 'Wikitravel defaults: wiki_path');
is($mvs->space_substitute, '_', 'Wikitravel defaults: space_substitute');
is($mvs->pagename_to_url('San Francisco', 'submit'),
        'http://wikitravel.org/wiki/en/index.php?action=submit&title=San_Francisco',
        '... and convert the filename to the URL?');

# test the Wikipedia defaults with new
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikipedia.org');
is($mvs->wiki_path, 'w/wiki.phtml', 'Wikipedia defaults: wiki_path');
is($mvs->space_substitute, '+', 'Wikipedia defaults: space_substitute');
is($mvs->pagename_to_url('San Francisco', 'submit'),
        'http://en.wikipedia.org/w/wiki.phtml?action=submit&title=San+Francisco',
        '... and convert the filename to the URL?');

# test the Wikitravel defaults with host
ok($mvs->host('wikitravel.org'), 'Can change host to wikitravel');
is($mvs->wiki_path, 'wiki/__LANG__/index.php', '... and get the right wiki_path');
is($mvs->space_substitute, '_', '... and get the right space_substitute');
is($mvs->pagename_to_url('San Francisco', 'submit'),
        'http://wikitravel.org/wiki/en/index.php?action=submit&title=San_Francisco',
        '... and convert the filename to the URL?');

# test the Wikipedia defaults with host
ok($mvs->host('www.wikipedia.org'), 'Can change host to wikipedia');
is($mvs->wiki_path, 'w/wiki.phtml', '... and get the right wiki_path');
is($mvs->space_substitute, '+', '... and get the right space_substitute');
is($mvs->pagename_to_url('San Francisco', 'submit'),
        'http://en.wikipedia.org/w/wiki.phtml?action=submit&title=San+Francisco',
        '... and convert the filename to the URL?');

# test the language code accessor
is($mvs->language_code, 'en', 'Does the default language code get set?');
ok($mvs->language_code('ru'), '... and can we change it');
is($mvs->language_code, 'ru', '... and get back the string we changed it to');

# test the space_substitute accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->space_substitute, '_', 'Does the default space substitute get set?');
ok($mvs->space_substitute('-'), '... and can we change it');
is($mvs->space_substitute, '-', '... and get back the string we changed it to');
eval { $mvs->space_substitute('&') };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException',
        '... and throws an exception if you try to set it to "&"');
eval { $mvs->space_substitute('?') };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException',
        '... and throws an exception if you try to set it to "?"');
eval { $mvs->space_substitute('=') };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException',
        '... and throws an exception if you try to set it to "="');
eval { $mvs->space_substitute('\\') };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException',
        '... and throws an exception if you try to set it to "\\"');
eval { $mvs->space_substitute('/') };
isa_ok($@, 'WWW::Mediawiki::Client::URLConstructionException',
        '... and throws an exception if you try to set it to "/"');

# test the username accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->username, undef, 'Is the username undef by default?');
ok($mvs->username('joeuser'), '... and can we change it');
is($mvs->username, 'joeuser', '... and get back the string we changed it to');

# test the password accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->password, undef, 'Is the password undef by default?');
ok($mvs->password('joeuser'), '... and can we change it');
is($mvs->password, 'joeuser', '... and get back the string we changed it to');

# test the wiki_path accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->wiki_path, 'wiki/index.php', 'Does the default wiki path get set?');
ok($mvs->wiki_path('foo/index.php'), '... and can we change it');
is($mvs->wiki_path, 'foo/index.php', '... and get back the string we changed it to');
$mvs->wiki_path('/foo/index.php');
is($mvs->wiki_path, 'foo/index.php', '... and do leading slashes get stripped');

# test the commit_message accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->commit_message, undef, 'Is the commit_message undef by default?');
ok($mvs->commit_message('yo'), '... and can we change it');
is($mvs->commit_message, 'yo', '... and get back the string we changed it to');

# test the watch accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->watch, OPT_DEFAULT, 'Is the watch OPT_DEFAULT by default?');
foreach my $val (OPT_YES, OPT_NO, OPT_DEFAULT, OPT_KEEP) {
    is($mvs->watch($val), $val, '... and can we change it');
    is($mvs->watch, $val, '... and get back the value we changed it to');
}

# test the minor_edit accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->minor_edit, OPT_DEFAULT, 'Is the minor_edit OPT_DEFAULT by default?');
foreach my $val (OPT_YES, OPT_NO, OPT_DEFAULT) {
    is($mvs->minor_edit($val), $val, '... and can we change it');
    is($mvs->minor_edit, $val, '... and get back the value we changed it to');
}

# test the status accessor (should be undef)
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->status, undef, 'Is the status undef by default?');
# ... and throws an error if you try to set it
eval { $mvs->status('foo') };
isa_ok($@, 'WWW::Mediawiki::Client::ReadOnlyFieldException',
        '... and throws an exception if you try to set it');

# test the escape_filenames accessor
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->escape_filenames, 0, 'Does the default escape_filenames get set?');
ok($mvs->escape_filenames(1), '... and can we change it');
is($mvs->escape_filenames, 1, '... and get back the string we changed it to');

# test get_local_page
open(OUT, '>:utf8', 'Paris.wiki');
print OUT $WikiData;
close OUT;
eq_or_diff($mvs->get_local_page('Paris.wiki'), $WikiData, 'Can get_local_page');
# test for WWW::Mediawiki::Client::FileAccessException
SKIP: {
    chmod 0200, 'Paris.wiki';
    skip("Can't deny access to file.  (Are you root?)", 1) if -r 'Paris.wiki';
    eval { $mvs->get_local_page('Paris.wiki') };
    isa_ok($@, 'WWW::Mediawiki::Client::FileAccessException',
	    '... and throws an exception if the file is unreadable');
}
# test for WWW::Mediawiki::Client::FileTypeException
eval { $mvs->get_local_page('foo.bar') };
isa_ok($@, 'WWW::Mediawiki::Client::FileTypeException',
        '... and throws an exception if we try reading the wrong sort of file');
# test for WWW::Mediawiki::Client::AbsoluteFileNameException 
eval { $mvs->get_local_page("$Testdir/Paris.wiki") };
isa_ok($@, 'WWW::Mediawiki::Client::AbsoluteFileNameException',
        '... and throws an exception if we try using an absolute path');

# test pagename_to_url
$mvs = WWW::Mediawiki::Client->new(host => 'www.wikifoo.org');
is($mvs->pagename_to_url('San Francisco', 'edit'),
        'http://www.wikifoo.org/wiki/index.php?action=edit&title=San_Francisco',
        'Can we convert a pagename to a URL?');
#  ... with __LANG__ token in path
ok($mvs->wiki_path('wiki/__LANG__/wiki.phtml'), 
        '... and can add __LANG__ to wiki_path');
is($mvs->pagename_to_url('San Francisco', 'edit'),
        'http://www.wikifoo.org/wiki/en/wiki.phtml?action=edit&title=San_Francisco',
        '... which gives us the right URL');
# ... with __LANG__ token in base url
ok($mvs->host('__LANG__.wikifoo.org'),
        '... and can add __LANG__ to host');
is($mvs->pagename_to_url('San Francisco', 'edit'),
        'http://en.wikifoo.org/wiki/en/wiki.phtml?action=edit&title=San_Francisco',
        '... which gives us the right URL');

# test filename_to_pagename
is($mvs->filename_to_pagename('San_Francisco.wiki'), 'San Francisco',
        'filename_to_pagename can convert a filename to a pagename.');
is($mvs->filename_to_pagename('Salt_Lake_City.wiki'), 'Salt Lake City',
        '... if it has more than one "_".');
eval { $mvs->filename_to_pagename('foo.bar') };
isa_ok($@, 'WWW::Mediawiki::Client::FileTypeException',
        '... and throws an exception if we try the wrong sort of file');
eval { $mvs->filename_to_pagename("$Testdir/Paris.wiki") };
isa_ok($@, 'WWW::Mediawiki::Client::AbsoluteFileNameException',
        '... and throws an exception if we try using an absolute path');

# test pagename_to_filename
is($mvs->pagename_to_filename('San Francisco'), 'San_Francisco.wiki',
        'pagename_to_filename can convert a page name into a filename');
is($mvs->pagename_to_filename('User:Mark/Maps'), 'User:Mark/Maps.wiki',
        '... even the sub-page of a User page.');

$mvs->escape_filenames(0);
is($mvs->pagename_to_filename('Нижний Новгород'), 'Нижний_Новгород.wiki',
        'pagename_to_filename with Unicode');
is($mvs->filename_to_pagename('Нижний_Новгород.wiki'), 'Нижний Новгород',
        'filename_to_pagename with Unicode');

$mvs->escape_filenames(1);
is($mvs->pagename_to_filename('Нижний Новгород'), '%D0%9D%D0%B8%D0%B6%D0%BD%D0%B8%D0%B9_%D0%9D%D0%BE%D0%B2%D0%B3%D0%BE%D1%80%D0%BE%D0%B4.wiki',
        'pagename_to_filename with Unicode escaping');
is($mvs->filename_to_pagename('%D0%9D%D0%B8%D0%B6%D0%BD%D0%B8%D0%B9_%D0%9D%D0%BE%D0%B2%D0%B3%D0%BE%D1%80%D0%BE%D0%B4.wiki'), 'Нижний Новгород',
        'filename_to_pagename with Unicode escaping');

# test url_to_filename
$mvs->space_substitute('+');
is($mvs->url_to_filename('http://www.wikifoo.org/wiki/en/wiki.phtml?action=edit&title=San+Francisco'),
        'San_Francisco.wiki',
        'url_to_filename can convert a URL to a filename.');
$mvs->space_substitute('_');
is($mvs->url_to_filename('http://www.wikifoo.org/wiki/en/wiki.phtml?action=edit&title=San_Francisco'),
        'San_Francisco.wiki',
        '... with underscores too.');

# test list_wiki_files
open(OUT, '>:utf8', 'foo.wiki');
print OUT 'foo';
close OUT;
mkdir 'foo';
open(OUT, '>:utf8', 'foo/bar.wiki');
print OUT 'bar';
close OUT;
my @expect = qw(Paris.wiki foo.wiki foo/bar.wiki);
my @got = $mvs->list_wiki_files; 
eq_array(\@got, \@expect,
        'list_wiki_files returns a recursive list of wiki files.');

1;

__END__

# vim:syntax=perl:
