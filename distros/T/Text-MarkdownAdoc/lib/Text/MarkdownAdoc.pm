package Text::MarkdownAdoc;

use 5.016;
use strict;
use warnings;

use Text::MarkdownAdoc::Parser;

our $VERSION = '0.1.0';

#===========================================================================
# Public OO Facade
#===========================================================================

sub new
{
   my ($class, %opts) = @_;

   my $self = {options => {%opts},};

   bless $self, $class;
   return $self;
}

sub convert
{
   my ($self, $text, $opts) = @_;

   # Merge constructor defaults with per-call overrides.
   # attributes hashes are merged key-by-key.
   my %merged = %{$self->{options}};
   if ($opts && ref $opts eq 'HASH')
   {
      for my $key (keys %$opts)
      {
         if ($key eq 'attributes' &&
             ref $self->{options}{attributes} eq 'HASH' &&
             ref $opts->{attributes} eq 'HASH')
         {
            $merged{attributes} = {%{$self->{options}{attributes}}, %{$opts->{attributes}},};
         }
         else
         {
            $merged{$key} = $opts->{$key};
         }
      }
   }

   # Delegate to the parser
   my $parser = Text::MarkdownAdoc::Parser->new(%merged);
   return $parser->parse($text);
}

1;

__END__

=head1 NAME

Text::MarkdownAdoc - Convert Markdown (GFM + kramdown) to AsciiDoc

=head1 SYNOPSIS

    use Text::MarkdownAdoc;

    my $converter = Text::MarkdownAdoc->new(
        attributes => { 'toc' => 'auto' },
    );

    my $asciidoc = $converter->convert($markdown_text, {
        attributes => { 'imagesdir' => 'img' },
    });

=head1 DESCRIPTION

Text::MarkdownAdoc is a pure Perl converter that transforms Markdown
documents into clean AsciiDoc output suitable for use with Asciidoctor.

The primary target dialect is GitHub-Flavored Markdown (GFM) plus
kramdown extensions (definition lists, footnotes).  Pure CommonMark
is also supported as a subset.

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new converter instance.  Options provided to the constructor
become defaults for all subsequent C<convert> calls.

Options:

=over 4

=item C<attributes>

A hashref of AsciiDoc attributes to inject into the output document
header.  Attributes from the constructor and per-call options are
merged key-by-key.

=back

=head1 METHODS

=head2 convert($text, \%per_call_opts)

Converts Markdown text to AsciiDoc.  Returns the converted string.

Per-call options are merged with constructor defaults.  The
C<attributes> hash is merged key-by-key; all other options are
overridden by the per-call value.

=head1 VERSION

0.1.0

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::MarkdownAdoc::Parser>,
L<Text::MarkdownAdoc::Inline>,
L<Text::MarkdownAdoc::Refs>

=cut
