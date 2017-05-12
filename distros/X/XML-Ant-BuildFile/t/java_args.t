#!perl
#
# This file is part of XML-Ant-BuildFile
#
# This software is copyright (c) 2014 by GSI Commerce.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use utf8;
use Modern::Perl;    ## no critic (UselessNoCritic,RequireExplicitPackage)

use English '-no_match_vars';
use Test::Most;
use Path::Class;
use Readonly;
use XML::Ant::BuildFile::Project;

my $tests;
Readonly my $PROJECT =>
    XML::Ant::BuildFile::Project->new( file => 't/yui-build.xml' );

my @java_tasks = $PROJECT->target('compress-files')->tasks('java');

for my $task (@java_tasks) {
    is( $task->jar, '${yuicompressor.jar}', 'unexpanded jar property' );
    $tests++;

    my @args = $task->args;
    cmp_deeply(
        [ @args[ 0, 2, 3, 5 ] ],
        [qw(--type --charset utf-8 -o)],
        'static args',
    );
    $tests++;
}

cmp_deeply(
    [ map { @{ [ $ARG->args ] }[ 4, 6 ] } @java_tasks ],
    [   map { unix_filestr_to_native("t/target/yui/$ARG") }
            qw(
            concat/site.css mincat/css/min/site.css
            concat/site.js  mincat/js/min/site.js
            )
    ],
    'pathref args',
);
$tests++;

done_testing();

sub unix_filestr_to_native { file( split q{/}, $ARG[0] )->stringify() }
