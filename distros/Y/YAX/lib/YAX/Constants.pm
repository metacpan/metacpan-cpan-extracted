package YAX::Constants;

use strict;
use base qw/Exporter/;

our @NODE_TYPES = qw(
    &ELEMENT_NODE
    &ATTRIBUTE_NODE
    &TEXT_NODE
    &CDATA_SECTION_NODE
    &ENTITY_REFERENCE_NODE
    &ENTITY_NODE
    &PROCESSING_INSTRUCTION_NODE
    &COMMENT_NODE
    &DOCUMENT_NODE
    &DOCUMENT_TYPE_NODE
    &DOCUMENT_FRAGMENT_NODE
    &NOTATION_NODE
);

sub ELEMENT_NODE                () { 1 }
sub ATTRIBUTE_NODE              () { 2 }
sub TEXT_NODE                   () { 3 }
sub CDATA_SECTION_NODE          () { 4 }
sub ENTITY_REFERENCE_NODE       () { 5 }
sub ENTITY_NODE                 () { 6 }
sub PROCESSING_INSTRUCTION_NODE () { 7 }
sub COMMENT_NODE                () { 8 }
sub DOCUMENT_NODE               () { 9 }
sub DOCUMENT_TYPE_NODE          () { 10 }
sub DOCUMENT_FRAGMENT_NODE      () { 11 }
sub NOTATION_NODE               () { 12 }

our @EXPORT_OK = @NODE_TYPES;

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;
__END__

=head1 NAME

YAX::Constants - constants used by YAX

=head1 SYNOPSIS

 # import all constants
 use YAX::Constants qw/:all/;
 
 # import just the ones you need
 use YAX::Constants qw/ELEMENT_NODE TEXT_NODE/;

=head1 DESCRIPTION

This module exports constant subs use by YAX nodes as their `type' field.
The constants mirror the constants used by the W3C DOM API. The full list
is:

=over 4

=item ELEMENT_NODE

=item ATTRIBUTE_NODE

=item TEXT_NODE

=item CDATA_SECTION_NODE

=item ENTITY_REFERENCE_NODE

=item ENTITY_NODE

=item PROCESSING_INSTRUCTION_NODE

=item COMMENT_NODE

=item DOCUMENT_NODE

=item DOCUMENT_TYPE_NODE

=item DOCUMENT_FRAGMENT_NODE

=item NOTATION_NODE

=back

=head1 AUTHOR

 Richard Hundt

=head1 SEE ALSO

L<YAX::Element>, L<YAX::Text>, L<YAX::Fragment>

=head1 LICENSE

This program is free software and may be modified and distributed under the
same terms as Perl itself.
