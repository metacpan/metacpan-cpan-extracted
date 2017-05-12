package WordPress::API::Category;
use base 'WordPress::Base::Data::Category';
use base 'WordPress::Base::Object';
use strict;
no strict 'refs';
use Carp;
use LEOCHARRE::DEBUG;
#use Smart::Comments '###';

# must happen before make xmlrpc aliases
#*WordPress::XMLRPC::getCategory  = \&xmlrpc_get;

__PACKAGE__->make_xmlrpc_aliases();

# there is no getCategory, need one
# should be in WordPress::XMLRPC

sub new {
   my($class,$self) = @_;
   unless ( $self ){
      print STDERR "nothing in tow\n";
   }
   $self ||={};
   bless $self, $class;
   return $self;
}

sub xmlrpc_edit {
   croak("48 Sorry, you cannot edit categories.". __LINE__ );
}

sub xmlrpc_delete {
   croak("52 Sorry, you cannot delete categories.".__LINE__);
}

# need this alias
*id = \&WordPress::Base::Data::Category::categoryId;
# WordPress php coders su<k balls. Why do they have post_id, page_id, categoryId.. WTF!!! why not
# idPost idPage idCategory 
# or page_id  post_id category_id
# or id() !!!!!!!!!!!!!!!!!!!!!!!!! RETARDS, what kind of coding standard is this!!!!!!!!!!!!!! GRRRRR
# i've spent countless hours just putting in/debugging hacks to work around these issues.. grrr



sub save {
   my $self = shift;

   $self->username or die('missing username');
   $self->password or die('missing password');  


   my $c={};
   $c->{name}        =  $self->categoryName or die('missing categoryName');
   #$c->{slug}        = ($self->slug || undef); # this is messed up too??
   $c->{description} = ($self->description || undef);
   $c->{parent_id}    = ($self->parentId || undef);
   #$c->{parentId}    = ($self->parentId || undef); # hah.. guess what. .. to set 
   # you have to use parent_id, but to retrieve it's parentId !!! WHAT A MESS
   #### save called... 
   ### $c 
   if( my $id = $self->id ) {
      croak("(id [$id]was set) Sorry, you cannot edit categories err 90");      
      #return $self->xmlrpc_edit( $self->id, $self->structure_data );
   }
   

   my $id  = $self->newCategory( $c )  # from WordPress::XMLRPC
      or confess("cant get id on saving cat '$$c{name}'".$self->errstr);
   #print STDERR "\t--have id $id\n";
   

   # $self->id($id); # TODO may need to reload, to see what defaults sever set
   # should load, otherwise url() would not return
   $self->load($id);
   
   return $self->id;
}




1;

__END__

=pod

=head1 NAME

WordPress::API::Category

=head1 SYNOPSIS

Ideally you wouldn't use this object directly.
   
   my $wp = new WordPress::API({
      proxy => 'http://whatvr.net/xmlrpc.php',
      username => 'pacman',
      password => 'misspacman',
   });

   # create a new category
   
   my $cat = $wp->category;
   $cat->categoryName('Writing Instruments');

   $cat->save or die($wp->errstr);

   # how would we access via browser?
   $cat->htmlUrl;
   
   # let's create a sub category ..
   my $parent_category_id = $cat->id;

   my $subcat = $wp->category();

   $subcat->categoryName('Pencils');
   $subcat->parentID( $parent_category_id );
   
   my $subcatid = $subcat->save; # remember save returns id



=head1 How to id the category

To fetch a category and its attributes, you can provide an id (or a categoryName?)
This is required before you call load() to fetch the data from the server.

   $cat->categoryName('Super Stuff'); # not sure about this yet

   $cat->id(34);

=head1 METHODS

=head2 category setget methods

=head3 categoryId()

Setget perl method.
Argument is number.

=head3 categoryName()

Setget perl method.
Argument is string.

=head3 rssUrl()

Setget perl method.
Argument is url.
Not used when creating a new category.

=head3 parentId()

Setget perl method.
Argument is number.

=head3 htmlUrl()

Setget perl method.
Argument is url.
Not used when creating new category.

=head3 description()

Setget perl method.
Argument is string. 

=head4 CAVEAT

This is buggy, you can create a new category with a description, but you can't fetch it.
See L<WordPress::XMLRPC> getCategory() for more.
So, the description if set *is* stored in your blog, but won't be fetched.

=head2 object_type()

Returns string 'Category'.


=head2 load()

Optional argument is an id or categoryName string.
Returns hashref, (but loads data into object)..

   my $cat = new WordPress::API::Category({
      proxy => 'http://site.com/xmlrpc.php',
      username => 'jimmy',
      password => 'jimmyspass',
   });

         $cat->id(5);
         $cat->load or die( $cat->errstr );
   print $cat->rssUrl;

load() is called by save().

=head2 save()

Unfortunately wordpress' xmlrpc command can't edit categories.
But you can use save to create a new category.


=head1 MAKING NEW CATEGORY

You cannot save changes to a category, you can only view existing categories and create new ones.
If you load() a category you cannot save() it. You can save() and then view its url, etc, though.

   $cat->categoryName('House Inspections');
   $cat->description('hi this is a description'); # will not show up after save, wordpress bug
   my $id = $cat->save;

   # or
   $cat->save;
   my $id = $cat->id;

   # now you can make a new post and set the parent to that category..
   #
   new WordPress::API::Post ....

=head1 CAVEATS

In development.

=head1 SEE ALSO

WordPress::API



