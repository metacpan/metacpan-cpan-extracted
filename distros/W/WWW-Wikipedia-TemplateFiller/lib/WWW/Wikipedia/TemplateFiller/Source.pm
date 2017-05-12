package WWW::Wikipedia::TemplateFiller::Source;
use warnings;
use strict;

# Plus:  +Field means show field only if extended-fields is enabled
# Minus: -Field means always show, regardless of extended-fields status
# Other:  Field means show only if filled

use Date::Calc;
use XML::Writer;
use HTML::Entities;
use Tie::IxHash;
use Carp;

=head1 NAME

WWW::Wikipedia::TemplateFiller::Source - Base class for data sources

=head1 DESCRIPTION

This is an internal base class from which data source classes
inherit. From an end-user perspective, there is unlikely any reason to
know anything about this module. That said, feel free to poke
around.

=head1 METHODS

=head2 new

  my $source = new WWW::Wikipedia::TemplateFiller::Source( filler => $filler, %attrs );

Create a new source object with the given filler and attributes
C<%attrs>.

=cut

sub new {
  my( $pkg, %attrs ) = @_;
  croak "no TemplateFiller object provided as 'filler' attr" unless $attrs{filler};

  if( my $class = $pkg->search_class ) {
    $attrs{__search} = new WWW::Search($class);
  }

  my $self = bless \%attrs, $pkg;
  return $self;
}

sub __result_from_cache { }
sub __result_to_cache { }

sub __cache_key {
  my( $self, $id ) = @_;
  return $self->type.'-'.$id;
}

=head2 _search_obj

  my $search = $source->_search_obj;

(Internal method.) Returns the L<WWW::Search> object used by this
source class. Only useful for source subclasses that define a
C<search_class()> class method, which defines the L<WWW::Search>
module to be used for backend searches.

=cut

sub _search_obj { shift->{__search} }

=head2 _search

  my $result = $source->_search($id);

(Internal method.) Performs a basic L<WWW::Search> search. Only useful
for source subclasses that define a C<search_class()> class
method. Essentially the same as:

  $source->_search->native_query($id);
  return $source->_search->next_result;

except that a cache may be used internally to speed things up.

=cut

sub _search {
  my( $self, $id ) = @_;

  my $result = $self->__result_from_cache( $id );
  if( not $result ) {
    $self->_search_obj->native_query($id);
    $result = $self->_search_obj->next_result;
    $self->__result_to_cache( $id => $result );
  }

  return $result;
}

=head2 template_name

Class method only; used by source classes to define the title of the
template they will be populating. Example for PubmedId source:

  sub template_name { 'cite journal' }

=cut

sub template_name { croak "no 'template_name' class method specified in this source" }

=head2 filler

Returns the filler associated with this source.

=cut

sub filler { shift->{filler} }

=head2 source_url

Returns the url associated with this source data.

=cut

sub source_url { shift->{__source_url} }

sub __source_obj {
  my( $self, $attrs ) = @_;

  while( my($k,$v) = each %$attrs ) {
    ( my $plain_k = $k ) =~ s/^\W//;
    $self->{$k} = $v;
    $self->{$plain_k} = $v;
  }

  return $self;
}

=head2 fill

  my $template = $source->fill;

Fills the appopriate template with data from this source.

=cut

sub fill {
  my( $self, %args ) = @_;
  $self->{_basic_fields} = $self->template_basic_fields( %args );
  return $self;
}

=head2 output

  my $markup = $source->output( %args );

Returns the filled template output. This is where the magic is.

=cut

