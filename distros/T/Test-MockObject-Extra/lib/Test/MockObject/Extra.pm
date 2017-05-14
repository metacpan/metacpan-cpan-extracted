use strict;
use warnings;

package Test::MockObject::Extra;

use base 'Test::MockObject';

=head1 NAME

Test::MockObject::Extra - A little bit Extra on top of Test::MockObject

=head1 SYNOPSIS

    # Create a mock
    my $mock = Test::MockObject::Extra->new();

    # Fake out a module
    $mock->fake_module(
    	'Some::Module',
    	som_sub => sub { ... },
    );
    
    # Do some testing....
    
    ...
    
    # Remove the fake module
    $mock->unfake_module;
    
=head1 DESCRIPTION

This module adds a bit of extra functionality I needed in Test::MockObject.
It could probably be rolled into Test::MockObject if the author wants it.

Test::MockObject::Extra inherits from Test::MockObject. It overrides
fake_module() and adds a new method unfake_module(). These are described
below.

=head1 METHODS
     
=head2 C<fake_module(I<module name>), [ I<subname> => I<coderef>, ... ]

Works in the same way as Test::MockObject, except it emits a warning if
called as a class method. This is because (in order for unfake_module()
to work) it needs to record what subs have been faked, so they can
be restored later.

=cut

sub fake_module {
    my ($class, $modname, %subs) = @_;
    
    unless (ref $class) {
    	require Carp;
    	Carp::carp("fake_module() called as class method - calling of unfake_module() unsupported");
    }

	$class->SUPER::fake_module($modname, %subs);
  
  	if (ref $class) {
	    $class->{_faked_module_name} = $modname;
	  
	    for my $sub (keys %subs)
	    {
	        push @{$class->{_faked_subs}}, $sub if ref $class;
	    }
  	}
}

=head2 C<unfake_module()>

If you've called fake_module() (or fake_new()), you may need to 'unfake' it
later, so the real class can load. This is especially true if you have a whole
lot of tests running in one process (such as under Test::Class::Load).

Note, that after calling unfake_module(), you'll need to load the real version
of the module in some way (this could probably be added as an option to this
method at a later date). If you're loading the modules you're testing with
use_ok(), you should be OK.

Also note it's possible to call fake_module() as a class method. If you do this, 
unfake_module() will die if you call it, since it needs
to hold onto some state data in order to unfake the module.

=cut

sub unfake_module {
	my ($class) = @_;
	
	require Carp;
	Carp::croak("unfake_module() can't be called as a class method") unless ref $class;
	
	my $modname = $class->{_faked_module_name};
		
	Carp::croak("Can't unfake module - don't know the module name. Did you call fake_module() as a class method?") unless $modname;
	
    $modname =~ s!::!/!g;
    delete $INC{ $modname . '.pm' };
        
    {
        no strict 'refs';
        delete ${ $modname . '::' }{VERSION};
    }    
    
    no strict 'refs';
    foreach my $sub (@{$class->{_faked_subs}}) {
    	undef *{ $class->{_faked_module_name} . '::' . $sub };
    }	
}

=head1 AUTHOR

Sam Crawley (Mutant) - mutant dot nz at gmail dot com

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;