package WebService::Google::Client::Credentials;
our $VERSION = '0.06';

# ABSTRACT: Credentials for particular Client instance. You can use this module as singleton also if you need to share credentials between two or more modules

use Moo;
use Log::Log4perl::Shortcuts qw(:all);
with 'MooX::Singleton';

has 'access_token' => ( is => 'rw' );
has 'user' => ( is => 'rw', trigger => \&get_access_token_for_user )
  ;    # full gmail, like pavel.p.serikov@gmail.com
has 'auth_storage' => (
    is      => 'rw',
    default => sub { WebService::Google::Client::AuthStorage->new }
);     # dont delete to able to configure


sub get_access_token_for_user {
    my $self = shift;
    if ( $self->auth_storage->is_set )
    {    # chech that auth_storage initialized fine
        $self->access_token(
            $self->auth_storage->get_access_token_from_storage( $self->user ) );
    }
    else {
        die "Can get access token for specified user because storage isnt set";
    }
}

1;

__END__

=pod

=head1 NAME

WebService::Google::Client::Credentials - Credentials for particular Client instance. You can use this module as singleton also if you need to share credentials between two or more modules

=head1 VERSION

version 0.06

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
