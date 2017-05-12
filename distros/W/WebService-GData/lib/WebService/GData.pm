package WebService::GData;
use 5.008008;
use strict;
use warnings;
use Carp;
use overload '""' => "__to_string", '==' => 'equal', fallback => 1;

our $VERSION = 0.06;

our $AUTOLOAD;

sub import {
	strict->import;
	warnings->import;
	my $import  = shift;
	my $package = caller;
	if ($import) {
		install_in_package( ['private'], sub { return \&private; }, $package );
	}
}

sub new {
	my $package = shift;
	my $this    = {};
	bless $this, $package;
	$this->__init(@_);
	return $this;
}

sub __init {
	my ( $this, %params ) = @_;

	while ( my ( $prop, $val ) = each %params ) {
		$this->{$prop} = $val;
	}
}

sub __to_string {
	return shift;
}

sub equal {
	my ( $left, $right ) = @_;
	return overload::StrVal($left) eq overload::StrVal($right);
}

sub install_in_package {
	my ( $subnames, $callback, $package ) = @_;

	$package = $package || caller;
	return if ( $package eq 'main' );    #never import into main
	{                                    #install
		no strict 'refs';
		no warnings 'redefine';
		foreach my $sub (@$subnames) {
			*{ $package . '::' . $sub } = &$callback($sub);
		}
	}

}

sub private {
	my ( $name, $sub ) = @_;
	my $package = caller;
	install_in_package(
		[$name],
		sub {
			return sub {
				my @args = @_;
				my $p    = caller;
				croak {
					code    => 'forbidden_access',
					content => 'private method called outside of its package'
				  }
				  if ( $p ne $package );
				return &$sub(@args);
			  }
		},
		$package
	);
}

sub disable {
	my ( $parameters, $package ) = @_;
	$package = $package || caller;
	install_in_package(
		$parameters,
		sub {
			return sub {

				#keep the chaining
				return shift();
			  }
		},
		$package
	);

}

##must test for side effects.
##Might get rid of the following...

sub AUTOLOAD {
	my $func = $AUTOLOAD;

	$func =~ s/.*:://;
	my $this = shift;

	return if $func =~ m/[A-Z]+/;

	return $this->__set( $func, @_ ) if @_ >= 1;

	$this->__get($func);

}

sub __set {
	my ( $this, $func, @args ) = @_;
	$this->{$func} = @args == 1 ? $args[0] : \@args;
	return $this;
}

sub __get {
	my ( $this, $func ) = @_;
	return $this->{$func};
}

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData - Google data protocol v2.

=head1 SYNOPSIS

    package WebService::MyService;
    use WebService::GData;#strict/warnings turned on
    use base 'WebService::GData';

    #this is the base implementation of the __init method in WebService::GData
    #it is call when new() is used. only overwrite it if necessary.

    sub __init {
        my ($this,%params) = @_;
        while(my ($prop,$val)=each %params){
            $this->{$prop}=$val;
        }
    }


    WebService::GData::install_in_package([qw(firstname lastname age gender)],sub {
            my $func = shift;
            return sub {
                my $this = shift;
                return $this->{$func};
            }
    });

    #the above is equal to writing these simple getters:

    #sub firstname {
    #    my $this = shift;
    #    return $this->{firstname};
    #}

    #sub lastname {
    #    my $this = shift;
    #    return $this->{lastname};
    #}

    #sub age {
    #    my $this = shift;
    #    return $this->{age};
    #}  

    #sub gender {
    #    my $this = shift;
    #    return $this->{gender};
    #}  

    1;

    
    use WebService::MyService; 

    my $object = new WebService::MyService(name=>'test');

    $object->name;#test
    
    #__set and __get are used to create automaticly getters and setters
    $object->age(24);
    $object->age();#24 
    $object->{age};#24

=head1 DESCRIPTION

WebService::GData module intends to implement the Google Data protocol and implements some services that use this protocol, like YouTube.

This package is a blueprint that most packages in this module inherit from. It offers a simple hashed based object creation mechanism via the word new. 

If you want to pock into the instance, it's easy but everything that is not documented 
should be considered private. If you play around with undocumented properties/methods and that it changes,upgrading to the new version with all 
the extra new killer features will be very hard to do. 

so...

dont.

As an example, the following classes extend L<WebService::GData> to implement their feature:

=over

=item L<WebService::GData::Base>

Implements the base get/post/insert/update/delete methods via HTTP for the Google data protocol.

=item L<WebService::GData::ClientLogin>

Implements the ClientLogin authorization system.

=item L<WebService::GData::Error>

Represents a Google data protocol Error.

=item L<WebService::GData::Query>

Implements the basic query parameters and create a query string.

=item L<WebService::GData::Feed>

Represents the basic tags found in a Atom Feed (JSON format).

=back

A service in progress:

=over

=item L<WebService::GData::YouTube>

Implements parts of the YouTube API .

=back

=head2  CONSTRUCTOR

=head3 new

=over 

Takes an hash which keys will be attached to the instance, $this.
You can also use C<install_in_package()> to create setters/getters or simply let the methods been redispatched automaticly.

