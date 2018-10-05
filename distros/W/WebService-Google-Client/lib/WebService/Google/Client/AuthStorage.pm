package WebService::Google::Client::AuthStorage;
our $VERSION = '0.07';

# ABSTRACT: Provide universal methods to fetch tokens from different types of data sources. Default is jsonfile

use Moo;

use WebService::Google::Client::AuthStorage::ConfigJSON;
use WebService::Google::Client::AuthStorage::DBI;
use WebService::Google::Client::AuthStorage::MongoDB;
use Log::Log4perl::Shortcuts qw(:all);

has 'storage' => (
    is      => 'rw',
    default => sub { WebService::Google::Client::AuthStorage::ConfigJSON->new }
);    # by default
has 'is_set' => ( is => 'rw', default => 0 );


sub setup {
    my ( $self, $params ) = @_;
    if ( $params->{type} eq 'jsonfile' ) {
        $self->storage->pathToTokensFile( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    elsif ( $params->{type} eq 'dbi' ) {
        $self->storage( WebService::Google::Client::AuthStorage::DBI->new );
        $self->storage->dbi( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    elsif ( $params->{type} eq 'mongo' ) {
        $self->storage( WebService::Google::Client::AuthStorage::MongoDB->new );
        $self->storage->mongo( $params->{path} );
        $self->storage->setup;
        $self->is_set(1);
    }
    else {
        die "Unknown storage type. Allowed types are jsonfile, dbi and mongo";
    }
}


sub file_exists {
    my ( $self, $filename ) = @_;
    if ( -e $filename ) {
        return 1;
    }
    else {
        return 0;
    }
}

### Below are list of methods that each Storage subclass must provide


sub get_credentials_for_refresh {
    my ( $self, $user ) = @_;
    $self->storage->get_credentials_for_refresh($user);
}

sub get_access_token_from_storage {
    my ( $self, $user ) = @_;
    $self->storage->get_access_token_from_storage($user);
}

sub set_access_token_to_storage {
    my ( $self, $user, $access_token ) = @_;
    $self->storage->set_access_token_to_storage( $user, $access_token );
}

1;

__END__

=pod

=head1 NAME

WebService::Google::Client::AuthStorage - Provide universal methods to fetch tokens from different types of data sources. Default is jsonfile

=head1 VERSION

version 0.07

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
