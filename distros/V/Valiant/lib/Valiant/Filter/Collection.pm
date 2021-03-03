package Valiant::Filter::Collection;

use Moo;

with 'Valiant::Filter';

has filters => (is=>'ro', required=>1);

sub filter {
  my ($self, $class, $fields) = @_;
  foreach my $filter (@{ $self->filters }) {
    if( (ref($filter)||'') eq 'ARRAY') {
      $fields = $filter->[0]->($class, $fields, +{ %{$filter->[1]||+{}} });
    } else {
      $fields = $filter->filter($class, $fields);
    }
  }
  return $fields;
}

1;

=head1 NAME

Valiant::Validator::Collection - A filter that contains and runs other filters

=head1 SYNOPSIS

    NA

=head1 DESCRIPTION

This is used internally by L<Valiant> and I can't imagine a good use for it elsewhere
so the documentation here is light.  There's no reason to NOT use it if for some
reason a good use comes to mind (I don't plan to change this so you can consider it
public API but just perhaps tricky bits for very advanced use cases).

I guess it could be used to make very complicated nested filters.  I'm not going
to show you how to do that since I think only people that can figure it out should
be allowed.  If you think I'm wrong ping me on IRC and submit a doc patch.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Filter::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
