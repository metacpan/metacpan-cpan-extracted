package WordPress::Post;
use base 'WordPress::Base';
use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)/g;


my @struct_possible_keys = qw(title
description
mt_excerpt
mt_text_more
mt_allow_comments
mt_allow_pings
mt_tb_ping_urls
dateCreated
categories);


sub _is_in_arrayref {
   my ($string,$arrayref) = @_;
   for my $element (@$arrayref) {
      return 1 if ($element eq $string);
   }
   return 0;
}

sub post {
   my $self = shift;
   my $struct = shift;
   ref $struct eq 'HASH' or die('arg must be hash');

   ### $struct

   # MAKE SURE WE HAVE A VALID STRUCT
   
   for my $key ( keys %$struct){
      _is_in_arrayref($key, \@struct_possible_keys) 
         or croak("element $key is invalid, valid are: [@struct_possible_keys]");
   }





   # CHECK MIN REQIREMENTS
   
   $struct->{title}  or die('missing title');
   $struct->{description} or die('missing description');





   # IF CATEGORY IS PRESENT, MAKE SURE IT IS A VALID ONE

   if ( defined $struct->{categories} ){
      ### had categories..
      for my $category (@{$struct->{categories}}){
         _is_in_arrayref($category, $self->categories)
            or croak("category $category is not one of the categories of the wordpress blog");
      }
   }
   else {
      $struct->{categories} = [];
   }




   # CHECK VALIDITY OF DATE IF PRESENT

   if( defined $struct->{dateCreated} ){
      # is it a valid date?
      #require Date::Simple;

      #my $date = Date::Simple->new($struct->{dateCreated})
       #  or croak("dateCreated value $$struct{dateCreated} is not a valid date");

      # date MUST be iso compliant - need to change the format to include time ?
      #$struct->{dateCreated} = ($date->as_iso . ' 12:00:00');      
      #
      warn('dateCreated not implemented.');
      delete $struct->{dateCreated};
   }


   ### $struct
   




   # MAKE THE CALL

   my $call = $self->server->call(
      'metaWeblog.newPost',
      1,  # blogid, idnored
      $self->username,
      $self->password,
      $struct,
      1, # 1 is publish
   );

   if( _call_has_fault($call) ){
      return 0;
   }


   if( my $result = $call->result ){
      ### $result
   }

   my $result =$call->result;
   defined $result or warn('result should return id');

   return $result;
}

sub _call_has_fault {
   my $call = shift;
   my $err = $call->fault or return 0;
   
   for( keys %$err ){
      print STDERR "ERROR:$_ $$err{$_}\n";
   }
   return 1;
}


sub _file_bits {
   my $abs_path = shift;
   # from http://search.cpan.org/~gaas/MIME-Base64-3.07/Base64.pm
   require MIME::Base64;

   open(FILE, $abs_path) or die($!);
   my $bits;
   my $buffer;
   while( read(FILE, $buffer, (60*57)) ) {
      $bits.= $buffer;
   }

   return $bits;
}



sub post_file {
   my ($self,$_abs_path) = @_;
   defined $_abs_path or croak('missing file path arg');
   require Cwd;
   my $abs_path = Cwd::abs_path($_abs_path) or die("cant resolve $_abs_path");
   -f $abs_path or die("$abs_path not on disk");

   $abs_path=~/([^\/]+)$/ or die;
   my $filename = $1;
   
   require File::Type;
   my $ft = new File::Type;
   my $type = $ft->mime_type($abs_path) or die('missing mime');

   ### $type
   ### $abs_path
   ### $filename

   my $struct ={
      name => $filename,
      type => $type,
      bits => _file_bits($abs_path),
   };

   my $call = $self->server->call(
      'metaWeblog.newMediaObject',
      1, # blogid ignored
      $self->username,
      $self->password,
      $struct,
   );

   if( _call_has_fault($call) ){
      return;
   }

   my $result = $call->result or die('no result returned');

   my $url = $result->{url} or warn('nothing in result->{url}') and return;
   ### $url
   
   return $url;

}


1;


__END__

=pod

=head1 NAME

WordPress::Post - DEPRECATED see WordPress::CLI instead

=head1 SYNOPSIS
   
   use WordPress::Post;

   my $o= WordPress::Post->new ({ 
      proxy => 'http://this/xmlrpc.php', 
      username => 'lou', 
      password => '2342ss' 
   });

   $o->post({
      title => 'My Vacation Plans',
      description => 'Jump around. Sleep.',      
   });


=head1 DESCRIPTION

This module is DEPRECATD. See L<WordPress::CLI> distribution instead.

The module WordPress did not work for me.
This one works.

It lets you post to a wordpress blog/site.

A script is included with this distribution, wppost. It allows you to post content via the command line. You can also have picture attachments.

=head1 METHODS

=head2 new()

Argument is hash ref. Keys are 'proxy', 'username', and 'password'.

   my $o= new WordPress::Base ({ 
      proxy => 'http://this/xmlrpc.php', 
      username => 'lou', 
      password => '2342ss' 
   });

Method resides in WordPress::Base.

=head2 post()

Argument is hash ref. This is the 'struct' referred to in xmlrpc.

Possible keys are:

   title - string
   description - body of your post, string
   mt_excerpt - string
   mt_text_more - boolean?
   mt_allow_comments - boolean?
   mt_allow_pings - boolean?
   mt_tb_ping_urls - boolean?
   dateCreated - cant figure out the right string
   categories - array ref

Example use:

   $o->post({
      title       => 'This is what happened',
      description => 'Morning is when I wake up.',
      categories  => ['life','sleep'],
   });

Returns post id.
This is useful if you want to know how to reach it via the web right away.
For example if your address for the wordpress blog is http://super.net/wp, 
then a post returning id '3' would be reached via http://super.net/wp/?p=3


=head2 post_file()

Argument is abs path to file you want to post.
Returns url via which the file can be reached.

This is useful in building more complex posts, with attachments, etc.


   

=head1 BUGS

This module is in infancy. It works for me, and well. 

I need to figure out how to determine the date, dateCreated strings such as 
2006-12-31 fail, I also tried '2006-12-31 12:00:00', still fails. 

Please contact the AUTHOR for any issues.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

L<WordPress::CLI> - replacement

=head1 INSTALLING AND TESTING

To test I suggest you download the package and test it out by hand.

For testing you will need to have a word press blog set up.
You must also know the proxy address, a username and password.

=cut


=head1 AUTHOR

leocharre leocharre at gmail dot com

=head1 COPYRIGHT

Copyright (c) 2010 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.
   
   =cut
