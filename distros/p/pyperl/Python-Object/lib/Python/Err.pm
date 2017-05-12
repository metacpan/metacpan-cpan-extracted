package Python::Err;

require Python::Object;

1;


__END__

=head1 NAME

Python::Err - Python exception objects

=head1 SYNOPSIS

   # catching
   eval {
     ....
   }
   if ($@ && UNIVERSAL::iso("Python::Err")) {
       # deal with the exception
   }

   # raising
   if (... arg is not as expected ...) {
      Python:Err->Raise(Python::Err::TypeError, "a foo object expected");
   }

=head1 DESCRIPTION

Python exceptions are wrapped up in C<Python::Err> objects.  If perl
calls some python function and this function raise an exception then
$@ will end up as a reference to a C<Python::Err> object.

The following methods are available:

=over

=item $err->type

What kind of exception this is.  It should usually be a reference to
one of exception type objects described below.

=item $err->value

An assosiated value, usually just a human readable string explaining
the reason for the failure.

=item $err->traceback

The traceback object contain stack trace information from the location
where the exceptions where raised and down.

=item $err->as_string

Overloaded stringify.  Allow python exceptions to be matched using
regular expressions on $@ and to be printed.  Exceptions are
stringified as:

   "$type: $value"

=item $err->as_bool

Overloaded for boolean tests and will always return TRUE, so it is not
actually very useful :-)

=back

If perl code is known to be invoked from python code, then it might
want to raise native python exceptions.

=over

=item Python::raise($type, $value)

The raise() function will raise a python exception of the given
I<type> and pass with it the given I<value>.

=back

=head2 Standard exception type objects

References to all the standard python exception type objects can be
obtained using the following names.

=over

=item	Python::Err::Exception

The root class for all exceptions.

=item	Python::Err::StandardError

The base class for all built-in exceptions.

=item	Python::Err::ArithmeticError

The base class for all arithmentic exceptions.

=item	Python::Err::LookupError

The base class for indexing and key exceptions.

=item	Python::Err::AssertionError

Failed assert statement.

=item	Python::Err::AttributeError

Failed attribute reference or asssignment

=item	Python::Err::EOFError

End of file.

=item	Python::Err::FloatingPointError


=item	Python::Err::EnvironmentError

Base class for errors that occur outside Python.

=item	Python::Err::IOError

Failed I/O operation.

=item	Python::Err::OSError

=item	Python::Err::ImportError

=item	Python::Err::IndexError

=item	Python::Err::KeyError

=item	Python::Err::KeyboardInterrupt

=item	Python::Err::MemoryError

=item	Python::Err::NameError

=item	Python::Err::OverflowError

=item	Python::Err::RuntimeError

=item	Python::Err::NotImplementedError

=item	Python::Err::SyntaxError

=item	Python::Err::SystemError

=item	Python::Err::SystemExit

=item	Python::Err::TypeError

=item	Python::Err::UnboundLocalError

=item	Python::Err::UnicodeError

=item	Python::Err::ValueError

=item	Python::Err::ZeroDivisionError

=back

If these functions are called with a single argument then they test if
the object passed in is of the given type.  The argument can be either
a Python exception object or a Python::Err object.  The test test does
not yet consider inheritance of exceptions.


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

L<Python::Object>, L<Python>, L<perlmodule>

