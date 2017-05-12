package Text::MessageLibrary;
$VERSION = "0.15";

=head1 NAME

Text::MessageLibrary - centrally manage lists of static and dynamic status,
                       error, or other messages, encapsulated in an object

=head1 SYNOPSIS

  # create a list of messages
    $error_messages = Text::MessageLibrary->new({
      bad_file_format  => 'File format not recognized!',
      file_open_failed => sub{"Unable to open file $_[0]: $!"},
      _default         => sub{"Unknown message " . shift() . 
                              " with params " . (join ",",@_)},
    });

  # generate messages
    print $error_messages->bad_file_format;           
    print $error_messages->file_open_failed('myfile');
    print $error_messages->no_such_message;  # falls back to _default

  # override default prefixes and suffixes
    $error_messages->set_prefix("myprogram: ");
    $error_messages->set_suffix("\n");

=head1 DESCRIPTION

=head2 Overview

With the Text::MessageLibrary class, you can create objects that dynamically
construct status, error, or other messages on behalf of your programs.
Text::MessageLibrary is intended to be useful in larger projects, where it
can be used to create centralized collections of messages that are easier to
maintain and document than string literals scattered throughout the code.

To create a Text::MessageLibrary object, you'll need to create a hash containing 
a set of keywords and a message associated with each keyword, then pass that
hash to the C<new> constructor. The keywords you choose are then exposed as 
methods of an individual Text::MessageLibrary object, so you can generate messages
with this syntax:

  $messages->message_keyword(...with params too, if you want...)

The messages themselves may be either literal strings or anonymous subroutines
that can perform arbitrarily complex operations. For instance, if you create
an C<$error_messages> object like this:

  $error_messages = Text::MessageLibrary->new({
    file_open_failed => sub{"Unable to open file $_[0]: $!\n"}
  });

You can then write this:

  open INPUT, "/no/such/file" 
    or die $error_messages->file_open_failed('myfile');

And get this result:

  Unable to open file myfile: No such file or directory

Notice that parameters to the method call are accessible to your subroutine
via C<@_>, and that the global C<$!> variable containing the error message
from the last file operation is available too.

When you're using static error messages -- i.e., where interpolation at the
moment of message generation is not required -- you can skip the anonymous
subroutine and simply provide a string literal:

  $status_messages = Text::MessageLibrary->new(
    new_record => 'loading new record',
    all_done   => 'processing complete',
  );
  ...
  print $status_messages->new_record;
  ...
  print $status_messages->all_done;

=head2 Prefixes and Suffixes

Whether you're using static or dynamic messages, there's actually one more
thing that Text::MessageLibrary objects do when constructing messages: They
add a prefix and a suffix. By default, the prefix contains the name of the
current executable (stripped of path information if you're running on a
Windows or Unix variant), and the suffix is simply a newline. So in practice
you'll normally get messages that look more like this:

  YourProgramName: Unable to open file myfile: No such file or directory\n

You can change this behavior by calling the C<set_prefix> and C<set_suffix>
methods:

  $error_messages->set_prefix("Error: ");
  $error_messages->set_suffix(".");

which would result instead in:

  Error: Unable to open file myfile: No such file or directory.

The prefix and suffix that you set apply to all messages emitted by an
individual Text::MessageLibrary object. Note that the prefix and suffix are
expected to be fixed strings, not subroutines.

(Incidentally, you can retrieve the current prefix and suffix by using the 
C<get_prefix> and C<get_suffix> methods, but I can't think of a particularly
compelling reason to actually do that.)

=head2 Defining Fallback Messages

What happens if you try to call a method for which no message was defined?
Text::MessageLibrary provides default behavior, so that:

  print $status_messages->no_such_message('nice try', 'dude');

results in:

  YourProgramName: message no_such_message(nice try,dude)\n

You can override this behavior by specifying a C<_default> key (and
associated message) in your constructor:

  $error_messages = Text::MessageLibrary->new({
    bad_file_format => 'File format not recognized!',
    _default => sub{"Unknown message '$_[0]' received"},
  });

With this C<_default> definition, the output would instead be:

  YourProgramName: Unknown message 'no_such_message' received\n

=head2 Practical Uses

