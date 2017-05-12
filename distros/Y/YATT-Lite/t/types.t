#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

sub eval_ok_by {
  my ($sub, $script, $expect, $title) = @_;
  local $@;
  my $result = eval $script;
  if ($@) {
    fail "$title; failed with: $@";
  } else {
    $sub->($result, $expect, $title);
  }
}

sub eval_error {
  my ($script) = @_;
  local $@;
  scalar eval $script;
  $@;
}

my $tn = 1;
{
  my $PKG = "Test$tn";
  my $PFX = $PKG . "::";
  my $strict = qq!use strict; use warnings FATAL => qw/FATAL all NONFATAL misc/;\n!;
  is eval_error(qq{package TestBase; \$INC{"TestBase.pm"} = 1; $strict}
		. <<'END')
sub new {
  my $pack = shift;
  bless +{@_}, $pack;
}
END
  , '', "Base class for this test";

  my $prelude = qq{package $PKG; $strict};
  is eval_error($prelude . <<'END')
  use YATT::Lite::Types
   (base => 'TestBase'
    , [Album    => fields => [qw/albumid  artist title/]]
    , [CD     => fields => [qw/cdid     artist title/]]
    , [Track  => fields => [qw/trackid  cd     title/]]
    , [Artist => fields => [qw/artistid name/]]
   );
END

    , '', 'use Types has no error';

  foreach my $type (qw/Album CD Track/) {
    eval_ok_by \&is, $prelude.$type, $PFX.$type
      , "Should eval: $type => $PFX.$type";
  }

  my @tests =
    ([q{my Album $album}]
     , [q{my Album $album = {}}]
     , [q{my Album $album = Album->new}]
     , [q{my Albumm $album}
	=> qr/^No such class Albumm at /]
     , [q{my CD $cd}]
     , [q{my CD $cd = {}; $cd->{artist}}]
     , [q{my CD $cd = {}; $cd->{artistt}}
	=> qr/^No such class field "artistt" in variable \$cd of type ${PFX}CD/]
     , [q{my Track $track = {}}]
     , [q{my Track $track = {}; my CD $cd = {}; $track->{cd} = $cd}]
     , [q{my Track $track = {}; my CD $cd = {}; $track->{cdd} = $cd}
	=> qr/^No such class field "cdd" in variable \$track of type ${PFX}Track/
      ]
   );

  foreach my $tests (@tests) {
    my ($script, $result) = @$tests;
    if (defined $result) {
      like eval_error($prelude.$script), $result
	, "Should raise error: $script";
    } else {
      is eval_error($prelude.$script), ''
	, "Should be valid: $script";
    }
  }
}

done_testing();
