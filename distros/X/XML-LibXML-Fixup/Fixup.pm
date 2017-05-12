package XML::LibXML::Fixup;
use strict;
use warnings;
use Carp;
use XML::LibXML;
use vars qw ( $VERSION @ISA );

$VERSION = '0.03';
@ISA = qw ( XML::LibXML );


#################################################################
# CONSTRUCTOR - calls parent constructor                        #
#################################################################
sub new
{
    my $self = XML::LibXML::new(@_);
    $self->{_throw_ex} = 1;
    $self->{_errors} = [];
    $self->{_error_cursor} = 0;
    $self->{_is_valid} = 0;
    $self->{_fixup} = [];
    $self->{_fixup_description} = [];
    $self->{_fixups_applied} = [];
    $self->{_fixup_cursor} = 0;
    return $self;
}

#################################################################
# VALIDATION AND FIXUPS                                         #
#################################################################
sub valid
{
    return $_[0]->{_is_valid};
}

sub fixed_up
{
    my $self = shift;
    if (wantarray){
	return @{$self->{_fixup_description}}[@{$self->{_fixups_applied}}];
    } else {
	return $#{$self->{_fixups_applied}} + 1;
    }
}
    

sub add_fixup
{
    my ($self, $fixup, $desc) = @_;
    my $filter;
    if (ref($fixup) eq 'CODE'){
	$filter = $fixup;
    } else {
	eval('$filter = sub { my $xml = shift;'."\n".
	     '$xml =~ '.$fixup.";\n".
	     'return $xml;'."\n}")
	    || croak("not a regex or subroutine reference");
    }
    push @{$self->{_fixup}}, $filter;
    push @{$self->{_fixup_description}}, $desc;
}

sub clear_fixups
{
    my $self = $_[0];
    $self->{_fixup} = [];
    $self->{_fixup_description} = [];
    $self->{_fixups_applied} = [];
    $self->{_fixup_cursor} = 0;
}

sub _do_fixup
{
    my ($self,$xml) = @_;
    my $fixup = $self->{_fixup}->[$self->{_fixup_cursor}];
    my $fixed_xml = $fixup->($xml);
    if ($fixed_xml ne $xml)
    {
	push @{$self->{_fixups_applied}}, $self->{_fixup_cursor};
    }
    $self->{_fixup_cursor}++;
    return $fixed_xml;
}

#################################################################
# PARSING - overridden methods of XML::LibXML                   #
#################################################################
sub parse_string
{
    my ($self, $string) = @_;
    $self->_clear_status();
    
    my $doc;

    # first attempt sans fixups
    $doc = $self->_safe_parse_string($string);

    # apply fixups one-by-one
    while(
	  (!$self->valid()) && 
	  ($self->{_fixup_cursor} <= $#{$self->{_fixup}})
	  )
    {
	$string = $self->_do_fixup($string);
	$doc = $self->_safe_parse_string($string);
    }
    
    if($self->throw_exceptions() && !$self->valid()){
	croak($self->get_last_error());
    }
    return $doc;
}

sub _safe_parse_string
{
    my ($self, $string) = @_;
    my $doc;
    eval {$doc = $self->SUPER::parse_string($string)};
    if ( $@ ) {
	$self->_add_error( $@ );
    } else {
	$self->{_is_valid} = 1;
    }
    return $doc;
}

sub parse_file
{
    die("not yet implimented");
}

sub parse_fh
{
    die("not yet implemented");
}

#################################################################
# ERROR HANDLING                                                #
#################################################################
sub throw_exceptions
{
    my ($self, $bool) = @_;
    if (defined $bool){
	$self->{_throw_ex} = $bool;
    }
    return $self->{_throw_ex};
}


sub get_errors
{
    return @{$_[0]->{_errors}};
}

sub _add_error
{
    my ($self, @err) = @_;
    push @{$self->{_errors}}, @err;
}

sub first_error
{
    my $self = shift;
    $self->{_error_cursor} = 0;
}

sub next_error
{
    my $self = shift;
    my $last_error_index = $#{$self->{_errors}};
    my $err;
    if ($self->{_error_cursor} <= $last_error_index)
    {
	$err = $self->{_errors}->[$self->{_error_cursor}];
	$self->{_error_cursor}++;
    }
    return $err;
}

sub _clear_status
{
    my $self = shift;
    $self->{_errors} = [];
    $self->{_is_valid} = 0;
    $self->{_fixups_applied} = [];
    $self->{_fixup_cursor} = 0;
    $self->first_error();
}

# slightly happier about this, rather than global variable
# used in XML::LibXML
sub get_last_error
{
    my $self = shift;
    my $last_error_index = $#{$self->{_errors}};
    my $err;
    if ($last_error_index >= 0){
	$err = $self->{_errors}->[$last_error_index];
    }
    return $err;
}

1;

__END__

=head1 NAME

XML::LibXML::Fixup - apply regexes to XML to fix validation and parsing errors

=head1 SYNOPSIS

  use XML::LibXML::Fixup;

=head1 DESCRIPTION

This module provides an interface to an XML parser to parse and validate XML files. 
The module allows fixups to be applied to non-parsing and non-validating XML. For 
full documentation, see the POD documentation for XML::LibXML. The documentation in
this module does not cover the methods inherited from XML::LibXML.

=head1 CONSTRUCTOR

Create an instance of this class by calling the new() method.

  use XML::LibXML::Fixup;
  my $v = XML::LibXML::Fixup->new();

=head1 METHODS

=head2 Validity checks

The documentation for XML::LibXML recommends eval'ing a parse statement and checking $@ 
to detect parse errors. With this module, it is recommended that parsability and validity
are checked using the $v-E<gt>valid() method.

=over 4

=item $v-E<gt>valid()

Should be called after some parse method; for example $v-E<gt>parse_string().
Returns a true value for valid/parsable XML. Returns a false value for invalid or unparsable XML.

  $v->parse_string($xml);
  print "valid" if $v->valid();

=back

=head2 XML fixups

These are the methods that are used to control fixing-up of XML. The fixups are applied one-by-one,
during parsing in the order that they were added to the object, until the XML validates or 
there are no more fixups to be applied.

=over 4

=item $v-E<gt>add_fixup($fixup,$description)

Adds a new fixup. $fixup must be a substitution regular expression or subroutine reference. If $fixup
is a subroutine reference, it must act as a fliter to its first parameter, as shown in the second 
example (below). $description is a description of the substitution, which will be returned by 
$v-E<gt>fixed_up() when called in list context. The following two fixups are similar, in that they 
both substitute upper-case closing paragraph tags with the lower-case equivalents.

  $v->add_fixup('s!</P>!</p>!gs', 'upper-case close-para tags');
  $v->add_fixup(sub{
                    my $xml = shift;
                    $xml =~ s#</P>#</p>#gs;
                    return $xml;
                   }, 'upper-case close-para tags');

=item $v-E<gt>clear_fixups()

Clears the list of fixups held within a module.

=item $v-E<gt>fixed_up()

In scalar context, returns the number of fixups that were applied during parsing. In list 
context, returns a list of description of the fixups that were applied during parsing. A fixup 
is deemed to have been applied if the search regex (first parameter to $v-E<gt>add_fixup() matches the XML).

Note that this doesn't indicate whether the XML was valid after fixing up. Use in conjunction 
with $v-E<gt>valid() to check whether fixups were necessary to parse the XML.

  $v->add_fixup('s#</P>#</p>#gs', 'upper-case close-para tags');
  $v->add_fixup('s#</?foobar/?>##gis', 'remove <FoObAr> tags');
  $v->parse_string($xml);
  if ($v->valid()){
    if ($v->fixed_up()){
      print "validated with some fixups: ";
      print $v->fixed_up(); # descriptions
      print "parsing errors without fixups were: ";
      print $v->get_errors();
    } else {
      print "validated without need for fixups";
  }

=back

=head2 Errors

Because the parser might need to make several attempts at parsing the XML before success, 
multiple parsing errors could occur. These are stored in an array and accessed using the 
utility methods listed below. Note that get_last_error() inherited from XML::LibXML can also 
be used to retrieve the most recent error.

=over 4

=item $v-E<gt>throw_exceptions(0)

Turns off (or on) the throwing of exceptions. Defaults to on. When exceptions are thrown, 
the parser will die (through croak()) when XML cannot be parsed or validated (only after all
fixups have been applied and parsing still fails). Such an exception can be trapped in an 
eval() block. This is similar to the default behaviour of XML::LibXML. 
When exceptions are being suppressed, the parser will not call die() after failing to parse invalid
XML. The validity of XML must, therefore, be checked using $v-E<gt>valid().

When called with no arguments, returns a true value if exceptions will be thrown, or a false value
if they will be suppressed.

=item $v-E<gt>get_errors()

Returns a list of errors produced during parsing and validation.

=item $v-E<gt>next_error()

Returns the next error, or undef if there are no more errors. Useful function 
when used as an iterator:

  while(my $error = $v->next_error()){
    # do something with $error
  }

=item $v-E<gt>first_error()

Resets position of next error to be retrieved by next_error().

=back

=head1 NOTES

The only XML::LibXML parsing function currently supported is $v->parse_string($xml).

=head1 SEE ALSO

L<XML::LibXML> - used by this module to validate XML.

=head1 AUTHOR

Nigel Wetters, E<lt>nwetters@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Rivals Digital Media Ltd. Use and distribution allowed under the same terms as Perl.

=cut
