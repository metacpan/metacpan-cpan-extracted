package XML::APML::ImplicitData;

use strict;
use warnings;

use base 'XML::APML::ExplicitData';

__PACKAGE__->tag_name('ImplicitData');
__PACKAGE__->is_implicit(1);

1;
__END__

=head1 NAME

XML::APML::ImplicitData - ImplicitData markup

=head1 SYNOPSIS

=head1 DESCRIPTION

Class that represents ImplicitData mark-up for APML

=head1 METHODS

=head2 new

Constructor

=head2 concepts

Get all concepts.
Returns as array in list context.

    my @concepts = $implicit->concepts;

Or returns as array reference.

    my $concepts = $implicit->concepts;

Also, you can set multiple concepts at once.

    $implicit->concepts($concept1, $concept2, $concept3);

=head2 add_concept

Add concept

    $implicit->add_concept($concept);

=head2 sources

Get all sources.
Returns as array in list context.

    my @sources = $implicit->sources;

Or returns as array reference.

    my $sources = $implicit->sources;

Also, you can set multiple sources at once.

    $implicit->sources($source1, $source2, $source3);

=head2 add_source

Add source

    $implicit->add_source($source);

=cut
