package WWW::EFA::Roles::Printable;
use Moose::Role;
=head1 NAME

WWW::EFA::Roles::Printable - makes objects printable

=head1 SYNOPSIS
  
my $thing = WWW::EFA::SomeThing->new();
print $thing->string;

package WWW::EFA::SomeThing;
use Moose;
with 'WWW::EFA::Roles::Printable'; # provides to_string


=head2 string

This is a generic "to string" method, very similar to YAML::Dump, but a bit more tailored
to the architecture of this module.
e.g. Class::Date does not print out nicely with YAML::Dump, but does with this method.

=cut
sub string {
    my $self = shift;

    my $string = '';
    foreach my $att( sort $self->meta->get_attribute_list ){
        if( $self->$att ){
            if( not ref( $self->$att ) ){
                $string .= sprintf( "%-20s %s", $att, $self->$att  );
            } else {
                $string .= sprintf( "%-20s %s\n", $att, ref( $self->$att ) );
                my $sub_string = '';
                if( ref( $self->$att ) eq 'ARRAY' ) {
                    foreach( @{ $self->$att } ){
                        $sub_string .= $_->string;
                        $sub_string .= "\n";
                    }
                } elsif( ref( $self->$att ) eq 'HASH' ) {
                    foreach( sort( keys( %{ $self->$att } ) ) ){
                        if( ref( $self->$att->{$_} ) ){
                            $sub_string .= $self->$att->{$_}->string;
                            $sub_string .= "\n";
                        } else {
                            $sub_string .= sprintf( "%-20s %s\n", $_, $self->$att->{$_} );
                        }
                    }
                }elsif( $self->$att->can( 'string' ) ){
                    $sub_string = $self->$att->string;
                }else{
                    $sub_string = ">>> has no string method <<<<\n";
                }
                $sub_string =~ s/^/    /gm;
                $string .= $sub_string;
            }
            $string .= "\n";
        }
    }
    return $string;
}


1;

=head1 METHODS

=over 4


=back

=head1 COPYRIGHT

Copyright 2011, Robin Clarke, Munich, Germany

=head1 AUTHOR

Robin Clarke <perl@robinclarke.net>

