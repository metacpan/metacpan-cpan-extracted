package WordPress::XMLRPC;
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use vars qw($VERSION $DEBUG);
$VERSION = sprintf "%d.%02d", q$Revision: 2.13 $ =~ /(\d+)/g;

# WP XML-RPC API METHOD LIST
# All the following methods are in the standard API https://codex.wordpress.org/XML-RPC_WordPress_API
#
# WP API METHOD			MODULE METHOD		RELEVANT OBSELETE METHOD	SINCE
# wp.getPost 			getPost			getPage 				3.4
# wp.getPosts			-			getRecentPosts,getPages,getPageList	3.4
# wp.newPost			newPost			newPage					3.4
# wp.editPost			editPost		editPage				3.4
# wp.deletePost			deletePost							3.4
# wp.getPostType		-								3.4
# wp.getPostTypes		-								3.4
# wp.getPostFormats		-								3.4
# wp.getPostStatusList		getPostStatusList	getPageStatusList 			3.4
# wp.getTaxonomy		-			getCategories,getTags			3.4
# wp.getTaxonomies		-								3.4
# wp.getTerm			-								3.4
# wp.getTerms			-								3.4
# wp.newTerm			-			newCategory				3.4
# wp.editTerm			-								3.4
# wp.deleteTerm			-			deleteCategory				3.4
# wp.getMediaItem		-								3.1
# wp.getMediaLibrary		-								3.1
# wp.uploadFile			uploadFile							3.1
# wp.getCommentCount		getCommentCount							2.7
# wp.getComment			getComment							2.7
# wp.getComments		getComments							2.7
# wp.newComment			newComment							2.7
# wp.editComment		editComment							2.7
# wp.deleteComment		deleteComment							2.7
# wp.getCommentStatusList	getCommentStatusList						2.7
# wp.getOptions			getOptions 							2.6
# wp.setOptions			setOptions 							2.6
# wp.getUsersBlogs		getUsersBlogs 							2.something
# wp.getUser			getUser								3.5
# wp.getUsers			getUsers							3.5
# wp.getProfile			-								3.5
# wp.editProfile		-								3.5
# wp.getAuthors			getAuthors							2.something
#
# WP ADDITIONAL METHOD LIST
# These methods are in the internal WP API that is not normally available over XML-RPC. They can be 
# individually enabled using the plug-in at https://github.com/realflash/extended-xmlrpc-api
# wp_insert_user		createUser
# add_user_meta			addUserMeta
# get_user_meta			getUserMeta

sub new {
   my ($class,$self) = @_;
   $self||={};
   bless $self, $class;
   return $self;
}

sub proxy {
   my $self = shift;
   my $val = shift;
   if( defined $val ){
      $self->{proxy} = $val;      
   }
	defined $self->{proxy} or carp("missing 'proxy'".  (caller(1))[3]);

   return $self->{proxy};
}

sub username {
   my $self = shift;
   my $val = shift;
   if( defined $val ){
      $self->{username} = $val;      
   }
	defined $self->{username} or carp("missing 'username'".  (caller(1))[3]);

   return $self->{username};
}

sub password {
   my $self = shift;
   my $val = shift;
   if( defined $val ){
      $self->{password} = $val;      
   }
	defined $self->{password} or carp("missing 'username'". (caller(1))[3]);

   return $self->{password};
}

sub blog_id {
   my $self = shift;
   my $val = shift;
   if( defined $val ){
      $val=~/^\d+$/ or croak('argument must be digits');
      $self->{blog_id} = $val;      
   }
   $self->{blog_id} ||= 1;
   return $self->{blog_id};
}

# post and page use 'publish' variable
sub publish {
   my ($self,$val) = @_;
   $self->{publish} = $val if defined $val;
   defined $self->{publish} or $self->{publish} = 1;
   return $self->{publish};
}

sub server {
   my $self = shift;
   unless( $self->{server} ){
      $self->proxy or confess('missing proxy');
      require XMLRPC::Lite;

      $self->{server} ||= XMLRPC::Lite->proxy( $self->proxy );
   }
   return $self->{server};
}

