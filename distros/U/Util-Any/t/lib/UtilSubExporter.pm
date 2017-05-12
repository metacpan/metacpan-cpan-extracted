package UtilSubExporter;

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
    as => 'do_import',
    exports => [qw/hello askme hi/],
    groups  => {
              greet => [qw/hello hi/],
              uk    => [qw/hello/],
              us    => [qw/hi/],
             }}
);

our $Utils = clone $Util::Any::Utils;
$Utils->{-l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];

sub hello { "hello there" }
sub askme { "what you will" }
sub hi    { "hi there" }

1;
