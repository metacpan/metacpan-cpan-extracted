use 5.006;    # our
use strict;
use warnings;

package Test::Stream::Plugin::Explain::Terse;

our $VERSION = '0.001001';

# ABSTRACT: Dump anything in a single line in 80 characters or fewer

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Test::Stream::Exporter qw/ default_exports import /;
use Data::Dump qw( pp );

default_exports qw/ explain_terse /;

no Test::Stream::Exporter;










use constant MAX_LENGTH  => 80;
use constant RIGHT_CHARS => 1;
use constant ELIDED      => q[...];

sub explain_terse {
  my $content = pp( $_[0] );       # note: using this for now because of list compression
  $content =~ s/\s*\n\s*/ /sxg;    # nuke literal newlines and swallow excess space.
  return $content if length $content <= MAX_LENGTH;

  return ( substr $content, 0, MAX_LENGTH - ( length ELIDED ) - RIGHT_CHARS ) . ELIDED
    . ( substr $content, ( length $content ) - RIGHT_CHARS );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::Explain::Terse - Dump anything in a single line in 80 characters or fewer

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

  use Test::Stream::Bundle::V1;
  use Test::Stream::Plugin::Explain::Terse qw( explain_terse );

  note "Studying: fn(y) = " . explain_terse(my $got = fn($y));

  # test $got

  done_testing;

=head1 DESCRIPTION

This module aims to provide a simple tool for adding trace-level details
about data-structures to the TAP stream to visually keep track of what is being
tested.

Its objective is to not be comprehensive, and only be sufficient for a quick
visual sanity check, allowing you to visually spot obviously wrong things at a
glance without producing too much clutter.

It is expected that if C<Explain::Terse> produces a data structure that needs
compacting for display, that the user will also be performing sub-tests on that
data structure, and those sub-tests will trace their own context closer to the
actual test.

  # Checking: { a_key => ["a value"], b_key => ["b value'], ... }
    # Subtest: c_key is expected
    # Checking: ["c value"]
    ok 1 - c_key's array has value "c value"
    1..1
  ok 1 - c_key is expected

The idea being the higher up in the data structure you're doing the comparison,
the less relevant the individual details are to that comparison, and the actual
details only being relevant in child comparisons.

This is obviously also better if you're doing structurally layered comparison,
and not simple path-based comparisons, e.g:

  # Not intended to be used this way.
  note explain_terse(\%hash);
  is( $hash{'key'}{'otherkey'}{'finalkey'}, 'expected_value' );

And you want something like:

  note explain_terse(\%hash);
  ok( exists $hash{'key'}, 'has q[key]')
    and subtest "key structure" => sub {

      my $structure = $hash{'key'};
      note explain_terse($structure);
      is( ref $structure, 'HASH', 'is a HASH' )
        and ok( exists $structure->{'otherkey'}, 'has q[otherkey]' )
        and subtest "otherkey structure" => sub {

          my $substructure = $structure->{'otherkey'};
          note explain_terse($substructure);
          is( ref $substructure, 'HASH', 'is a HASH' )
            and ok( exists $structure->{'finalkey'}, 'has final key' )
            and subtest "finalkey structure" => sub {

              my $final_structure = $substructure->{'finalkey'};
              note explain_terse($final_structure);
              ok( !ref $final_structure, "finalkey is not a ref")
                and ok( defined $final_structure, "finalkey is defined")
                and is( $final_structure, 'expected_value', "finalkey is expected_value" );
          };

      };
  };

Though of course you'd not want to write it like that directly in your tests,
you'd probably want something more like

  with(\%hash)->is_hash->has_key('key', sub {
      with($_[0])->is_hash->has_key('otherkey', sub {
        with($_[0])->is_hash->has_key('finalkey', sub {
          with($_[0])->is_scalar->defined->is_eq("expected_value");
        });
      });
  });

Or

  cmp_deeply( \%hash, superhashof({
      key => superhashof({
        otherkey => superhashof({
          finalkey => "expeted_value"
        }),
      }),
  }));

And have C<Explain::Terse> operating transparently under the hood of these implementations
so you can see what is happening.

=head1 FUNCTIONS

=head2 C<explain_terse>

  my $data = explain_terse($structure);

Returns C<$structure> pretty printed and compacted to be less than 80
characters long.

=head1 FUTURE STABILITY

=head2 C<Test::Stream>

This module intends to inter-operate with L<< C<Test::Stream>|Test::Stream >>
which this modules author considers still in a heavy state of flux, and so this
module cannot be considered even remotely stable until some point after that
becoming more stable.

=head2 C<Dumper> internals.

This module presently uses L<< C<pp> from C<Data::Dump>|Data::Dump/pp >> as its
main formatter bolted into some simple sub-string operations and newline
transformations.

It is planned that this module will switch to using
L<< C<Data::Dumper>|Data::Dumper >> at some future time, pending on its
addition of features like range-list reductions, and other niceties
C<Data::Dump> offers.

Alas, C<Data::Dump> doesn't support C<sub> de-parsing, and C<Data::Dump> doesn't
have internals that could be considered a canonical reference implementation
C<Data::Dumper> is.

So as soon as C<Data::Dumper> has all the features this module wants, it will
switch.

But you shouldn't be relying on the output of this module having a fixed string
representation anyway, its I<purely> for human consumption.

=head2 Controlled Non-Terse Dumping

Two features here could be useful, but I'm still working out how to do it
nicely.

=over 4

=item * It would be nice to stash C<diag> traces in a context and then reveal
the entire leg of the test prior to the failure, but only on failure, such that
when you were just reading a passing TAP series it wasn't burdensome, but when
failures occurred you got all the details you needed still.

=item * Conditionally C<diag>ing in full uncondensed form might eventually be a
feature at user request.

=back

And the above two in conjunction could be really handy.

=head1 INTEROP WITH TEST::STREAM ECOSYSTEM

=head2 IMPORT STYLE

The author of C<Test::Stream> presently indicates their preferred way of
consuming plugins like this one would be as follows:

  use Test::Stream -V1, 'Explain::Terse';

The author of this module finds such a style confusing an unclear to new users
and finds it seriously impedes automatic prerequisite detection.

  use Test::Stream::Bundle::V1, 'Explain::Terse';

This style is less confusing, but not yet perfectly clear.

  use Test::Stream::Bundle::V1;
  use Test::Stream::Plugin::Explain::Terse qw( explain_terse );

is much more obvious what is happening.

=head2 EXPORTER

This module presently uses
L<< C<Test::Stream::Exporter>|Test::Stream::Exporter >> as its exporter
library. This is for inter-operability with the C<Test::Stream> bundling system
which allows for bundles to compose multiple plugins into a single calling
class.

This technique requires a bit of indirection, and requires allowing the
bundle to clearly communicate the name of the bundles caller to its composed
plugins while allowing plugins to augment that callers name-space directly.

But to facilitate this, a specific non-C<import> interface must exist on the
plugin which the C<Test::Stream> infrastructure can use to permit explicit
passing of C<caller()> data without needing to pull cute tricks like
locally redefining C<caller()> like C<Sub::Uplevel>, or imposing limitations
on the C<< ->import(@ARGS) >> syntax, and avoids needing to do strange import
tricks like C<Import::Into> does with C<eval>.

L<< C<Test::Stream@1.302026>|https://metacpan.org/source/EXODIST/Test-Stream-1.302026/lib/Test/Stream.pm >>

  020: sub import {
  021:   my $class = shift;
  022:   my @caller = caller;
  023:
  024:   push @_ => $class->default unless @_;
  025:
  026:   $class->load(\@caller, @_);
  027:
  028:   1;
  029: }
  030: sub load {
  ...
  140: if ($mod->can('load_ts_plugin')) {
  141:   $mod->load_ts_plugin($caller, @$import);
  142: }
  143: elsif (my $meta = Test::Stream::Exporter::Meta->get($mod)) {
  144:   Test::Stream::Exporter::export_from($mod, $caller->[0], $import);
  145: }

L<< C<Test::Stream::Bundle@1.302026>|https://metacpan.org/source/EXODIST/Test-Stream-1.302026/lib/Test/Stream/Bundle.pm >>

  09: default_export import => sub {
  10:    my $class = shift;
  11:    my @caller = caller;
  12:
  13:    my $bundle = $class;
  14:    $bundle =~ s/^Test::Stream::Bundle::/-/;
  15:
  16:    require Test::Stream;
  17:    Test::Stream->load(\@caller, $bundle, @_);
  18: };

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