If you have a fairly large, multi-module program, you may want to centralize
many of your messages in a single module somewhere. For example:

  package MyMessages;
  @ISA = qw(Exporter);
  @EXPORT = qw($error_messages $status_messages);
  use vars qw($error_messages $status_messages);
  use Text::MessageLibrary;
  use strict;
  
  {
    my $verbose = 1;

    $error_messages = Text::MessageLibrary->new(
      file_open => sub {return qq{file open failed on $_[0]: $!}},
      _default  => sub {return "unknown error $_[0] reported"},
    );

    $status_messages = Text::MessageLibrary->new(
      starting_parser    => ($verbose ? "Starting parser\n" : ""),
      starting_generator => ($verbose ? sub {"Starting generator $_[0]\n"} : ""),
    );
    $status_messages->set_prefix();
    $status_messages->set_suffix();

    1;
  }

Then your other modules can simply C<use MyMessages> and do things like:

  print $status_messages->starting_parser;
  print $status_messages->starting_generator('alpha');
  print $status_messages->starting_generator('omega');
  print $error_messages->unexpected_end_of_file;

Since all your messages are located in one module, it's a simple task to
change their wording, control their level of verbosity with a single
statement, and so on. You could also easily change the language of your
messages, though this package is not really intended as a substitute for
a dedicated module such as C<Locale::Maketext>.

Note that the methods generated are unique to each Text::MessageLibrary object,
so that given the definitions above, this statement:

  print $status_messages->file_open('my_file');

would end up calling the C<_default> message generator for the 
C<$status_messages> object. (C<file_open> was defined only in the constructor
for C<$error_messages>, so no C<file_open> method exists for
C<$status_messages>.) In effect, the method-call syntax is merely syntactic
sugar for a hypothetical method call like this:

  # there's not really a 'generate_message' method...
  print $status_messages->generate_message('file_open','my_file');

On a separate note, if you wish to subclass Text::MessageLibrary, you can override
the default (empty) C<_init> function that the constructor calls and perform
further initialization tasks there.

=head2 Performance Considerations

Not surprisingly, encapsulating your message generation within an object --
and, sometimes, an anonymous subroutine -- exacts a performance penalty. I've
found in small-scale experiments that the method call and anonymous-subroutine
execution is roughly an order of magnitude slower than using literal strings
and Perl's native interpolation. But it's still I<pretty> fast in most cases, 
and the reduced speed may be an acceptable tradeoff for improved
maintainability, particularly when it comes to things like error messages that
are (we hope!) generated only infrequently.

=head2 Potential Enhancements

There's currently no way to modify or add messages once you've constructed the
object, nor a clone/copy method, but I haven't yet found a reason to
implement either capability. And Simple Is Beautiful.

=cut


############################## CODE STARTS HERE ##############################

use vars qw($AUTOLOAD);
use strict;
use warnings;
use Carp;


=head1 PUBLIC METHODS

=over 4

=item Text::MessageLibrary->new(\%keyword_message_hash);

Construct a new Text::MessageLibrary object. The C<(key,value)> pairs in
C<%keyword_message_hash> are used to define the methods that the object will
expose and the messages that will be generated when those methods are called.
The keys should be names that would pass muster as Perl subroutine names, 
because you'll likely be calling them using the OO arrow syntax:

  $message_library->method_name;

The values (messages) may be either literal strings or blocks of code to be
interpreted each time the method is invoked. Parameters passed to the method
are accessible to the code block in C<@_> as if it were a normal subroutine.
For example:

  $status_message = Text::MessageLibrary->new(
    {general => sub{"You said: $_[0], $_[1], $_[2]."}};
  );
  print $status_message->general('zero', 'one', 'two');

results in:

  You said: zero, one, two.

The key C<_default> has a special significance: It defines a message that is
used if an unknown method is called. In this case, C<$_[0]> contains the name
of the unknown method, and the rest of C<@_> contains the parameters. The
object will provide baseline (one might say 'default') C<_default> behavior
if no such key is explicitly provided in the constructor.

=cut

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self, $class;
  $self->_init(@args);  # do the real work
  return $self;
}


=item $messages->set_prefix($new_prefix)

