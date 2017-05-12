#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

WebService::ProfitBricks::Class - Class helper functions

=head1 DESCRIPTION

This is a module exporting some helper functions to ease the creation of objects.

=head1 SYNOPSIS

 package My::Pkg;
 use WebService::ProfitBricks::Class;
     
 has_many foo    => "My::Foo";
 belongs_to file => "My::File";
    
 # the constructor, to extend the provided constructor.
 sub construct {
    my ($self, @data) = @_;
 }
     
 
=head1 EXPORTED FUNCTIONS

=over 4

=cut
   
package WebService::ProfitBricks::Class;

use strict;
use warnings;

use Data::Dumper;
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(new attrs attr does has_many belongs_to serializer pluralize);

my %FUNC_MAP;

$FUNC_MAP{list} = sub {
   my ($self, $caller_pkg, $option) = @_;

   if(! exists $option->{through}) {
      die("list: you have to define ,,through''.");
   }

   map { $_ = $caller_pkg->new(%{ $_ }) } $self->connection->call($option->{through});
};

$FUNC_MAP{find} = sub {
   my ($self, $caller_pkg, $option, $search) = @_;
   my $lookup_key = $option->{through};

   if(wantarray) {
      grep { $_->$lookup_key eq $search } $self->list;
   }
   else {
      [ grep { $_->$lookup_key eq $search } $self->list ]->[0];
   }

};

=item new(%data)

A common constructor. It accepts an hash (key, values pairs) and stores this hash. If you need to do more, you can create a function I<construct>.

=cut
sub new {
   my $that = shift;
   my $proto = ref($that) || $that;

   my $self = ref($that) ? $that : {};


   eval {
      if($proto->SUPER) {
         $self = $proto->SUPER::new(@_);
      }
   };

   bless($self, $proto);

   $self->set_data({ @_ });

   eval {
      $self->construct(@_);
   };

   return $self;
}

=item has_many($what, $class, $options)

Create a relations to $class over $what.

=cut
sub has_many {
   my ($what, $pkg_class, $options) = @_;

# disable warnings
no warnings;

   my $what_pl = pluralize($what);

   my ($caller_pkg) = caller;
   my $through = $options->{through} || $what;

   eval "use $pkg_class";
   if($@) {
      die("has_many: no available class: $pkg_class found.\n$@");
   }

   no strict 'refs';

   my @old_relations = $caller_pkg->get_relations();

   *{ $caller_pkg . "::get_relations" } = sub {
      my ($self) = @_;
      return ({name => $what, through => $through}, @old_relations);
   };

   # function to get related objects
   *{ $caller_pkg . "::" . $what_pl } = sub {
      my ($self) = @_;

      my $current_data = $self->get_data;

      my @data;
      #print Dumper($self);
      if(ref($through) eq "CODE") {
         @data = &{ $through }($self);
      }
      else {
         # if only one element is in the relation, it will be not a arrayRef...
         if(ref($current_data->{$through}) eq "HASH") {
            $current_data->{$through} = [ $current_data->{$through} ];
         }

         @data = @{ $current_data->{$through} || [] };
      }

                     # only create a new object if $_ is a hashref
      return map { if(ref($_) eq "HASH") { $_ = $pkg_class->new(%{ $_ }) } else { $_ } } @data;
   };

   # function to add related objects
   *{ $caller_pkg . "::" . $what } = sub {
      my ($self) = @_;

      my ($pkg_name) = [ split(/::/, ref($self)) ]->[-1];
      my $get_data_func_key   = lcfirst($pkg_name) . "Id";

      my $obj = $pkg_class->new($get_data_func_key => $self->$get_data_func_key);

      if(ref($self->{__data__}->{$through}) eq "HASH") {
         $self->{__data__}->{$through} = [ $self->{__data__}->{$through} ];
      }

      push(@{ $self->{__data__}->{$through} }, $obj);
      return $obj;
   };

   use strict;
}