sub _call_has_fault {
   my $self = shift;
   my $call = shift;
   defined $call or confess('no call passed');
   my $err = $call->fault or return 0;
   
   #my $from = caller();   
   #my($package, $filename, $line, $subroutine, $hasargs,
   #   $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);

   my $_err;
   for my $k( keys %$err ){
      
      $_err.= sprintf "# %s() - ERROR %s, %s\n", 
         (caller(1))[3], # sub name
         $k, # error label, from XMLRPC::Simple call
         $err->{$k}, # error text                  
         ;
   }
   $self->errstr($_err);
   
   return $self->errstr;
}

sub errstr {
   my ($self,$val) = @_;
   $self->{errstr} = $val if defined $val;   
   ($self->{errstr} and $DEBUG) and Carp::cluck($self->{errstr});
   return $self->{errstr};
}

sub _process_response
{
	my $self = shift;
	my $response = shift;

	my $err = $self->_call_has_fault($response);
	if ($err)
	{
		return { error => $err, result => undef };
	}
	my $result = $response->result;
	defined $result	or die('no result');

	return { error => undef, result => $response->result }; 
}

sub _is_number { $_[0]=~/^\d+$/ ? $_[0] : confess("Argument '$_[0] ' is not number") }
sub _is_href { ($_[0] and (ref $_[0]) and (ref $_[0] eq 'HASH')) ? $_[0] : confess("Expected argument to be hashref/struct") }

# helper for uploading media..

sub abs_path_to_media_object_data {
   my $abs_path = shift;
   
   -f $abs_path or Carp::cluck("not on disk: $abs_path") and return;

   my $data;
   
   $data->{name} = get_file_name($abs_path) or die('cant get filename');
   $data->{type} = get_mime_type($abs_path) or die("cant get mime type");
   $data->{bits} = get_file_bits($abs_path) or die('cant get file bits');
   
   return $data;

   # optionally we can request other files to get mime on
   sub get_mime_type {
      my $abs = shift;
      $abs or confess('missing arg');   
      require File::Type;
      my $ft = new File::Type;
      my $type = $ft->mime_type($abs) or die('missing mime');
      return $type;
   }

   sub get_file_bits {
      my $abs_path = shift;
      $abs_path or die;
      # from http://search.cpan.org/~gaas/MIME-Base64-3.07/Base64.pm
      require MIME::Base64;

      open(FILE, $abs_path) or die($!);
      binmode FILE; ### fix for Win32 if binary data (GwenDragon)
      ### see bug https://rt.cpan.org/Public/Bug/Display.html?id=97830
      my $bits;
      my $buffer;
      while( read(FILE, $buffer, (60*57)) ) {
         $bits.= $buffer;
      }

      return $bits;
   }

   sub get_file_name {
      my $string = shift;
      $string or croak('missing path');
      
      $string=~s/^.+\/+|\/+$//g;
      return $string;
   }

}

# XML RPC METHODS

# OBSELETE
# xmlrpc.php: function wp_getPage
# sub getPage {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $page_id = shift;
	# my $username = $self->username;
	# my $password = $self->password;

	# $page_id or confess('missing page id');  

	# my $call = $self->server->call(
		# 'wp.getPage',
		# $blog_id,
		# $page_id,
		# $username,
		# $password,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# OBSELETE
# # xmlrpc.php: function wp_getPages
# sub getPages {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;
	

	# my $call = $self->server->call(
		# 'wp.getPages',
		# $blog_id,
		# $username,
		# $password,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# OBSELETE
# # xmlrpc.php: function wp_newPage
# sub newPage {
	# my $self = shift;
   # my $blog_id = $self->blog_id;
   # my $username = $self->username;
   # my $password = $self->password;   
	# my $page = shift;

	# defined $page or confess('missing page arg');
   # ref $page eq 'HASH' or croak('arg is not hash ref');
   
	# my $publish = shift;
	# unless (defined $publish) {
		# $publish = $self->publish;
	# }

   

	# my $call = $self->server->call(
		# 'wp.newPage',
      # $blog_id, # ignored
      # $username, # i had missed these!!!
      # $password,
		# $page,
		# $publish,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# OBSELETE
# # xmlrpc.php: function wp_deletePage
# sub deletePage {
	# my $self       = shift;
	# my $blog_id    = $self->blog_id;  
	# my $username   = $self->username;
	# my $password   = $self->password;
	# my $page_id    = shift;

	# defined $page_id or confess('missing page id arg');
   

	# my $call = $self->server->call(
		# 'wp.deletePage',
		# $blog_id,
		# $username,
		# $password,
		# $page_id,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# OBSELETE
