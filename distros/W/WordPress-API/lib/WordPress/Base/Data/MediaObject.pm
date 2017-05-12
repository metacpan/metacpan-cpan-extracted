package WordPress::Base::Data::MediaObject;
use strict;
use base 'WordPress::Base::Data::Object';

__PACKAGE__->make_structure_data_accessor(qw(name bits type));

sub object_type {
   return 'MediaObject';
}

1;

__END__

=pod

=head1 NAME

WordPress::Base::Data::MediaObject

=head1 DESCRIPTION

This is just a data holder.

=haed1 METHODS

=head2 media object setget methods

=head3 name()

setget perl method
argument is string

=head3 bits()

setget perl method
argument is string

=head3 type()

setget perl method
argument is string

=head2 object_type()

returns 'MediaObject'

=head1 SEE ALSO

WordPress::Base::Data::Object
WordPress::Base

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut



