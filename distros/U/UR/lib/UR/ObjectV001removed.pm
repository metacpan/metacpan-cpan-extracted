package UR::Object;

=pod 

=head1 NAME

UR::ObjectV001removed - restores changes removed in UR version 0.01 

=head1 SYNOPSIS

use UR::ObjectV001removed

=head1 DESCRIPTION

Extends the UR::Object API have methods removed in the 0.01 release. 

If you upgrade UR, but depend on old APIs, use this module.

For version 0.xx of UR, APIs may change with each release.  After 1.0, APIs will
only change with major releases number increments.

=cut

use warnings;
use strict;
our $VERSION = "0.46"; # UR $VERSION;
use Data::Dumper;
use Scalar::Util qw(blessed);

*get_class_meta = sub { shift->__meta__ }; 
*get_class_object = sub { shift->__meta__ }; 
*get_rule_for_params = \&define_boolexpr;
*get_boolexpr_for_params = \&define_boolexpr;
*get_object_set = \&define_set;

our ($all_objects_loaded, $all_change_subscriptions, $all_objects_are_loaded, $all_params_loaded);

*all_objects_loaded         = \$UR::Context::all_objects_loaded;
*all_change_subscriptions   = \$UR::Context::all_change_subscriptions;
*all_objects_are_loaded     = \$UR::Context::all_objects_are_loaded;
*all_params_loaded          = \$UR::Context::all_params_loaded;

# These live in UR::Context, where they may switch to point to 
# different data structures depending on sub-context, transaction, etc.

# They are aliased here for backward compatability, since many parts 
# of the system use $UR::Object::whatever to work with them directly.

sub load {
    # this is here for backward external compatability
    # get() now goes directly to the context
    
    my $class = shift;
    if (ref $class) {
         # Trying to reload a specific object?
         if (@_) {
             Carp::confess("load() on an instance with parameters is not supported");
             return;
         }
         @_ = ('id' ,$class->id());
         $class = ref $class;
    }

    my ($rule, @extra) = UR::BoolExpr->resolve_normalized($class,@_);        
    
    if (@extra) {
        if (scalar @extra == 2 and $extra[0] eq "sql") {
            return $UR::Context::current->_get_objects_for_class_and_sql($class,$extra[1]);
        }
        else {
            die "Odd parameters passed directly to $class load(): @extra.\n"
                . "Processable params were: "
                . Data::Dumper::Dumper({ $rule->params_list });
        }
    }
    return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,1);
}

sub _load {
    Carp::cluck();
    my ($class,$rule) = @_;
    return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,1);
}

sub dbh {
    Carp::confess("Attempt to call dbh() on a UR::Object.\n" 
                  . "Objects no longer have DB handles, data_sources do\n"
                  . "use resolve_data_sources_for_class_meta_and_rule() on a UR::Context instead");
    my $ds = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule(shift->__meta__);
    return $ds->get_default_handle;
}


sub matches {
    no warnings;
    my $self = shift;
    my %param = $self->preprocess_params(@_);
    for my $key (keys %param) {
        next unless $self->can($key);
        return 0 unless $self->$key eq $param{$key}
    }
    return 1;
}

sub property_names {
    my $class = shift;
    my $meta = $class->__meta__;
    return $meta->all_property_names;
}

sub _is_loaded {
    Carp::cluck();
    my ($class,$rule) = @_;
    return $UR::Context::current->get_objects_for_class_and_rule($class,$rule,0);
}

# as we remove more logic from the default API, add extensions here.
use UR::ObjectV04removed;

