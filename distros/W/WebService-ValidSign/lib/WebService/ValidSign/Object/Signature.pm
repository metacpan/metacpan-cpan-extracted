package WebService::ValidSign::Object::Signature;
our $VERSION = '0.002';
use Moo;

# ABSTRACT: A ValidSign Signature object
#
has a_set_of_fields => (
    is       => 'rw',
);

has data_specific_to_a_particular_signature => (
    is     => 'rw',
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object::Signature - A ValidSign Signature object

=head1 VERSION

version 0.002

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
