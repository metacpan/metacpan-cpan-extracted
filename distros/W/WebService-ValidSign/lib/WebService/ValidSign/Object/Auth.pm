package WebService::ValidSign::Object::Auth;
our $VERSION = '0.002';
use Moo;
extends 'WebService::ValidSign::Object';

# ABSTRACT: A Signer auth object (whatever that may be)

use Types::Standard qw(Str ArrayRef);

has '+type' => (required => 0);

has challenges => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    default => sub { [] }
);

has scheme => (
    is      => 'rw',
    isa     => Str,
    default => 'NONE'
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Auth - A Signer auth object (whatever that may be)

=head1 VERSION

version 0.002

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
