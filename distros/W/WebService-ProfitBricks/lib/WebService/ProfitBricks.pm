#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks - ProfitBricks Base Class

=head1 DESCRIPTION

Profitbricks API

This is the first version of the API implementation. This is currently work-in-progress.

With this library it is possible to provision your ProftBricks datacenter with perl. This library will connect to the SOAP webservice of ProfitBricks.

=head1 HELP

If you need help or want to report bugs please feel free to use our issue tracker.

=over 4

=item *

http://github.com/Krimdomu/p5-webservice-profitbricks/issues

=back

=head1 SYNOPSIS

 use WebService::ProfitBricks qw/DataCenter Image IpBlock/;
 WebService::ProfitBricks->auth($user, $password);
    
 Image->list;
 my $dc = DataCenter->new(dataCenterName => "DC1", region => "EUROPE");
 $dc->save;
 $dc->wait_for_provisioning;
   
 my $stor1 = $dc->storage->new(size => 50, storageName => "store01", mountImageId => $use_image, profitBricksImagePassword => $root_pw);
 $stor1->save;
 $dc->wait_for_provisioning;
    
 my $srv1 = $dc->server->new(cores => 1, ram => 512, serverName => "srv01", lanId => 1, bootFromStorageId => $stor1->storageId, internetAccess => 'true');
 $srv1->save;
 $dc->wait_for_provisioning;


=head1 METHODS

This class inherits from WebService::ProfitBricks::Base.
This is the base class for all the other ProfitBricks classes. 

=over 4

=cut
   
package WebService::ProfitBricks;

use strict;
use warnings;

use Data::Dumper;
use WebService::ProfitBricks::Class;

use WebService::ProfitBricks::Base;
use WebService::ProfitBricks::Connection;

use base qw(WebService::ProfitBricks::Base);

our $VERSION = "0.0.1";

my $user;
my $password;

sub construct {
   my ($self, @data) = @_;

   $self->connection(WebService::ProfitBricks::Connection->new(user => $user, password => $password));

   if(! @data) {
      return;
   }

   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $get_data_func_name = "get$pkg_name";
   my $get_data_func_key   = lcfirst($pkg_name) . "Id";

   if(! exists $self->{__data__}->{$get_data_func_key}) {
      return;
   }

   # later, this should be rewritten so it will only call the soap iface 
   # if the data someone wanted to use is not present yet
   $self->find_by_id($self->$get_data_func_key);

   return $self;
}

=item find_by_id($id)

Tries to find a thing with the given $id.

 my $server = $dc->server->find_by_id("a-b-c-d");

=cut
sub find_by_id {
   my ($self, $id) = @_;
   
   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $get_data_func_name = "get$pkg_name";
   my $get_data_func_key   = lcfirst($pkg_name) . "Id";

   my $data = $self->connection->call($get_data_func_name, $get_data_func_key => $id);
   $self->set_data($data);

   return $self;
}

=item save()

This method created the current object at ProfitBricks. Don't call this method if you only want to update an object. Use I<update> instead. 

 my $dc = DataCenter->new(dataCenterName => "DC1", region => "EUROPE");
 $dc->save;

=cut
sub save {
   my ($self) = @_;

   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $create_func_name = "create" . $pkg_name;

   my $ret_data = $self->connection->call($create_func_name, xml => $self->to_xml);

   $self->set_data($ret_data);
   $self->update_data;

   # get and save relations
   my @relations = $self->get_relations;
   for my $rel (@relations) {
      my $rel_name = pluralize($rel->{name});
#print "(" . ref($self) . ") finding relations through: $rel_name\n";
      for my $child_obj ($self->$rel_name()) {
         my $update_ref_key   = lcfirst($pkg_name) . "Id";
         $child_obj->$update_ref_key($self->$update_ref_key);
         $child_obj->save;
      }
   }

   return $self;
}

=item update()

Updates an exisisting object at ProfitBricks. If you want to create a new object use the I<save> method instead.

 my $dc = DataCenter->find_by_name("DC1");
 $dc->dataCenterName("new_name");
 $dc->update;

=cut
sub update {
   my ($self) = @_;

   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $update_func_name = "update" . $pkg_name;

   my $ret_data = $self->connection->call($update_func_name, xml => $self->to_xml);

   return $self;
}

sub update_data {
   my ($self) = @_;

   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $get_func_name = "get" . $pkg_name;
   my $get_key   = lcfirst($pkg_name) . "Id";

   my $ret_data = $self->connection->call($get_func_name, $get_key => $self->$get_key);

   #print Dumper($ret_data);

   $self->set_data($ret_data);
}

=item delete();

This function delete the current object.

=cut
sub delete {
   my ($self) = @_;

   my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
   my $delete_func_name = "delete" . $pkg_name;
   my $delete_param_name = lcfirst($pkg_name) . "Id";

   my $ret_data = $self->connection->call($delete_func_name, $delete_param_name => $self->$delete_param_name);

   return 1;
}

=item auth($user, $password)

Sets the authentication.

=cut
sub auth {
   my ($class, $_user, $pass) = @_;

   $user = $_user;
   $password = $pass;
}

sub import {
   my ($class, @names) = @_;

   my ($caller_pkg) = caller;

   no strict 'refs';

   for my $name (@names) {
      
      *{ $caller_pkg . "::" . $name } = sub {
         my $pkg = __PACKAGE__ . "::$name";
         eval "use $pkg";
         if($@) {
            die($@);
         }

         shift;
         return $pkg->new(@_);
      };

   }

}

=back

=cut

"For the Horde!";
