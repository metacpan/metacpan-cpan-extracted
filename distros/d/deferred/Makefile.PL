#!perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'deferred',
  AUTHOR           => 'David Leadbeater <dgl@dgl.cx>',
  VERSION_FROM     => "lib/deferred.pm",
  ABSTRACT_FROM    => "lib/deferred.pm",
  LICENSE          => "wtfpl",
  MIN_PERL_VERSION => 5.008, # (PerlIO, probably)
  META_MERGE       => {
    resources      => {
      license      => 'http://search.cpan.org/perldoc?Software::License::WTFPL_2',
      bugtracker   => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=deferred',
      repository   => 'http://github.com/dgl/perl-deferred',
    }
  },
);

