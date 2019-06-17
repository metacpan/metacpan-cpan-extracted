package Yancy::Command::backend::copy;
our $VERSION = '1.032';
# ABSTRACT: Copy data between backends

#pod =head1 SYNOPSIS
#pod
#pod     Usage: APPLICATION backend copy DEST_BACKEND SRC_SCHEMA [DEST_SCHEMA]
#pod
#pod         ./myapp.pl backend copy sqlite:prod.db users
#pod         ./myapp.pl backend copy sqlite:prod.db users new_users
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command copies data from the application's backend to another backend.
#pod Use this to set up a new application from an existing application's data,
#pod copy data between environments, or migrate data to a different backend.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Command::backend>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Command';
use Yancy::Util qw( load_backend );

has description => 'Copy data between backends';
has usage => sub { shift->extract_usage };

sub run {
    my ( $self, @argv ) = @_;

    my ( $dest_url, $source_schema, $dest_schema ) = @argv;
    $dest_schema ||= $source_schema;
    my $source_backend = $self->app->yancy->backend;
    my $schema = $self->app->yancy->schema( $source_schema );
    my $id_field = $schema->{'x-id-field'} || 'id';
    my $dest_backend = load_backend( $dest_url, { $dest_schema => $schema } );
    for my $item ( @{ $source_backend->list( $source_schema )->{items} } ) {
        # XXX This is two round-trip requests to the database for every
        # item. We could fetch the entire list to have known IDs, but
        # that could be potentially thousands of rows. Either the
        # backend list() method needs some kind of iterator version so
        # as to not load the entire table before returning, or we need
        # a way for list() to return a single column instead of the
        # entire data set.
        if ( $dest_backend->get( $dest_schema, $item->{ $id_field } ) ) {
            $dest_backend->set( $dest_schema, $item->{ $id_field }, $item );
        }
        else {
            $dest_backend->create( $dest_schema, $item );
        }
    }
}

1;

__END__

=pod

=head1 NAME

Yancy::Command::backend::copy - Copy data between backends

=head1 VERSION

version 1.032

=head1 SYNOPSIS

    Usage: APPLICATION backend copy DEST_BACKEND SRC_SCHEMA [DEST_SCHEMA]

        ./myapp.pl backend copy sqlite:prod.db users
        ./myapp.pl backend copy sqlite:prod.db users new_users

=head1 DESCRIPTION

This command copies data from the application's backend to another backend.
Use this to set up a new application from an existing application's data,
copy data between environments, or migrate data to a different backend.

=head1 SEE ALSO

L<Yancy::Command::backend>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
