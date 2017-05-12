=head1 NAME

XML::Filter::Glossary::XBEL - Implements an XBEL-based glossary system.

=head1 SYNOPSIS

You should really be using I<XML::Filter::Glossary> proper, but since you're here :

 use XML::Filter::Glossary::XBEL;

 my $glossary = XML::Filter::Glossary::XBEL->new();
 my $parser   = XML::SAX::ParserFactory->parser(Handler=>$glossary);

 $glossary->set_keyword("aaronland");
 $parser->parse_uri("/path/to/glossary.xbel");

 print $glossary->result();

=head1 DESCRIPTION

Perform a glossary lookup via an XBEL files.

=cut

package XML::Filter::Glossary::XBEL;
use strict;

$XML::Filter::Glossary::XBEL::VERSION = '0.1';
use base qw (XML::SAX::Base);

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new(%args)

Inherits from I<XML::SAX::Base>

=head1 OBJECT METHODS

=head2 $pkg->set_keyword($text)

Set the keyword to lookup in the glossary.

I<$text> will be compared against :

 # No, the package doesn't use XPath.
 # I just find the syntax handy, sometime.
 /xbel//bookmark[title='$text']

=cut

sub set_keyword {
  my $self = shift;
  $self->{'__keyword'} = $_[0];
}

=head2 $pkg->result()

Returns a string, formatted as an HTML anchor element.

If no match was found, returns undef.

=cut

sub result {
  my $self = shift;
  return undef if (! $self->{'__link'});
  return "<a href = \"".$self->{'__link'}."\">".$self->{'__keyword'}."</a>";
}

sub start_document {
  my $self = shift;

  $self->{'__bookmark'} = 0;
  $self->{'__title'}    = 0;
  $self->{'__match'}    = 0;
  $self->{'__link'}     = undef;
}

sub end_document {
  my $self = shift;

  if (! $self->{'__match'}) {
    $self->{'__link'} = undef;
  }
}

sub start_element {
  my $self = shift;
  my $data = shift;

  return if ($self->{'__match'});

  if ((! $self->{'__bookmark'}) && ($data->{Name} eq "bookmark")) {
    $self->{'__bookmark'} = 1;
  }

  return if (! $self->{'__bookmark'});

  if ($data->{Name} eq "bookmark") {
    $self->{'__link'} = $data->{Attributes}->{'{}href'}->{Value};
    # print $self->{'__link'}."\n";
  }

  $self->{'__title'} = 1 if ($data->{Name} eq "title");
}

sub end_element {
  my $self = shift;
  my $data = shift;

  return if ($self->{'__match'});

  if ($data->{Name} eq "title") {
    $self->{'__title'} = 0;
  }

  if ($data->{Name} eq "bookmark") {
    $self->{'__bookmark'} = 0;
  }

}

sub characters {
  my $self = shift;
  my $data = shift;

  return if ($self->{'__match'});
  return if (! $self->{'__bookmark'});
  return if (! $self->{'__title'});

  if ($data->{Data} eq $self->{'__keyword'}) {
    $self->{'__match'} = 1;
  }
}

=head1 VERSION

0.1

=head1 DATE

September 10, 2002

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO 

L<XML::Filter::Glossary>

=head1 LICENSE

Copyright (c) 2002, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;
