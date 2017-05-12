package Test::Mock::Wrapper;
$Test::Mock::Wrapper::VERSION = '0.13';
use strict;
use warnings;
use base qw(Exporter);
use Test::Deep;
use Test::More;
use Clone qw(clone);
use Scalar::Util qw(weaken isweak);
use Module::Runtime qw(use_module);
require Test::Mock::Wrapper::Verify;
use vars qw(%GLOBAL_MOCKS);
use lib qw(t/);

sub import {
    my($proto, @args) = @_;
    foreach my $package (@args){
	use_module $package;
	$GLOBAL_MOCKS{$package} = Test::Mock::Wrapper->new($package);
    }
}

# ABSTRACT: Flexible and prowerful class and object mocking library for perl

=head1 NAME

Test::Mock::Wrapper

=head1 VERSION

version 0.13

=head1 SYNOPSIS

=head2 Mock a single instance of an object

    use Test::Mock::Wrapper;
    use Foo;
    
    my $foo = Foo->new;
    my $wrapper = Test::Mock::Wrapper->new($foo);
    
    $wrapper->addMock('bar')->with('baz')->returns('snarf');
    # Old api, depricated but still supported
    # $wrapper->addMock('bar', with=>['baz'], returns=>'snarf');
    # #######################################
    
    &callBar($wrapper->getObject);
    
    $wrapper->verify('bar')->with(['baz'])->once;

=head2 Mock an entire package

    use Test::Mock::Wrapper;
    use Foo;
    
    my $wrapper = Test::Mock::Wrapper->new('Foo');
    
    $wrapper->addMock('bar')->with('baz')->returns('snarf');
    
    &callBar(Foo->new);
    
    $wrapper->verify('bar')->with(['baz'])->once;
    
    $wrapper->DESTROY;
    
    my $actualFoo = Foo->new;

=head2 Mock Exported functions

    use Test::Mock::Wrapper qw(Foo);
    use Foo qw(bar);
    
    is(&bar, undef);   # Mocked version of bar, returns undef by default.
    
    my $wrapper = Test::Mock::Wrapper->new('Foo');
    
    $wrapper->addMock('bar')->with('baz')->returns('snarf');
    
    print &bar('baz'); # prints "snarf"
    
    $wrapper->verify('bar')->exactly(2); # $wrapper also saw the first &bar (even though it was before you instantiated it)
    
    $wrapper->DESTROY;
    
    print &bar('baz');  # Back to the original Foo::bar (whatever that did)

    
=head1 DESCRIPTION

This is another module for mocking objects in perl.  It will wrap around an existing object, allowing you to mock any calls
for testing purposes.  It also records the arguments passed to the mocked methods for later examination. The verification
methods are designed to be chainable for easily readable tests for example:

  # Verify method foo was called with argument 'bar' at least once.
  $mockWrapper->verify('foo')->with('bar')->at_least(1);
  
  # Verify method 'baz' was called at least 2 times, but not more than 5 times
  $mockWrapper->verify('baz')->at_least(2)->at_most(5);

Test::Mock::Wrapper can also be used to wrap an entire package.  When this is done, Test::Mock::Wrapper will actually use
L<metaclass> to alter the symbol table an wrap all methods in the package. The same rules about mocking type (see options to
new below) apply to mocked packages, but you only get one wrapper that records and mocks calls to all instances of the package,
and any package methods called outside of an object. When mocking an entire package, destroying the wrapper object will "unwrap"
the package, restoring the symbol table to is original unmocked state. Objects instantiated before the wrapper was destroyed
may not behave correctly (i.e. throw exceptions).

=head1 METHODS

=over

=item Test::Mock::Wrapper->new($object, [%options])

Creates a new wrapped mock object and a controller/accessor object used to manipulate the mock without poluting the
namespace of the object being mocked.

Valid options:

=over 2

=item B<type>=>(B<mock>|B<stub>|B<wrap>): Type of mocking to use.

=over 3

=item B<mock>:  All methods available on the underlying object will be available, and all will be mocked

=item B<stub>:  Any method called on the mock object will be stubbed, even those which do not exist in the original
object

=item B<wrap> (default): Only methods which have been specifically set up with B<addMock> will be mocked
all others will be passed through to the underlying object.

