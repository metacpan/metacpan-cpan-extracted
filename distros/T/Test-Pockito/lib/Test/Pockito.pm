package Test::Pockito;

use strict;
use warnings;

use Test::Pockito::DefaultMatcher;

use Carp;
use Class::MOP;
use Class::MOP::Class;

our $VERSION = "0.02";

=head1 NAME

Pockito - Inspired by Mockito, a library to build mock objects for test driven development

=head1 SYNOPSIS

Pockito allows for very matter of fact mock definitions and uses.

=over 1

=item 1. when A happens, produce B

=item 2. if it's impossible for A to happen, complain

=item 3. make every A produce B, or have it return different values

=item 4. after using my mock objects, let me know if my expectations were met

=back

With the advent of Class::MOP, new methods for package creation exists.  The almighty Moose is made possible by it.  Pockito is intended to fit most ways of class creation.

=head1 DESCRIPTION

A mock object is a thing that imitates something else that may be hard to setup or can be brittle.  Examples of such are databases, network connections, and things deemed non trivial that may involve state.

The following is an overly complicated class that marries two people together, that takes two user ids and inserts that user1 is married to user2, and vice versa.  We should probably check to make sure they exist to make sure they aren't married already.

Our database object we wish to mock out may provide methods like, is_married( $user ), and marry($user1, $user2);


	package Love;

	sub new {
	    return bless {}, Love;
	}

	sub marry {
	    my $self  = shift;
	    my $user1 = shift;
	    my $user2 = shift;

	    my $db_object = $self->{'db_object'};

	    if (   $db_object->is_married($user1) == 0
		&& $db_object->is_married($user2) == 0 )
	    {
		$db_object->marry( $user1, $user2 );
		$db_object->marry( $user2, $user1 );
		return 1;
	    }
	    return 0;
	}

	package MyDbClass;

	sub is_married {
	    # do some complicated stuff
	}

	sub marry {
	    # do some other complicated stuff
	}

	#Our test can be

	use Test::Pockito;
	use Test::Simple;

	my $pocket  = Test::Pockito->new("MyNamespace");
	my $db_mock = $pocket->mock("MyDbClass");

	$pocket->when( $db_mock->is_married("bob") )->then(0);
	$pocket->when( $db_mock->is_married("alice") )->then(0);
	$pocket->when( $db_mock->marry( "alice", "bob" ) )->then();
	$pocket->when( $db_mock->marry( "bob",   "alice" ) )->then();

	my $target = Love->new();
	$target->{'db_object'} = $db_mock;

	ok( $target->marry( "bob", "alice" ) == 1, "single to married == success!" );

	ok( scalar keys %{ $pocket->expected_calls } == 0,
	    "No extra cruft calls, huzzah!" );

A few things are going on here.

The $pocket object holds logs of interactions between objects you mock through it.  This offers the convenience of validating through one object, but if you wish to have two completely different mocks, one can create different Pockito objects.  The namespace passed along is a prefix to all packages created for the mock to avoid collisions.  In this case, a MyNamespace::Love package is created.  

The ->mock call is just like ->new except the package name is passed. It will inspect the package for all subs, and in the case of Moose, attributes to mimic.

$pocket->when( .... )->then( ... ) records many things.  It records in the ->is_married sub is called, with a parameter "bob".  When this combination occurs the first time, return 0.  One can queue up multiple calls with the same signature to have multiple results.

$pocket->{'warn'} tells Pockito to complain about calls that it doesn't expect.

Finally, a hash of calls that have yet to be executed are returned via expected_calls.  Since we called everything we expected, we can celebrate.  If is_married returned a random number, we could inspect the result of expected_calls and make a judgement call if the expectations were met.

There are some conveniences written in for default calls, partial mocks, outputting a formated report of what method calls have yet to be called, custom equality comparisons for parameters and bridges for package creation.


=cut

sub _push_expected_call {
    my $self      = shift;
    my $mock_call = shift;

    my $package = $$mock_call{'package'};
    my $method  = $$mock_call{'method'};
    my $params  = $$mock_call{'params'};
    my $result  = $$mock_call{'result'};
    my $execute = $$mock_call{'execute'};

    push(
        @{ $self->{'_calls'}{$package}{$method} },
        { 'params' => $params, 'result' => $result, 'execute' => $execute }
    );
}

sub _mock_call {
    my $self    = shift;
    my $package = shift;
    my $method  = shift;
    my @params  = @_;

    return if ( $method eq "DESTROY" );

    %{ $self->{'_last_mock_call'} } = (
        'package' => $package,
        'method'  => $method,
        'params'  => \@params
    );

    if ( exists $self->{'_calls'}{$package}{$method} ) {
        my @expectation = @{ $self->{'_calls'}{$package}{$method} };

        my $method_last_index = $#expectation;
        foreach my $x ( 0 .. $#expectation ) {
            my ($found) =
              $self->{'call_matcher'}( $package, $method, \@params,
                $expectation[$x]->{'params'} );
            if ($found) {
                splice @{ $self->{'_calls'}{$package}{$method} }, $x, 1;

                my @result = @{ $expectation[$x]->{'result'} };
                $self->{'_last_mock_call'}{'result'}   = \@result;
                $self->{'_last_mock_call'}{'complete'} = 1;
                $self->{'_last_mock_call'}{'execute'} =
                  $expectation[$x]->{'execute'};

                if ( $self->{'go'} and $expectation[$x]->{'execute'} ) {
                    return $result[0]();
                }
                else {
                    return wantarray ? @result : shift @result;
                }
            }
        }
    }
    if ( exists $self->{'_defaultcalls'}{$package}{$method} ) {
        my @expectation = @{ $self->{'_defaultcalls'}{$package}{$method} };

        my $method_last_index = $#expectation;
        foreach my $x ( 0 .. $#expectation ) {
            my ($found) =
              $self->{'call_matcher'}( $package, $method, \@params,
                $expectation[$x]->{'params'} );

            my (@result) = @{ $expectation[$x]->{'result'} };
            return wantarray ? @result : shift @result if $found;
        }

    }

    if ( $self->{warn} ) {
        my $original_package = $package;
        $original_package =~ s/^$self->{namespace}:://;

        carp("Mock call not found to ${original_package}->${method}");
    }

    return;
}

=head1 ATTRIBUTES

=over 4

=item warn

Setting the hash key of warn to 1 will cause a mock call that wasn't scheduled, but called, to be carped.

=item go

Pockito can keep track of state pretty well, except when ->execute is called for the same parameters more than once.  Perl evaluates lazily, so

   $pocket->when( $mock->a(1) )->execute( sub{ ... } );
   $pocket->when( $mock->a(1) )->execute( sub{ ... } );

will cause the anonymous sub to be called twice.  If this occurs a warning will be produced. Toggle go to 0 before scheduling calls, and back to 1 when the test starts to use mocks to quiet it.

=back

=head1 METHODS

=over 4

=item new(package [, matcher])

Instanciate Pockito.  package is a prefix name for the namespace for your mocks.  It would be rude to assume every nacemspace will be valid.  You do that work.  matcher is a reference to a sub to check for equality of a mocked call.   See Test::Pockito::DefaultMatcher::default_call_match for more information on how to implement this subroutine.

=cut 

sub new {
    my $package   = shift;
    my $namespace = shift;
    my $matcher   = shift || \&Test::Pockito::DefaultMatcher::default_call_match;
    return bless {
        '_calls'       => {},
        'namespace'    => $namespace,
        'call_matcher' => $matcher,
        'go'	       => 1
    }, $package;
}

=pod

=item mock(module, [excluded1, excluded2, ..., excluded-n])

module is the name of the package to inspect and construct a mock from.  The result is an objet that looks just like the object you would normally use.  In the case of IO::Socket::connect, a connect method would be constructed.  In the case of Moose, attributes and methods are mocked out, right down to meta. 

The second parameter is a list of methods not to mock.  This is useful for partial mocks for those heavily coupled methods.  Example uses are for data that is harder to setup, but easier to call a helping method.
	
=cut

sub mock {
    my $self     = shift;
    my $module   = shift;
    my @excluded = @_;

    my $package     = $self->{'namespace'} . "::" . $module;
    my $module_meta = Class::MOP::Class->initialize($module);
    my %dispatch    = ();

    foreach my $method ( $module_meta->get_method_list ) {
        if ( !grep { $method eq $_ } @excluded ) {
            $dispatch{$method} = sub {
                shift;
                $self->_mock_call( $package, $method, @_ );
              }
        }
    }

    $module_meta->make_mutable if $module_meta->can("make_mutable");

    if ( $module_meta->can("get_all_attributes") ) {
        foreach ( $module_meta->get_all_attributes ) {
            my $attr = $_->clone( required => 0 );
            $module_meta->add_attribute($attr);
        }
    }

    Class::MOP::Class->create(
        $package,
        'methods'      => \%dispatch,
        'superclasses' => [$module]
    )->new_object();
}

=pod

=item when( ... )

