use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

#======================================================
package XML::Pastor::SimpleType;

use XML::LibXML;
use XML::Pastor::Type;

use Scalar::Util qw(reftype);
use XML::Pastor::Util  qw(getAttributeHash getChildrenHashDOM);

our @ISA = qw(XML::Pastor::Type);





#----------------------------------------------
# xml_validate_value
#----------------------------------------------
sub xml_validate_value {
	my $self 	= shift;
	my $path	= shift || '';	
	my $type	= $self->XmlSchemaType();
	my $value	= $self->__value;
	    $value	= $self->normalize_whitespace($value);

	unless (defined $type) {
		return ($self->xml_validate_further(@_) && $self->xml_validate_ancestors(@_));			
	}
	
	if (defined(my $prop = $type->length)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $len (@$prop) {
			($len == length($value)) or die "Pastor : Validate : $path : Length must be exactly '$len' for value '$value'";
		}				
	}

	if (defined(my $prop = $type->minLength)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $minLen (@$prop) {
			(length($value) >= $minLen) or die "Pastor : Validate : $path : Length must be minimum '$minLen' for value '$value'";
		}				
	}
	
	if (defined(my $prop = $type->maxLength)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $maxLen (@$prop) {
			(length($value) <= $maxLen) or die "Pastor : Validate : $path : Length must be maximum '$maxLen' for value '$value'";
		}				
	}
	
	if (defined(my $prop = $type->regex)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		my $pass=0;
		foreach my $regex (@$prop) {
			if ($value =~ /$regex/) {
				$pass =1;
				last;
			}
		}				
		$pass or die "Pastor : Validate : $path : Value does not match any of the given regexes. Value is '$value'";
	}

	if (defined(my $prop = $type->pattern)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		my $pass=0;
		foreach my $pattern (@$prop) {
			if ($value =~ /$pattern/) {
				$pass =1;
				last;
			}
		}				
		$pass or die "Pastor : Validate : $path : Value does not match any of the given patterns. Value is '$value'";
	}
	

	if (defined(my $enumeration = $type->enumeration)) {
		(exists $enumeration->{$value}) or die "Pastor : Validate : $path : Not in the permitted enumeration : value '$value'";
	}
	
	
	if (defined(my $prop = $type->minInclusive)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $min (@$prop) {
			($value >= $min) or die "Pastor : Validate : $path : Value must be at least (minimum) '$min' : But value is '$value'";
		}				
	}
	
	if (defined(my $prop = $type->maxInclusive)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $max (@$prop) {
			($value <= $max) or die "Pastor : Validate : $path : Value must be at most (maximum) '$max' : But value is '$value'";
		}				
	}

	if (defined(my $prop = $type->minExclusive)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $min (@$prop) {
			($value > $min) or die "Pastor : Validate : $path : Value must be greater than '$min' : But value is '$value'";
		}				
	}
	
	if (defined(my $prop = $type->maxExclusive)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $max (@$prop) {
			($value < $max) or die "Pastor : Validate : $path : Value must be less than '$max' : But value is '$value'";
		}				
	}


	# Digits part is shamelessly copied from XML::Validator::Schema by Sam Tregar
   if (defined($type->totalDigits) || defined($type->fractionDigits)) {
        # strip leading and trailing zeros for numeric constraints
        my $digits = $value;
        $digits  =~ s/^([+-]?)0*(\d*\.?\d*?)0*$/$1$2/g;

        if (defined(my $prop=$type->totalDigits)) {
			$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];        	
            foreach my $tdigits (@$prop) {
                die "Pastor : Validate : $path : Value has more total digits than the allowed '$tdigits'"
                  if $digits =~ tr!0-9!! > $tdigits;
            }
        }

        if (defined(my $prop=$type->fractionDigits)) {
			$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];        	        	
            foreach my $fdigits (@$prop) {
                die "Pastor : Validate : $path : Value has more fraction digits than the allowed '$fdigits'"            	
                  if $digits =~ /\.\d{$fdigits}\d/;
            }
        }        
    }

	
	return 1;	
}



#-----------------------------------------------------------------------------
# By default, this just returns TRUE. But it could be overriden by descendants (like 'date').
#-----------------------------------------------------------------------------
sub xml_validate_further {
	return 1;
}


#-----------------------------------------------------------------------------
# Validate the ancestors. Base classes need to be validated.
#-----------------------------------------------------------------------------
sub xml_validate_ancestors {
	my $self	= shift;
	my $value	= $self->__value;
	my @ancestors = $self->get_ancestors();
		
	foreach my $class (@ancestors) {
		next unless (UNIVERSAL::can($class, 'new') && UNIVERSAL::can($class, 'xml_validate'));
		
		my $obj=$class->new(__value => $value);
		return 0 unless $obj->xml_validate(@_);
	}
	
	return 1;
}


