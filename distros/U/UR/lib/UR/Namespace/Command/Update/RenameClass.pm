

package UR::Namespace::Command::Update::RenameClass;                         

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Update::RewriteClassHeader",
);

# Standard methods used to output help.

sub shell_args_description {
    "My::Old My::New";
}

sub help_description {
    "Updates class descriptions for to correspond with database schema changes."
}

# Wrap execute since we take different parameters than a standard
# "runs on modules in tree" rewrite command.

our $old;
our $new;

sub execute {
    my $self = shift;
    $old = shift;
    $new = shift;
    $self->error_message("rename $old to $new not implemented");
    return;
}

# Override "before" to do the class editing.

sub before {
    my $self = shift;
    my $class_objects = shift;
    
    # By default, no classes are rewritten.
    # As we find classes with the $old name, in their metadata,
    # we add them to this list.
    $class_objects = [];
    
    print "finding properties which seem to refernce a class\n";
    my @p = UR::Object::Property->is_loaded(
        property_name => ["class_name","r_class_name","parent_class_name"]
    );
    
    print "found " . join("\n",map { $_->class_name . " -> " . $_->property_name } @_) . "\n";
    
    print "checking instances of those properties\n";
    my @changes;
    for my $p (@p) {
        my $class_name = $p->class_name;
        my $property_name = $p->property_name;
        my @obj = $class_name->is_loaded();
        for my $obj (@obj) {
            if ($obj->$property_name eq $new) {
                Carp::confess("Name $new is already in use on $class_name, " 
                    . $obj->{id} 
                    . $property_name . "!"
                );
            }
            elsif ($obj->$property_name eq $old) {
                print "Setting $new in place of $old on $class_name, " 
                    . $obj->{id} 
                    . $property_name . ".\n";
                push @changes, [$obj,$property_name,$new];
            }
        }
    }
    
    return 1;
}

# we implement before() but use the default call to  
# for_each_class_object() call in UR::Namespace::Command::rewrite

1;