The idiom is ->when( $mock_object->a_call( ... )->then( ... ).  Some house keeping is done within when.  It is possible to write:

	$pocket->when(); 
	$mock->a_call( ... );
	$pocket->then( ... ); 

It is awkward.  Don't do that.

=cut

sub when {
    my $self = shift;
    if ( $self->{'_last_mock_call'}{'complete'} ) {
        $self->_push_expected_call( $self->{'_last_mock_call'} );
    }
    if ( $self->{'go'} and $self->{'_last_mock_call'}{'execute'} ) {
        carp(
"when called after an executable mock result occured. set ->{'go'} = 1 after all mocks are setup"
        );
    }
    return $self;
}

=pod

=item then( ... )

then takes 0 or many parameters, the result of the subroutine call should the mock get called for a method and the right parameters.  Then is the right side of the bookshelf holding up the mock.  No when without a then and vice versa.  

then will record one instance of the combination of method and parameters returning the values requested.  To illustrate:

	$pocket->when( $db_mock->is_married("bob") )->then(2);
	$pocket->when( $db_mock->is_married("alice") )->then(3);
	$pocket->when( $db_mock->is_married("bob") )->then(1);

	print $db_mock->is_married("alice");
	print $db_mock->is_married("bob");
	print $db_mock->is_married("bob");

will print 321. I've told my mock to return 2 and then 1 for my two consecutive calls with parameter bob.  Alice, she's alone in her call expectations, until she gets married.  

Note well, within the default matcher, Test::Pockito::DefaultMatcher, there are ways to match anything that's defined instead of specific values, or any array reference and so on.  See that documentation for details.

=cut

sub then {
    my $self   = shift;
    my @result = @_;

    $self->{'_last_mock_call'}{'result'} = \@result;
    $self->_push_expected_call( $self->{'_last_mock_call'} );

    delete $self->{'_last_mock_call'};
}

=pod

=item execute( ... )

Execute takes 1 parameter, a reference to a sub to execute on call.  Similar to then, but useful when state comes into play.  Examples of use would be returning a random number or throwing an exception.

=cut

sub execute {
    my $self = shift;
    my $sub  = shift;

    $self->{'_last_mock_call'}{'result'}  = [$sub];
    $self->{'_last_mock_call'}{'execute'} = 1;
    $self->_push_expected_call( $self->{'_last_mock_call'} );

    delete $self->{'_last_mock_call'};
}

=pod

=item default( ... )

default acts exacty like then except it if a mock using ->then doesn't match, check for a default.  Defaults are not reported if they are not used.

=cut

sub default {
    my $self      = shift;
    my $mock_call = $self->{'_last_mock_call'};
    my @result    = @_;

    my $package = $$mock_call{'package'};
    my $method  = $$mock_call{'method'};
    my $params  = $$mock_call{'params'};

    unshift(
        @{ $self->{'_defaultcalls'}{$package}{$method} },
        { 'params' => $params, 'result' => \@result }
    );
}

=item report_expected_calls( [\*HANDLE] )

Prints out in a pretty format, all packages, calls and parameters that were unused. to STDOUT or the glob passed in.

=cut

sub report_expected_calls {
    my $self = shift;
    my $handle = shift || \*STDOUT;

    my $last_package = "";
    foreach my $package ( keys %{ $self->{'_calls'} } ) {
        foreach my $call ( keys %{ $self->{'_calls'}{$package} } ) {
            my @calls = $self->{'_calls'}{$package}{$call};
            foreach my $x ( 0 .. $#calls ) {
                foreach my $y ( 0 .. $#{ $calls[$x] } ) {
                    if ( $last_package ne $package ) {
                        print $handle "${package}::\n";
                        $last_package = $package;
                    }
                    print $handle "\t$call(";
                    my @values = @{ $calls[$x][$y]->{'params'} };
                    @values = map { $_ =~ s/"/\" /g; $_ } @values;
                    print $handle join ",", @values;
                    print $handle ");\n";
                }
            }
        }
    }
}

=item expected_calls

Returns a complicated data structure if you really wish to know the outstanding history

	{ 
	  $package =>
	    $method => 
	      [
		{
		  'params' => [ $p1, $p2, ... $pn ],
		  'result' => [ $r1, $r2, ... $rn ] 
		}
	      ]   
	}

For: 

	Foo::bar( 1, 2, 3 ) = ( 4, 5, 6 )

	my ( $one, $two, $three ) = { 'Foo' }{ 'bar' }[0]->{'params'};
	my ( $four, $five, $six ) = { 'Foo' }{ 'bar' }[0]->{'result'};


=cut

sub expected_calls {
    my $self = shift;

    foreach my $package ( keys %{ $self->{'_calls'} } ) {
        foreach my $method ( keys %{ $self->{'_calls'}{$package} } ) {
            delete $self->{'_calls'}{$package}{$method}
              if ( $#{ $self->{'_calls'}{$package}{$method} } == -1 );
        }
    }

    foreach my $package ( keys %{ $self->{'_calls'} } ) {
        delete $self->{'_calls'}{$package}
          if ( !scalar keys %{ $self->{'_calls'}{$package} } );
    }
    return $self->{'_calls'};
}


=back


=head1 SUPPORT

exussum@gmail.com

=head1 AUTHOR

Spencer Portee
CPAN ID: EXUSSUM
exussum@gmail.com

=head1 SOURCE

http://bitbucket.org/exussum/pockito/

=head1 COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
