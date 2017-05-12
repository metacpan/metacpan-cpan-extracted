package WWW::AdServer::Database;
{
  $WWW::AdServer::Database::VERSION = '1.01';
}
use Moo;

has dsn => (
    is       => 'ro',
    required => 1,
);

has type => (
    is       => 'rw',
);

has db => (
    is    => 'rw',
);


sub BUILD {
    my ($self) = @_;

    if (not $self->type) {
        if ($self->dsn =~ /\.yml$/) {
            $self->type('YAML');
            with 'WWW::AdServer::Database::YAML';
            $self->db( $self->load($self->dsn) );
            #$self->db( WWW::AdServer::Database::YAML->new );
            #$self->db->load($self->dsn);
        }
    }
    return;
}

1;

__END__

=pod

=head1 NAME

WWW::AdServer::Database

=head1 VERSION

version 1.01

=head1 AUTHOR

Gabor Szabo <szabgab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
