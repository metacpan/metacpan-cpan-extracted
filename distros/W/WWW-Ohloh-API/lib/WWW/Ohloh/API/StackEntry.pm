package WWW::Ohloh::API::StackEntry;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/ any /;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh);
my @request_url_of : Field : Arg(request_url) : Get( request_url );
my @xml_of : Field : Arg(xml);

my @api_fields = qw/
  id
  created_at
  stack_id
  project_id
  /;

__PACKAGE__->create_field( '%' . $_, ":Set(_set_$_)", ":Get($_)" )
  for @api_fields;

my @project : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my $dom = $xml_of[$$self] or return;

    for my $f (@api_fields) {
        my $method = "_set_$f";
        $self->$method( $dom->findvalue("$f/text()") );
    }

    if ( my ($project_xml) = $dom->findnodes('//project[1]') ) {
        $project[$$self] = WWW::Ohloh::API::Project->new(
            ohloh => $ohloh_of[$$self],
            xml   => $project_xml,
        );
    }

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('stack_entry');

    for my $f (@api_fields) {
        $w->dataElement( $f => $self->$f );
    }

    if ( my $project = $project[$$self] ) {
        $xml .= $project->as_xml;
    }

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub project {
    my $self     = shift;
    my $retrieve = shift;
    $retrieve = 1 unless defined $retrieve;

    if ($retrieve) {
        $project[$$self] ||=
          $ohloh_of[$$self]->get_project( $self->project_id );
    }

    return $project[$$self];
}

'end of WWW::Ohloh::API::StackEntry';
__END__

=head1 NAME

WWW::Ohloh::API::StackEntry - A project entry in a stack

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );

    # from an account
    my @entries = $ohloh->get_account_stack( $account_id )->stack_entries;

    # from a project
    my @stacks = $ohloh->get_project_stacks( $project_id );
    my @entries = $stacks[0]->stack_entries;


=head1 DESCRIPTION

W::O::A::StackEntry represents one project in a stack.

=head1 METHODS 

=head2 API Data Accessors

=head3 $entry->id

Returns the unique id for the stack entry.

=head3 $entry->created_at

Returns the time at which the project was added to the stack.

=head3 $entry->stack_id

Returns the id of the stack containing the entry.

=head3 $entry->project_id

Returns the id of the project.

=head3 $entry->project( $retrieve )

Returns the project as a L<WWW::Ohloh::API::Project> object.

If the optional argument I<$retrieve> is given and false, the project
will not be queried from the Ohloh server if it's not already known,
and the method will return nothing.

=head2 Other Methods

=head3 as_xml

Return the stack entry as an XML string.  
Note that this is not the same xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>. 


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/stack_entry

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut


