package XML::Bits;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

use overload
  '""' => sub {shift->stringify},
  fallback => 1;

use base 'Tree::Base';
use Class::Accessor::Classy;
rw 'tag';
ro 'type';
lw 'atts';
ri 'doctype';
ro 'content';
no  Class::Accessor::Classy;

our @EXPORT_OK = qw(T);
BEGIN {
  require Exporter;
  *import = \&Exporter::import;
}

=head1 NAME

XML::Bits - a tree of XML nodes

=head1 SYNOPSIS

  use XML::Bits;

  my $div = XML::Bits->new(div =>);
  $div->create_child(div =>)->create_child(div =>);

  print $div, "\n";

=cut

=head2 new

  my $node = XML::Bits->new($tag => [%attributes], @children);

=cut

sub new {
  my $class = shift;
  my $tag = shift;
  my $self = $class->SUPER::new(tag => $tag);

  $self->{atts} = ref($_[0]) eq 'ARRAY' ? shift(@_) : [];
  my @children = @_;

  if($self->tag eq '') {
    $self->{type} = 'text';
    $self->{content} = join('', @children);
  }
  else {
    $self->{type} = 'node';
    # TODO this is expensive unless we contextually disable re-rooting
    foreach my $child (@children) {
      $self->add_child($child);
    }
  }

  return($self);
} # new ################################################################

=head2 add_child

Adds a child, regardless of the child's previous parenthood.

  $node->add_child($child);

NOTE: there's some questionable issues about the tree parentage and
rerooting here.  Beware of bugs if you move elements around between
trees.  ALSO NOTE:  this API might change such that it is required to
use a different method for this sort of thing.

=cut

sub add_child {
  my $self = shift;
  my ($child) = @_;

  delete $child->{root};
  delete $child->{parent};

  return $self->SUPER::add_child($child);
} # add_child ##########################################################

=head2 is_text

Returns true if this is a text node.

  $node->is_text;

=cut

sub is_text { shift->type eq 'text' }
########################################################################

=head2 stringify

Stringification (and operator overloading support.)

  my $string = $node->stringify;

=cut

sub stringify {
  my $self = shift;

  return($self->{content}) if($self->type eq 'text');

  my $string = '<' . $self->tag;
  if(my $dt = $self->doctype) {
    $string = '<!DOCTYPE ' . $dt . ">\n\n" . $string;
  }

  if(my @atts = $self->atts) {
    $string .= ' ' . join(' ', 
      map({$atts[2*$_] . '="' . $atts[2*$_+1] . '"'} 0..(($#atts-1)/2))
    );
  }

  if(my @kids = $self->children) {
    $string .= '>' .
    join('', map({$_->stringify} @kids)) .
    '</' . $self->tag . '>';
  }
  else {
    $string .= ' />';
  }
  return($string);
} # stringify ##########################################################

=head2 T

A shortcut tag constructor.

  T{tag => [%atts], @content};

=cut

sub T (&) {
  my ($sub) = @_;
  my @what = $sub->();
  #warn "what: (@what)\n";
  foreach my $item (@what) {
    $item = __PACKAGE__->new('', $item) unless(ref($item));
  }
  return(__PACKAGE__->new(@what));
} # T ##################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