=back

=item recordAll=>BOOLEAN (default B<false>)

If set to true, this will record the arguments to all calls made to the object, regardless of the method being
mocked or not.

=item recordMethod=>(B<copy>|B<clone>)

By default arguments will be a simple copy of @_, use B<clone> to make a deep copy of all data passed in. If references are being
passed in, the default will not trap the state of the object or reference at the time the method was called, though clone will.
Naturally using clone will cause a larger memory foot print.

=back

=cut

sub new {
    my($proto, $object, %options) = @_;
    $options{type} ||= ref($object) ? 'wrap' : 'stub';
    $options{recordType} ||= 'copy';
    my $class = ref($proto) || $proto;
    my $controll = bless({__object=>$object, __mocks=>{}, __calls=>{}, __options=>\%options}, $class);
    $controll->{__mocked} = Test::Mock::Wrapped->new($controll, $object);
    if (! ref($object)) {
	if (exists $GLOBAL_MOCKS{$object}) {
	    return $GLOBAL_MOCKS{$object};
	}
	
	eval "package $object; use metaclass;";  
	my $metaclass = $object->meta;

	$metaclass->make_mutable if($metaclass->is_immutable);

	$controll->{__metaclass} = $metaclass;
	
	foreach my $method_name ($metaclass->get_method_list){
	    push @{ $controll->{__wrapped_symbols} }, {name => $method_name, symbol => $metaclass->find_method_by_name($method_name)};
	    $controll->{__symbols}{$method_name} = $metaclass->find_method_by_name($method_name)->body;
	    if ($method_name eq 'new') {
		my $method = $metaclass->remove_method($method_name);
		$metaclass->add_method($method_name, sub{
		    my $copy = $controll->{__options}{recordType} eq 'copy' ? [@_] : clone(@_);
		    push @{ $controll->{__calls}{new} }, $copy;
		    my $obj = bless {_inst => scalar(@{ $controll->{__calls}{new} })}, $object;
		    push @{ $controll->{__instances} }, $obj;
		    return $obj;
		});
		
	    }else{
		my $method = $metaclass->remove_method($method_name);
		$metaclass->add_method($method_name, sub{ $controll->_call($method_name, @_); });
	    }
	}
    }
    return $controll;
}

sub stop_mocking {
    my $controll = shift;
    no strict qw(refs);
    no warnings 'redefine', 'prototype';
    $controll->resetAll;
    if ($controll->{__metaclass}) {
	foreach my $sym (@{ $controll->{__wrapped_symbols} }){
	    if ($sym->{symbol}) {
		$controll->{__metaclass}->add_method($sym->{name}, $sym->{symbol}->body);
	    }
	}
    }
    $controll->{__options}{type} = 'wrap';
}

sub DESTROY {
    shift->stop_mocking;
}

=item $wrapper->getObject

This method returns the wrapped 'mock' object.  The object is actually a Test::Mock::Wrapped object, however it can be used
exactly as the object originally passed to the constructor would be, with the additional hooks provieded by the wrapper
baked in.

=cut

sub getObject {
    my $self = shift;
    return Test::Mock::Wrapped->new($self, $self->{__object});#$self->{__mocked};
}

sub _call {
    my $self = shift;
    my $method = shift;
    my $copy = $self->{__options}{recordType} eq 'copy' ? [@_] : clone(@_);
    push @{ $self->{__calls}{$method} }, $copy;
    
    if ($self->{__mocks}{$method}) {
	my $mock = $self->{__mocks}{$method}->hasMock(@_);
	if ($mock) {
	    return $mock->_fetchReturn(@_);
	}
	
    }
    
    if($self->{__options}{type} ne 'wrap'){
	# No default, type equals stub or mock, return undef.
	return undef;
    }
    else{
	# We do not have a default, and our mock type is not stub or mock, try to call underlying object.
	unshift @_, $self->{__object}; 
	if ($self->{__metaclass}) {
	    # Pacakge is mocked with method wrappers, must call the original symbol metaclass
	    goto &{ $self->{__symbols}{$method} };
	}else{
	    goto &{ ref($self->{__object}).'::'.$method };
	}
	
    }
}

=item $wrapper->addMock($method, [OPTIONS])

