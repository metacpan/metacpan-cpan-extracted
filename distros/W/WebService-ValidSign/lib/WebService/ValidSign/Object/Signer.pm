package WebService::ValidSign::Object::Signer;
our $VERSION = '0.004';
use Moo;

extends 'WebService::ValidSign::Object::Sender';
use WebService::ValidSign::Object::Auth;

# ABSTRACT: A ValidSign signer object

has phone => (
    is => 'rw'
);

has auth => (
    is      => 'rw',
    lazy    => 1,
    builder => 1,
);

has knowledge_based_authentication => (
    is => 'rw',
);

sub _build_auth {
    return WebService::ValidSign::Object::Auth->new();

}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Signer - A ValidSign signer object

=head1 VERSION

version 0.004

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
