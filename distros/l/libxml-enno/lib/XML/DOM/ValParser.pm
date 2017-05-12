#
# Use XML::DOM::ValParser instead of XML::DOM::Parser and it will
# use XML::Checker to validate XML at parse time.
#

package XML::DOM::ValParser;

use strict;
use XML::DOM;
use XML::Checker::Parser;

use vars qw( @ISA @SupportedHandlers );

@ISA = qw( XML::Checker::Parser );

# These XML::Parser handlers are currently supported by XML::DOM
@SupportedHandlers = qw( Init Final Char Start End Default Doctype
			 CdataStart CdataEnd XMLDecl Entity Notation Proc 
			 Default Comment Attlist Element Unparsed );

sub new
{
    my ($class, %args) = @_;
    
    my %handlers = ();
    for (@SupportedHandlers)
    {
	my $domHandler = "XML::Parser::Dom::$_";
	$handlers{$_} = \&$domHandler;
    }
    $args{Handlers} = \%handlers;
    $class->SUPER::new (%args);
}

sub parse
{
    # Do what XML::DOM::Parser normally does.
    # Temporarily override his @ISA, so that he thinks he's a
    # XML::DOM::ValParser and calls the right SUPER::parse(),
    # (otherwise he thinks he's an XML::DOM::Parser and you see runtime
    #  error: Can't call method "Init" on unblessed reference ...)
    local @XML::DOM::Parser::ISA = @ISA;
    local $XML::Checker::Parser::_skipInsignifWS = $_[0]->{SkipInsignifWS};
    XML::DOM::Parser::parse (@_);
}

1; # package return code

__END__

=head1 NAME

XML::DOM::ValParser - an XML::DOM::Parser that validates at parse time

=head1 SYNOPSIS

 use XML::DOM::ValParser;

 my %expat_options = (KeepCDATA => 1, 
		      Handlers => [ Unparsed => \&my_Unparsed_handler ]);
 my $parser = new XML::DOM::ValParser (%expat_options);

 eval {
     local $XML::Checker::FAIL = \&my_fail;
     my $doc = $parser->parsefile ("fail.xml");
     ... XML::DOM::Document was created sucessfully ...
 };
 if ($@) {
     # Either XML::Parser (expat) threw an exception or my_fail() died.
     ... your error handling code here ...
     # Note that the XML::DOM::Document is automatically disposed off and
     # will be garbage collected
 }

 # Throws an exception (with die) when an error is encountered, this
 # will stop the parsing process.
 # Don't die if a warning or info message is encountered, just print a message.
 sub my_fail {
     my $code = shift;
     die XML::Checker::error_string ($code, @_) if $code < 200;
     XML::Checker::print_error ($code, @_);
 }

=head1 DESCRIPTION

Use XML::DOM::ValParser wherever you would use L<XML::DOM::Parser> and
your XML will be checked using L<XML::Checker> at parse time.

See L<XML::DOM> for details on XML::DOM::Parser options.
See L<XML::Checker> for details on setting the fail handler (my_fail.)

The following handlers are currently supported, just like XML::DOM::Parser:
Init, Final, Char, Start, End, Default, Doctype, CdataStart, CdataEnd, 
XMLDecl, Entity, Notation, Proc, Default, Comment, Attlist, Element, Unparsed.

=head1 XML::DOM::ValParser

XML::DOM::ValParser extends from L<XML::Checker::Parser>. It creates an
L<XML::Checker> object and routes all event handlers through the checker,
before processing the events to create the XML::DOM::Document.

Just like L<XML::Checker::Parser>, the checker object can be retrieved with
the getChecker() method and can be reused later on (provided that the DOCTYPE
section of the XML::DOM::Document did not change in the mean time.)

You can control which errors are fatal (and therefore should stop creation
of the XML::DOM::Document) by filtering the appropriate error codes in
the global $XML::Checker::FAIL handler 
(see L<XML::Checker/ERROR_HANDLING>) and 
calling I<die> or I<croak> appropriately.

Just like XML::Checker::Parser, XML::DOM::ValParser supports the 
SkipExternalDTD and SkipInsignifWS options. See L<XML::Checker::Parser>
for details.

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Enno Derksen at
<F<enno@att.com>>.

=head1 SEE ALSO

L<XML::DOM>, L<XML::Checker> (L<XML::Checker/SEE_ALSO>)
