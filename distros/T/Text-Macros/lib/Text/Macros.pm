
=head1 NAME

Text::Macros.pm - an object-oriented text macro engine

=head1 SYNOPSIS

use Text::Macros;

 # poetic:
 my $macro_expander = new Text::Macros qw( {{ }} );
 $text = expand_macros $macro_expander $data_object, $text;

 # noisy:
 $macro_expander = Text::Macros->new( "\Q[[", "\Q]]", 1 );
 print $macro_expander->expand_macros( $data_object, $text );

=cut


package Text::Macros;

use strict;

use vars qw( $VERSION );
$VERSION = '0.04';

=head1 DESCRIPTION

Typical usage might look like this:

=over 4

 my $template = <<EOF;
   To: [[ RecipientEmail ]]
   From: [[ SenderEmail ]]
   Subject: Payment Past Due on Account # [[ AccountNum ]]

   Dear [[ RecipientName ]]:
   Your payment of [[ PaymentAmount ]] is [[ DaysPastDue ]] days past due.
 EOF

 # get a data object from somewhere, e.g.:
 my $data_object = $database->get_record_object( 'acctnum' => $account_num );

 # make a macro expander:
 my $macro_expander = Text::Macros->new( "\Q[[", "\Q]]" );

 # expand the macros in the template:
 my $email_text = $macro_expander->expand_macros( $data_object, $template );

=back

To support this, a "data object" would need to exist which would need to
define methods which will be used as macro names, e.g. like this:

=over 4

 package RecordObject;
 sub RecipientEmail { $_[0]->{'RecipientEmail'} }
 sub SenderEmail    { $_[0]->{'SenderEmail'}    }
 sub AccountNum     { $_[0]->{'AccountNum'}     }
 sub RecipientName  { $_[0]->{'RecipientName'}  }
 sub PaymentAmount  { $_[0]->{'PaymentAmount'}  }
 sub DaysPastDue    { $_[0]->{'DaysPastDue'}    }

=back

Alternatively, the data object class might have AUTOLOAD defined, for example
like this:

=over 4

 package RecordObject;
 sub AUTOLOAD {
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*:://;
  $self->{$name}
 }

=back

If this is the case, then the macro expander should be instructed not to
assert that the macro names encountered are valid for the object -- since
CAN might fail, even though the calls will be handled by AUTOLOAD.
To do this, pass a true value for the third value to the constructor:

=over 4

 my $macro_expander = Text::Macros->new( "\Q[[", "\Q]]", 1 );

=back


Macros can take arguments.  Any strings which occur inside the macro text
after the macro name will be passed as arguments to the macro method call.
By default, the macro name and any arguments are all separated by newlines.
You can override this behavior; see the documentation of parse_args, below.

Example:

=over 4

 $macro_expander = new Macros qw( {{ }} );

 print $macro_expander->expand_macros( $cgi_query, 
   "You entered {{ param
    Name }} as your name."
 );

=back

This will replace the substring 

 {{ param
 Name }}

with the result of calling

=over 4

 $cgi_query->param("Name")

=back

(Obviously this example is a little contrived.)


=head1 METHODS

=head2 The Constructor

=over 4

 Text::Macros->new( $open_delim, $close_delim, $no_CAN_check, $parse_args_cr );

=back

The delimiters are regular expressions; this gives you the greatest power in
determining how macros are to be detected in the text.
But it means that if you simply want them to be considered literal strings,
then you must quotemeta them.

Since the macro expander will be calling object methods, you have an option:
do you want any encountered macro names to be required to be valid for the
given object?  Or do you have some kind of autoloading in effect, which will
handle undefined methods? 

If you have some kind of autoloading, pass a true value for the third
argument to new().  If you want the expander to assert CAN for each method,
pass false (the default).

The fourth argument, $parse_args_cr, is a reference to a sub which implements
your macro argument parsing policy.  See the section on parse_args, below.

=cut

sub new {
  my $pkg = shift;
  bless {
    open_delim => shift,
    close_delim => shift,
    no_CAN_check => shift,
    parse_args_cr => shift, # code ref 
  }, $pkg;
}


=head2 The Main Method: Expand Macros

=over 4

 $text = $macro_expander->expand_macros( $data_object, $text );

=back

The $data_object argument is not an object of the Macros package.
Rather, this is the object upon which the macro will be called as a method. 

expand_macros() returns the result of replacing all the macros it finds
with their appropriate expansions.  Note that recursion can occur; that is,
if the expansion of a macro results in text which also contains a valid
macro, that new macro will also be expanded.  The text will be scanned
for macros, and those macros will be expanded, until none are found.

=cut

