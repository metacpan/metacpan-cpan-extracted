package WWW::LogicBoxes::Contact::CA::Agreement;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::LogicBoxes::Types qw( Str );

our $VERSION = '1.11.0'; # VERSION
# ABSTRACT: CA Registrant Agreement

has 'version' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'content' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=pod

=head1 NAME

WWW::LogicBoxes::Contact::CA::Agreement - The Registrant Agreement for a .ca Contact

=head1 SYNOPSIS

    use strict;
    use warnings;

    my $api = WWW::LogicBoxes->new( ... );
    my $agreement = $api->get_ca_registrant_agreement();

    print "Version: " . $agreement->version;

=head1 DESCRIPTION

.ca domain registrations require a specialized CA Agreement be accepted.  This object contains the version of that agreement as well as the raw HTML for displaying the agreement to customers for them to agree to.

=head1 ATTRIBUTES

=head2 B<version>

Str describing the version of the CA Registrant Agreement.

=head2 B<content>

HTML content of the CA Registrant Agreement.

=cut
