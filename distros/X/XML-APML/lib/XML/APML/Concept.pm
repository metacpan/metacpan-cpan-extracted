package XML::APML::Concept;

use strict;
use warnings;

use base 'XML::APML::Node';

__PACKAGE__->tag_name('Concept');

1;
__END__

=head1 NAME

XML::APML::Concept - concept markup

=head1 SYNOPSIS

    my $explicit_concept = XML::APML::Concept->new(
        key   => 'sport',
        value => 0.9,
    );

    # change value
    $explicit_concept->value(0.1);

    $profile->explicit->add_concept($explicit_concept);

    my $implicit_concept = XML::APML::Concept->new(
        key     => 'television',
        value   => 0.77,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
    );
    print $implicit_concept->key;
    print $implicit_concept->value;
    print $implicit_concept->from;
    $dt = DateTime::Format::W3CDTF->new->parse_datetime($implicit_concept->updated);
    print $dt->year;
    print $dt->month;
    $implicit_concept->updated( DateTime::Format::W3CDTF->new->format_datetime( DateTime->now ) );

    $profile->implicit->add_concept($implicit_concept);

=head1 DESCRIPTION

Class that represents Concept mark-up for APML.

=head1 METHODS

=head2 new

Constructor

=head2 key

key accessor

=head2 value

value accessor

=head2 from

from accessor

=head2 updated

updated accessor
get/set W3CDTF(iso8601) formatted string.

=cut