#-----------------------------------------------------------------------------
# Normalize white space. 
#-----------------------------------------------------------------------------
sub normalize_whitespace {
    my $self 	= shift;
    my $value 	= shift;
	my $type	= $self->XmlSchemaType();

	if (defined($type) and defined(my $prop = $type->whiteSpace)) {
		$prop = (reftype($prop) eq 'ARRAY') ? $prop : [$prop];
		foreach my $ws (@$prop) {
	        if ($ws =~ /^replace$/i) {
    	        $value =~ s![\t\n\r]! !g;            
        	} elsif ($ws =~ /^collapse$/i) {
            	$value =~ s!\s+! !g;
	            $value =~ s!^\s!!g;
    	        $value =~ s!\s$!!g;
        	}
	        return $value;	# only the first one gets treated!
		}				
	}else {
		my @ancestors = $self->get_ancestors();
		foreach my $class(@ancestors) {
			next unless UNIVERSAL::can($class, 'normalize_whitespace') && UNIVERSAL::can($class, 'new');
			my $object = $class->new(__value=>$value);
			my $nvalue = $object->normalize_whitespace($value);
			
			return $nvalue if ($nvalue ne $value);			
		}
	}
		    
    return $value;
}

1;

__END__

=head1 NAME

B<XML::Pastor::SimpleType> - Ancestor of all simple classes generated by L<XML::Pastor> and also the builtin simple classes.

=head1 ISA

This class descends from L<XML::Pastor::Type>. 

=head1 DESCRIPTION

B<XML::Pastor::SimpleType> is an B<abstract> ancestor of all simple classes 
(those global and implicit Simple Type definitions in the schema, including builtin ones) generated 
by L<XML::Pastor> which is a Perl code generator from W3C XSD schemas. For an introduction, please refer to the
documentation of L<XML::Pastor>.

B<XML::Pastor::SimpleType> defines some overloads (stringification, numification, boolification) and method overrides 
from L<XML::Pastor::Type>. 

B<XML::Pastor::SimpleType> contains (actually I<inherits from> L<XML::Pastor::Type>) a class data accessor called L</XmlSchemaType()> 
with the help of L<Class::Data::Inheritable>. This accessor is normally used by many other methods to access the W3C schema meta information 
related to the class at hand. But at this stage, L</XmlSchemaType()> does not contain any information and this is 
why B<XML::Pastor::ComplexType> remains abstract. 

The generated subclasses set L</XmlSchemaType()> to information specific to the W3C schema type. It is then used for the XML binding and validation methods. 

=head1 OVERLOADS

Several overloads are performed so that a B<XML::Pastor::SimpleType> object looks like a regular scalar. Basically, they all use the 'value' field as the scalar.

=head4 stringification

This is done with the B<stringify> (overridable) method. The returned value is the stringification of the contents of the 'value' field.
 
=head4 numification

This is done with the B<numify> (overridable) method. The returned value is the numification of the contents of the 'value' field.

=head4 boolification

This is done with the B<boolify> (overridable) method. The returned value is the boolification of the contents of the 'value' field. This method is
indeed overriden by the B<XML::Pastor::Builtin::boolean> class in order to count the string 'false' as a false value.

=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  $class->new($value)
  $class->new(%fields)

B<CONSTRUCTOR> overriden from L<XML::Pastor::Type>.

The new() constructor method instantiates a new B<XML::Pastor::SimpleType> object. It is inheritable, and indeed inherited,
by the generated decsendant classes. Normally, you do not call the B<new> method on B<XML::Pastor::SimpleType>. You rather
call it on your generated subclasses.
  
Any -named- fields that are passed as parameters are initialized to those values within
the newly created object. The only field that makes any sense at this time is the 'I<value>' field.
This is why it has been made easier to pass I<value> as the one and only parameter.

The following two calls are equivalent:

  my $object = $class->new($value);
  my $object = $class->new(value => $value);

Stick with the first one, as the second one requires the knowledge of the internal 
organization of the object.

=head4 from_xml_dom() 

	my $object = $class->from_xml_dom($node);
	
B<CONSTRUCTOR> that should be called upon your generated class rather than B<XML::Pastor::ComplexType>.
  
This method instatiates an object of the generated class from a DOM object passed as a parameter. Currently, the DOM
object must be either of type L<XML::LibXML::Attr>, L<XML::LibXML::Text> or of type L<XML::LibXML::Element> (with textContent).

Currently, the method is quite forgiving as to the actual contents of the DOM. No validation is performed during this call.

.

=head2 CLASS DATA ACCESSORS

=head4 XmlSchemaType()

  my $type = $class->XmlSchemaType()

B<CLASS METHOD>, but may also be called directly on an B<OBJECT>. 

B<XML::Pastor::SimpleType> defines (thanks to L<Class::Data::Inheritable>) 
a class data acessor B<XmlSchemaType> which returns B<undef>. 

This data accessor is set by each generated simple class to the meta information coming from your B<W3C Schema>. 
This data is of class L<XML::Pastor::Schema::SimpleType>. 

You don't really need to know much about B<XmlSchemaType>. It's used internally by Pastor's XML binding and validation 
methods as meta information about the generated class. 


=head2 ACCESSORS

=head4 value()

  $currentValue = $object->value();	# GET
  $object->value($newValue);		# SET

Gets and sets the value of the 'value' field, which is the actual SCALAR value of the object.

=head2 OTHER METHODS

=head4 is_xml_valid()

  $bool = $object->is_xml_valid();

B<OBJECT METHOD>, inherited from L<XML::Pastor::Type>. Documented here for completeness.

'B<is_xml_valid>' is similar to L</xml_validate> except that it will not B<die> on failure. 
Instead, it will just return FALSE (0). 

The implementation of this method, inherited from L<XML::Pastor::Type>, is very simple. Currently,
it just calls L</xml_validate> in an B<eval> block and will return FALSE (0) if L</xml_validate> dies.  
Otherwise, it will just return the same value as L</xml_validate>.

In case of failure, the contents of the special variable C<$@> will be left untouched in case you would like to access the 
error message that resulted from the death of L</xml_validate>.

.

=head4 xml_validate()
 
	$object->xml_validate();	# Will die on failure

B<OBJECT METHOD>, overriden from L<XML::Pastor::Type>.
 
'B<xml_validate>' validates a Pastor XML object (of a generated class) with respect to the META information that
had originally be extracted from your original B<W3C XSD Schema>.

On sucess, B<xml_validate> returns TRUE (1). On failure, it will B<die> on you on validation errors. 

The W3C recommendations have been observed as closely as possible for the implementation of this method. 
Neverthless, it remains somewhat more relaxed and easy compared to B<Castor> for example.


The following properties of XML Simple Type declarations in the W3C schema are observed:

=over

=item length

The string length of the value.

=item minLength, maxLength

The minimum and maximum string lengths for the value.

=item pattern

One ore more W3C regex patterns that the value must match. If more than one is present, 
any one match is considered sufficient for validity. 

=item regex  (not present in W3C schema)

Like 'pattern', but guaranteed to be a Perl regular expression even if the W3C 'pattern' diverges from this in the future.
This is used internally for builtin types. Like 'pattern', one or more regexes can be present. 

=item enumeration

A hash of enumeration values. 

=item minInclusive, maxInclusive

Minimum and maximum inclusive values.

=item minExclusive, maxExclusive

Minimum and maximum exclusive values.

=item totalDigits, fractionDigits

The total and fraction digits (in a floating point number) respectively.

=back

These properties are obtained from the schema type object returned from the L</XmlSchemaType> class data accessor call.

The builtin types use these properties extensively to enforce vaildity. The 'regex' property is 
used heavily for builtin types. 

After checking the conformity with these properties, B<xml_validate> calls L</xml_validate_further> to perform 
extra checks. For B<XML::Pastor::SimpleType> this always returns TRUE, but some builtin types 
(like L<XML::Pastor::Builtin::date> and L<XML::Pastor::Builtin::dateTime>) actually perform some extra validation 
during this call. 

Then, the B<xml_validate> method is called on any capable ancestors in the ISA array. A failure in any one of these 
calls will result in the failure of B<xml_validate> which will consequently I<die>.


=head4 xml_validate_further()
 
	$object->xml_validate_further();	# Never called directly.

B<OBJECT METHOD>, overriden from L<XML::Pastor::Type>.
 
'B<xml_validate_further>' should perform extra validation on a Pastor XML object (of a generated class).

It is called by L</xml_validate> after performing rutine validations.  

This method should return TRUE(1) on success, and I<die> on failure with an error message.

For B<XML::Pastor::SimpleType>, this method simple returns TRUE(1).

This method may be overriden by subclasses and it is indeed oevrriden by several builtin classes like
like L<XML::Pastor::Builtin::date> and L<XML::Pastor::Builtin::dateTime>. 

=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2007 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<XML::Pastor::Type>, L<XML::Pastor::ComplexType>, L<XML::Pastor>

And if you are curious about the implementation, see L<Class::Accessor>, L<Class::Data::Inheritable>


=cut
