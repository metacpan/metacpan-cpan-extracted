package MARC::Moose::Formater;
# ABSTRACT: Base class to format Marc record
$MARC::Moose::Formater::VERSION = '1.0.45';
use Moose;


# FIXME Experimental. Not used yet.
#has converter => (
#    is      => 'rw',
#    isa     => 'Text::IconvPtr',
#    default => sub { Text::Iconv->new( "cp857", "utf8" ) }
#);


sub begin { }

sub end { }


sub format {
    my ($self, $record) = @_;
    return "Marc Record";
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater - Base class to format Marc record

=head1 VERSION

version 1.0.45

=head1 DESCRIPTION

A Marc formater is used by any writer to transform a Marc record into something
undestandable by human (text readable format) or by machine (standartized format
like ISO2709 or MARCXML).

A formater surclass this base class 3 methods to format a set of Marc records.

=head1 METHODS

=head2 begin

Prior to formating a set of records one by one calling I<format> method, a
writer may need an header which is returned by this method.

=head2 end

A the end of formating a set of records, it may be required by a writer to
finished its stream of date by a footer.

=head2 format

Returns something (a string, another object) containing a representation of a
MARC record.

  # $formater type is Marc::Formater subclass
  # $record type Marc::Record or any subclass
  my $formatted_string = $formater->format( $record );

=head1 SEE ALSO

=over 4

=item *

L<MARC::Moose>

=item *

L<MARC::Moose::Formater::Iso2709>

=item *

L<MARC::Moose::Formater::Marcxml>

=item *

L<MARC::Moose::Formater::Text>

=item *

L<MARC::Moose::Formater::Yaml>

=item *

L<MARC::Moose::Formater::UnimarcToMarc21>

=item *

L<MARC::Moose::Lint::Processor>

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
