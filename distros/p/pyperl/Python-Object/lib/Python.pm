package Python;

require Python::Object;

use vars qw($VERSION);
$VERSION = $Python::Object::VERSION;

1;

__END__

=head1 NAME

Python - Encapuslate python objects

=head1 SYNOPSIS

    use Python qw(getattr list);

    # constructors
    $list = list(1..10);

    # accessor
    if (my $foo = getattr($o, "foo")) {
        # ...
    }

=head1 DESCRIPTION

C<Python> is an interpreted, interactive, object-oriented programming
language programming language created by Guido van Rossum
(www.python.org).  This manpage describe the perl interface to python
data managed by an embedded Python interpreter.

The C<Python::> namespace contain various functions to construct,
modify and examine python objects.  Python objects themselves are
wrapped up in instances of the perl class C<Python::Object>.

=head2 Constructors

The following object constructor functions are provided.  They all
return C<Python::Object> instances.  Usually one will not have to
construct C<Python::Object>s directly since they are constructed
implicitly when python data is passed to perl either as perl function
arguments or as the return values from calls into python.

=over

=item $o = object($something);

The object() constructor will first make a python object of whatever
perl data is passed in and then return a Python::Object wrapper for
it.  A call like:

  $o = object("$something")

will make sure you produce a string object.

=item $o = int( INT )

This will make a new integer object.

=item $o = long( STRING_OF_DIGITS )

This will make a new long integer object.  Long integers can grow to
arbitrary size (bignum).

=item $o = float( NUMBER )

This will make a new float object.

=item $o = complex( NUMBER, NUMBER )

This will make a new complex object with the given I<real> and I<imag>
parts.

=item $o = list( ELEM,... )

This will make a new list object initialized with the elements passed
in as separate arguments to the constructor function.

=item $o = tuple( ELEM,... )

This will make a new tuple object initialized with the elements passed
in as separate arguments to the constructor function.

=item $o = dict( KEY => VALUE,... );

This will make a new dictionary object.  Initial items are extracted
as pairs from the argument list.

=back

=head2 Python functions

The following functions with mostly identical behaviour to the
corresponding python builtins are available.  These functions will
croak if the $o argument is not a C<Python::Object> instance.

=over

=item getattr($o, $name)

=item hasattr($o, $name)

=item setattr($o, $name => $value)

=item delattr($o, $name)

These functions provide access to the attributes of an object.

=item cmp($o1, $o2)

Compares the two objects and returns -1, 0 or 1 if $o is less, equal
or greater than $o2 respectively.

=item id($o)

Returns a number which will be different for different objects.

=item hash($o)

This return the hash value of the object.

=item len($o)

This return the length of the object.

=item type($o)

Returns the corresponsding type object.

=item str($o)

Returns a stringified representation of the object.

Overloaded as perl stringify operator.

=item repr($o)

Returns a possibly different stringified representation of the object
that tries be valid python syntax.

=item exec($string, [$globals, [$locals]);

Executes a bit of python code.  The global and local namespace to use
during execution can be passed in as dictionary objects.  If omitted
they default to the __main__ namespace.

=item eval($string, [$globals, [$locals]);

Returns the value of the expression given as first argument.  The
global and local namespace can be overridden like for exec.

=item apply($o, \@args, \%keywords)

This will invoke the object with the given arguments.  The \@args
argument can be a perl array reference, undef or some python sequence.  The
\%keywords argument can be a perl hash reference, undef or a python
directory.

=item funcall($o, @args)

This will invoke the object with the given arguments if it is
callable.  Similar to apply(), but arguments are not passed as a
single list reference argument.

=item Import( $module )

Loads the module and returns a reference to it.  Notice that this
function is spelled with a capital "i".  (The reason is that perl
already use "import" for something else.)

=item raise($type, $value)

Raise a python exception of the specific type.  References to Python's
standard exception types can be obtained from the C<Python::Err>
namespace.  E.g.:

  Python::raise(Python::Err::TypeError, "'foo' wanted here");

=back


=head2 Python API functions

The following functions that map the Python internal C API are made
available.

=over

=item PyObject_GetItem($o, $key)

=item PyObject_SetItem($o, $key, $value)

=item PyObject_DelItem($o, $key)

These methods provide access to the items of objects that implement
the sequence or the mapping interface.  These function also have
aliases named getitem(), setitem() and delitem() after the pattern
established by the corresponding {get,set,del}attr() calls.

=item PyObject_IsTrue($o)

This return a boolean value for the object.

Overloaded as boolean test operator.

=back

=head2 Type check functions

The following functions determine if the object is of the given type.
If $o is not a reference to a C<Python::Object> instance, then these
all return FALSE.

=over

=item PyCallable_Check($o)

Return TRUE if the object is callable.

=item PyNumber_Check($o);

Return TRUE if the object provide the number interface.

=item PySequence_Check($o)

Return TRUE if the object provide the sequence interface.

=item PyMapping_Check($o)

Return TRUE if the object provide the mapping interface.

=back

=head1 COPYRIGHT

(C) 2000-2001 ActiveState

This code is distributed under the same terms as Perl; you can
redistribute it and/or modify it under the terms of either the GNU
General Public License or the Artistic License.

THIS SOFTWARE IS PROVIDED BY ACTIVESTATE `AS IS'' AND ANY EXPRESSED OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL ACTIVESTATE OR ITS CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 SEE ALSO

L<python>, L<perl>, L<Python::Object>, L<Python::Err>, L<perlmodule>

