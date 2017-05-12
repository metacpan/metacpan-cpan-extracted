package MARC::Moose::Field::Std;
# ABSTRACT: Standard Marc Field (tag >= 010)
$MARC::Moose::Field::Std::VERSION = '1.0.33';
use Moose;

extends 'MARC::Moose::Field';

has ind1 => (is => 'rw', isa => 'Str', default => ' ');
has ind2 => (is => 'rw', isa => 'Str', default => ' ');


has subf => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );


override 'as_formatted' => sub {
    my $self = shift;

    join ' ', (
        $self->tag,
        $self->ind1 . $self->ind2,
        map { ("\$$_->[0]", $_->[1]) } @{$self->subf} );
};


override 'clone' => sub {
    my ($self, $tag) = @_;
    my $field = MARC::Moose::Field::Std->new( tag => $self->tag );
    $field->tag($tag) if $tag;
    $field->subf( [ map { [ $_->[0] => $_->[1] ] } @{$self->subf} ] );
    return $field;
};


sub subfield {
    my ($self, $letter) = @_;

    return unless defined($letter);

    my @values;
    for ( @{$self->subf} ) {
        push @values, $_->[1] if $_->[0] =~ $letter;
    }

    return unless @values;
    return wantarray ? @values : $values[0];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Field::Std - Standard Marc Field (tag >= 010)

=head1 VERSION

version 1.0.33

=head1 ATTRIBUTES

=head2 subf

An ArrayRef of field subfields. Each subfield is this array is an 2D ArrayRef.
For example:

  $field->subf( [ [ 'a', 'Part1' ], [ 'b', 'Part2' ] ] );

or

  $field->subf( [ [ a => 'Part1' ], [ b => 'Part2' ] ] );

=head1 METHODS

=head2 subfield( I<regexp> )

In scalar context, returns the first content of subfield which letter match
regular expression C<regexp> . In list context, returns all subfields content.

For example:

  my $field = MARC::Moose::Field::Std->new(
    tag => '600',
    subf => [
      [ a => 'Part 1' ],
      [ x => '2010' ],
      [ a => 'Part 2' ],
      [ b => 'Part 3' ],
    ] );
  my $value = $field->subfield('a|b'); # Get 'Part 1'
  my @values = $field->subfield('a|b'); # Get ('Part1', 'Part 2')

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
