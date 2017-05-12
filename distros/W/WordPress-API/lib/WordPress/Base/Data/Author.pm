package WordPress::Base::Data::Author;
use strict;
use base 'WordPress::Base::Data::Object';

__PACKAGE__->make_structure_data_accessor(qw(user_id user_login display_name));

sub object_type {
   return 'Author';
}

1;

__END__

=pod

=head1 NAME

WordPress::Base::Data::Author

=head1 DESCRIPTION

This is just a data holder.
It represents a wordpress 'Author'.

=head1 METHODS

=head2 author setget methods

=head3 user_id()

setget perl method
argument is number

=head3 user_login()

setget perl method
argument is string

=head3 display_name()

setget perl method
argument is string

=head2 object_type()

returns 'Author'

=haed1 SEE ALSO

WordPress::Base::Data::Object
WordPress::Base

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut





