use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);

package XML::Pastor::Schema::NamespaceInfo;
use base qw (Class::Accessor);

XML::Pastor::Schema::NamespaceInfo->mk_accessors(qw(uri nsPrefix classPrefix id usageCount));

#------------------------------------------------------------
sub new () {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self = {@_};
	
	unless ($self->{usageCount}) {
		$self->{usageCount} = 0;
	}

	return bless $self, $class;
}

1;

__END__

=head1 NAME

B<XML::Pastor::Schema::NamespaceInfo> - Class that represents the META information about a target namespace within a W3C schema.

=head1 WARNING

This module is used internally by L<XML::Pastor>. You do not normally know much about this module to actually use L<XML::Pastor>.  It is 
documented here for completeness and for L<XML::Pastor> developers. Do not count on the interface of this module. It may change in 
any of the subsequent releases. You have been warned. 

=head1 ISA

This class descends from L<Class::Accessor>.

=head1 DESCRIPTION

B<XML::Pastor::Schema::NameSpaceInfo> is a class that is used internally to represent a target namespace of a given schema. 

=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  $class->new(%fields)

B<CONSTRUCTOR>, inherited. 

The new() constructor method instantiates a new object. It is inheritable. 
  
Any -named- fields that are passed as parameters are initialized to those values within
the newly created object. 

.

=head2 ACCESSORS


=head3 Accessors defined here

=head4 uri()

  my $uri = $object->uri();	# GET
  $object->uri($uri);       # SET

The namespace URI associated. 
 
=head4 nsPrefix()

  my $pfx = $object->nsPrefix();	# GET
  $object->nsPrefix($pfx);       # SET

The namespace prefix associated with this URI. 

=head4 classPrefix()

  my $pfx = $object->classPrefix();	# GET
  $object->classPrefix($pfx);       # SET

The class prefix that will be used in conjunction with this target namespace.  

=head4 id()

  my $id = $object->id();	# GET
  $object->id($id);       # SET

An identifier, local to the schema model, of this namespace.   

.

=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Note that, although some testing was done prior to releasing the module, this should still be considered alpha code. 
So use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev(at)ulusoy(dot)name>


=head1 COPYRIGHT

  Copyright (C) 2006-2008 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

See also L<XML::Pastor>, L<XML::Pastor::Schema::Model>

=cut
