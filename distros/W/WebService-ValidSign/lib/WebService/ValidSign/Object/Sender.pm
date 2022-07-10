package WebService::ValidSign::Object::Sender;
our $VERSION = '0.004';
use Moo;

extends 'WebService::ValidSign::Object';

use Types::Standard qw(Str Bool);

# ABSTRACT: A ValidSign Sender object

has '+type' => (default => "SENDER");

has first_name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has last_name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has email => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

sub as_signer {
    my $self = shift;
    my $meta = $self->meta;

    my %result;
    for my $attr ($meta->get_all_attributes) {
        my $name  = $attr->name;
        my $value = $attr->get_value($self);
        $result{$name} = $value if defined $value;
    }
    require WebService::ValidSign::Object::Signer;
    return WebService::ValidSign::Object::Signer->new(%result);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Sender - A ValidSign Sender object

=head1 VERSION

version 0.004

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
