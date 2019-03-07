package WebService::ValidSign::Object;
our $VERSION = '0.001';
use Moo;

# ABSTRACT: A ValidSign object in use for the API

use Types::Standard qw(Str);

has id => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_id'
);

has type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub TO_JSON {
    my $self = shift;
    my $meta = $self->meta;
    my %result;
    for my $attr ($meta->get_all_attributes) {
        my $name  = $attr->name;
        my $value = $attr->get_value($self);
        my $type  = $attr->type_constraint;

        if ($type) {
            if ($type->equals('Bool')) {
                $value = $value ? \1 : \0;
            }
            elsif ($type->equals('ArrayRef')) {
                $value = undef if !@$value;
            }
            elsif ($type->equals('HashRef')) {
                $value = undef if !keys %$value;
            }
        }
        $result{$name} = $value if defined $value;

    }
    return \%result;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::ValidSign::Object - A ValidSign object in use for the API

=head1 VERSION

version 0.001

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