B<Parameters>

=over 4

=item C<parameters:Hash>

=back

B<Returns> 

=over 4

=item C<WebService::GData>

=back

Example:


    my $object = new WebService::GData(firstname=>'doe',lastname=>'john',age=>'123');

    $object->{firstname};#doe
    $object->firstname;#doe
    $object->firstname('billy');
    $object->firstname;#billy
	
=back

=head2 METHODS

=head3 __init

=over

This method is called by the constructor C<new()>.
This function receives the parameters set in C<new()> and assign the key/values pairs to the instance.
You should overwrite it and add your own logic if necessary.

Default implementation:

    sub __init {
        my ($this,%params) = @_;
        while(my ($prop,$val)=each %params){
            $this->{$prop}=$val;
        }
    }

=back

=head2 OVERLOAD

=head3 __to_string

=over

Overload the stringification quotes and return the object. 
You should overwrite it to create a specific output (Dump the object, display a readable representation...).

=back

=head3 equal

=over

Overload the comparison "==" by checking that boch objects are hosted in the same memory slot.

=back

=head2 AUTOLOAD

Calls to undefined methods on an instance are catched and dispatch to __get if the call does not contain any parameter or __set if 
parameters exist.
You can overwrite these two methods in your package to meet your naming needs.
For example, when you call $instance->dont_exist, you might want to look into $instance->{__DONT_EXIST} instead of the default $instance->{dont_exist}.


=head3 __get

=over

This method catches all calls to undefined methods to which no parameters are passed.
If you call $instance->unknown_method, the C<__get> method will return $instance->{unknown_method} by default.
The C<__get> method gets the instance and the name of the function has parameters.

Below is the default implementation:

sub __get {
    my ($this,$func) = @_;
    return $this->{$func};
}

=back

=head3 __set

=over

This method catches all calls to undefined methods to which parameters are passed.
If you call $instance->unknown_method($val,$val2), the C<__set> method will set the parameters to $instance->{unknown_method}
 by default.
When several parameters are passed, they are saved as an array reference.
The C<__set> method gets the instance,the name of the function and the parameters as its own arguments.

Below is the default implementation:

sub __set {
    my ($this,$func,@args) = @_;
    $this->{$func}= @args == 1 ? $args[0] : \@args;
    return $this;
}


=back

=head2  SUBS

=head3 install_in_package

=over

Install in the package the methods/subs specified. Mostly use to avoid writting boiler plate getter/setter methods
and a bit more efficient than AUTOLOAD methods as they are installed directly into the package 
so it will not climb up a function chain call. 

B<Parameters>

=over 4

=item C<subnames:ArrayRef> - Should list the name of the methods you want to install in the package.

=item C<callback:Sub> - The callback will receive the name of the function. This callback should itself send back a function.

=item C<package_name:Scalar> (optional) - Add functions at distance by specifying an other module.

=back

B<Returns> 

=over 4

=item C<void>

=back

Example:

    package Basic::User;
    use WebService::GData;
    use base 'WebService::GData';
    
    #install simple setters; it could also be setter/getters
	
    WebService::GData::install_in_package([qw(firstname lastname age gender)],sub {
            my $func = shift;#firstname then lastname then age...
            return sub {
                my $this = shift;
                return $this->{$func};
            }
    });

    1;

    #in user code:

    my $user = new Basic::User(firstname=>'doe',lastname=>'john',age=>100,gender=>'need_confirmation');

    $user->age;#100
    $user->firstname;#doe
	
=back

=head3 private

=over

Create a method that is private to the package. Calling a private function from outside of the package will throw an error.

You can import the private method:

    use WebService::GData 'private';

B<Parameters>

=over

=item C<function_name_with_sub:Hash> - Accept an hash which key is the function name and value a sub.

=back

B<Returns> 

=over 4 

=item C<void>

=back

B<Throws> 

=over 4 

=item C<error:RefHash> - an hash containing the code: 'forbidden_access' and the content:'private method called outside of its package'.

=back

Example:

    package Basic::User;
    use WebService::GData 'private';
    use base 'WebService::GData';
    
    private my_secret_method => sub {
		
    };  #note the comma

    1;

    #in user code:
	
    my $user = new Basic::User();

    $user->my_secret_method();#throw an error
	
    eval {
        $user->my_secret_method();
    };
    if(my $error = $@){
        #$error->{code};
        #$error->{content};
    }
	
=back

=head3 disable

=over

Overwrite a method so that it does nothing...
Some namespaces inherit from functionalities that are not required.
The functions will still be available but will just return the instance.

B<Parameters>

=over

=item C<functions:ArrayRef> - array reference containing the functions to disable 

=item C<package:Scalar*> - (optional) By default it uses the package in which it is called but you can specify a package.

=back

B<Returns> 

=over 4 

=item C<void>

=back


Example:

    package Basic::User;
    use WebService::GData;
    use base 'WebService::GData::Feed';
    
    WebService::GData::disable([qw(etag title)]);

    1;

    #in user code:
	
    my $user = new Basic::User();

    $user->etag("ddd")->title("dddd");#does nothing at all

	
=back


=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
