#!/usr/local/bin/perl

package Text::PORE::Object;

use Exporter;
@Text::PORE::Object::ISA = qw(Exporter);
$Text::PORE::Object::VERSION = "0.05";

sub new
{
        my ($type) = shift;
        my (%att_list) = @_;
        my ($self) = {};
 
        foreach $key (keys %att_list) {
                $self->{"\L$key\E"} = $att_list{$key};
        }
 
        bless $self;
        $self;
}
 

#######################################
# getAttribute($name)
#######################################
sub getAttribute() {
	return GetAttribute(@_);
};

#######################################
# setAttribute($name=>$value)
#######################################
sub setAttribute() {
	LoadAttributes(@_);
}

#######################################
# setAttributes($name1=>$value1, $name2=>$value2, ..., $nameN=>$valueN)
#######################################
sub setAttributes() {
	LoadAttributes(@_);
}


sub GetClassType
{	
	my($type) = shift;
	my($dummy);
	($type,$dummy) = split(/\=/,$type);
	return ($type);
}


#######################################
# Given the attribute name,
# return the value of itself, closest ancestor or default
#######################################
sub GetAttribute
{
	my ($self) = shift; 
	my ($att) = @_;
	$att = "\L$att\E";
	return ($self->{$att}) if (defined $self->{$att});

	my ($obj_id);
	if ($obj_id = $self->{"ID\_$att"}) {
		#####################################
		# this attribute exists, but the object is now allocated yet
		# allocate the object now
		#####################################
		my($class) = $::obj_type_2_class{$self->{"TYPE_$att"}};	
		if ($class) {
			require "$class.pm"; import $class;
			if ($::_PRINT_NEW_) {
				print "new $class(id=>$obj_id)\n";
			}
			$self->{$att} = $class->new (id=>$obj_id);
		}
		return ($self->{$att});
	}
	elsif ($self->{'parent'}) {
		#####################################
		# this attribute dosn't exists, 
		# look one level up
		#####################################
		return ($self->{'parent'}->GetAttribute($att));
	}
	else {
		#########################################
		# this attribute is not found anywhere within myself and
		# my ancestors, return the default one
		#########################################
		#print "default:[$att]=[$::default_attribs{$att}]";
		return ($::default_attribs{$att});

	}
}

######################################
# returns a reference to a list of all attribute names
######################################
sub GetAllAttributeNames
{
	my($self) = shift;
	my ($att,@att_list);

	$self->FinalizeAllAttributes;
	foreach $att (sort keys %{$self}) {
		if ($att =~ /^ID_|^TYPE_/) { next; }
		push (@att_list, $att);
	}
	return (\@att_list);
}

######################################
# Finalize All the Attributes
# Internal Function, outsiders should not care about it.
######################################
sub FinalizeAllAttributes
{
	my($self) = shift;
	my ($att,$class,$obj_id);
	foreach $att(keys %{$self}) {
	    if ($att =~ /^ID_(.+)$/) {
		$obj_id = $self->{$att};
		$att = $1;
		$class = $::obj_type_2_class{$self->{"TYPE_$att"}};	
		if ($class) {
			require "$class.pm"; import $class;
			if ($::_PRINT_NEW_) {
				print "new $class(id=>$obj_id)\n";
			}
			$self->{$att} = $class->new (id=>$obj_id);
		}
	    	$self->{"ID_$att"} = $self->{"TYPE_$att"} = undef;
	    }
	}
}

######################################
# returns a reference to a hash 
# the hash keys are the attribute names
# the hash values are the attribute values
# an example:
#	$page = new Page(id=>$id);
#	$hash_ref = $page->GetAllAttributes;
#	foreach $attr (keys %$hash_ref) {
#		print "name: $attr, value: $hash_ref->{$attr}";
#	....
######################################
sub GetAllAttributes
{
    my($self) = shift;
	my ($att,%obj);
	$self->FinalizeAllAttributes;
	foreach $att (sort keys %{$self}) {
		if ($att =~ /^ID_|^TYPE_/) { next; }
		else {
		  $obj{$att} = $self->{$att};
		}
	}
        return (\%obj);
}
 


######################################
# Print All Attributes and Values for debugging purpose
######################################
sub PrintAllAttributes
{
    my($self) = shift;
	my $att_ref = $self->GetAllAttributes;
	my ($attr,$val);
	while (($attr,$val) = (each %{$att_ref})) {
		print "'$attr'=[";
		if (ref $val eq 'ARRAY') {
			### multi-value attribute
			print "multi: @$val";
		}
		else { print $val; }
		print "]<br>\n";
	}
}



######################################
# Return 1 if these multi-value attribute 
#		$attr has value $value
# Return 0 otherwise
######################################
sub MultiValAttrHas
{
    my($self) = shift;
	my($attr,$val) = @_;

	if (ref $self->{$attr} ne 'ARRAY') { return 0; }
	foreach (@{$self->{$attr}}) {
		if ($_ eq $val) { return 1; }
	}
	return 0;
}

	
#################################################
# Load Attributes 
# In: pair(s) of attribute_name and attribute_value
# Example:
#	$object->LoadAttributes($name1=>$value1,$name2=>$value2,...);
#################################################
sub LoadAttributes
{
	my($self) = shift;
	my(%att_list) = @_;

	foreach $key (keys %att_list) {
		$self->{"\L$key\E"} = $att_list{$key};
	}

	return $self;
}

###############################################
# given an attribute name, an id and a type, 
# create a object, which is my child
# if id is 0, then the object is a scalar, use
# type as its value
###############################################
sub MakeChild 
{
	my $self = shift;
        my($child_name, $id, $type) = @_;
 
        ###############################################
        # it's not a object but a value, return value($type)
        ###############################################
        if (!$id) {
                $self->{$child_name} = $type;
        }
 
        ###############################################
        # it's a object
        ###############################################
        my $class = $::obj_type_2_class{$type};
	if ($class) {
		require "$class.pm"; import $class;
		if ($::_PRINT_NEW_) {
			print "new $class(id=>$obj_id)\n";
		}
		my $obj = $class->new(id=>$id,parent=>$self);
		$self->{$child_name} = $obj;
	}
	else { return undef; }
}


###############################################
# Atts2QueryString
#	convert attributes to QueryString
###############################################
sub Atts2QueryString
{
	my $self = shift;
	my %atts = @_;
	$self->LoadAttributes(%atts);
 
	my $string = undef;
	my $key;
	my $value;
        foreach $key (keys %{$self}) {
                if ($key eq 'parent') { next; }
		$value = urlencode ($self->{$key});
		$key = urlencode_word ($key);
                $string .= "$key=$value\&";
        }
 
        return $string;
}

1;
__END__

=head1 NAME

Text::PORE::Object - PORE Objects

=head1 SYNOPSIS

	$obj = new Text::PORE::Object('name'=>'Joe Smith');
	@chilren = (
		new Text::PORE::Object('name'=>'John Smith', 'age'=>10, 'gender'=>'M'),
		new Text::PORE::Object('name'=>'Jack Smith', 'age'=>15, 'gender'=>'M'),
		new Text::PORE::Object('name'=>'Joan Smith', 'age'=>20, 'gender'=>'F'),
		new Text::PORE::Object('name'=>'Jim Smith', 'age'=>25, 'gender'=>'M'),
	);
	$obj->{'children'} = \@chilren;

=head1 DESCRIPTION

PORE::Object is the superclass of all renderable objects. That is, if you want to render an object, the
object must be an instance of PORE::Object or an instance of its subclass.

The purpose of this class is to provide methods to create and access attributes. Attributes can be
created via the constructor C<new> and setters C<setAttribute()> and C<setAttributes()>. Attributes can be 
retrieve via the getter C<getAttribute()>.

=head1 METHODS

=over 4

=item new

Usage:

	new Text::PORE::Object();
	new Text::PORE::Object($name1=>$value1, $name2=>$value2, ..., $nameN=>$valueN);

The constructor can take no argument or a list of name-value pairs. If a list of name-value pairs is
provided, the object is created with the given attributes.

=item getAttribute()

Usage:

	$obj->getAttribute($name);

This method retrieves the value of the given attribute. If the attribute is an object, its reference is
returned.

=item setAttribute()

Usage:

	$obj->setAttribute($name=>$value);

This method takes a name-value pair. It sets the attribute for the given name to the given value.
If the attribute previously has an old value, the new value overrides the old one.

=item setAttributes()

Usage:

	$obj->setAttributes($name1=>$value1, $name2=>$value2, ..., $nameN=>$valueN);

This method takes a list of name-value pairs. It sets the attribute for each given name to its
corresponding value.
If the attribute previously has an old value, the new value overrides the old one.

=back

=head1 AUTHOR

Zhengrong Tang, ztang@cpan.org

=head1 COPYRIGHT

Copyright 2004 by Zhengrong Tang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