# # xmlrpc.php: function wp_editPage
# sub editPage {
	# my $self    = shift;
   # my($blog_id, $page_id, $content, $publish);
	# $blog_id    = $self->blog_id;
  
   # # the following hack is a workaround for getting args as one of:
   # # $id, $content, $publish
   # # $content, $publish
   # # $content
   # # $id, $content

   # # i know.. this is a very ugly hack   
   # my $_arg_1 = shift;
   # if ($_arg_1=~/^\d+$/){
      # $page_id=$_arg_1;
      # $content = shift;
      # $publish = shift;

	   # (defined $content and ( ref $content ) and ( ref $content eq 'HASH' ))
         # or confess('content arg is not hash ref');
   # }

   # else {
      # $content = $_arg_1;      
      # $publish = shift;
      # ( defined $content and (ref $content) and (ref $content eq 'HASH'))
         # or confess('content arg is not hash ref');

      # $page_id = $content->{page_id}
         # or confess("missing page_id in content hashref");
   # }

   

   # my $password   = $self->password;
   # my $username   = $self->username;


   # ( defined $page_id and $page_id=~/^\d+$/ )
      # or confess('missing page id arg');

   
	# unless (defined $publish) {
		# $publish = $self->publish;
	# }
   

	# my $call = $self->server->call(
		# 'wp.editPage',
		# $blog_id,
      # $page_id,
      # $username,
      # $password,
		# $content,
		# $publish,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# OBSELETE
# # xmlrpc.php: function wp_getPageList
# sub getPageList {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;


	# my $call = $self->server->call(
		# 'wp.getPageList',
		# $blog_id,
		# $username,
		# $password,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# xmlrpc.php: function wp_getAuthors
sub getAuthors {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;


	my $call = $self->server->call(
		'wp.getAuthors',
		$blog_id,
		$username,
		$password,
	);

	return $self->_process_response($call);
}


#
# OBSELETE
# xmlrpc.php: function wp_newCategory
# sub newCategory {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;
	# my $category = shift;
   # (ref $category and ref $category eq 'HASH')
      # or croak("category must be a hash ref");

   # $category->{name} or confess('missing name in category struct');
   

   # ### $category

	# defined $category or confess('missing category string');

	# my $call = $self->server->call(
		# 'wp.newCategory',
		# $blog_id,
		# $username,
		# $password,
		# $category,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# xmlrpc.php: function wp_suggestCategories
# sub suggestCategories {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;
	# my $category = shift;
	# my $max_results = shift; # optional

	

	# my $call = $self->server->call(
		# 'wp.suggestCategories',
		# $blog_id,
		# $username,
		# $password,
		# $category,
		# $max_results,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }





# OBSELETE
# xmlrpc.php: function mw_newMediaObject
# *uploadFile = \&newMediaObject;
# sub newMediaObject {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $data = shift;

   # defined $data or confess('missing data hash ref arg');
   # ref $data eq 'HASH' or croak('arg is not hash ref');

	# my $call = $self->server->call(
		# 'metaWeblog.newMediaObject',
		# $blog_id,
      # $self->username,
      # $self->password,
		# $data,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }



# xmlrpc.php: function mw_newPost
sub newPost {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $user_login = $self->username;
	my $user_pass = $self->password;
	my $content_struct = shift;
	my $publish = shift;
	unless (defined $publish) {
		$publish = $self->publish;
	}
   defined $content_struct or confess('missing post hash ref arg');
   ref $content_struct eq 'HASH' or croak('arg is not hash ref');

	my $call = $self->server->call(
		'metaWeblog.newPost',
		$blog_id,
		$user_login,
		$user_pass,
		$content_struct,
		$publish,
	);

	return $self->_process_response($call);
}

