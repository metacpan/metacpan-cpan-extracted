package Wikibase::Datatype::Struct;

use strict;
use warnings;

our $VERSION = 0.06;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct - Wikibase structure serialization.

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct::Reference>

Wikibase reference structure serialization.

=item L<Wikibase::Datatype::Struct::Sitelink>

Wikibase sitelink structure serialization.

=item L<Wikibase::Datatype::Struct::Snak>

Wikibase snak structure serialization.

=item L<Wikibase::Datatype::Struct::Statement>

Wikibase statement structure serialization.

=item L<Wikibase::Datatype::Struct::Utils>

Wikibase structure serialization utilities.

=item L<Wikibase::Datatype::Struct::Value>

Wikibase value structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Globecoordinate>

Wikibase globe coordinate structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Item>

Wikibase item structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Monolingual>

Wikibase monolingual structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Property>

Wikibase property structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Quantity>

Wikibase quantity structure serialization.

=item L<Wikibase::Datatype::Struct::Value::String>

Wikibase string structure serialization.

=item L<Wikibase::Datatype::Struct::Value::Time>

Wikibase time structure serialization.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.06

=cut
