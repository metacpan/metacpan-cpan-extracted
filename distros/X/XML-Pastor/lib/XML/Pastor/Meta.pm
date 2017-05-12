use utf8;
use strict;
use warnings;
no warnings qw(uninitialized);


package XML::Pastor::Meta;

use Class::Accessor;
use Class::Data::Inheritable;

our @ISA = qw(Class::Accessor Class::Data::Inheritable);

XML::Pastor::Meta->mk_classdata('Model');


#----------------------------------------------
# Accepts a single parameter or a hash.
# If single parameter, then it is taken to be the value.
#----------------------------------------------
sub new {
	my $proto 	= shift;
	my $class	= ref($proto) || $proto;
	my $self 	= {@_};
	
	return bless $self, $class;
}

1;

__END__


=head1 NAME

B<XML::Pastor::Meta> - Ancestor of the generated ::Pastor::Meta classes. 

=head1 ISA

This class descends from L<Class::Accessor>  and L<Class::Data::Inheritable>

=head1 SYNOPSIS

  # please see the documentation of XML::Pastor  

=head1 DESCRIPTION

B<XML::Pastor::Meta> is the ancestor of the generated ::Pastor::Meta classes.

Suppose you use L<XML::Pastor> for code generation with a B<class prefix> of B<MyApp::Data>. Then,
L<XML::Pastor> will also generate a class that enables you to access meta information about the generated code under 'MyApp::Data::Pastor::Meta'.

Currently, the only information you can access is the 'B<Model>' that was used to generate code. 
'B<Model>' is class data that references to an entire schema model object (of type L<XML::Schema::Model>). 
With the help of the generated 'meta' class, you can access the Model which will in turn enable you to
call methods such as 'B<xml_item_class()>' which helps you determine the generated Perl class of a given global element or
type in the schema. 

=head1 CONSTRUCTORS

=head4 new(%args)

Creates and initializes the object.


=head1 CLASS METHODS

=head4 Model()

Returns the schema model object (of type L<XML::Schema::Model>) associated with the set of schemas that were
used for the code generation.

You can actually assign a model with this method as well, just by passing a reference as the only argument. But why would you want to do it. 

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

See also L<XML::Pastor>


=cut



