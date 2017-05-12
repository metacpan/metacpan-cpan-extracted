#!/usr/bin/env perl
use warnings;
use strict;
use Text::Pipe 'PIPE';
use Test::More tests => 1;
my $pipe = PIPE 'Translate::Babelfish', from => 'en', to => 'de';
like(
    $pipe->filter('My hovercraft is full of eels.'),
    qr/mein.*Luftkissenfahrzeug.*(Aalen.*voll|voll.*Aalen)/i,
    'Translate::Babelfish pipe (en -> de)'
);