# xmlrpc.php: function mw_editPost
sub editPost {
	my $self = shift;
	my $post_id = shift;
	my $user_login = $self->username;
	my $user_pass = $self->password;
	my $content_struct = shift;
	my $publish = shift;
	unless (defined $publish) {
		$publish = $self->publish;
	}

	defined $post_id or confess('missing post id');
	defined $content_struct or confess('missing content struct hash ref arg');
   ref $content_struct eq 'HASH' or croak('arg is not hash ref');

	my $call = $self->server->call(
		'metaWeblog.editPost',
		$post_id,
		$user_login,
		$user_pass,
		$content_struct,
		$publish,
	);

	return $self->_process_response($call);
}

# xmlrpc.php: function mw_getPost
sub getPost {
	my $self = shift;
	my $post_id = shift;
	my $user_login = $self->username;
	my $user_pass = $self->password;
   defined $post_id or confess('missing post id arg');


	my $call = $self->server->call(
		'metaWeblog.getPost',
		$post_id,
		$user_login,
		$user_pass,
	);

	return $self->_process_response($call);
}


# OBSELETE
# xmlrpc.php: function mw_getRecentPosts
# sub getRecentPosts {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $user_login = $self->username;
	# my $user_pass = $self->password;
	# my $num_posts = shift;
   

	# my $call = $self->server->call(
		# 'metaWeblog.getRecentPosts',
		# $blog_id,
		# $user_login,
		# $user_pass,
		# $num_posts,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# OBSELETE
# xmlrpc.php: function mw_getCategories
# sub getCategories {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $user_login = $self->username;
	# my $user_pass = $self->password;
   

	# my $call = $self->server->call(
		# 'metaWeblog.getCategories',
		# $blog_id,
		# $user_login,
		# $user_pass,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# OBSELETE
# # this nextone doesn't really exist.. this is a hack ..
# # this is not keeping in par with xmlrpc.php but.. shikes..
# sub getCategory {
   # my $self = shift;
   # my $id = shift;
   # $id or croak('missing id argument');

   # # get all categorise

   # my @cat = grep { $_->{categoryId} == $id } @{$self->getCategories};

   # @cat and scalar @cat 
      # or $self->errstr("Category id $id not found.")
      # and return;

   # return $cat[0];
# }




# xmlrpc.php: function blogger_deletePost
sub deletePost {
	my $self = shift;
   my $blog_id = $self->blog_id;
	my $post_id = shift;
	my $user_login = $self->username;
	my $user_pass = $self->password;
	my $publish = shift;
	unless (defined $publish) {
		$publish = $self->publish;
	}

	defined $post_id or confess('missing post id');

	my $call = $self->server->call(
		'metaWeblog.deletePost',
      $blog_id, #ignored
		$post_id,
		$user_login,
		$user_pass,
		$publish,
	);

	return $self->_process_response($call);
}


# OBSELETE
# xmlrpc.php: function blogger_getTemplate
# sub getTemplate { # TODO this fails, why????
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $user_login = $self->username;
	# my $user_pass = $self->password;
	# my $template = shift;   

	# defined $template or confess('missing template string');   
   # ### $template
   # ### $blog_id
   # ### $user_login
   # ### $user_pass
	# my $call = $self->server->call(
		# 'metaWeblog.getTemplate',
		# $blog_id,
		# $user_login,
		# $user_pass,
		# $template,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# # xmlrpc.php: function blogger_setTemplate
# sub setTemplate {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $user_login = $self->username;
	# my $user_pass = $self->password;
	# my $content = shift;
	# my $template = shift;

	# defined $template or confess('missing template string arg');
	# defined $content or confess('missing content hash ref arg');
   # ref $content eq 'HASH' or croak('arg is not hash ref');

	# my $call = $self->server->call(
		# 'metaWeblog.setTemplate',
		# $blog_id,
		# $user_login,
		# $user_pass,
		# $content,
		# $template,
	# );

	# if ( $self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# xmlrpc.php: function blogger_getUsersBlogs
sub getUsersBlogs {
	my $self = shift;
	my $user_login = $self->username;
	my $user_pass = $self->password;
   

	my $call = $self->server->call(
		'metaWeblog.getUsersBlogs',
      $self->blog_id, # ignored
		$user_login,
		$user_pass,
	);

	return $self->_process_response($call);
}

# OBSELETE
# xmlrpc.php: function wp_deleteCategory
# sub deleteCategory {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;
	# my $category_id = shift;
   # _is_number($category_id);

	# my $call = $self->server->call(
		# 'wp.deleteCategory',
		# $blog_id,
		# $username,
		# $password,
		# $category_id,
	# );

	# if ( $self->_call_has_fault($call) ){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }

