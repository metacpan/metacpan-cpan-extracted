use strict;
use warnings;

use Test::More;
use Text::Gitignore qw(build_gitignore_matcher);

subtest 'mixed patterns' => sub {
    ok( build_gitignore_matcher('*.js')->('foo.js') );
    ok( !build_gitignore_matcher('*.js')->('foo.bar') );
    ok( !build_gitignore_matcher('!*.js')->('foo.js') );

    ok( build_gitignore_matcher('*.js')->('nested/dir/foo.js') );
    ok( !build_gitignore_matcher('/*.js')->('nested/dir/foo.js') );

    ok( !build_gitignore_matcher('*.js')->('foo.json') );

    ok( build_gitignore_matcher('*.js*')->('foo.json') );

    ok( build_gitignore_matcher('/bin')->('bin') );
    ok( !build_gitignore_matcher('/bin')->('usr/bin') );

    ok( build_gitignore_matcher('bin/')->('bin/') );
    ok( build_gitignore_matcher('bin/')->('bin/inside') );
    ok( !build_gitignore_matcher('bin/')->('bin') );

    ok( build_gitignore_matcher('f[oa]o')->('foo') );
    ok( build_gitignore_matcher('f[oa]o')->('fao') );
    ok( !build_gitignore_matcher('f[oa]o')->('fza') );

    ok( build_gitignore_matcher('f[!oa]o')->('fzo') );
    ok( !build_gitignore_matcher('f[!oa]o')->('foa') );

    ok( build_gitignore_matcher('f[a-z]o')->('foo') );
    ok( !build_gitignore_matcher('f[a-z]o')->('f1a') );

    ok( build_gitignore_matcher('lib/*.pm')->('lib/Foo.pm') );
    ok( !build_gitignore_matcher('lib/*.pm')->('lib/Foo/Bar.pm') );

    ok( build_gitignore_matcher('**/foo')->('/foo') );
    ok( build_gitignore_matcher('**/foo')->('/hello/foo') );
    ok( build_gitignore_matcher('**/foo')->('/hello/foo') );

    ok( build_gitignore_matcher('**/foo/bar')->('/foo/bar') );
    ok( build_gitignore_matcher('**/foo/bar')->('/hello/foo/bar') );
    ok( !build_gitignore_matcher('**/foo/bar')->('/hello/foo/baz') );

    ok( build_gitignore_matcher('lib/**/*.pm')->('lib/Foo.pm') );
    ok( build_gitignore_matcher('lib/**/*.pm')->('lib/Foo/Bar/Baz.pm') );
    ok( build_gitignore_matcher('lib/**/*.p?')->('lib/Foo/Bar/Baz.pl') );
    ok( !build_gitignore_matcher('lib/**/*.pm')->('Foo.pm') );

    ok( build_gitignore_matcher('**.pm')->('lib/Foo.pm') );
    ok( build_gitignore_matcher('**.pm')->('lib/hello/Foo.pm') );
    ok( build_gitignore_matcher('**.pm')->('Foo.pm') );

    ok( build_gitignore_matcher('lib/**')->('lib/Foo.pm') );
    ok( build_gitignore_matcher('lib/**')->('lib/bar/Foo.pm') );

    ok( build_gitignore_matcher( [ '*.pm', '!Foo.pm' ] )->('Bar.pm') );
    ok( !build_gitignore_matcher( [ '*.pm',  '!Foo.pm' ] )->('Foo.pm') );
    ok( !build_gitignore_matcher( [ '**.pm', '!t/' ] )->('t/lib/test.pm') );

    ok( build_gitignore_matcher( [ '*.js', 'lib/*.pm', '!foo.js' ] )
          ->('lib/Foo.pm') );

    ok( build_gitignore_matcher( [ '*.js', '!static/*', 'static/init.js' ] )
          ->('static/init.js') );

    ok( !build_gitignore_matcher( [ '!**/except.pm', ] )->('else.js') );
    ok( !build_gitignore_matcher( [ '**/*.pm', '!**/except.pm' ] )->('else.js')
    );

    ok( build_gitignore_matcher( [ '**.js', '!**.c', '**.pm' ] )->('else.js') );
    ok( !build_gitignore_matcher( [ '**.js', '!**.c', '**.pm' ] )->('file.c') );

    ok( build_gitignore_matcher( ['tests/**/*Test.pm'] )
          ->('foo/tests/worker/MyTest.pm') );
    ok( build_gitignore_matcher( ['/tests/**/*Test.pm'] )
          ->('tests/worker/MyTest.pm') );
    ok( !build_gitignore_matcher( ['/tests/**/*Test.pm'] )
          ->('foo/tests/worker/MyTest.pm') );

    ok( !build_gitignore_matcher( ['!tests/'] )->('foo/tests/worker/MyTest.pm')
    );
    ok( build_gitignore_matcher( [ '!tests/', '*.pm' ] )
          ->('foo/worker/MyTest.pm') );
    ok( build_gitignore_matcher( ['tests/'] )->('foo/tests/worker/MyTest.pm') );
};

done_testing;
