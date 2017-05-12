package UR::Object::Accessorized;

use strict;
use warnings;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => ['UR::Object'],
);

#--- just because I'm tired of GSCApp and Class::Accessor not playing nice, here we go

sub delegate{
    my $class = shift;
    my %p = @_;
    foreach my $get_object_method(keys %p){
	foreach my $delegated_function(@{$p{$get_object_method}}){
	    my $class_function = $class.'::'.$delegated_function;
	    no strict;
	    *$class_function = sub{
		my $self = shift;
		my $obj = $self->$get_object_method; #--- get the object of delgation
		unless($obj){
		    $self->error_message("Failed to call $function on $self");
		    return;
		}
		return $obj->$delegated_function(@_);
	    };
	}
    }
    1;
}

sub ro_delegate{
    my $class = shift;
    my %p = @_;
    foreach my $function (keys %p){
	foreach my $delegator_func(@_){
	    my $class_function = $class.'::'.$delegator_func;
	    no strict;
	    *$class_function = sub{
		my $self = shift;
		my $obj = $self->$function(); #--- get the object of delgation
		unless($obj){
		    $self->error_message("Failed to call $function on $self");
		    return;
		}
		return $obj->$delegator_func();
		};
	}
    }
    1;
}

sub accessorize{
    my $class = shift;
    foreach my $accessor_func(@_){
	my $setfunc = $class.'::'.$accessor_func;
	no strict;
	*$setfunc = sub{
	    my $self = shift;
	    if(@_){
		return $self->__set($accessor_func, @_);
	    }
	    return $self->__get($accessor_func);
	};
    }
}

sub explicit_accessorize{
    my $class = shift;
    foreach my $accessor_func(@_){
	my $write_func = $class.'::set_'.$accessor_func;
	my $read_func = $class.'::get_'.$accessor_func;
	no strict;
	*$write_func = sub{
	    my $self = shift;
	    return unless @_;
	    return $self->__set($accessor_func, @_);
	};
	*$read_func = sub{
	    my $self = shift;
	    return unless @_;
	    return $self->__get($accessor_func, @_);
	};
    }
}

sub ro_accessorize{
    my $class = shift;
    foreach my $accessor_func(@_){
	my $setfunc = $class.'::get_'.$accessor_func;
	no strict;
	*$setfunc = sub{
	    my $self = shift;
	    if(@_){
		die "cannot set values for read only accessor $accessor_func";
	    }
	    return $self->__get($accessor_func);
	};
    }
}

sub ro_array_accessorize{
    my $class = shift;
    foreach my $accessor_func(@_){
	no strict;
	#--- get
	my $getf = $class.'::'.$accessor_func;
	*$getf = sub{
	    my $self = shift;
	    return $self->__get_array($accessor_func);
	};
    }
}

sub array_accessorize{
    my $class = shift;
    foreach my $accessor_func(@_){
	no strict;
	#--- get
	my $getf = $class.'::get_'.$accessor_func;
	*$getf = sub{
	    my $self = shift;
	    return $self->__get_array($accessor_func);
	};
	#--- set
	my $setf = $class.'::set_'.$accessor_func;
	*$setf = sub{
	    my $self = shift;
	    return $self->__set_array($accessor_func, @_);
	};
	#--- add
	my $addf = $class.'::add_'.$accessor_func;
	*$addf = sub{
	    my $self = shift;
	    return $self->__add_array($accessor_func, @_);
	};
	#--- remove
	my $removef = $class.'::remove_'.$accessor_func;
	*$removef = sub{
	    my $self = shift;
	    return $self->__remove_array($accessor_func, @_);
	};
	#--- clear
	my $clearf = $class.'::clear_'.$accessor_func;
	*$clearf = sub{
	    my $self = shift;
	    return $self->__clear_array($accessor_func);
	};
	#--- default
        unless($class->can($accessor_func)){
            my $defaultf = $class.'::'.$accessor_func;
            *$defaultf = sub{
                my $self = shift;
                if(@_){
                    #--- with parameters, it is 'set'
                    return $self->__set_array($accessor_func, @_);
                }
                else{
                    return $self->__get_array($accessor_func, @_);
                }
            };
        }
    }
}


sub __get{
    my $self = shift;
    my $func = shift;
    return unless ref $self;
    return $self->{$func};
}

sub __set{
    my $self = shift;
    my $func = shift;
    return unless @_;
    return unless ref $self;
    $self->{$func} = shift;
    return 1;
}

sub __get_array{
    my $self = shift;
    my $func = shift;
    return unless exists $self->{$func} && ref $self->{$func} eq 'ARRAY';
    if(@_){
	if(@_ == 1){
	    return $self->{$func}->[shift];
	}
	else{
	    return @{$self->{$func}}[@_];
	}
    }
    return @{$self->{$func}};
}

sub __set_array{
    my $self = shift;
    my $func = shift;
    return unless @_;
    $self->{$func} = [@_];
    1;
}

sub __add_array{
    my $self = shift;
    my $func = shift;
    unless(exists $self->{$func}){
	$self->__set_array($func => @_);
	return 1;
    }
    return unless ref $self->{$func} eq 'ARRAY';
    push @{$self->{$func}}, @_;
    1;
}

sub __remove_from_array{
    my $self = shift;
    my $func = shift;
    return unless exists $self->{$func} && ref $self->{$func} eq 'ARRAY' && @{$self->{$func}};
    my $count = 0;
    my %bad = map {$_ => 1} @_;
    my $i=0;
    while($i < scalar(@{$self->{$func}})){
	if($bad{$self->{$func}[$i]}){
	    splice @{$self->{$func}}, $i, 1;
	    ++$count;
	    next;
	}
	++$i;
    }
    return $count;
}

sub __clear_array{
    my $self = shift;
    my $func = shift;
    return unless exists $self->{$func} && ref $self->{$func} eq 'ARRAY' && @{$self->{$func}};
    $self->{$func} = [];
    return;
}


1;
