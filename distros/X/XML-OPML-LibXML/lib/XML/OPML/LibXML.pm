package XML::OPML::LibXML;

use strict;
our $VERSION = '0.03';

use XML::LibXML;
use XML::OPML::LibXML::Document;

sub new {
    my $class = shift;
    bless {
        parser => XML::LibXML->new,
    }, $class;
}

for my $method (qw( parse_string parse_fh parse_file )) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        my $dom = $self->{parser}->$method(@_);
        XML::OPML::LibXML::Document->new_from_doc($dom);
    };
}

1;
__END__

=head1 NAME

XML::OPML::LibXML - Parse OPML document with LibXML parser

=head1 SYNOPSIS

  use XML::OPML::LibXML;

  my $parser = XML::OPML::LibXML->new;
  my $doc    = $parser->parse_file($opml_file);

  # Alternatively, you can create Document object using XML::LibXML::Document
  use XML::LibXML;
  my $dom = XML::LibXML->new->parse_file($opml_file);
  my $doc = XML::OPML::LibXML::Document->new_from_doc($dom);

  # OPML document head properties
  $doc->title;
  $doc->date_created;
  $doc->date_modified;
  $doc->owner_name;

  # XML::OPML::LibXML::Outline
  my @outline = $doc->outline;
  for my $outline (@outline) {
      $outline->title;
      $outline->text;
      if ($outline->is_container) {
          my @outline = $outline->children;
          # do some recursive stuff, see also walkdown()
      } else {
          $outline->type;
          $outline->xml_url;
          $outline->html_url;
      }
  }

  # depth-first walkdown the tree
  $doc->walkdown(\&callback);
  sub callback {
      my $outline = shift;
      # ...
  }

=head1 DESCRIPTION

XML::OPML::LibXML is an OPML parser written using XML::LibXML. This
module is part of spin-off CPANization of Plagger plugins.

For now, all this module does is just parsing an OPML document. The
API is very simple and limited to low-level access, yet.

B<NOTE>: This module is not designed to be a drop-in replacement of
XML::OPML.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::OPML>, L<Plagger>

=cut
