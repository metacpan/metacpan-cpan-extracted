package Tie::CHI;
BEGIN {
  $Tie::CHI::VERSION = '0.02';
}
use CHI;
use Scalar::Util qw(blessed);
use strict;
use warnings;

sub TIEHASH {
    my ( $class, $cache ) = @_;

    if ( ref($cache) eq 'HASH' ) {
        $cache = CHI->new(%$cache);
    }
    elsif ( !( blessed($cache) && $cache->isa('CHI::Driver') ) ) {
        die "must pass a hash of options or a CHI object";
    }
    my $self = bless { _cache => $cache }, $class;
    return $self;
}

sub _cache {
    return $_[0]->{_cache};
}

sub STORE {
    my ( $self, $key, $value ) = @_;
    $self->_cache->set( $key, $value );
}

sub FETCH {
    my ( $self, $key ) = @_;
    return $self->_cache->get($key);
}

sub FIRSTKEY {
    my ($self) = @_;
    $self->{_keys_iterator} = $self->_cache->get_keys_iterator();
    return $self->{_keys_iterator}->();
}

sub NEXTKEY {
    my ($self) = @_;
    return $self->{_keys_iterator}->();
}

sub EXISTS {
    my ( $self, $key ) = @_;
    return $self->_cache->is_valid($key);
}

sub DELETE {
    my ( $self, $key ) = @_;
    $self->_cache->remove($key);
}

sub CLEAR {
    my ($self) = @_;
    $self->_cache->clear();
}

sub SCALAR {
    my ($self) = @_;
    defined( $self->FIRSTKEY );
}

1;



=pod

=head1 NAME

Tie::CHI - Tied hash to persistent CHI cache

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Tie::CHI;

    my %cache;

    # Pass CHI options to tie
    #
    tie %cache, 'Tie::CHI', { driver => 'File', root_dir => '/path/to/root' };
    tie %cache, 'Tie::CHI',
      {
        driver             => 'Memcached::libmemcached',
        namespace          => 'homepage',
        servers            => [ "10.0.0.15:11211", "10.0.0.15:11212" ],
        default_expires_in => '10 min'
      } );

    # or pass an existing CHI object
    #
    my $chi_object = CHI->new(...);
    tie %cache, 'Tie::CHI', $chi_object;

    # Perform cache operations
    #
    my $customer = $cache{$name};
    if ( !defined $customer ) {
          $customer = get_customer_from_db($name);
          $cache{$name} = $customer;
    }
    delete( $cache{$name} );

    # Break the binding
    #
    untie(%cache);

=head1 DESCRIPTION

Tie::CHI implements a tied hash connected to a L<CHI|CHI> cache. It can be used
with any of CHI's backends (L<File|CHI::Driver::File>,
L<Memcached|CHI::Driver::Memcached>, L<DBI|CHI::Driver::DBI>, etc.)

Usage is one of the following:

    tie %cache, 'Tie::CHI', $hash_of_chi_options;
    tie %cache, 'Tie::CHI', $existing_chi_cache;

A read/write/delete on the tied hash will result in a C<get>/C<set>/C<remove>
on the underlying cache. C<keys> and C<each> will be supported if the
underlying CHI driver supports C<get_keys>.

There is no way to specify expiration for an individual C<set>, but you can
pass C<expires_in>, C<expires_at> and/or C<expires_variance> to the tie to
specify default expiration. e.g.

    tie %cache, 'Tie::CHI', { 
        namespace => 'products',
        driver => 'DBI',
        dbh => DBIx::Connector->new(...),
        expires_in => '4 hours',
        expires_variance => '0.2'
    };

=head1 SUPPORT AND DOCUMENTATION

Questions and feedback are welcome, and should be directed to the perl-cache
mailing list:

    http://groups.google.com/group/perl-cache-discuss

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-CHI
    bug-tie-chi@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-tie-chi/tree/master
    git clone git://github.com/jonswar/perl-tie-chi.git

=head1 SEE ALSO

L<CHI|CHI>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