sub output {
  my( $self, %args ) = @_;
  $self->fill(%args) unless $self->{_basic_fields};

  my $ref_name = $self->get_ref_name;
  my $add_ref_tag = $args{add_ref_tag};
  my $vertical = $args{vertical};
  my $format = $args{format} ? $args{format} : 'text';
  my $add_param_space = $args{add_param_space};
  my $show_extended = $args{extended};

  tie( my %all_fields, 'Tie::IxHash' );
  %all_fields = ( %{ $self->{_basic_fields} }, %{ $self->template_output_fields(%args) } );

  my @pairs = ( );
  while( my( $param, $info ) = each %all_fields ) {
 			die $param unless ref $info;
    $info->{show} ||= 'always';
    next if $info->{show} eq 'if-filled' and !defined($info->{value});
    next if $info->{show} eq 'if-extended' and !$show_extended;

    my $param_value = $info->{value} || '';
       $param_value =~ s/\|/&#124;/g;

    my $pair = sprintf ( ($add_param_space ? "%s = %s" : "%s=%s"), $param, $param_value );
    push @pairs, $pair;
  }

  my $citation;
  $citation = "{{".$self->template_name;
  $citation .= $vertical ? "\n" : ' ';
  foreach my $pair ( @pairs ) {
    $citation .= ' ' unless $vertical;
    $citation .= !$vertical && $citation =~ s/\s*$// ? ' ' : '';
    $citation .= $add_param_space ? "| $pair" : "|$pair";
    $citation .= "\n" if $vertical;
  }
  $citation .= "}}";

  if( $add_ref_tag ) {
    $citation = $ref_name
      ? sprintf( '<ref name="%s">%s</ref>', $ref_name, $citation )
      : sprintf( '<ref>%s</ref>', $citation );
  }

  if( $format eq 'xml' ) {
    my $output = '';
    my $writer = new XML::Writer( OUTPUT => \$output );
    $writer->startTag( 'wikitemplate', application => 'cite' );
      $writer->startTag( 'content' );
      $writer->characters( $citation );
      $writer->endTag();

      $writer->startTag('paramlist');
      while( my( $param, $info ) = each %all_fields ) {
        $writer->startTag( 'param', name => $param );
        $writer->characters($info->{value});
        $writer->endTag();
      }
      $writer->endTag();

    $writer->endTag;
    $writer->end;
    $writer->close;

    return $output;
  }

  $citation = encode_entities( $citation ) if $args{encode_entities};

  return $citation;
}

=head2 template_basic_fields

Used in subclasses. Static class method that returns an ordered hash
of fields to be populated only during the call to C<fill()>.

=cut

sub template_basic_fields { croak "no 'template_basic_fields' provided by this source" }

=head2 template_output_fields

Used in subclasses. Static class method that returns an ordered hash
of fields to be populated only during the call to C<output()>.

=cut

sub template_output_fields { {} }

=head2 get_ref_name

  my $id = $source->get_ref_name;

Returns the ID to be used in the C<E<lt>refE<gt>> tag. Wraps around the
C<template_ref_name()> method to provide wiki escaping.

=cut

sub get_ref_name {
  my $self = shift;
  my $ref_name = $self->template_ref_name;

  # Arcadian asks that quotation marks are removed from ref_name
  # so that MediaWiki renders the ref properly
  $ref_name =~ s/[\"\']//g;

  return $ref_name;
}

=head2 template_ref_name

Returns the ID to be used in the C<E<lt>refE<gt>> tag. You should be
using C<get_ref_name()> instead, probably.

=cut

sub template_ref_name { my $pkg = shift; croak ref($pkg).' does not define a template_ref_name() method' }

=head2 type

  my $type = $source->type;

Returns the type of source this is.

=cut

sub type {
  my $self = shift;
  ( my $type = ref $self || $self ) =~ s/.*::(.*)//;
  return lc $type;
}

sub __today_and_now {
  my @ymd = map { $_ < 10 ? "0$_" : $_ } Date::Calc::Today();
  return sprintf '%s-%s-%s', @ymd;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-wikipedia-templatefiller at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Wikipedia-TemplateFiller>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Wikipedia::TemplateFiller::Source

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Wikipedia-TemplateFiller-Source>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Wikipedia-TemplateFiller-Source>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Wikipedia-TemplateFiller-Source>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Wikipedia-TemplateFiller-Source>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
