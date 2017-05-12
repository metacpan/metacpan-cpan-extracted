package WordPress::Base::Object;
use strict;
use Carp;
use base 'WordPress::XMLRPC'; # these are calls to xmlrpc.php

sub new {
   my ($class,$self) = @_;
   $self||={};
   bless $self,$class;
   return $self;
}

sub load_file {
   my $self = shift;
   my $abs = shift;
   if (defined $abs){
      $self->abs_path($abs);
      $self->abs_path_resolve;   
   }
   
   $self->abs_path or croak('must set abs_path()');

   require YAML;
   my $data = YAML::LoadFile($self->abs_path);
   $self->structure_data($data);
   return 1;
}

sub save_file {
   my $self = shift;
   my $abs = shift;
   if(defined $abs){
      $self->abs_path($abs);
      # dont resolve abs path?
   }
   $self->abs_path or croak('mus set abs_path()');
   
   require YAML;
   YAML::DumpFile($self->abs_path,$self->structure_data);
   return 1;
}



# abs_path is used by MediaObject to upload a file, and for the other objects,
# if we save to disk as well
# these are not part of the data structure, because those are not used by xmlrpc
#  maybe this should reset structure_data??
sub abs_path {
   my ($self,$abs_path) = @_;
   if (defined $abs_path){
      # resolve to disk or not???? not if we are going to save
      $self->{abs_path} = $abs_path;
   }
   return $self->{abs_path};
}

sub abs_path_resolve {
   my $self = shift;
   my $abs = shift;
   if (defined $abs){ $self->{abs_path} = $abs; }

   $self->abs_path or croak('cant resolve, no abs_path() was set');
   require Cwd;
   my $abs_ = Cwd::abs_path($self->abs_path)
      or carp($self->abs_path .' was not on disk')
      and return;

   $self->abs_path($abs_);
   return $self->abs_path;
}


# these must be aliased to for example:
#*{id}            = \&WordPress::Base::Data::Page::page_id;
#*{xmlrpc_get}    = \&WordPress::XMLRPC::getPage;
#*{xmlrpc_new}    = \&WordPress::XMLRPC::newPage;
#*{xmlrpc_edit}   = \&WordPress::XMLRPC::editPage;
#*{xmlrpc_delete} = \&WordPress::XMLRPC::deletePage;

# can do it auto, right here.

sub make_xmlrpc_aliases {
   my $class = shift;
   my $Type = shift;
   
   unless( defined $Type ){
      $Type = $class;
      $Type=~s/^.+\://;
   }
   

   my $type = lc($Type);   

   no strict 'refs';

   my $data_pkg = "WordPress::Base::Data::$Type";
   #require $data_pkg;

   *{"$class\::id"}            = \&{"$data_pkg\::$type\_id"};
   *{"$class\::object_type"}   = \&{"$data_pkg\::object_type"};
   
   *{"$class\::xmlrpc_get"}    = \&{"WordPress::XMLRPC::get$Type"};
   *{"$class\::xmlrpc_new"}    = \&{"WordPress::XMLRPC::new$Type"};
   *{"$class\::xmlrpc_edit"}   = \&{"WordPress::XMLRPC::edit$Type"};
   *{"$class\::xmlrpc_delete"} = \&{"WordPress::XMLRPC::delete$Type"};
   
   return;
}

sub load {
   my $self = shift;
   my $id = shift;
   $id ||= $self->id;
   $id or croak('missing id value');

   my $structure_data = $self->xmlrpc_get($id) or return;   
   $self->structure_data($structure_data);
   return 1;
}

sub save {
   my $self = shift;
   $self->username or die('missing username');
   $self->password or die('missing password');   
   
   if( $self->id) {
      #print STDERR "\t--had id\n";
      return $self->xmlrpc_edit( $self->id, $self->structure_data );
   }
   
   #print STDERR "\t--had no id\n";

   my $id  = $self->xmlrpc_new( $self->structure_data ) 
      or confess("cant get id on saving, ".$self->errstr);
   #print STDERR "\t--have id $id\n";
   

   # $self->id($id); # TODO may need to reload, to see what defaults sever set
   # should load, otherwise url() would not return
   $self->load($id);
   
   return $self->id;
}

sub delete {
   my $self = shift;
      
   if( my $id = $self->id ){
      my $del = $self->xmlrpc_delete($id)
         or return 0;
      ### $del
      return 1;
   }
   croak('id not set, use id()');
   return 0;
}






# dates, only useful for Page and Post, i guess
# DATE methods are in WordPress::Base::Date


sub url {
   my $self = shift;
   
   if ($self->object_type eq 'Page' or $self->object_type eq 'Post' ){
      $self->id or $self->save; # TODO it wont feed link or url without explicit load after save
      return $self->link;
   }

   warn('cant call url for this object type');
   return;
}



1;

__END__

=pod

=head1 NAME

WordPress::Base::Object

=head1 DESCRIPTION

base for WordPress::API objects

=head1 METHODS

=head2 new()

=head2 abs_path()

=head2 abs_path_resolve()

optional argument is abs path
if not, expects abs_path() to have been set.
attempts to resolve to disk
returns abs path resolved
subsequent calls to abs_path() will also return this value.

=head2 save_file()

dumps data structure to abs_path(), as YAML conf file

=head2 url() not implemented

attempts to save unless we have an id
the method link() will return only if it was loaded, the method url() will save
to the wordpress blog if no url is present, and then return

=head2 load()

=head2 save()

=head2 delete()

=head2 id() 

aliased to post_id or page_id, etc depending on object_type()

=head2 make_xmlrpc_alieases()

arg is class (your object class) and optionally one of 'Post', 'Page' 
we try to resolve what kind of object you have from the name, if your object
package class ends in Post or Page, don't worry.

This creates aliases to WordPress::XMLRPC::getPage or WordPress::XMLRPC::getPost, etc.

=head3 xmlrpc_get() xmlrpc_new() xmlrpc_delete() xmlrpc_edit()

These are called internally.
If your object is a Post object, then xmlrpc_get returns same as getPost would, arg is id.
Used internally.


=head2 object_type()

returns Page, Post, or MediaObject

=head1 NOTES


This module is meant to be inherited by
WordPress::API::Page
WordPress::API::Post
WordPress::API::MediaObject, etc




