#!/usr/bin/perl
use Test::More tests => 79;
use Test::Exception;
use File::Path;
use t::Regen qw(test_setup write_config);
use lib "lib";
use WWW::Selenium::Utils qw(generate_suite cat);
use Cwd qw(getcwd);
use Data::Dumper;

my $verbose = 1;

Basic_generation: {
    my $testdir = test_setup();
    gen_suite( test_dir => $testdir );
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
    my $suite = cat("$testdir/TestSuite.html");
    like $suite, qr#>bar</a>#, "link is from filename";
    like $suite, qr#foo\.html#, "suite contains link to foo.html";
    like $suite, qr#>some title</a>#, "link is from wiki title";
    like $suite, qr#bar\.html#, "suite contains link to bar.html";
    my $foo = cat("$testdir/foo.html");
    like $foo, qr#<title>some title</title>#, 'proper title';
    like $foo, qr#<b>Auto-generated from $testdir/foo\.wiki</b>#;
    like $foo, qr#<hr />Auto-generated from $testdir/foo\.wiki at #;
    like $foo, qr#open#;
    like $foo, qr#<td>/foo</td>#;
    like $foo, qr#verifyText#;
    like $foo, qr#verifyLocation#;
    like $foo, qr#<td>/bar</td>#;
    like $foo, qr#<td>&nbsp;</td></tr>#, '&nbsp in empty cell';
    like $foo, qr#<td>type</td>#;
    like $foo, qr#<td>ipaddress</td>#;
    like $foo, qr#<td>0</td>#;
    unlink $foo, qr#comment#, 'comment was stripped out';
}

Invalid_line: {
    my $testdir = test_setup('extra-wiki', 'nintendo | sony | xbox |');
    throws_ok {generate_suite(test_dir => $testdir)}
              qr#Error parsing file t/tests/foo\.wiki:.+line 8: Invalid line#s;
}


Extra_Pipe: {
    my $testdir = test_setup("extra-wiki", " | open | http://extra_pipe.com |||");
    like cat("$testdir/foo.wiki"), qr#extra_pipe#;
    throws_ok { generate_suite( test_dir => $testdir ) }
              qr#Error parsing file t/tests/foo\.wiki:.+extra_pipe#s;
}

Multiple_errors: {
    my $testdir = test_setup("extra-wiki", "super\nduper\n");
    throws_ok { generate_suite( test_dir => $testdir ) }
              qr#Error parsing file t/tests/foo\.wiki:.+super.+duper#s;
}

Generate_with_path: {
    my $testdir = test_setup();
    gen_suite( test_dir => $testdir,
               base_href => "/peanut_butter/" );
    my $foo = cat("$testdir/foo.html");
    like $foo, qr#<title>some title</title>#, 'proper title';
    like $foo, qr#<td>/peanut_butter/foo</td>#;
    like $foo, qr#<td>/peanut_butter/bar</td>#;
}

Generate_from_cwd: {
    my $testdir = test_setup();
    my $cwd = getcwd;
    chdir $testdir or die "Can't chdir $testdir: $!";
    gen_suite( test_dir => '.' );
    my $suite = cat("./TestSuite.html");
    like $suite, qr#a href="\./foo\.html">some title<#, ;
    like $suite, qr#a href="\./bar\.html">bar<#, ;
    chdir $cwd or die "Can't chdir $cwd: $!";
}

Orphaned: {
    my $testdir = test_setup("with orphan");
    ok -e "$testdir/orphan.html";
    gen_suite( test_dir => $testdir);
    ok !-e "$testdir/orphan.html";
    ok -e "$testdir/bar.html";
}

From_old_config: {
    my $testdir = test_setup();
    local $ENV{SELUTILS_ROOT} = "t";
    write_config("t", "old style");
    gen_suite(); # should read env variable
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
}

From_perl_config: {
    my $testdir = test_setup();
    local $ENV{SELUTILS_ROOT} = "t";
    write_config("t");
    gen_suite(); # should read env variable
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
}

Per_directory_suites: {
    my $testdir = test_setup("multi-dir");
    ok -e "$testdir/baz/foo.wiki";
    ok -d "$testdir/empty";
    gen_suite( test_dir => $testdir, perdir => 1 );
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
    ok -e "$testdir/baz/TestSuite.html", "baz TestSuite created";
    ok -e "$testdir/baz/foo.html", "baz/foo.wiki converted to html";
    ok !-e "$testdir/empty/TestSuite.html", "empty dir TestSuite";
}

Per_directory_suites_config: {
    my $testdir = test_setup("multi-dir");
    ok -e "$testdir/baz/foo.wiki";
    ok -d "$testdir/empty";
    local $ENV{SELUTILS_ROOT} = "t";
    write_config("t");
    gen_suite();
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/foo.html", "foo.wiki converted to html";
    ok -e "$testdir/baz/TestSuite.html", "baz TestSuite created";
    ok -e "$testdir/baz/foo.html", "baz/foo.wiki converted to html";
    ok !-e "$testdir/empty/TestSuite.html", "empty dir TestSuite";
}

Master_index: {
    my $testdir = test_setup("multi-dir");
    gen_suite( test_dir => $testdir, perdir => 1, index => "t/index.html" );
    ok -e "$testdir/TestSuite.html", "TestSuite created";
    ok -e "$testdir/baz/TestSuite.html", "baz TestSuite created";
    ok -e "t/index.html";
    my $index = cat("t/index.html");
    like $index, qr#<title>Selenium TestSuites</title>#;
    like $index, qr#<a href="TestRunner\.html\?test=\./tests/TestSuite\.html">Main TestSuite</a>#;
    like $index, qr#<a href="TestRunner\.html\?test=\./tests/baz/TestSuite\.html">baz TestSuite</a>#;
}
 
Comment_before_title: {
    my $testdir = test_setup("comment before title");
    like cat("$testdir/foo.wiki"), qr#comment before title#;
    gen_suite( test_dir => $testdir );
    like cat("$testdir/foo.html"), qr#<title>some title#;
}

Too_many_args: {
    for my $line ( '| click | what | extra |',
                   '| open | this | extra |',
                   '| Close | extra |',
                   '| Close | extra | extra |',
                 ) {
        my $testdir = test_setup("extra-wiki", $line);
        like cat("$testdir/foo.wiki"), qr#\Q$line\E#; # verify test setup
        my ($cmd) = $line =~ m#^\| (\w+)#;
        throws_ok { generate_suite( test_dir => $testdir, verbose => $verbose ) }
                  qr#line 8: Incorrect number of arguments for $cmd#;
    }
}

Include_directive: {
    my $testdir = test_setup("include");
    gen_suite( test_dir => $testdir );
    my $foo = cat("$testdir/foo.html");
    unlike $foo, qr#include\s#;
    like $foo, qr#included#;
    like $foo, qr#1234#;
}

Bad_include: {
    my $testdir = test_setup("extra-wiki", "include cantfind\n");
    throws_ok {generate_suite(test_dir => $testdir)}
              qr#Can't include $testdir/cantfind -#;
}

sub gen_suite {
    my @opts = @_;
    lives_ok { generate_suite( @opts, verbose => $verbose ) };
}


