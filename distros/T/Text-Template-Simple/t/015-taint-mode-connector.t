#!perl -Tw
use constant TAINTMODE => 1;
#!/usr/bin/env perl -w
package main;
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use TTSConnector;

ok( my $t = Text::Template::Simple->new,     'Got the object'           );
ok( my $s = TTSConnector->new( cache => 1 ), 'Got the sub-class object' );

my $p = 'Text::Template::Simple::';

is( $t->connector('Cache')     , $p . 'Cache',     'Connector Cache'       );
is( $t->connector('Cache::ID') , $p . 'Cache::ID', 'Connector Cache::ID'   );
is( $t->connector('IO')        , $p . 'IO',        'Connector IO'          );
is( $t->connector('Tokenizer') , $p . 'Tokenizer', 'Connector Tokenizer'   );

is( $s->connector('Cache')     , 'TTS::Cache',     'S-Connector Cache'     );
is( $s->connector('Cache::ID') , 'TTS::Cache::ID', 'S-Connector Cache::ID' );
is( $s->connector('IO')        , 'TTS::IO',        'S-Connector IO'        );
is( $s->connector('Tokenizer') , 'TTS::Tokenizer', 'S-Connector Tokenizer' );

my $template = q|<%my@p=@_%>Compile from subclass: <%=$p[0]%>|;

is(
    $s->compile( $template, [ 'Test' ] ), 'Compile from subclass: Test',
    'Compile from subclass'
);
