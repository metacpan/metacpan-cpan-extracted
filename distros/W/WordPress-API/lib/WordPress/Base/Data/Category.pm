package WordPress::Base::Data::Category;
use strict;
use base 'WordPress::Base::Data::Object';

__PACKAGE__->make_structure_data_accessor(
   qw(categoryId categoryName rssUrl parentId htmlUrl description)
);

sub object_type {
   return 'Category';
}


1;

__END__

=pod

=head1 NAME

WordPress::Base::Data::Category

=head1 DESCRIPTION

This is just a data holder.
It represents a wordpress 'Category'.

=head1 METHODS

=head2 category setget methods

=head3 categoryId()

setget perl method
argument is number

=head3 categoryName()

setget perl method
argument is string

=head3 rssUrl()

setget perl method
argument is url

=head3 parentId()

setget perl method
argument is number

=head3 htmlUrl()

setget perl method
argument is url

=head3 description()

setget perl method
argument is string.
buggy!

=head2 object_type()

returns 'Category'

=haed1 SEE ALSO

WordPress::Base::Data::Object

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut





