package Throwable::Factory::Try;

use 5.10.0;
use strict;
use warnings FATAL => 'all';

use base qw(Exporter);
use Scalar::Util qw(blessed);

use Sub::Import 'Try::Tiny' => (
    catch       => { -as => '_catch' },
    try         => undef,
    finally     => undef,
);

=head1 NAME

Throwable::Factory::Try - exception handling for Throwable::Factory

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module provides a try/catch/finally mechanism to be used with C<Throwable::Factory>, based off C<Try::Tiny::ByClass> and C<Dispatch::Class>.
The goal is to provide a simple but powerful exception framework.

    use Throwable::Factory
        FooBarException => ['-notimplemented'],
        FooException => ['-notimplemented'],
    ;
    use Throwable::Factory::Try;

    try {
        FooBarException->throw('it happened again')
    }
    catch [
        'LWP::UserAgent' => sub { print 'Why are you throwing that at me' },
        ['LWP::UserAgent', 'HTTP::Tiny'] => sub { print 'Why are you throwing those at me' },
        'FooBarException' => sub { print shift },
        qr/^Foo/ => sub { FooException->throw },
        ['FooBarException','FooException'] => sub { print "One of these two" },
        '-notimplemented' => sub { print 'One of these' },
        [':str', qr/^Foo/] => sub { print 'String starting with Foo: ' . shift },
        ':str' => sub { print 'Just a string: ' . shift },
        '*' => sub { print 'default case' },
    ],
    finally {
        do_it_anyway()
    };
    

=head1 FUNCTIONS

=head2 catch

Replacement for L<C<catch>|Try::Tiny/catch->. It has to be right after the L<C<try>|Try::Tiny/try-> code block, and can handle the L<C<finally>|Try::Tiny/finally-> statement as an argument.
It takes an array reference of C<< CONDITION => CODE BLOCK >>, which will be treated in the same order it was passed to C<catch>. C<CONDITION> can be one of the following:

=over

=item *

C<< '<class>' >> - matches objects which L<C<DOES>|UNIVERSAL/obj-DOES-ROLE-> or L<C<isa>|UNIVERSAL/obj-isa-TYPE-> C<< <class> >>

    try {
        My::Exception::Class->throw('my own exception')
    }
    catch [
        'My::Exception::Class' => sub { print 'Here it is' }
    ];

=item *

C<< ['<class>'] >> - matches objects whose classname is in the array

    try {
        My::Exception::Class->throw('my own exception')
    }
    catch [
        ['My::Exception::Class', 'My::Exception::SecondClass'] => sub { print 'Here it is' }
    ];

=item *

C<< '<TYPE>' >> - matches Throwable::Factory objects based on their TYPE

    use Throwable::Factory
        FooBarException => undef,
    ;
    
    try {
        FooBarException->throw('I failed')
    }
    catch [
        'FooBarException' => sub { print 'Here it is' }
    ];

=item *

C<< ['<TYPE>'] >> - same as above, but with multiple choice.

    use Throwable::Factory
        FooBarException => undef,
    ;
    
    try {
        FooBarException->throw('I failed')
    }
    catch [
        ['FooBarException', 'FooException'] => sub { print 'Here it is' }
    ];
    
=item *

C<Regexp> - matches Throwable::Factory objects whose TYPE matches the pattern

    use Throwable::Factory
        ConnectionClosedException => undef,
        ConnectionFailedException => undef,
    ;
    
    try {
        ConnectionClosedException->throw('Damn')
    }
    catch [
        qr/^Connection/ => sub { print 'Here it is' }
    ];

=item *

C<< '<TAXONOMY>' >> - matches Throwable::Factory objects based of their L<C<taxonomy>|Throwable::Factory/Exception-Taxonomy->

    use Throwable::Factory
        BadArgumentException => ['-caller'],
    ;
    
    try {
        BadArgumentException->throw('try again')
    }
    catch [
        '-caller' => sub { print 'Here it is' }
    ];

=item *

