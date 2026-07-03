package Text::AsciidocDown;

use strict;
use warnings;
use Carp qw(croak);
use version 0.77;

our $VERSION = '0.1.0';

use Text::AsciidocDown::Include ();
use Text::AsciidocDown::Parser ();

sub new {
  my ($class, %opts) = @_;
  return bless { options => \%opts }, $class;
}

sub convert {
  my ($self, $text, $opts) = @_;

  croak 'convert must be called on an object instance (call ->new first)'
    unless ref($self) && eval { $self->isa(__PACKAGE__) };

  $text = '' unless defined $text;
  $opts = _merge_options($self->{options}, $opts);

  $text = Text::AsciidocDown::Include::expand_includes($text, $opts);

  return Text::AsciidocDown::Parser::convert($text, $opts);
}

sub _merge_options {
  my ($base, $overrides) = @_;
  $base ||= {};
  $overrides ||= {};

  my %merged = (%{$base}, %{$overrides});
  if (ref($base->{attributes}) eq 'HASH' || ref($overrides->{attributes}) eq 'HASH') {
    my %attrs = (
      %{ref($base->{attributes}) eq 'HASH' ? $base->{attributes} : {}},
      %{ref($overrides->{attributes}) eq 'HASH' ? $overrides->{attributes} : {}},
    );
    $merged{attributes} = \%attrs;
  }

  return \%merged;
}

1;

__END__

=head1 NAME

Text::AsciidocDown - Lightweight AsciiDoc to Markdown conversion

=head1 SYNOPSIS

  use Text::AsciidocDown;

  my $converter = Text::AsciidocDown->new(
    attributes => {
      'markdown-list-indent' => 4,
    },
  );

  my $asciidoc = <<'ASCIIDOC';
  = Hello, AsciidocDown

  This is a *paragraph* with `inline` formatting.

  == Section

  Here is a list:

  * one
  * two
  * three
  ASCIIDOC

  my $markdown = $converter->convert($asciidoc);
  print $markdown;

=head1 DESCRIPTION

Text::AsciidocDown is a pure Perl, dependency-minimal converter intended to
transform practical AsciiDoc documents into Markdown.

The module supports include pre-merge expansion (optional), parser conversion,
and reference rewrite passes through a single OO interface.

=head1 METHODS

=head2 new

  my $converter = Text::AsciidocDown->new(%opts);

Creates a converter object with default options.

Any option accepted by C<convert> may also be provided here as a default.
Per-call options override constructor defaults.

If no constructor options are provided, defaults are effectively empty.

Special merge behavior:

=over 4

=item * C<attributes>

Constructor and per-call C<attributes> hashes are merged key-by-key, with
per-call keys taking precedence.

=back

=head2 convert

  my $md = $converter->convert($asciidoc, \%opts);

Converts AsciiDoc text to Markdown and returns the converted string.

If C<\%opts> is not provided, constructor defaults are used as-is. If neither
constructor defaults nor per-call options are provided, conversion runs with
empty options (no runtime attributes and include pre-merge disabled).

Accepted options (constructor defaults and/or per call):

=over 4

=item * attributes

Hash reference containing runtime AsciiDoc attributes used by include
pre-merge and parser stages.

Default when unspecified: empty attribute set.

Example:

  attributes => {
    'markdown-list-indent' => 4,
    'hide-uri-scheme' => '',
  }

=item * source_path

Absolute or relative path to the input document being converted.

Used for include pre-merge resolution and diagnostics when processing
C<include::...[]> directives.

Default when unspecified: undefined (include resolution falls back to
C<include.base_dir> when needed).

=item * include

Hash reference controlling include pre-merge behavior.

Default when unspecified: include pre-merge is disabled.

Supported keys:

=over 4

=item * C<enabled>

Boolean. When true, local include directives are expanded before parser
conversion.

Default: false.

=item * C<base_dir>

Base directory used when resolving relative include targets and C<source_path>
is not available.

Default: current working directory.

=item * C<max_depth>

Maximum include recursion depth (default: C<64>).

=item * C<on_missing>

Policy for missing include files: C<error>, C<keep>, or C<drop>.

Default: C<error>.

=item * C<on_cycle>

Controls what happens when include expansion detects an include loop, meaning a file includes itself through a chain

Policy for include cycles: C<error>, C<keep>, or C<drop>.

Default: C<error>.

=item * C<restrict_to_base_dir>

Boolean. When true, include targets must resolve under C<base_dir>.

Default: false.

=item * C<on_missing_tag>

Policy for missing include tag selectors (C<tag>/C<tags>): C<error>, C<keep>,
or C<drop>.

Default: C<error>.

=item * C<on_bad_selector>

Policy for invalid selector syntax (for example C<lines=bad>): C<error>,
C<keep>, or C<drop>.

Default: C<error>.

=item * Policy values: C<error>, C<keep>, C<drop>

Shared behavior across C<on_missing>, C<on_cycle>, C<on_missing_tag>, and
C<on_bad_selector>:

  C<error> - stop conversion and throw an error
  C<keep>  - keep the original C<include::...[]> line unchanged
  C<drop>  - remove the C<include::...[]> line from output

=back

=back

=head1 NOTES

- Include pre-merge currently supports local filesystem includes.
- Include selector support includes C<tag>, C<tags>, and C<lines>.
- Some advanced Asciidoctor include and xref semantics remain intentionally
  conservative.

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

Same terms as Perl itself.

=cut