sub expand_macros {
    my $self = shift;
    my $object = shift;
    local $_ = shift; # the string to expand macros in.

    my $open_delim = $self->{'open_delim'};
    my $close_delim = $self->{'close_delim'};

    while (
        s(($open_delim)(.*?)($close_delim)) {
            local $Text::Macros::open = $1;
            local $Text::Macros::close = $3;
            $self->call_macro( $object, $self->_call_parse_args( $2 ) )
        }se
    ) { } # all the work is done in the predicate.

    $_;
}



=head2 A Utility Method: Call Macro

=over 4

 $macro_expander->call_macro( $data_object, $macro_name, @arguments );

=back

This is used internally by expand_macros(), but you can call it directly if you wish.

Essentially all this does is this:

=over 4

 $macro_expander->call_macro( $data_object, $macro_name, @arguments );

=back

results in the call:

=over 4

 $data_object->$macro_name( @arguments );

=back

All the macros supported by the data object can be predefined,
or you might have some kind of autoloading mechanism in place for it.
If you have autoloading in effect, you should have passed a true value as
the third argument to new().  If you pass false (the default), 
the call_macro() will check to see that the object CAN do the method;
and if it can't an exception will be thrown.

Note: data objects' macro methods must return a string.
They can take any number of arguments, which will all be strings.

=cut

sub call_macro {
    my $self = shift;
    my $object = shift;
    defined $_[-1] && $_[-1] eq '' and pop @_; # drop last item if empty.
    my $func = shift;
    $func =~ s/^\s+//;
    $func =~ s/\s+$//;
    $self->{'no_CAN_check'} or $object->can( $func ) or die "Can't $func!";
    $object->$func( @_ ) 
}


=head2 Parsing the Macro Arguments: parse_args

This is used internally by expand_macros().

expand_macros tries to call the sub which was passed by reference as the
fourth argument to new(), if there was one.  If no such coderef was given
to the constructor, then expand_macros calls the parse_args method in the 
Text::Macros class, which implements the default behavior of splitting
the arg text on newlines, triming off leading/trailing whitespace, and
then dropping any list elements which are '' (empty strings).

To implement some behavior other than the default, you may derive a class
from Text::Macros which overrides parse_args.  The parse_args method
takes the Text::Macros object reference as the first arg (as usual), and
the macro text as the second argument.  This is all the text between the
delimiters, as it occurs in the template text.  This method is responsible
for extracting the macro name and the values of any arguments from the
macro text.  It is advisable that the parse_args routine strip any leading
and trailing whitespace from the argument values.  (It happens automatically
for the macro name, though, so you needn't worry about that.)

Example:

=over 4

 package MyMacroParser;
 @ISA = qw( Text::Macros );
 sub parse_args {
    my( $self, $macro_text ) = @_;
    # return a list of args extracted from $macro_text...
 }

=back

And then, of course, you would instantiate a MyMacroParser rather than a
Text::Macros.  Everything else about its usage would be identical.

If you prefer, you can redefine the Text::Macros::parse_args sub directly. 
That might look something like this:

=over 4

 *Text::Macros::parse_args = sub {
    my( $self, $macro_text ) = @_;
    # return a list of args extracted from $macro_text...
 };

=back

Alternatively, you may pass a code reference as the fourth argument to new().
The arguments to and results from this sub are the same as for the parse_args
method, as described above, even though it is not (necessarily) a method itself.

The precedence is this: if a sub was passed to new(), that is called;
if not, the parse_args() of the derived class is called, if defined;
if not, the parse_args() of the base class (Text::Macros) is called.

=cut

# PRIVATE: DO NOT OVERRIDE!
sub _call_parse_args {
    my( $self, $macro_text ) = @_;
    if ( defined $self->{'parse_args_cr'} ) {
        ref($self->{'parse_args_cr'}) =~ /CODE/
          or die "parse_args_cr is not a code ref!";
        return( $self->{'parse_args_cr'}->( $self, $macro_text ) );
    }
    return( $self->parse_args( $macro_text ) );
}

#
# default behavior; this can be overridden in a derived class.
# the parse_args() method -- in the base class and in any derived class --
# is ALWAYS superceded by a sub passed as the fourth argument to new().
#
sub parse_args {
    my( $self, $macro_text ) = @_;
    return(
        grep  { length }
        map   { s/^\s+//; s/\s+$//; $_ }
        split /\n/, $macro_text
    );
}

=head1 EXAMPLES

Brief examples of all these usage techniques can be found in the test script,
test.pl, which accompanies this distribution.  Any questions can be directed
to the author via email.

=cut


1;

__END__

=head1 AUTHOR

jdporter@min.net (John Porter)

=head1 COPYRIGHT

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