Set the prefix that is prepended onto any message returned by this object. By
default, the prefix contains the name of the current executable (with path
stripped out if you're running under Windows and *nix OSs).

Omitting C<$new_prefix> is equivalent to specifying a null string.

=cut

sub set_prefix {
  croak "set_prefix expects a single optional param" unless @_ <= 2;
  my ($self, $prefix) = @_;
  $prefix = '' unless defined($prefix);
  $self->{prefix} = $prefix;
  return 1;
}


=item $messages->set_suffix($new_suffix)

Set the suffix that is appended onto any message returned by this object. By
default, the suffix is a single newline.

Omitting C<$new_suffix> is equivalent to specifying a null string.

=cut

sub set_suffix {
  croak "set_suffix expects a single optional param" unless @_ <= 2;
  my ($self, $suffix) = @_;
  $suffix = '' unless defined($suffix);
  $self->{suffix} = $suffix;
  return 1;
}


=item $messages->get_prefix

Return the currently defined prefix.

=cut

sub get_prefix {
  croak "get_prefix expects no params" unless @_ == 1;
  return $_[0]->{prefix};
}


=item $messages->get_suffix

Return the currently defined suffix.

=cut

sub get_suffix {
  croak "get_suffix expects no params" unless @_ == 1;
  return $_[0]->{suffix};
}

=back

=cut

##### PRIVATE METHODS (AND VARIABLES)

##### AUTOLOAD
# The AUTOLOAD method is called whenever a Text::MessageLibrary object receives a
# method call to generate a message. It does not cache methods in the symbol
# table for future access, because methods are unique to I<individual>
# Text::MessageLibrary objects. (Remember that we're using method calls merely as
# syntactic sugar to make the calling code more readable.)

sub AUTOLOAD {

  # figure out how we were called
  
  my $self = shift;
  $AUTOLOAD =~ /.*::(\w+)/;
  my $message_name = $1;
  return if $message_name eq 'DESTROY';
  
  # look up the message for this method, or use the default message
  
  my $message_generator = $self->{messages}->{$message_name};
  if (!defined($message_generator)) {                        
    $message_generator = $self->{messages}->{_default};      
    @_ = ($message_name, @_);                                
  }

  my $prefix = $self->get_prefix();
  my $suffix = $self->get_suffix();

  # construct a dynamic message if needed, or simply return a static one

  if (ref $message_generator eq 'CODE') {
    return $prefix . (&$message_generator) . $suffix;
  } else {
    return $prefix . $message_generator . $suffix;
  }
}


##### $messages->_init(@_)
# does the actual initialization.

sub _init {
  my ($self, @params) = @_;
  
  # dereference the input hash, or provide an empty hash if none was sent
  # and set default values
  
  my %message_hash = defined $_[1] ? %{$_[1]} : ();
  my %messages = (
    _default => sub {
      return "message " . $_[0] . "(" . (join ",", @_[1..$#_]) . ")"
    },
    %message_hash
  );
  $self->{messages} = \%messages;
  
  # rule of thumb to figure out name of executable (sans path): eliminate
  # everything after the last slash (*nix) or backslash (Win)
  
  my $prefix = $0;                                      
  if ($^O eq 'MSWin32') {                               
    $0 =~ m{(\\|\A)([^\\]*)$};                          
    $prefix = $2;
  } elsif ($^O ne 'Mac' && $^O ne 'VMS' && $^O ne 'OS2') {
    $0 =~ m{(/|\A)([^/]*)$};
    $prefix = $2;
  }
  
  $self->set_prefix("$prefix: ");
  $self->set_suffix("\n");
}

##### Internal Data Structure

# A Text::MessageLibrary is a blessed hash containing the following keys:

# A reference to the hash containing message keywords and message text/code
#   that was passed into the constructor.
# prefix
#   The current prefix, set with C<set_prefix>.
# suffix
#   The current suffix, set with C<set_suffix>.

1;

=head1 REVISION HISTORY

  0.15 (2002-10-30)
       Minor documentation tweaks.

  0.14 (2002-10-29)
       Packaged for distribution on CPAN.

  0.13 (2002-10-16)
       Minor (mostly cosmetic) updates to documentation, code, and test suite.
       Converted to Artistic License.

  0.12 (2002-01-06)
       First public beta. Changed constructor to expect hash to be passed by
       reference. Split C<_init> out from C<new>.

  0.11 (2002-01-05)
       Removed method caching (which caused conflicts when instantiating
       multiple objects), rationalized code, completed POD.

  0.10 (2001-12-17)
       Initial implementation (not released).

=head1 AUTHOR

John Clyman (module-support@clyman.com)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002 John Clyman. All Rights Reserved.

This module is released under the Artistic License (see 
http://www.perl.com/language/misc/Artistic.htmlZ<>).

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
