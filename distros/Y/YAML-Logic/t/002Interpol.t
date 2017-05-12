######################################################################
# Test suite for YAML::Logic
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use YAML::Syck qw(Load Dump);
use YAML::Logic;
use Test::More qw(no_plan);
use Data::Dumper;

my $logic = YAML::Logic->new();

my $out = $logic->interpolate( '$var', { var => "foo" } );
is($out, "foo", "simple variable interpolation");

$out = $logic->interpolate( '${var}', { var => "foo" } );
is($out, "foo", "simple variable interpolation with \${} notation");

$out = $logic->interpolate( '"${var}"', { var => "foo" } );
is($out, "\"foo\"", 
         "simple variable interpolation with \${} notation and quotes");

$out = $logic->interpolate( '"${var}${var}"', { var => "foo" } );
is($out, "\"foofoo\"", 
         "two \${x} variables concatenated");

$out = $logic->interpolate( '"${var}abc${var}"', { var => "foo" } );
is($out, "\"fooabcfoo\"", 
         "two \${x} variables concatenated");

$out = $logic->interpolate( '"$var$var"', { var => "foo" } );
is($out, "\"foofoo\"", 
         "two \$x variables concatenated");

$out = $logic->interpolate( '"$var abc $var"', { var => "foo" } );
is($out, "\"foo abc foo\"", 
         "two \$x variables concatenated");

$out = $logic->interpolate( '$varfoo', { var => "foo" } );
is($out, "", "unknown variable");

$out = $logic->interpolate( '${var}foo', { var => "foo" } );
is($out, "foofoo", "\${} notation");

$out = $logic->interpolate( '${var}foo${var}', { var => "foo" } );
is($out, "foofoofoo", "\${} notation, multiple vars");

$out = $logic->interpolate( '$var.field', { var => { field => "foo" } } );
is($out, "foo", "hash entry");

$out = $logic->interpolate( 'blah $var.field', { var => { field => "foo" } } );
is($out, "blah foo", "hash entry with text");

$out = $logic->interpolate( '"$var.field"', { var => { field => "foo" } } );
is($out, "\"foo\"", "hash entry with quotes");
