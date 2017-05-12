package XML::ED::NodeSet;
use strict;
use warnings;

=over 4

=item child

Return a NodeSet of all of the children of this node set

=cut

sub child
{
    my $self = shift;

    return bless [ map({ @{$_->child() || []} } @$self) ], __PACKAGE__;
}

=over 4

=item to_string

render the nodeset as a string

=cut

sub to_string
{
use Data::Dumper;

Dumper [ 'bob', @_ ];

}

sub _attributes
{
   my $object = shift;

   my @keys = grep {!/^_/} keys %$object;

   return @keys ? ' ' . join(' ', map({ sprintf(qq($_="%s"), $object->{$_}->{value}) } sort @keys)) : '';
}

=item to_xml

render the nodeset as an xml string

=cut

sub to_xml
{
    my $object = shift;

    my @data = ();
    for my $obj (@$object) {
        if ($obj->{_type} == 0) {
	    push @data, to_xml($obj->{_data}); 
        } elsif ($obj->{_type} == 1) {
	    if (defined $obj->{_data}) {
		push @data, sprintf("<%s%s>", $obj->{_name}, _attributes( $obj )), to_xml($obj->{_data}), sprintf("</%s>",  $obj->{_name}); 
	    } else {
		push @data, sprintf("<%s%s/>",  $obj->{_name}, _attributes( $obj )); 
	    }
	} elsif ($obj->{_type} == 5) {
	    push @data, $obj->{_value} || '';
	} elsif ($obj->{_type} == 12) {
	    push @data, sprintf("<!--%s-->",  $obj->{_value}); 
	} elsif ($obj->{_type} == 10) {
	    push @data, sprintf("<!%s>",  $obj->{_value}); 
	} elsif ($obj->{_type} == 2) {
	    push @data, sprintf("<?%s%s?>",  $obj->{_name}, _attributes( $obj )); 
	} else {
warn "x";
	    push @data, $obj->{_type};
	}
    }
    return join('', @data);
}

1;

=back

http://www.w3.org/TR/xpath20/