# xmlrpc.php: function wp_deleteComment
sub deleteComment {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $comment_id = shift;
   _is_number($comment_id);

	my $call = $self->server->call(
		'wp.deleteComment',
		$blog_id,
		$username,
		$password,
		$comment_id,
	);

	return $self->_process_response($call);
}

# xmlrpc.php: function wp_editComment
sub editComment {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $comment_id = shift;
   _is_number($comment_id);

	my $content_struct = shift;
   _is_href($content_struct);

	my $call = $self->server->call(
		'wp.editComment',
		$blog_id,
		$username,
		$password,
		$comment_id,
		$content_struct,
	);

	return $self->_process_response($call);
}


# xmlrpc.php: function wp_getComment
sub getComment {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $comment_id = shift;
   _is_number($comment_id);

	my $call = $self->server->call(
		'wp.getComment',
		$blog_id,
		$username,
		$password,
		$comment_id,
	);

	return $self->_process_response($call);
}

# xmlrpc.php: function wp_getCommentCount
sub getCommentCount {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $post_id = shift;
   _is_number($post_id);

	my $call = $self->server->call(
		'wp.getCommentCount',
		$blog_id,
		$username,
		$password,
		$post_id,
	);

	return $self->_process_response($call);
}


# xmlrpc.php: function wp_getCommentStatusList
sub getCommentStatusList {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;

	my $call = $self->server->call(
		'wp.getCommentStatusList',
		$blog_id,
		$username,
		$password,
	);

	return $self->_process_response($call);
}


# xmlrpc.php: function wp_getComments
sub getComments {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $struct = shift;
   _is_href($struct);

	my $call = $self->server->call(
		'wp.getComments',
		$blog_id,
		$username,
		$password,
		$struct,
	);

	return $self->_process_response($call);
}


# xmlrpc.php: function wp_getOptions
sub getOptions {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $options = shift;

	my $call = $self->server->call(
		'wp.getOptions',
		$blog_id,
		$username,
		$password,
		$options,
	);

   $call or warn("no call");

	return $self->_process_response($call);
}



# OBSELETE
# xmlrpc.php: function wp_getPageStatusList
# sub getPageStatusList {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;

	# my $call = $self->server->call(
		# 'wp.getPageStatusList',
		# $blog_id,
		# $username,
		# $password,
	# );

	# if ( $self->_call_has_fault($call) ){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# # OBSELETE
# # xmlrpc.php: function wp_getPageTemplates
# sub getPageTemplates {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;

	# my $call = $self->server->call(
		# 'wp.getPageTemplates',
		# $blog_id,
		# $username,
		# $password,
	# );

	# if ($self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }



# xmlrpc.php: function wp_getPostStatusList
sub getPostStatusList {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;

	my $call = $self->server->call(
		'wp.getPostStatusList',
		$blog_id,
		$username,
		$password,
	);

	return $self->_process_response($call);
}

#
# OBSELETE
# # xmlrpc.php: function wp_getTags
# sub getTags {
	# my $self = shift;
	# my $blog_id = $self->blog_id;
	# my $username = $self->username;
	# my $password = $self->password;

	# my $call = $self->server->call(
		# 'wp.getTags',
		# $blog_id,
		# $username,
		# $password,
	# );

	# if ($self->_call_has_fault($call)){
		# return;
	# }

	# my $result = $call->result;
	# defined $result
		# or die('no result');

	# return $result;
# }


# xmlrpc.php: function wp_newComment
sub newComment {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $post = shift;
	my $content_struct = shift;
   _is_href($content_struct);

	my $call = $self->server->call(
		'wp.newComment',
		$blog_id,
		$username,
		$password,
		$post,
		$content_struct,
	);

	return $self->_process_response($call);
}


# xmlrpc.php: function wp_setOptions
sub setOptions {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $options = shift;

	my $call = $self->server->call(
		'wp.setOptions',
		$blog_id,
		$username,
		$password,
		$options,
	);

	return $self->_process_response($call);
}

# TESTED FROM HERE

