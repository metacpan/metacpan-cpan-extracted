package WordPress::Base::Data::Post;
use strict;
use base 'WordPress::Base::Data::Object';

__PACKAGE__->make_structure_data_accessor(
   qw(mt_allow_comments mt_text_more mt_keywords mt_excerpt mt_allow_pings),
   qw(dateCreated date_created_gmt),
   qw(permaLink link title description categories userid postid),
   qw(wp_password wp_slug wp_author_id wp_author_display_name),
);

no strict 'refs';
*{post_id} = \&postid;

sub object_type {
   return 'Post'; 
}

1;

__END__

=pod

=head1 NAME

WordPress::Base::Data::Post

=head1 DESCRIPTION

This is just a data holder.
One object instance represents a wordpress 'post'.

=haed1 METHODS

=head2 DATA STRUCTURE SETGET METHODS

=head3 permaLink()

setget perl method
argument is url

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

=head3 mt_excerpt()

setget perl method
argument is string

=head3 wp_author_display_name()

setget perl method
argument is string

=head3 link()

setget perl method
argument is url

=head3 wp_slug()

setget perl method
argument is string

=head3 mt_allow_comments()

setget perl method
argument is boolean

=head3 categories()

setget perl method
argument is array ref

=head3 description()

setget perl method
argument is string

=head3 postid() and post_id()

setget perl method
argument is number

=head3 wp_author_id()

setget perl method
argument is number

=head3 mt_keywords()

setget perl method
argument is string

=head3 title()

setget perl method
argument is string

=head3 mt_text_more()

setget perl method
argument is string

=head2 object_type()

returns 'Post'

=head1 SEE ALSO

WordPress::Base::Data::Object

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut







