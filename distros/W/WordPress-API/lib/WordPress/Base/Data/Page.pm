package WordPress::Base::Data::Page;
use strict;
use base 'WordPress::Base::Data::Object';

__PACKAGE__->make_structure_data_accessor(
   qw(wp_password wp_page_parent_title wp_page_parent_id wp_author_id wp_slug wp_author wp_page_order wp_author_display_name),   
   qw(mt_allow_pings mt_allow_comments),
   qw(date_created_gmt dateCreated),
   qw(title description page_id link page_status categories text_more permaLink userid excerpt),
);

sub object_type {
   return 'Page';
}

1;

__END__

=pod

=head1 NAME

WordPress::Base::Data::Page

=head1 SYNOPSIS

   use WordPress::Base::Data::Page;
  
   my $p = WordPress::Base::Data::Page->new();
   my $struct = $p->structure_data;
   $p->wp_page_parent_title('Stories');

   $p->object_type; # returns 'Page'

=head1 DESCRIPTION

This is just a data holder.

=head1 METHODS

=head2 page setget methods

=head3 wp_page_parent_title()

setget perl method
argument is string

=head3 permaLink()

setget perl method
argument is url

=head3 excerpt()

setget perl method
argument is string

=head3 wp_password()

setget perl method
argument is string

=head3 userid()

setget perl method
argument is number

=head3 mt_allow_pings()

setget perl method
argument is boolean

=head3 date_created_gmt()

setget perl method
argument is string

=head3 dateCreated()

setget perl method
argument is string

=head3 wp_page_order()

setget perl method
argument is number

=head3 wp_author()

setget perl method
argument is string

=head3 text_more()

setget perl method
argument is string

=head3 wp_author_display_name()

setget perl method
argument is string

=head3 wp_page_parent_id()

setget perl method
argument is number

=head3 wp_slug()

setget perl method
argument is string

=head3 link()

setget perl method
argument is url

=head3 page_status()

setget perl method
argument is string

=head3 mt_allow_comments()

setget perl method
argument is boolean

=head3 page_id()

setget perl method
argument is number

=head3 categories()

setget perl method
argument is array ref

=head3 description()

setget perl method
argument is string

=head3 wp_author_id()

setget perl method
argument is number

=head3 title()

setget perl method
argument is string

=head2 object_type()

returns 'Page'

=head2 structure_data()

Returns the data structure as you would present to a WordPress::XMLRPC set call.
Perl setget method. Argument and return is hash ref.




=head1 SEE ALSO

WordPress::Base::Data::Object

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut






