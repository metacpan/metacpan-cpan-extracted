package lib::with::preamble;

use strict;
use warnings FATAL => 'all';
use File::Spec;
use PerlIO::via::dynamic;

our $VERSION = '0.001003'; # 0.1.3

sub require_with_preamble {
  my ($arrayref, $filename) = @_;
  my (undef, $preamble, @libs) = @$arrayref;
  foreach my $cand (map File::Spec->catfile($_, $filename), @libs) {
    if (-f $cand) {
      if (open my $fh, '<', $cand) {
        return with_preamble($preamble."\n#line 1 $cand\n", $fh);
      }
    }
  }
}

sub with_preamble {
  my ($preamble, $fh) = @_;
  PerlIO::via::dynamic->new(untranslate => sub {
    $preamble and $_[1] =~ s/\A/$preamble/, undef($preamble);
  })->via($fh);
  return $fh;
}

sub import {
  my ($class, $preamble, @libs) = @_;
  return unless defined($preamble) and @libs;
  unshift @INC, [ \&require_with_preamble, $preamble, @libs ];
}

1;

=head1 NAME

lib::with::preamble - invent your own default perl setup

=head1 SYNOPSIS

  use lib::with::preamble 'use v5.16; use strictures 1;', 'lib';

The above will load .pm files from lib/ - but they'll act as if your code
always started with 'use v5.16; use strictures 1;'.

=head1 USING THIS IN A DISTRIBUTION

To use this in a dist, you'll want to create two files -

  # my/lib.pm
  use lib::with::preamble 'use v5.16; use strictures 1;', 'lib';
  1;

  # my/filter
  print "use v5.16;\nuse strictures 1;\n#line 1\n";
  while (<STDIN>) { print }

and then tell your Makefile.PL to use the filter -

  WriteMakefile(
    ...
    PM_FILTER => 'perl my/filter'
  );

Then during development instead of doing

  $ perl -Ilib bin/script-to-test

you'll want to do -

  $ perl -Mmy::lib bin/script-to-test

and for prove -

  $ PERL5OPT=-Mmy::lib prove t/some-test.t

but once you run

  $ make

your blib/ will get populated with files that already have your
preamble added, so

  $ prove -b t/some-test.t

will just work, as will

  $ make test

and when your users install your module, the .pm files will already have
the preamble at the top, so your installed files will look like

  # My/Foo.pm
  use v5.16;
  use strictures 1;
  # line 1
  package My::Foo;
  ...

and everything should work, without you even needing to add this module
as a dependency.

Patches to document an equivalent for those of you using L<Dist::Zilla>
(and L<Module::Build>, even if I don't like the bedamned thing) would be
very welcome.

=head1 WARNING

This is as much a proof of concept as anything else at this point, so the
interface is NOT guaranteed to be stable. Especially since this is meant
to be a sort of implicit sugar, and history has proven that other people
are much better at designing APIs to sugar than I am.

But provided you're using it the way I describe above, the my/filter script
isn't dependent on anything, so your users will be insulated from that.

So please do have a play around and see if it works for you.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet. Well volunteered? :)

=head1 COPYRIGHT

Copyright (c) 2013 the lib::with::preamble L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
