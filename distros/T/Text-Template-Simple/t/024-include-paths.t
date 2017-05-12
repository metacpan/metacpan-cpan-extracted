#!/usr/bin/env perl -w
use strict;
use warnings;
use Test::More qw( no_plan );
use Text::Template::Simple;
use File::Spec;

my @p = (
    include_paths => [
                        qw(
                            t/data/path1
                            t/data/path2
                        )
                    ],
);

ok( my $t = Text::Template::Simple->new,       'Got the object'         );
ok( my $i = Text::Template::Simple->new( @p ), 'Got the include object' );

ok( my $i_got_1 = $i->compile('test1.tts'), 'Compile test1.tts (inc)');
ok( my $i_got_2 = $i->compile('test2.tts'), 'Compile test2.tts (inc)');

ok( my $t_got_1 = $t->compile('test1.tts'), 'Compile test1.tts' );
ok( my $t_got_2 = $t->compile('test2.tts'), 'Compile test2.tts' );

ok( my $tf_got_1 = eval { $t->compile([ FILE => 'test1.tts']); } || $@,
    'Compile or error 1' );

ok( my $tf_got_2 = eval { $t->compile([ FILE => 'test2.tts']); } || $@,
    'Compile or error 2' );

my $canon = File::Spec->canonpath( 't/data/path2/test3.tts' );

is($i_got_1, 'test1: test1.tts', 'Include path successful for test1');
is($i_got_2, "test2: test2.tts - dynamic $canon - static "
              .'<%= $0 %>', 'Include path/dynamic/static successful for test1:'
              ."'$i_got_2'");

is($t_got_1, 'test1.tts', 'First test: Parameter interpreted as string');
is($t_got_2, 'test2.tts', 'Second test: Parameter interpreted as string');

my $c = 'code died since file does not exists and include_paths unset';

like( $tf_got_1, qr/ \QError opening 'test1.tts' for reading\E /xms,
        "First test: $c");

like( $tf_got_2, qr/ \QError opening 'test2.tts' for reading\E /xms,
        "Second test: $c");