C<':str'> - matches all strings

    try {
        die 'oops'
    }
    catch [
        ':str' => sub { print 'Here it is: ' . shift }
    ];

C<< [':str', <Regexp>] >> - matches strings with a Regexp

    try {
        die 'oops'
    }
    catch [
        [':str', qr/^oops/ ] => sub { print 'Here it is: ' . shift }
    ];

=item *

C<'*'> - matches everything. Use this as a 'catch all' case.

=back

=cut

our @EXPORT = qw(try catch finally);
our @EXPORT_OK = @EXPORT;


sub catch ($@) {
    my $handlers = shift;
    my $dispatch = _dispatch(
        @$handlers,
        '*' => sub { die shift }
    );

    &_catch($dispatch, @_);
}

=head1 INTERNAL METHODS

=head2 _class_case

Method based on L<C<class_name>|Dispatch::Class/class_name->, but with cases specific to Throwable::Factory, i.e. taxonomy cases and exception type.

=cut

sub _class_case
{
    my @prototable = @_;

    return sub {
        my ($x) = @_;

        my $blessed = blessed $x;
        my $ref = ref $x;
        my $scope = 'obj';

        my @table = @prototable;
        while (my ($key, $value) = splice @table, 0, 2)
        {
            # everything undefined
            unless(defined $key)
            {
                return $value
                    unless defined $x
            }
            
            # key is a wildcard
            return $value
                if $key eq '*';
            
            # prepare array cases
            if(ref $key eq 'ARRAY' && ~~@$key)
            {
                # regexp to match against string
                if(~~@$key >= 2 && $key->[0] eq ':str' && ref $key->[1] eq 'Regexp')
                {
                    $scope = 'str';
                    $key = $key->[1];
                }
                # list of class/types
                elsif(! grep {ref $_} @$key )
                {
                    my $re = join('|', map { quotemeta($_) } @$key);
                    $key = qr/^($re)$/;
                    $scope = 'obj';
                }
            }

            # key is a regexp and value's ref matches key
            if(ref $key eq 'Regexp')
            {
                return $value
                    if $scope eq 'obj' && $ref && $ref =~ $key;

                return $value
                    if $scope eq 'str' && !$ref && $x =~ $key;
            }

            # value is a string
            if($key eq ':str')
            {
                return $value
                    unless $ref
            }

            # value's ref is equal to the key
            return $value
                if $key eq $ref;

            # value DOES key
            # + taxonomy cases
            if($blessed)
            {
                my $DOES = $x->can('DOES') || 'isa';
                
                return $value
                    if  $key eq '-caller' &&
                        $x->$DOES('Throwable::Taxonomy::Caller');

                return $value
                    if  $key eq '-environment' &&
                        $x->$DOES('Throwable::Taxonomy::Environment');
                
                return $value
                    if  $key eq '-notimplemented' &&
                        $x->$DOES('Throwable::Taxonomy::NotImplemented');
                
                return $value if
                    $x->$DOES($key);
            }

            # value can do TYPE and value's TYPE is key
            if($blessed && $x->can('TYPE'))
            {
                if(ref $key eq 'Regexp')
                {
                    return $value
                        if $scope ne 'str' && $x->TYPE =~ $key;
                }

                return $value
                    if $x->TYPE eq $key;
            }
        }
    }
}

=head2 _dispatch

Method based on L<C<dispatch>|Dispatch::Class/dispatch->.

=cut

sub _dispatch
{
    my $analyze = _class_case(@_);

    return sub {
        my $e = shift;
        my $handler = $analyze->($e);
        $handler->($e);
    }
}

=head1 AUTHOR

Lucien Coffe, C<< <lcoffe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-throwable-factory-try at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Throwable-Factory-Try>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Throwable::Factory::Try


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Throwable-Factory-Try>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Throwable-Factory-Try>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Throwable-Factory-Try>

=item * Search CPAN

L<http://search.cpan.org/dist/Throwable-Factory-Try/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Lucien Coffe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

0xC0FFE
