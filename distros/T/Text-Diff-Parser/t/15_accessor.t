#!/usr/bin/perl -w
# $Id: 15_accessor.t 194 2006-12-19 13:51:18Z fil $
use strict;

use Test::More ( tests => 20 );
use Text::Diff::Parser;
use IO::File;

my $file = 't/double.diff';
my $file2 = "t/dbix-abstract.patch";

##########
my $parser = Text::Diff::Parser->new( File=>$file, Simplify=>1 );

my $files = { $parser->files };
is_deeply( $files, {
            Changes => 'Changes',
            README  => 'README',
    }, "List of files changed" );


my $changes = $parser->changes( 'README' );

is( $changes, 1, "One change to README" );


##########
$parser = Text::Diff::Parser->new( {File=>$file2, Simplify=>1, Strip=>2} );
is_deeply( { $parser->files }, 
           { qw( Abstract.pm Abstract.pm
                 2-dbix-abstract.t 2-dbix-abstract.t
                 dbia.config dbia.config
               ) }, "Stripped filenames" );

##########
$parser = Text::Diff::Parser->new( {File=>$file2, Simplify=>1, Strip=>1} );

$changes = $parser->changes( 'Abstract.pm' );
is( $changes, 21, "21 changes to Abstract.pm" );

$changes = $parser->changes( 't/2-dbix-abstract.t' );
is( $changes, 13, "13 changes to t/2-dbix-abstract.t" );


##########
$parser = Text::Diff::Parser->new( {File=>$file2} );

my @changes = $parser->changes( 'dbix-abstract/Abstract.pm' );

my $c = $changes[0];
is( $c->filename1, 'DBIx-Abstract-1.005/Abstract.pm', 'filename1' );
is( $c->filename2, 'dbix-abstract/Abstract.pm', 'filename2' );
is( $c->line1, 1, 'line1' );
is( $c->line2, 1, 'line2' );
is( $c->size, 1, 'size' );
is( $c->type, 'REMOVE', 'type' );

$c = $changes[8];
is( $c->filename1, 'DBIx-Abstract-1.005/Abstract.pm', 'filename1' );
is( $c->filename2, 'dbix-abstract/Abstract.pm', 'filename2' );
is( $c->line1, 12, 'line1' );
is( $c->line2, 10, 'line2' );
is( $c->size, 11, 'size' );
is( $c->type, 'ADD', 'type' );

my @lines = $c->text;
is( 0+@lines, 11, 'text()' );
is( $lines[0], '    eval {' );
is( $c->text(0), '    eval {', 'text(0)' );
