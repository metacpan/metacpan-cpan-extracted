package WordPress::Base; 
# DEPRECATED
use strict;
use warnings;
use Carp;

no strict 'refs';


sub new {
   my ($class,$self) = @_;
   ref $self eq 'HASH' or croak('expected hash ref arg to constructor');
   

   bless $self, $class;
   return $self;

}


#required params/methods for a connection
for my $param (qw(proxy username password)){
   #my $method = "_$param";

   *{$param} = sub {
      my $self = shift;
      my $val = shift;
      if( defined $val ){
         $self->{$param} = $val;      
      }

      return $self->{$param};
   };

}





# i know it doesnt cache it in object, this is just the raw method
sub _categories {
   my $self = shift;
   my $call = $self->server->call(
      'metaWeblog.getCategories',
      1, # blogid ignored
      $self->username,
      $self->password,
      );

   my @categories =  map { $_->{categoryName} } @{ $call->result };
   return @categories;
}
# may return undef





# yes this one caches. always returns array ref
sub categories {
   my $self = shift;
   $self->{_categories} ||= [ $self->_categories ];
   return $self->{_categories};
}






sub server {
   my $self = shift;
   unless( $self->{_server} ){
      $self->proxy or croak('missing proxy');
      require XMLRPC::Lite;

      $self->{_server} ||= XMLRPC::Lite->proxy( $self->proxy );
   }
   return $self->{_server};
}


1;

__END__


=pod

=head1 NAME

WordPress::Base - DEPRECATED basic connection to wordpress via xmlrpc

=head1 DESCRIPTION

This module is for use for other modules like WordPress::Post

=head1 SYNOPSIS
   
   package Wordpress::Something;
   use base 'WordPress:Base';

   my $o= WordPress::Base->new ({ 
      proxy => 'http://this/xmlrpc.php', 
      username => 'lou', 
      password => '2342ss' 
   });

   $o->server;
   $o->_categories;  # re-query
   $o->categories; # query once

=head1 new()

Argument is hash ref. Keys are 'proxy', 'username', and 'password'.

   my $o= new WordPress::Base ({ 
      proxy => 'http://this/xmlrpc.php', 
      username => 'lou', 
      password => '2342ss' 
   });

=head1 METHODS

head2 server()

returns XMLRPC::Lite object
proxy must be set

=head2 username()

Perl set/get method. Argument is string.
If you pass 'username' to constructor, it is prepopulated.

   my $username = $o->username;
   $o->username('bill');

=head2 password()

Perl set/get method. Argument is string.
If you pass 'password' to constructor, it is prepopulated.

   my $pw = $o->password;
   $o->password('jim');

=head2 proxy()

Perl set/get method. Argument is string.
If you pass 'poxy' to constructor, it is prepopulated.

=head1 SEE ALSO

XMLRPC::Lite
SOAP::Lite
WordPress::Post

WordPress::CLI - replacement

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





