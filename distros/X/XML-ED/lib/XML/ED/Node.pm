package XML::ED::Node;

=over 4

=item child

  returns XML::ED::NodeSet
=cut

sub child
{
    my $self = shift;

    return $self->{_data};
}

=item to_xml

   convert Node to xml string;

=cut

sub to_xml
{
    my $self = shift;

    bless([ $self ], 'XML::ED::NodeSet')->to_xml();
}

1;
__END__

=back