=item belongs_to($what, $class, $options)

Creates a backward relaion to $class.

=cut
sub belongs_to {
   my ($what, $pkg_class, $options) = @_;

   my ($caller_pkg) = caller;
   my $through = $options->{through} || $what;

   eval "use $pkg_class";
   if($@) {
      die("belongs_to: no available class: $pkg_class found.\n$@");
   }

   no strict 'refs';

   *{ $caller_pkg . "::" . $what } = sub {
      my ($self) = @_;
      return $pkg_class->new()->find_by_id($self->{__data__}->{$through});
   };

   use strict;
  
}

=item does($what, $option)

=cut
sub does {
   my ($what, $option) = @_;

   my ($caller_pkg) = caller;

   no strict 'refs';

   my $code = $FUNC_MAP{$what};

   if(! $code) {
      die("does: $what not valid.");
   }

   *{ $caller_pkg . "::" . $what } = sub {
      my ($self, @data) = @_;

      if(exists $option->{code}) {
         $code = $option->{code};
         return &$code($self, @data);
      }

      return &$code($self, $caller_pkg, $option, @data);
   };

   use strict;
}

=item attr($attr, $option)

Create a class attribute $attr.

=cut
sub attr {
   my ($attr, $option) = @_;
   my ($caller_pkg) = caller;

   no strict 'refs';

   *{ $caller_pkg . "::" . $attr } = sub {
      my ($self, $set) = @_;
      if(defined $set) {
         $self->{__data__}->{$attr} = $set;
      }

      return $self->{__data__}->{$attr};
   };

   if(exists $option->{searchable} && $option->{searchable}) {
      my ($pkg_name) = [ split(/::/, $caller_pkg) ]->[-1];
      my $find_key   = lcfirst($pkg_name) . "Name";

      if(exists $option->{find_by}) {
         $find_key = $option->{find_by};
      }

      *{ $caller_pkg . "::find_by_" . $find_key } = sub {
         my ($self, $find) = @_;

         if(exists $option->{through}) {
            my $through = $option->{through};
            my $pl = pluralize(lcfirst($pkg_name));
            my @data = $self->$through->$pl();

            if(wantarray) {
               return grep { $_->$find_key eq $find } @data;
            }
            else {
               return [ grep { $_->$attr eq $find } @data ]->[0];
            }
         }
         #$self->connection->call();
      };
   }

   use strict;

}

=item attrs(@attributes)

Create multiple attributes for the class.

=cut
sub attrs {
   my (@has) = @_;
   my ($caller_pkg) = caller;

   no strict 'refs';

   for my $attr (@has) {
      *{ $caller_pkg . "::" . $attr } = sub {
         my ($self, $set) = @_;
         if(defined $set) {
            $self->{__data__}->{$attr} = $set;
         }

         return $self->{__data__}->{$attr};
      };
   }

   use strict;
}

=item serializer($type, $options)

Sets a serializer for the class.

This will create a method $class->to_$type([%data]).

=cut
sub serializer {
   my ($type, $options) = @_;

   my ($caller_pkg) = caller;

   my $pkg_class = "WebService::ProfitBricks::Serializer::$type";
   eval "use $pkg_class";
   if($@) {
      die("serializer: unknown class $pkg_class.\n$@");
   }

   no strict 'refs';
   *{ $caller_pkg . "::to_" . $type } = sub {
      my ($self, %data) = @_;
      my $serializer = $pkg_class->new(%{ $options });
      if(keys %data) {
         return $serializer->serialize({ %data });
      } else
      {
         return $serializer->serialize($self->get_data);
      }
   };
   use strict;
}

# simple pluralize
sub pluralize {
   my ($name) = @_;

   if($name =~ m/s$/) {
      $name .= "es";
   }
   else {
      $name .= "s";
   }
}

=back

=cut

"Use me, if you want to shoot your feet!";
