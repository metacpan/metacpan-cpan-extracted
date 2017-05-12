package XML::FeedWriter::Base;

use strict;
use warnings;
use Carp;
use base qw( Class::Accessor::Fast Class::Data::Inheritable );
use Encode;
use DateTimeX::Web;
use XML::Writer;

__PACKAGE__->mk_accessors(qw(
  xml dtx
  _closed _output _encoding _use_cdata
));

__PACKAGE__->mk_classdata( _alias => {} );
__PACKAGE__->mk_classdata( _requires => {} );
__PACKAGE__->mk_classdata( _sort_order => {} );

sub new {
  my ($class, %options) = @_;

  delete $options{version};  # this is for XML::FeedWriter only.

  my $encoding = delete $options{encoding} || 'utf-8';

  my $output;
  my $self = bless {
    xml => XML::Writer->new( OUTPUT => \$output ),
    dtx => DateTimeX::Web->new,
    _output    => \$output,
    _encoding  => $encoding,
    _closed    => 0,
  }, $class;

  $self->_extra_options( \%options );

  my $modules = delete $options{modules} || {};
  my %channel = $self->_canonize( \%options );

  $self->_validate( channel => \%channel );

  $self->xml->xmlDecl( $self->_encoding );

  $self->_root_element( $modules );

  $self->xml->setDataMode(1);
  $self->xml->setDataIndent(2);

  $self->_channel( \%channel );

  return $self;
}

sub _extra_options {}
sub _root_element {}
sub _channel {}

sub add_items {}

sub close {}

sub save {
  my ($self, $file) = @_;

  $self->close unless $self->_closed;

  open my $fh, '>', $file;
  binmode $fh;
  print $fh encode( $self->_encoding, $self->as_string );
  CORE::close $fh;
}

sub as_string { ${ shift->_output } }

sub _data_element {
  my ($self, $key, $data) = @_;

  if ( ref $data eq 'ARRAY' ) {
    $self->xml->dataElement( $key => @{ $data } );
  }
  elsif ( ref $data eq 'HASH' ) {
    my %attr = %{ $data };
    my $value = delete $attr{value};
    $self->xml->dataElement( $key => $value, %attr );
  }
  else {
    $self->xml->dataElement( $key => $data );
  }
}

sub _cdata_element {
  my ($self, $key, $data) = @_;

  if ( $self->_use_cdata ) {
    $self->xml->cdataElement( $key => $data );
  }
  else {
    $self->_data_element( $key => $data );
  }
}

sub _datetime_element {
  my ($self, $key, $data) = @_;

  my $datetime;
  if ( ref $data eq 'ARRAY' ) {
    $datetime = $self->dtx->for_rss20( @{ $data } );
  }
  if ( ref $data eq 'HASH' ) {
    $datetime = $self->dtx->for_rss20( %{ $data } );
  }
  elsif ( ref $data ) {
    $datetime = $self->dtx->for_rss20( $data );
  }
  elsif ( $data && $data =~ /^\d+$/ ) {
    $datetime = $self->dtx->for_rss20( epoch => $data );
  }
  else {
    $datetime = $self->dtx->for_rss20;
  }

  $self->_data_element( $key => $datetime );
}

sub _empty_element {
  my ($self, $key, $hashref) = @_;

  $self->_validate( $key => $hashref );
  $self->xml->emptyTag( $key => %{ $hashref } );
}

sub _element_with_children {
  my ($self, $key, $children) = @_;

  $self->_validate( $key => $children );

  $self->xml->startTag($key);
  foreach my $subkey ( $self->_sort_keys( $children ) ) {
    $self->_data_element( $subkey => $children->{$subkey} );
  }
  $self->xml->endTag($key);
}

sub _duplicable_elements {
  my ($self, $key, $data) = @_;

  if ( ref $data eq 'ARRAY' ) {
    foreach my $item ( @{ $data } ) {
      $self->_data_element( $key => $item );
    }
  }
  else {
    $self->_data_element( $key => $data );
  }
}

sub _element_with_duplicable_children {
  my ($self, $key, $data, $children_name) = @_;
  my @items   = ( ref $data eq 'ARRAY' )
    ? @{ $data }
    : ( $data );

  $self->xml->startTag($key);
  foreach my $item ( @items ) {
    $self->_data_element( $children_name => $item );
  }
  $self->xml->endTag($key);
}

sub _validate {
  my ($self, $type, $hashref) = @_;

  foreach my $req ( @{ $self->_requires->{$type} } ) {
    if ( ref $req eq 'ARRAY' ) {
      croak "$type: $req is required"
        unless defined $hashref->{$req->[0]};
      croak "$type: $req is too long"
        unless length( $hashref->{$req->[0]} ) < $req->[1];
    }
    else {
      croak "$type: $req is required"
        unless defined $hashref->{$req};
    }
  }
}
sub _canonize {
  my ($self, $hashref) = @_;

  my %hash;
  foreach my $key ( keys %{ $hashref } ) {
    $hash{ $self->_alias->{$key} || $key } = $hashref->{$key};
  }
  return %hash;
}

sub _sort_keys {
  my ($self, $hashref) = @_;

  return map  { $_->{key} }
         sort { $b->{order} <=> $a->{order} }
         map  { +{
           key   => $_,
           order => $self->_sort_order->{$_} || 0,
         }}
         keys %{ $hashref };
}

1;

__END__

=head1 NAME

XML::FeedWriter::Base

=head1 DESCRIPTION

This class is a base class for more specific feed writers. See appropriate pods for details.

=head1 METHODS

See L<XML::FeedWriter> for usage.

=head2 new

=head2 add_items

=head2 close

=head2 save

=head2 as_string

=head1 SEE ALSO

L<XML::FeedWriter>, L<XML::FeedWriter::RSS20>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
