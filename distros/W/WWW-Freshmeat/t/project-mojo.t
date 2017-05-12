#!perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use File::Slurp;

use WWW::Freshmeat 0.12;

my $fm = WWW::Freshmeat->new();
isa_ok($fm,'WWW::Freshmeat');

my $xml=read_file('t/mojomojo.xml');
my $project = $fm->project_from_xml($xml);

isa_ok($project,'WWW::Freshmeat::Project');
is($project->name(),'MojoMojo');
is($project->date_add(),'2009-01-22 14:58:27');
is($project->date_updated(),'2009-08-03 08:05:25');
