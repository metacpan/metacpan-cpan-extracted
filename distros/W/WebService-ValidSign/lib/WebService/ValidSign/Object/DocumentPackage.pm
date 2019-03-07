## Please see file perltidy.ERR
package WebService::ValidSign::Object::DocumentPackage;
our $VERSION = '0.001';
use Moo;

extends 'WebService::ValidSign::Object';

use Types::Standard qw(Str Bool ArrayRef HashRef);
use WebService::ValidSign::Object::Ceremony;

# ABSTRACT: A ValidSign DocumentPackage object

has '+type' => (default => "PACKAGE");

has name => (
    is       => 'ro',
    required => 1,
);

has language => (
    is      => 'rw',
    isa     => Str,
    default => 'en',
);

has email_message => (
    is  => 'rw',
    isa => Str,
);

has auto_complete => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has description => (
    is  => 'rw',
    isa => Str,
);

has sender => (
    is        => 'rw',
    predicate => 'has_sender',
);

has settings => (
    is      => 'rw',
    builder => 1
);

has visibility => (
    is      => 'rw',
    isa     => Str,
    default => 'ACCOUNT',
);

has roles => (
    is        => 'rw',
    default   => sub { {} },
    isa       => HashRef,
    traits    => ["Hash"],
    predicate => 'has_roles',

    #handles   => {
    #    add_signer    => 'push',
    #    count_signer  => 'elements',
    #    delete_signer => 'delete',
    #},
);

has documents => (
    is        => 'rw',
    lazy      => 1,
    isa       => ArrayRef,
    predicate => 'has_documents',
    default   => sub { [] },
);

sub _build_settings {
    my $self = shift;
    return { ceremony => WebService::ValidSign::Object::Ceremony->new() };
}

sub add_document {
    my ($self, $document) = @_;
    if ($self->count_documents) {
        croak("Current implementation only supports one document!");
    }

    push(@{$self->documents}, $document);
    return 1;
};

sub count_documents {
    my $self = shift;
    return 0 unless $self->has_documents;
    return scalar @{$self->documents};
}


sub add_role {
    my $self   = shift;
    my $role_name = shift;
    my $signer = shift;
    if ($self->count_roles) {
        croak("Current implementation only supports one signer!");
    }

    if (!$signer->can("as_signer")) {
        croak("You need to implement as_signer");
    }

    #push(@{$self->signers}, $signer->as_signer);
    return 1;
};

sub count_roles {
    my $self = shift;
    return 0 unless $self->has_roles;
    return scalar keys %{$self->roles};
}

#around TO_JSON => sub {
#    my $orig = shift;
#    my $self = shift;
#
#    return $orig->($self, @_);
#};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::DocumentPackage - A ValidSign DocumentPackage object

=head1 VERSION

version 0.001

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