This method is used to add a new mocked method call. Currently supports two optional parameters:

=over 2

=item * B<returns> used to specify a value to be returned when the method is called.

    $wrapper->addMock('foo', returns=>'bar')
    
Note: if "returns" recieves an array refernce, it will return it as an array.  To return an actual
array reference, wrap it in another reference.

    $wrapper->addMock('foo', returns=>['Dave', 'Fred', 'Harry'])
    my(@names) = $wrapper->getObject->foo;
    
    $wrapper->addMock('baz', returns=>[['Dave', 'Fred', 'Harry']]);
    my($rnames) = $wrapper->getObject->baz;

=item * B<with> used to limit the scope of the mock based on the value of the arguments.  Test::Deep's eq_deeply is used to
match against the provided arguments, so any syntax supported there will work with Test::Mock::Wrapper;

    $wrapper->addMock('foo', with=>['baz'], returns=>'bat')

=back

The B<with> option is really only usefull to specify a different return value based on the arguments passed to the mocked method.
When addMock is called with no B<with> option, the B<returns> value is used as the "default", meaning it will be returned only
if the arguments passed to the mocked method do not match any of the provided with conditions.

For example:

    $wrapper->addMock('foo', returns=>'bar');
    $wrapper->addMock('foo', with=>['baz'], returns=>'bat');
    $wrapper->addMock('foo', with=>['bam'], returns=>'ouch');
    
    my $mocked = $wrapper->getObject;
    
    print $mocked->foo('baz');  # prints 'bat'
    print $mocked->foo('flee'); # prints 'bar'
    print $mocked->foo;         # prints 'bar'
    print $mocked->foo('bam');  # prints 'ouch'
    

=cut

sub addMock {
    my $self = shift;
    my($method, %options) = @_;
    $self->{__mocks}{$method} ||= Test::Mock::Wrapper::Method->new();
    return $self->{__mocks}{$method}->addMock(%options);
}


=item $wrapper->isMocked($method, $args)

This is a boolean method which returns true if a call to the specified method on the underlying wrapped object would be handled by a mock,
and false otherwise. Any conditional mocks specified with the B<with> option will be evaluated accordingly.

    $wrapper->addMock('foo', with=>['bar'], returns=>'baz');
    $wrapper->isMocked('foo', ['bam']); # False
    $wrapper->isMocked('foo', ['bar']); # True

=cut

sub isMocked {
    my $self = shift;
    my $method = shift;
    my(@args) = @_;
    if ($self->{__options}{type} eq 'stub') {
	return 1;
    }
    elsif ($self->{__options}{type} eq 'mock') {
	return $self->{__object}->can($method);
    }
    else {
	if ($self->{__mocks}{$method} && $self->{__mocks}{$method}->hasMock(@args)) {
	    return 1;
	} else {
	    return undef;
	}
    }
}

=item $wrapper->getCallsTo($method)

This method wil return an array of the arguments passed to each call to the specified method, in the order they were recieved.

=cut

sub getCallsTo {
    my $self = shift;
    my $method = shift;
    if (exists $self->{__calls}{$method}) {
	return $self->{__calls}{$method} || [];
    }
    return;
}

=item $wrapper->verify($method)

This call returns a Test::Mock::Wrapper::Verify object, which can be used to examine any calls which have been made to the
specified method thus far.  These objects are intended to be used to simplify testing, and methods called on the it
are I<chainable> to lend to more readable tests.

=cut

sub verify {
    my($self, $method, %options) = @_;
    return Test::Mock::Wrapper::Verify->new($method, $self->{__calls}{$method});    
}


=item $wrapper->resetCalls([$method])

This method clears out the memory of calls that have been made, which is usefull if using the same mock wrapper instance
multiple tests. When called without arguments, all call history is cleared.  With the optional $method argument, only
history for that method is called.

=cut

sub resetCalls {
    my($self, $method) = @_;
    if (defined($method) && length($method)) {
	$self->{__calls}{$method} = [];
    }else{
	$self->{__calls} = {};
    }
    return 1;
}

=item $wrapper->resetMocks([$method])

This method clears out all previously provided mocked methods. Without arguments, all mocks are cleared. With the optional
$method argument, only mocks for that method are cleared.

=cut

