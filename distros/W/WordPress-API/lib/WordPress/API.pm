package WordPress::API;
use strict;
use WordPress::API::Post;
use WordPress::API::MediaObject;
use WordPress::API::Page;
use base 'WordPress::XMLRPC';
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /(\d+)/g;

sub new {
   my ($class, $self) = @_;
   $self ||={};
   bless $self,$class;
   return $self;
}



# OBJECTS -------------------------------------------------------------

sub post {
   my ($self, $id) = @_;
   
   my $p = WordPress::API::Post->new($self->_childargs);
   
   if($id){
      $p->id($id);
      $p->load or die('post() '.$p->errstr);      
   }
   return $p;
}

sub page {
   my ($self, $id) = @_;
   
   my $p = WordPress::API::Page->new($self->_childargs);
   
   if($id){
      $p->id($id);
      $p->load or die('page() '.$p->errstr);      
   }
   return $p;
}

sub media {
   my ($self, $abs) = @_;

   my $p = WordPress::API::MediaObject->new($self->_childargs);

   if($abs){
      $p->load_file($abs) or die('media() '.$p->errstr);
   }
   return $p;
}

sub _childargs {
   {
      server => $_[0]->server,
      username => $_[0]->username,
      password => $_[0]->password,
      proxy => $_[0]->proxy,
   }
}







sub _bloginfo {
   my $self = shift;
   
   unless( $self->{_bloginfo} ){   

      my $blogs = $self->getUsersBlogs
         or die($self->errstr);

      scalar @$blogs or die('no blogs');
   

      $self->{_bloginfo} = {};
      for my $hashref ( @$blogs ){      
         $self->{_bloginfo}->{$hashref->{blogid}} = $hashref;         
      }
   }      

   $self->{_bloginfo}->{$self->blog_id};
}

sub blog_name { $_[0]->_bloginfo->{blogName} }

sub blog_url { $_[0]->_bloginfo->{url} }








1;

__END__

=pod

=head1 NAME

WordPress::API

=head1 DESCRIPTION

Management of wordpress api objects.
Inherits WordPress::XMLRPC and all its methods

The basic scope of WordPress::API is to do all the oo magic
There should be no cli here, if you want to access the cli scripts, see WordPress::CLI

By contrast. WordPress::XMLRPC deals with all the calls to the wordpress server.
And WordPress::CLI, is about scripting via the command line to interact with wordpress objects, defined here.

These packages can be used to do some marvelous remote maintenance of WordPress blogs.
What if you wanted to scan all posts by Author 'jim' and move them to a new sub category called 'jim', which 
may or may not already exist?
You can do that with these packages.

=head2 WARNING

This is under development. As feedback comes in more work will be done.

=head3 WHAT YOU SHOULD INTERFACE WITH

The API objects,

   WordPress::API::Post
   WordPress::API::Page
   WordPress::API::MediaObject

Will not be changing in interface. Everything else is use at your own risk. 


=head1 METHODS

=head2 new()

arg is hashref

   my $w = new WordPress::API({
      proxy => 'http://site.com/xmlrpc.php',
      username => 'jimmy',
      password => 'secret',
   });


=head1 GETTING OBJECTS

The main idea of WodPress::API is to manage objects (pages, posts, etc) in wordpress.
You could use all the objects by themselves, but this offers some convenience.

=head2 post()

Optional arg is id (number)
Returns WordPress::API::Post object

if you pass an id, we attemp to load, if we cannot, dies

=head2 page()

Optional arg is id (number)
Returns WordPress::API::Page object

if you pass an id, we attemp to load, if we cannot, dies

=head2 media()

Optional arg is abs path to media file, likely image or pdf, etc
return WordPress::API::MediaObject object

=head2 category()

Optional argument is an id of the category that exists.
Returns WordPress::API::Category object.


=head1 XMLRPC METHODS

All methods in WordPress::XMLRPC are available in this package.
For creating, editing, and inspecting posts, pages, etc, You can use 
the provided object calls such as page(), post(), and media().

=head2 deletePage()

Arg is page id.

=head2 deletePost()

Arg is post id.








=head1 BLOG INFO

=head2 blog_id()

1 by default.

=head2 blog_name()

Get the blog name.

=head2 blog_url()

Get the blog url.

=head1 SYNOPSIS

	use WordPress::API;
	
	my $w = WordPress::API->new({
	   proxy => 'http://site/xmlrpc.php', # or abs path for working on disk instead???
	   username => 'jim',
	   password => 'pazz',
	})
	
	my $post = $w->post(4)
	$post->delete;
	
	my $page = $w->page;
	
	$page->title('great title here');
	$page->description('great content');
	$page->save;
	
	my $media = $w->media('./image.jpg');
	$media->save;
	
	print "saved ./image/jpg to ". $media->url;


=head1 SEE ALSO

Date::Manip
WordPress::API::Category - abstraction to a category
WordPress::API::MediaObject - abstraction to a 'media object'
WordPress::API::Page - abstraction to a 'page'
WordPress::API::Post - abstraction to a 'post'
WordPress::XMLRPC - base interaction with wordpress blog
WordPress::CLI - scripts to interact with this package via the command line
YAML


=head1 BUGS

Please contact the AUTHOR.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut




