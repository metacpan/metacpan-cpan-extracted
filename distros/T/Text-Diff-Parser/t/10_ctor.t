#!/usr/bin/perl -w
# $Id: 10_ctor.t 118 2006-04-13 01:20:06Z fil $
use strict;

use Test::More ( tests => 21 );
use Text::Diff::Parser;
use IO::File;

my $file = 't/easy.diff';
my $file2 = "t/dbix-abstract.patch";

##########
my $parser = Text::Diff::Parser->new();
ok( $parser, "Plain constructor" );

##########
$parser = Text::Diff::Parser->new( $file );
ok( $parser, "Constructor with filename" );
is( $parser->source, $file, "Read $file" );
is( $parser->changes, 7, "7 changes" );

#########
my $io = IO::File->new( $file );
my $p2 = Text::Diff::Parser->new( $io );
ok( $p2, "Contstructor with a handle" );
delete $parser->{source};
delete $p2->{source};
is_deeply( $p2, $parser, "Same output" );

#########
$io = IO::File->new( $file );
my $text = join '', <$io>;
$p2 = Text::Diff::Parser->new( $text );
ok( $p2, "Contstructor with diff text" );
delete $parser->{source};
delete $p2->{source};
is_deeply( $p2, $parser, "Same output" );

##########
$parser = Text::Diff::Parser->new( File=>$file, Simplify=>1 );
ok( $parser, "Constructor with hash" );
is( $parser->source, $file, "Read $file" );
is( $parser->changes, 3, "3 changes" );

##########
$parser = Text::Diff::Parser->new( {File=>$file} );
ok( $parser, "Constructor with hashref" );
is( $parser->source, $file, "Read $file" );
is( $parser->changes, 7, "7 changes" );

##########
$p2 = Text::Diff::Parser->new( Diff=>$text );
ok( $parser, "Constructor with hash" );
delete $parser->{source};
delete $p2->{source};
is_deeply( $p2, $parser, "Same output" );

##########
$parser = Text::Diff::Parser->new( {File=>$file2, Simplify=>1, Strip=>1} );
ok( $parser, "Constructor with hashref" );

is( $parser->{changes}[0]{filename1}, 'Abstract.pm', 
                    "Stripped one directory" );
is( 0+$parser->changes, 38, "38 changes" );


##########
$parser = Text::Diff::Parser->new( {File=>$file2, Simplify=>1, Strip=>2} );
is( $parser->{changes}[0]{filename1}, 'Abstract.pm', 
                    "Stripped one directory" );
is( $parser->{changes}[30]{filename1}, '2-dbix-abstract.t', 
                    "Stripped two directories" );
