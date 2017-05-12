package WWW::Ohloh::API::ActivityFacts;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/ any /;
use WWW::Ohloh::API::ActivityFact;

our $VERSION = '0.3.2';

my @ohloh_of : Field : Arg(ohloh);
my @project_of : Field : Arg(project);
my @analysis_of : Field : Arg(analysis);
my @facts_of : Field;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _init : Init {
    my $self = shift;

    my ( $url, $xml ) =
      $ohloh_of[$$self]
      ->_query_server( "projects/$project_of[ $$self ]/analyses/"
          . "$analysis_of[ $$self ]/activity_facts.xml" );

    $facts_of[$$self] =
      [ map { WWW::Ohloh::API::ActivityFact->new( xml => $_ ) }
          $xml->findnodes('activity_fact') ];

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub as_xml {
    my $self = shift;
    my $xml;
    my $w = XML::Writer->new( OUTPUT => \$xml );

    $w->startTag('activity_facts');

    $xml .= $_->as_xml for @{ $facts_of[$$self] };

    $w->endTag;

    return $xml;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub all {
    my $self = shift;

    return @{ $facts_of[$$self] };
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub latest {
    my $self = shift;
    return $facts_of[$$self][-1];
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub total {
    my $self = shift;
    return scalar @{ $facts_of[$$self] };
}

'end of WWW::Ohloh::API::ActivityFacts';
__END__

=head1 NAME

WWW::Ohloh::API::ActivityFacts - an Ohloh project's set of activity facts

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $project = $ohloh->get_project( $project_id );
    my $facts =  $ohloh->activity_facts;

    print "number of facts for the project: ", $facts->total;

=head1 DESCRIPTION

W::O::A::ActivityFacts gathers all the activity facts known 
about a project. 
To be properly populated, it must be retrieved via
the C<get_activity_facts> method of a L<WWW::Ohloh::API> object,
or the C<activity_facts()> method of a L<WWW::Ohloh::API::Project>
object.

=head1 METHODS 

=head2 all

Return the retrieved activity facts as a list of
L<WWW::Ohloh::API::ActivityFact> objects.

Example:

    # sum the overall number of commits for the project
    my $commits;
    for my $fact ( $facts->all ) {
        $commits += $fact->commits;
    }

=head3 as_xml

Return the activity facts 
as an XML string.  Note that this is not the exact xml document as returned
by the Ohloh server. 

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::ActivityFact>, 
L<WWW::Ohloh::API::Language>, 
L<WWW::Ohloh::API::Project>,
L<WWW::Ohloh::API::Analysis>, 
L<WWW::Ohloh::API::Account>.


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/activity_fact

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


