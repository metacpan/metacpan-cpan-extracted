package MARC::Moose::Field;
# ABSTRACT: Marc field base object
$MARC::Moose::Field::VERSION = '1.0.40';
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Tag'
    => as 'Str'
    => where { $_ =~ /^\w{3}$/ }
    => message { 'A 3 alphanumeric characters is required' };

has tag => ( is => 'rw', isa => 'Tag', required => 1, );


sub clone {
    my ($self, $tag) = @_;

    my $field = MARC::Moose::Field->new( tag => $self->tag );
    $field->tag($tag) if $tag;
    return $field;
}


sub as_formatted {
    my $self = shift;
    return $self->tag;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Field - Marc field base object

=head1 VERSION

version 1.0.40

=head1 ATTRIBUTES

=head2 tag

3-alphanumerics identifing a field. Required.

=head1 METHODS

=head2 clone([$tag])

Return a new field cloning the field. If tag is provided, the cloned field tag
is changed.

=head1 SEE ALSO

=over 4



=back

* L<MARC::Moose::Field::Control>
* L<MARC::Moose::Field::Std>

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
