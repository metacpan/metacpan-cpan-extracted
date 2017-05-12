package WebAPI::DBIC::Resource::Role::SetWritable;
$WebAPI::DBIC::Resource::Role::SetWritable::VERSION = '0.004002';

use Devel::Dwarn;
use Carp qw(confess);

use Moo::Role;


requires 'render_set_as_plain';
requires 'render_item_into_body';
requires 'decode_json';
requires 'set';
requires 'prefetch';
requires 'writable';
requires 'path_for_item';
requires 'allowed_methods';


has item => ( # for POST to create
    is => 'rw',
);

has content_types_accepted => (
    is => 'lazy',
);

sub _build_content_types_accepted {
    return [ {'application/vnd.wapid+json' => 'from_plain_json'} ]
}

around 'allowed_methods' => sub {
    my $orig = shift;
    my $self = shift;
    my $methods = $self->$orig();
    push @$methods, 'POST' if $self->writable;
    return $methods;
};


sub post_is_create { return 1 }

sub create_path_after_handler { return 1 }


sub from_plain_json {
    my $self = shift;
    my $item = $self->create_resource( $self->decode_json($self->request->content) );
    return $self->item($item);
}


sub create_path {
    my $self = shift;
    return $self->path_for_item($self->item);
}


sub create_resource {
    my ($self, $data) = @_;

    my $item = $self->set->create($data);

    # resync with what's (now) in the db to pick up defaulted fields etc
    $item->discard_changes();

    # called here because create_path() is too late for Web::Machine
    $self->render_item_into_body(item => $item)
        if grep {defined $_->{self}} @{$self->prefetch||[]};

    return $item;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Role::SetWritable

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

Handles POST requests for resources representing set resources, e.g. to insert
rows into a database table.

Supports the C<application/json> content type.

=head1 NAME

WebAPI::DBIC::Resource::Role::SetWritable - methods handling requests to update set resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