sub getUser {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $args = shift;
	my $user_id = $args->{'id'};
	my $fields = $args->{'fields'};

	defined $user_id or confess("Argument 'id' is missing");
	_is_number($user_id);
	
	$fields = undef unless defined($fields);
	croak("Argument 'fields' is not an array reference") if defined($fields) and ref $fields ne 'ARRAY';

	my $call = $self->server->call(
		'wp.getUser',
		$blog_id,
		$username,
		$password,
		$user_id,
		$fields
	);

	return $self->_process_response($call);
}

sub getUsers {
	my $self = shift;
	my $blog_id = $self->blog_id;
	my $username = $self->username;
	my $password = $self->password;
	my $args = shift;
	my $filter = $args->{'filter'};
	my $fields = $args->{'fields'};

	$fields = undef unless defined($fields);
	croak("Argument 'fields' is not an array reference") if defined($fields) and ref $fields ne 'ARRAY';
	$filter = undef unless defined($filter);
	croak("Argument 'filter' is not a hash reference") if defined($filter) and ref $filter ne 'HASH';

	my $call = $self->server->call(
		'wp.getUsers',
		$blog_id,
		$username,
		$password,
		$filter,
		$fields
	);

	return $self->_process_response($call);
}

sub createUser
{
	my $self = shift;
	my $username = $self->username;
	my $password = $self->password;
	my $user = shift;

	# Check arguments
	$user = undef unless defined($user);
	croak('Missing argument - hash reference of user information') unless defined($user);
	croak('Argument is not a hash reference') unless ref $user eq 'HASH';
	croak('User information must contain user_login') unless defined($user->{'user_login'});
	croak('User information must contain user_email') unless defined($user->{'user_email'});
	croak('User information must contain user_password') unless defined($user->{'user_pass'});
	
	# Manipulate arguments
	$user->{'role'} = lc($user->{'role'}) if defined($user->{'role'});	# otherwise they don't match with real WP roles

	my $call = $self->server->call(
		'wpext.callWpMethod',
		$username,
		$password,
		'wp_insert_user',
		$user
	);

	return $self->_process_response($call);
}

sub addUserMeta 
{
	my $self = shift;
	my $username = $self->username;
	my $password = $self->password;
	my $meta = shift;

	# Check arguments
	$meta = undef unless defined($meta);
	croak('Missing argument - hash reference of user meta') unless defined($meta);
	croak('Argument is not a hash reference') unless ref $meta eq 'HASH';
	croak('User information must contain user_id') unless defined($meta->{'user_id'});
	croak('user_id isn\'t a number') unless looks_like_number($meta->{'user_id'});
	croak('User information must contain meta_key') unless defined($meta->{'meta_key'});
	croak('User information must contain meta_value') unless defined($meta->{'meta_value'});
	$meta->{'unique'} = 'false' unless defined($meta->{'unique'});
	croak('Unique should be "true" or "false"') unless ($meta->{'unique'} eq "true" || $meta->{'unique'} eq "false");
	
	my $call = $self->server->call(
		'wpext.callWpMethod',
		$username,
		$password,
		'add_user_meta',
		$meta->{'user_id'}, $meta->{'meta_key'}, $meta->{'meta_value'}, $meta->{'unique'}
	);

	return $self->_process_response($call);
}

sub getUserMeta 
{
	my $self = shift;
	my $username = $self->username;
	my $password = $self->password;
	my $meta = shift;

	# Check arguments
	$meta = undef unless defined($meta);
	croak('Missing argument - hash reference of user meta requirements') unless defined($meta);
	croak('Argument is not a hash reference') unless ref $meta eq 'HASH';
	croak('User information must contain user_id') unless defined($meta->{'user_id'});
	croak('user_id isn\'t a number') unless looks_like_number($meta->{'user_id'});
	$meta->{'meta_key'} = '' unless defined($meta->{'meta_key'});
	$meta->{'single'} = 'false' unless defined($meta->{'single'});
	croak('Single should be "true" or "false"') unless ($meta->{'single'} eq "true" || $meta->{'single'} eq "false");
	
	my $call = $self->server->call(
		'wpext.callWpMethod',
		$username,
		$password,
		'get_user_meta',
		$meta->{'user_id'}, $meta->{'meta_key'}, $meta->{'single'}
	);

	return $self->_process_response($call);
}
__END__
# lib/WordPress/XMLRPC.pod
