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

use Test::Most tests => 3;
use English '-no_match_vars';
use Readonly;
use Path::Class;
use XML::Ant::BuildFile::Project;

my $project = XML::Ant::BuildFile::Project->new( file => 't/java.xml' );

my $java = ( $project->target('testSpawn')->tasks('java') )[0];
ok( $java, 'java task' );
is( $java->classname, '${spawnapp}', 'classname' );
cmp_deeply( [ $java->args ], [ '${timeToWait}', '${logFile}' ], 'args' );
