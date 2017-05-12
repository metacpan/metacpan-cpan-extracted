package WebAPI::DBIC::Resource::Role::Set;
$WebAPI::DBIC::Resource::Role::Set::VERSION = '0.004002';

use Moo::Role;


requires 'encode_json';
requires 'render_item_as_plain_hash';


has content_types_provided => (
    is => 'lazy',
);

sub _build_content_types_provided {
    return [ { 'application/vnd.wapid+json' => 'to_plain_json'} ]
}

sub to_plain_json { return $_[0]->encode_json($_[0]->render_set_as_plain($_[0]->set)) }

sub allowed_methods { return [ qw(GET HEAD) ] }

# Avoid complaints about $set:
## no critic (NamingConventions::ProhibitAmbiguousNames)

sub render_set_as_plain {
    my ($self, $set) = @_;
    my $set_data = [ map { $self->render_item_as_plain_hash($_) } $set->all ];
    return $set_data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Role::Set

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

Handles GET and HEAD requests for requests representing set resources, e.g.
the rows of a database table.

Supports the C<application/json> content type.

=head1 NAME

WebAPI::DBIC::Resource::Role::Set - methods related to handling requests for set resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
