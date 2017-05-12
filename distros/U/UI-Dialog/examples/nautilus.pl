#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;

use UI::Dialog::Backend::Nautilus;
my $n = new UI::Dialog::Backend::Nautilus;

my @paths = $n->paths();
my @uris = $n->uris();
my $path = $n->path();
my $uri = $n->uri();
my @geo = $n->geometry();

use UI::Dialog::GNOME;
my $d = new UI::Dialog::GNOME;
$d->msgbox
  ( text=>
    [ 'paths: '.join(" ",@paths),
      'uris: '.join(" ",@uris),
      'path: '.$path,
      'uri: '.$uri,
      'geo: '.join(" ",@geo)
    ]
  );