sub resetMocks {
    my($self, $method) = @_;
    if (defined($method) && length($method)) {
	delete $self->{__mocks}{$method};
    }else{
	$self->{__mocks} = {};
    }
    return 1;
}

=item $wrapper->resetAll

This method clears out both mocks and calls.  Will also rebless any mocked instances created from a mocked package
(Prevents intermitent failures during global destruction).

=back

=cut

sub resetAll {
    my $self = shift;
    if ($self->{__metaclass}) {
        foreach my $inst (@{ $self->{__instances} }){
            bless $inst, 'Test::Mock::Wrapped' if($inst);
        }
    }
    $self->{__instances} = [];
    $self->{__calls}     = {};
    $self->{__mocks}     = {};
}


package Test::Mock::Wrapper::Method;
$Test::Mock::Wrapper::Method::VERSION = '0.13';
use Test::Deep;
use strict;
use warnings;

sub new {
    my($proto, %args) = @_;
    $proto = ref($proto) || $proto;
    return bless({_mocks=>[]}, $proto)
}

sub addMock {
    my($self, %args) = @_;
    my $mock = Test::Mock::Wrapper::Method::Mock->new();
    $mock->with(@{$args{with}}) if(exists $args{with});
    $mock->returns($args{returns}) if(exists $args{returns});
    push @{ $self->{_mocks} }, $mock;
    return $mock;
}

sub hasMock {
    my($self, @args) = @_;
    my $def = undef;
    foreach my $mock (@{$self->{_mocks}}){
	if ($mock->_matches(@args)) {
	    if ($mock->_isDefault) {
		$def = $mock;
	    }else{
		return $mock;
	    }
	}
    }
    return $def;
}

package Test::Mock::Wrapper::Method::Mock;
$Test::Mock::Wrapper::Method::Mock::VERSION = '0.13';
use Test::Deep;
use strict;
use warnings;

sub new {
    my($proto, %args) = @_;
    $proto = ref($proto) || $proto;
    my $self = {};
    if ($args{with}) {
	$self->{_condition} = $args{with};
    }
    if ($args{returns}) {
	$self->{_return} = $args{returns};
    }
    
    return bless($self, $proto)
}

sub with {
    my($self, @args) = @_;
    if (scalar(@args) > 1) {
	$self->{_condition} = \@args;
    }
    else{
	$self->{_condition} = shift @args;
    }
    
    #$self->{_condition} = \@args;
    return $self;
}

sub returns {
    my($self, @value) = @_;
    $self->{_return} = scalar(@value) > 1 ? \@value : $value[0];
}

sub _isDefault {
    my($self) = @_;
    return ! exists($self->{_condition});
}

sub _matches {
    my $self = shift;
    my(@args) = @_;
    
    if (exists $self->{_condition}) {
	return eq_deeply(\@args, $self->{_condition});
    }else{
	return 1;
    }
}

sub _fetchReturn {
    my($self, @args) = @_;
    if (ref($self->{_return}) eq 'ARRAY') {
	return @{ $self->{_return} };
    }elsif(ref($self->{_return}) eq 'CODE'){
	return $self->{_return}->(@args);
    }else{
	return $self->{_return};	
    }
}


package Test::Mock::Wrapped;
$Test::Mock::Wrapped::VERSION = '0.13';
use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken isweak);
use vars qw(@ISA);

sub new {
    my($proto, $controller, $object) = @_;
    weaken($controller);
    my $class = ref($proto) || $proto;
    my $self = bless({__controller=>$controller, __object=>$object}, $class);
    weaken($self->{__controller});
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my(@args) = @_;
    $Test::Mock::Wrapped::AUTOLOAD=~m/::(\w+)$/;
    my $method = $1;
    if ($self->{__controller}->isMocked($method, @args)) {
	return $self->{__controller}->_call($method, $self, @args);
    }
    else {
	if ($self->{__object}->can($method)) {
	    unshift @_, $self->{__object}; 
	    goto &{ ref($self->{__object}).'::'.$method };
	}
	else {
	    my $pack = ref($self->{__object});
	    croak qq{Can't locate object method "$method" via package "$pack"};
	}
    }
}

return 42;

=head1 AUTHOR

  Dave Mueller <dave@perljedi.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Mueller.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
