package Text::AsciidocDown::Refs;

use strict;
use warnings;

our $VERSION = '0.1.0';

sub new_index {
  return {
    by_id => {},
    by_title => {},
  };
}

sub register_heading {
  my ($idx, $attrs, $title, $explicit_id, $reftext) = @_;
  return unless ref($idx) eq 'HASH';

  my $auto_id = _auto_id($attrs, $title);
  my $id = defined($explicit_id) && $explicit_id ne '' ? $explicit_id : $auto_id;

  my $entry = {
    id => $id,
    auto_id => $auto_id,
    title => $title,
    reftext => (defined($reftext) && $reftext ne '') ? $reftext : $title,
  };

  $idx->{by_id}{$id} = $entry;
  $idx->{by_title}{$title} ||= $entry;
  return $entry;
}

sub resolve_target {
  my ($idx, $target) = @_;
  return undef unless ref($idx) eq 'HASH';
  return undef unless defined $target && $target ne '';

  return $idx->{by_id}{$target} if exists $idx->{by_id}{$target};
  return $idx->{by_title}{$target} if exists $idx->{by_title}{$target};
  return undef;
}

sub rewrite_links {
  my ($idx, $markdown) = @_;
  return '' unless defined $markdown;
  return $markdown unless ref($idx) eq 'HASH';

  $markdown =~ s{\[([^\]]+)\]\(#!([^\)]+)\)}{_rewrite_link($idx, $1, $2)}ge;
  return $markdown;
}

sub _rewrite_link {
  my ($idx, $label, $target) = @_;
  my $entry = resolve_target($idx, $target);
  if ($entry) {
    return '[' . $label . '](#' . $entry->{auto_id} . ')';
  }
  return '[' . $label . '](#' . $target . ')';
}

sub _auto_id {
  my ($attrs, $title) = @_;
  $title = '' unless defined $title;
  my $idprefix = ref($attrs) eq 'HASH' ? ($attrs->{idprefix} // '_') : '_';
  my $idseparator = ref($attrs) eq 'HASH' ? ($attrs->{idseparator} // '_') : '_';

  my $slug = lc $title;
  $slug =~ s/[^a-z0-9]+/ /g;
  $slug =~ s/^\s+|\s+$//g;
  $slug =~ s/\s+/$idseparator/g;
  $slug = 'section' if $slug eq '';
  return $idprefix . $slug;
}

1;

__END__

=head1 NAME

Text::AsciidocDown::Refs - Reference index and link rewriting for AsciiDoc

=head1 SYNOPSIS

  use Text::AsciidocDown::Refs;

  my $idx = Text::AsciidocDown::Refs::new_index();
  Text::AsciidocDown::Refs::register_heading($idx, $attrs, $title);
  my $output = Text::AsciidocDown::Refs::rewrite_links($idx, $markdown);

=head1 DESCRIPTION

This module maintains a cross-reference index for AsciiDoc section headings
and rewrites internal xref links (C<#!target>) to their resolved anchors.
It is not intended for direct use; callers should use the OO interface
provided by L<Text::AsciidocDown>.

=head1 INTERFACE

=head2 new_index

  my $idx = Text::AsciidocDown::Refs::new_index();

Creates a new, empty reference index.

=head2 register_heading

  Text::AsciidocDown::Refs::register_heading($idx, $attrs, $title, $explicit_id, $reftext);

Registers a heading in the reference index for later xref resolution.

=head2 resolve_target

  my $entry = Text::AsciidocDown::Refs::resolve_target($idx, $target);

Looks up a target (by ID or title) in the reference index.

=head2 rewrite_links

  my $output = Text::AsciidocDown::Refs::rewrite_links($idx, $markdown);

Rewrites internal xref markers (C<#!target>) to resolved heading anchors.

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

Same terms as Perl itself.

=cut
