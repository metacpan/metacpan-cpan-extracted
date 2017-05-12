package UtilSubExporter2;

use strict;
use Clone qw/clone/;
BEGIN {
  my $err;
  {
    local $@;
    eval "use Sub::Exporter ()";
    $err = $@;
  }
  if ($err) {
    die $err;
  }
}

use Util::Any -SubExporter;

Sub::Exporter::setup_exporter
  (
   {
    as => $UtilSubExporter2::SubExporterImport = '___import___',
    exports => [qw/hello askme hi/],
    groups  => {
              greet => [qw/hello hi/],
              uk    => [qw/hello/],
              us    => [qw/hi/],
             }}
);

our $Utils = clone $Util::Any::Utils;
$Utils->{-l2s} = [
                  ['List::Util', '',,
                  {
                   -select => [qw(first min minstr max maxstr sum)],
                  }
                  ],
                  [
                   'UtilSubExporter2', '',
                   {
                    'hoge' => \&hoge_generator, # generator
                    'hogehoge' => 'hello', # &hello
                   }
                  ]
                ];

sub hello { "hello there" }
sub askme { "what you will" }
sub hi    { "hi there" }
sub hoge_generator { sub {} };
1;
