NAME
    Pockito - Inspired by Mockito, a library to build mock objects for test
    driven development

SYNOPSIS
    Pockito allows for very matter of fact mock definitions and uses.

    1. when A happens, produce B
    2. if it's impossible for A to happen, complain
    3. make every A produce B, or have it return different values
    4. after using my mock objects, let me know if my expectations were met

    With the advent of Class::MOP, new methods for package creation exists.
    The almighty Moose is made possible by it. Pockito is intended to fit
    most ways of class creation.

DESCRIPTION
    A mock object is a thing that imitates something else that may be hard
    to setup or can be brittle. Examples of such are databases, network
    connections, and things deemed non trivial that may involve state.

    The following is an overly complicated class that marries two people
    together, that takes two user ids and inserts that user1 is married to
    user2, and vice versa. We should probably check to make sure they exist
    to make sure they aren't married already.

    Our database object we wish to mock out may provide methods like,
    is_married( $user ), and marry($user1, $user2);

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

    The $pocket object holds logs of interactions between objects you mock
    through it. This offers the convenience of validating through one
    object, but if you wish to have two completely different mocks, one can
    create different Pockito objects. The namespace passed along is a prefix
    to all packages created for the mock to avoid collisions. In this case,
    a MyNamespace::Love package is created.

    The ->mock call is just like ->new except the package name is passed. It
    will inspect the package for all subs, and in the case of Moose,
    attributes to mimic.

    $pocket->when( .... )->then( ... ) records many things. It records in
    the ->is_married sub is called, with a parameter "bob". When this
    combination occurs the first time, return 0. One can queue up multiple
    calls with the same signature to have multiple results.

    $pocket->{'warn'} tells Pockito to complain about calls that it doesn't
    expect.

    Finally, a hash of calls that have yet to be executed are returned via
    expected_calls. Since we called everything we expected, we can
    celebrate. If is_married returned a random number, we could inspect the
    result of expected_calls and make a judgement call if the expectations
    were met.

    There are some conveniences written in for default calls, partial mocks,
    outputting a formated report of what method calls have yet to be called,
    custom equality comparisons for parameters and bridges for package
    creation.

ATTRIBUTES
    warn
        Setting the hash key of warn to 1 will cause a mock call that wasn't
        scheduled, but called, to be carped.

    go  Pockito can keep track of state pretty well, except when ->execute
        is called for the same parameters more than once. Perl evaluates
        lazily, so

           $pocket->when( $mock->a(1) )->execute( sub{ ... } );
           $pocket->when( $mock->a(1) )->execute( sub{ ... } );

        will cause the anonymous sub to be called twice. If this occurs a
        warning will be produced. Toggle go to 0 before scheduling calls,
        and back to 1 when the test starts to use mocks to quiet it.

METHODS
    new(package [, matcher])
        Instanciate Pockito. package is a prefix name for the namespace for
        your mocks. It would be rude to assume every nacemspace will be
        valid. You do that work. matcher is a reference to a sub to check
        for equality of a mocked call. See
        Test::Pockito::DefaultMatcher::default_call_match for more
        information on how to implement this subroutine.

    mock(module, [excluded1, excluded2, ..., excluded-n])
        module is the name of the package to inspect and construct a mock
        from. The result is an objet that looks just like the object you
        would normally use. In the case of IO::Socket::connect, a connect
        method would be constructed. In the case of Moose, attributes and
        methods are mocked out, right down to meta.

        The second parameter is a list of methods not to mock. This is
        useful for partial mocks for those heavily coupled methods. Example
        uses are for data that is harder to setup, but easier to call a
        helping method.

    when( ... )
        The idiom is ->when( $mock_object->a_call( ... )->then( ... ). Some
        house keeping is done within when. It is possible to write:

                $pocket->when(); 
                $mock->a_call( ... );
                $pocket->then( ... );

        It is awkward. Don't do that.

    then( ... )
        then takes 0 or many parameters, the result of the subroutine call
        should the mock get called for a method and the right parameters.
        Then is the right side of the bookshelf holding up the mock. No when
        without a then and vice versa.

        then will record one instance of the combination of method and
        parameters returning the values requested. To illustrate:

                $pocket->when( $db_mock->is_married("bob") )->then(2);
                $pocket->when( $db_mock->is_married("alice") )->then(3);
                $pocket->when( $db_mock->is_married("bob") )->then(1);

                print $db_mock->is_married("alice");
                print $db_mock->is_married("bob");
                print $db_mock->is_married("bob");

        will print 321. I've told my mock to return 2 and then 1 for my two
        consecutive calls with parameter bob. Alice, she's alone in her call
        expectations, until she gets married.

    execute( ... )
        Execute takes 1 parameter, a reference to a sub to execute on call.
        Similar to then, but useful when state comes into play. Examples of
        use would be returning a random number or throwing an exception.

    default( ... )
        default acts exacty like then except it if a mock using ->then
        doesn't match, check for a default. Defaults are not reported if
        they are not used.

    report_expected_calls( [\*HANDLE] )
        Prints out in a pretty format, all packages, calls and parameters
        that were unused. to STDOUT or the glob passed in.

    expected_calls
        Returns a complicated data structure if you really wish to know the
        outstanding history

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

SUPPORT
    exussum@gmail.com

AUTHOR
    Spencer Portee CPAN ID: EXUSSUM exussum@gmail.com

SOURCE
    http://bitbucket.org/exussum/pockito/

COPYRIGHT
    This program is free software licensed under the...

        The BSD License

    The full text of the license can be found in the LICENSE file included
    with this module.

SEE ALSO
    perl(1).

