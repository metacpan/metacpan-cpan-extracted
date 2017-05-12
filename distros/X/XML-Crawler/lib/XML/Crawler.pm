package XML::Crawler;

use strict;
use warnings;

use English qw( -no_match_vars $EVAL_ERROR );
use XML::LibXML;
require Exporter;

our @ISA = qw( Exporter );

our @EXPORT_OK = qw(
    xml_to_ra
);

our $VERSION = '0.01';

sub xml_to_ra {
    my ($xml) = @_;

    my $doc;

    eval {
        $doc = XML::LibXML->load_xml( string => $xml );
    };

    return
        if $EVAL_ERROR;

    return {}
        if not $doc;

    return _crawl($doc);
}

sub _crawl {
    my ( $node ) = @_;

    my $name       = $node->nodeName();
    my %attributes = map { ( $_->nodeName() => $_->getValue() ) } grep { $_ } $node->attributes();
    my $text;
    my @children;

    my @child_nodes = $node->nonBlankChildNodes();

    if (@child_nodes) {

        @children = map { _crawl( $_ ) } @child_nodes;

        if ( @children == 1 && not ref $children[0] ) {

            $text = pop @children;
        }
    }
    else {

        $text = $node->textContent();
    }

    return $text
        if $text && $name eq '#text';

    my @result = ( $name );

    push @result, \%attributes
        if keys %attributes;

    push @result, $text
        if $text;

    push @result, \@children
        if @children;

    return \@result;
}

1;

__END__

=head1 NAME

XML::Crawler - Crawl an XML document to create a Perl data structure which
resembles the XML data structure.

=head1 SYNOPSIS

  use XML::Crawler qw( xml_to_ra );

  my $array_ref = xml_to_ra( $xml );

=head1 DESCRIPTION

This:

  <?xml version="1.0"?>
  <fruit type="banana">yellow</fruit>

Is translated to:

  [
      '#document' => [
          [ 'fruit' => { 'type' => 'banana' } => 'yellow' ]
      ]
  ]

This:

  <?xml version="1.0"?>
  <contact-info>
      <name>Jane Smith</name>
      <company>AT&amp;T</company>
      <phone>(212) 555-4567</phone>
  </contact-info>

Is translated to:

  [
      '#document' => [ [
              'contact-info' => [
                  [ 'name'    => 'Jane Smith' ],
                  [ 'company' => 'AT&T' ],
                  [ 'phone'   => '(212) 555-4567' ],
              ],
          ],
      ],
  ];

=head1 SEE ALSO

XML::LibXML

There are more modules in the XML namespace than one can
shake a stick at.

=head1 AUTHOR

Dylan Doxey, E<lt>dylan.doxey@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dylan Doxey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
