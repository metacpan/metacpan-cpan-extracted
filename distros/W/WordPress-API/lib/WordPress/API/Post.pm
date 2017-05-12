package WordPress::API::Post;
use strict;
use Carp;
use base 'WordPress::Base::Data::Post'; # this is the data structure
use base 'WordPress::Base::Object';
use WordPress::Base::Date;

__PACKAGE__->make_xmlrpc_aliases();


1;

__END__

=pod

=head1 NAME

WordPress::Post

=head1 SYNOPSIS

=head2 NEW POST EXAMPLE

   use WordPress::API::Post;

   my $p = WordPress::API::Post->new({
      username => 'jim',
      password => 'pazz',
      proxy => 'http://site/xmlrpc.php',
   });   

   $p->title('Wonderful Thing');
   $p->description('This is the main page content');  

   $p->dateCreated('20060731'); # set the date for the post
   
   $p->save; # save to wordpress

   $p->id; # what is the id for this?   
   $p->url; # how would we access this page via http?


=head2 GET POST EXAMPLE

  use WordPress::API::Post;

   my $p = WordPress::Post({
      username => 'jim',
      password => 'pass',
      proxy => 'http://site/xmlrpc.php',
   });

   $p-id(35);  # what page do we want to get from wordpress
   $p->load; # from server
   print $p->title;
   print $p->description;


=head1 METHODS

=head2 new()

Arg is hashref. Requires 'proxy', 'username', and 'password' keys.
See WordPress::XMLRPC

   new({ 
      proxy    => $proxy, 
      username => $username, 
      password => $password, 
   });

=head2 save()

No argument.
If id is set, will edit.

Returns post id.

=head2 load()

Get object data from server using xmlrpc.

You must have id() set.
If you called via load, id is set for you.
If you upload, id is also set automatically.

=head2 delete()

Deletes the post from server.
Returns boolean.

   $o->delete
      or die( $o->errstr );

=head2 abs_path()

Setget method. Argument is path string.
(We can use this module to save the "struct" to a YAML file for editing.)

=head2 abs_path_resolve()

Optional argument is abs path- If not, expects abs_path() to have been set already.
Attempts to resolve to disk.
Returns abs path resolved.
Subsequent calls to abs_path() will also return this value.

=head2 save_file()

Dumps data structure to abs_path(), as YAML conf file.

Imagine you want to save a post from your blog to a text file on your machine:

   $o->id(43);
   $o->abs_path('/home/myself/posts/43.yml');
   $o->save_file or die($o->errstr);

Don't confuse this with save(), which saves to the blog.

=head2 errstr()

   $o->save
      or die($o->errstr);

Or

   $o->load
      or die($o->errstr);


=head2 STRUCTURE DATA SETGET METHODS

These are all inherited from WordPress::Base::Data::Post

=head3 dateCreated()

Setget perl method.
Argument is string.
Argument is checked by Date::Manip

=head3 date_created_gmt()

returns date_created_gmt value as a unix timestamp.
If you call dateCreated(0 with an argument, this is reset.

=head3 permaLink()

Setget perl method.
argument is url

=head3 wp_password()

Setget perl method.
Argument is string.

=head3 userid()

Setget perl method.
Argument is number.

=head3 mt_allow_pings()

Setget perl method.
argument is boolean

=head3 mt_excerpt()

Setget perl method.
Argument is string.

=head3 wp_author_display_name()

Setget perl method.
Argument is string.

=head3 link()

Setget perl method.
argument is url

=head3 wp_slug()

Setget perl method.
Argument is string.

=head3 mt_allow_comments()

Setget perl method.
argument is boolean

=head3 categories()

Setget perl method.
argument is array ref

=head3 description()

Setget perl method.
Argument is string.

=head3 postid() and post_id()

Setget perl method.
Argument is number.

=head3 wp_author_id()

Setget perl method.
Argument is number.

=head3 mt_keywords()

Setget perl method.
Argument is string.

=head3 title()

Setget perl method.
Argument is string.

=head3 mt_text_more()

Setget perl method.
Argument is string.

=head2 object_type()

Returns 'Post'.

=head2 structure_data()

Perl serget method.
Argument is hashref, represents the struct as per wordpress.
It is rare that this method should be called by your code.

Returns the data structure as you would present to a WordPress::XMLRPC set call.

If you made a WordPress::XMLRPC get call, that return hash ref should be an argument here.

=cut













=head1 THE POST DATA

To get the data in one hashref (or struct as wordpress expects it), call structure_data()

=head2 POST STRUCT EXAMPLE

    $struct: {
               categories => [
                               'Uncategorized'
                             ],
               dateCreated => '20080205T14:55:30',
               date_created_gmt => '20080205T22:55:30',
               description => 'this is test content',
               link => 'http://leocharre.com/articles/this-is-ok1202252126/',
               mt_allow_comments => '1',
               mt_allow_pings => '1',
               mt_excerpt => '',
               mt_keywords => '',
               mt_text_more => '',
               permaLink => 'http://leocharre.com/articles/this-is-ok1202252126/',
               postid => '174',
               title => 'This is ok1202252126',
               userid => '2',
               wp_author_display_name => 'leocharre',
               wp_author_id => '2',
               wp_password => '',
               wp_slug => 'this-is-ok1202252126'
             }


=head2 PAGE STRUCT EXAMPLE

    $struct: {
               categories => [
                               'Uncategorized'
                             ],
               dateCreated => '20080205T14:51:28',
               date_created_gmt => '20080205T22:51:28',
               description => 'this is test content',
               excerpt => '',
               link => 'http://leocharre.com/this-is-ok1202251882/',
               mt_allow_comments => '1',
               mt_allow_pings => '1',
               page_id => '173',
               page_status => 'publish',
               permaLink => 'http://leocharre.com/this-is-ok1202251882/',
               text_more => '',
               title => 'This is ok1202251882',
               userid => '2',
               wp_author => 'leocharre',
               wp_author_display_name => 'leocharre',
               wp_author_id => '2',
               wp_page_order => '0',
               wp_page_parent_id => '0',
               wp_page_parent_title => '',
               wp_password => '',
               wp_slug => 'this-is-ok1202251882'
             }

=head1 WHY ARE THERE PATH METHODS

Part of the usefulness of these modules is that you can work with text files as the posts, locally.
And then you can upload to server.

=head1 SEE ALSO

WordPress::Base::Date
Date::Manip
WordPress::API
WordPress::XMLRPC
YAML

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 CAVEATS

This module is in development. Please contact the AUTHOR.

=cut



