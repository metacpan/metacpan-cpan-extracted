package XML::XMetaL::Utilities;

use strict;
use warnings;
use Carp;
use Hash::Util qw(lock_keys);
use Win32;

# DOM node types
use constant DOMELEMENT               => 1;
use constant DOMATTR                  => 2;
use constant DOMTEXT                  => 3;
use constant DOMCDATASECTION          => 4;
use constant DOMENTITYREFERENCE       => 5;
use constant DOMENTITY                => 6;
use constant DOMPROCESSINGINSTRUCTION => 7;
use constant DOMCOMMENT               => 8;
use constant DOMDOCUMENT              => 9;
use constant DOMDOCUMENTTYPE          => 10;
use constant DOMDOCUMENTFRAGMENT      => 11;
use constant DOMNOTATION              => 12;
use constant DOMCHARACTERREFERENCE    => 505; # Extension to DOM

# Attribute types
use constant UNKNOWN        => -1; 
use constant CDATA          =>  0; 
use constant ID             =>  1;
use constant IDREF          =>  2; 
use constant IDREFS         =>  3; 
use constant ENTITY         =>  4;
use constant ENTITIES       =>  5;
use constant NMTOKEN        =>  6;
use constant NMTOKENS       =>  7;
use constant NOTATION       =>  8;
use constant NAMETOKENGROUP =>  9;



require Exporter;

our  @ISA = qw(Exporter);

our @dom_type_names = qw(
    DOMELEMENT                  DOMATTR                   DOMTEXT
    DOMCDATASECTION             DOMENTITYREFERENCE        DOMENTITY
    DOMPROCESSINGINSTRUCTION    DOMCOMMENT                DOMDOCUMENT
    DOMDOCUMENTTYPE             DOMDOCUMENTFRAGMENT       DOMNOTATION
    DOMCHARACTERREFERENCE
);

our @attribute_type_names = qw(
    UNKNOWN            CDATA            ID
    IDREF              IDREFS           ENTITY
    ENTITIES           NMTOKEN          NMTOKENS
    NOTATION           NAMETOKENGROUP
);

our %EXPORT_TAGS = (
    all             => [@dom_type_names, @attribute_type_names],
    dom_node_types  => [@dom_type_names],
    attribute_types => [@attribute_type_names],
);

our  @EXPORT_OK = (@{$EXPORT_TAGS{all}});  

# Variables used by the generate_id() method
our $count = 0;
our $user = Win32::LoginName();
our $time = time();



sub new {
    my ($class, %args) = @_;
    my $self;
    eval {
        lock_keys(%args, qw(-application));
        $self = bless {
            _application => $args{-application} || croak("-application parameter missing or undefined"),
        }, ref($class) || $class;
        lock_keys(%$self, keys %$self);
    };
    croak $@ if $@;
    return $self;
}

sub get_application {
    my ($self) = @_;
    return $self->{_application};
}

sub get_active_document {
    my ($self) = @_;
    return $self->get_application()->{ActiveDocument};
}

sub get_selection {
    my ($self) = @_;
    my $application = $self->get_application();
    return $application->{Selection};
}

sub insert_element_with_id {
    my ($self, $generic_identifier) = @_;
    my $inserted_node = undef;
    eval {
        my $active_document = $self->get_active_document();
        my $initial_position_range = $active_document->{Range};
        my $final_position_range;
        my $selection = $self->get_selection();
        if ($selection->CanInsert($generic_identifier)) {
            $selection->InsertElementWithRequired($generic_identifier);
            $final_position_range = $active_document->{Range};
            $initial_position_range->Select();
            $selection->MoveRight(0);
            $inserted_node = $selection->{ContainerNode};
            $self->populate_element_with_id($inserted_node);
            $final_position_range->Select();
        }
    };
    croak $@ if $@;
	return $inserted_node;
}

sub generate_id {
    $count++;
    my $id = sprintf "%s%u%04u",$user,$time,$count;
    return $id;
}

sub get_id_attribute_name {
    my ($self, $generic_identifier) = @_;
    my $id_attribute_name;
    eval {
        my $active_document = $self->get_active_document();
        my $doctype = $active_document->{doctype};
        my $count = 0;
        while ($id_attribute_name = $doctype->elementAttribute($generic_identifier, $count)) {
            $count++;
            last if $doctype->attributeType($generic_identifier,$id_attribute_name) == ID;
        }
    };
    croak $@ if $@;
    return $id_attribute_name || undef;
}

sub populate_id_attributes {
    my ($self, $generic_identifier) = @_;
    eval {
        my $active_document = $self->get_active_document();
            my $element_node_list = $active_document->getElementsByTagName($generic_identifier);
            my $element;
            for (my $count = 0; $count < $element_node_list->{length}; $count++) {
                $element = $element_node_list->item($count);
                $self->populate_element_with_id($element);
            }
    };
    croak $@ if $@;
}

sub populate_element_with_id {
    my ($self, $element_node) = @_;
    eval {
        my $generic_identifier = $element_node->{tagName};
        my $attribute_name = $self->get_id_attribute_name($generic_identifier);
        if ($attribute_name) {
            unless ($element_node->hasAttribute($attribute_name)) {
                my $id_value = $self->generate_id();
                $element_node->setAttribute($attribute_name, $id_value);
            }
        }
    };
    croak $@ if $@;
}

sub word_count {
    my ($self, $argument) = @_;
    my $word_count;
    eval {
        $word_count = ref($argument) ?
            $self->_count_words_in_element($argument):
            $self->_count_words_in_string($argument);
        
    };
    croak($@) if $@;
    return $word_count;
}

sub _count_words_in_string {
    my ($self, $string) = @_;
    my $word_count;
    eval {
        my @words = split /[\s\:\-\;\,]+/, $string;
        @words = grep {$_} @words; # Filter out empty strings
        $word_count = @words;
    };
    croak $@ if $@;
    return $word_count;
}

sub _count_words_in_element {
    my ($self, $element) = @_;
    my $word_count = 0;
    eval {
        my $child_nodes = $element->{childNodes};
        my ($child, $node_type);
        for (my $count = 0; $count < $child_nodes->{length};$count++) {
            $child = $child_nodes->item($count);
            $node_type = $child->{nodeType};
            foreach ($node_type) {
                $node_type == DOMELEMENT && do {
                    $word_count += $self->_count_words_in_element($child);
                    last;
                };
                $node_type == DOMTEXT && do {
                    $word_count += $self->_count_words_in_string($child->{data});
                    last;
                };
                $node_type == DOMCDATASECTION && do {
                    $word_count += $self->_count_words_in_string($child->{data});
                    last;
                };
            }
        }
    };
    croak $@ if $@;
    return $word_count;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Utilities - Utility functions

=head1 SYNOPSIS

 # Use the module
 use XML::XMetaL::Utilities;

 # Use the module and import constants
 use XML::XMetaL::Utilities qw(:dom_node_types :attribute_types);

 # Use the module and import all constants
 use XML::XMetaL::Utilities qw(:all);

 # The constructor
 my $utilities = XML::XMetaL::Utilities->new(-application => $xmetal);

 # Utility Methods
 my $id_attribute_name = $utilities->get_id_attribute_name('Para');

 my $id = $utilities->generate_id();
 $utilities->populate_element_with_id($element_node);
 $utilities->populate_id_attributes('Article');
 my $inserted_node = $utilities->insert_element_with_id('VariableList');

 my $word_count = $utilities->word_count($string);
 my $word_count = $utilities->word_count($element_node);


 # Miscellaneous Methods
 my $xmetal_application = $utilities->get_application();
 my $active_document = $utilities->get_active_document();
 my $selection = $utilities->get_selection();


=head1 DESCRIPTION

The C<XML::XMetaL::Utilities> class contains utility methods:

=over 4

=item Id utilities

=item Word counting

=item Miscellaneous utility methods

=back

=head2 EXPORT

On request, the C<XML::XMetaL::Utilities> package can export a number of
constants used by XMetaL. The following export tags are available:

=over 4

=item C<:dom_node_types>

The C<:dom_node_types> tag exports constants representing the DOM node
types used by XMetaL. The following constants are exported:

    DOMELEMENT                  DOMATTR                   DOMTEXT
    DOMCDATASECTION             DOMENTITYREFERENCE        DOMENTITY
    DOMPROCESSINGINSTRUCTION    DOMCOMMENT                DOMDOCUMENT
    DOMDOCUMENTTYPE             DOMDOCUMENTFRAGMENT       DOMNOTATION
    DOMCHARACTERREFERENCE

The integer values represented by these constants are the same as those
returned by the C<nodeType> property of the C<DOMNode> class in the
XMetaL API.

=item C<:attribute_types>

The C<:attribute_types> tag exports constants representing attribute
node types used by XMetaL. The following constants are exported:

    UNKNOWN            CDATA            ID
    IDREF              IDREFS           ENTITY
    ENTITIES           NMTOKEN          NMTOKENS
    NOTATION           NAMETOKENGROUP

The integer values represented by these constants are the same as those
returned by the C<attributeType> property of the C<DOMDocumentType>
class in the XMetaL API.

=item C<:all>

The C<:all> tag exports all of the constants listed above.

=back

=head2 Constructor and initialization

 use XML::XMetaL::Utilities qw(:all);
 my $utilities = XML::XMetaL::Utilities->new(-application => $xmetal_application);

The C<use> statement takes optional export tags as arguments as described
in the L<EXPORT> section.

The constructor requires one named parameter: an XMetaL application object.


=head2 Class Methods

None.

=head2 Public Methods

=over 4

=item C<get_id_attribute_name>

 my $id_attribute_name = $utilities->get_id_attribute_name('Para');

The C<get_id_attribute_name> method takes the name of an element
(a generic identifier) as an argument, and returns the name of the ID
type attribute of that element, if there is an ID type attribute
declared.

If there is no ID attribute declared for the element, C<undef> will be
returned.

=item C<generate_id>

 my $id = $utilities->generate_id();

The C<generate_id> method generates an id value of the following format:

 <user_name><time_stamp><count>

=over 4

=item C<user_name>

The C<user_name> is the user name of the XMetaL user

=item C<time_stamp>

The C<time_stamp> is obtained using the Perl C<time> function when the
utilities object is created. Thus, in most cases, the time stamp will
remain constant for an entire XMetaL session.

=item C<count>

The C<count> is incremented by one each time the C<generate_id> method
is called.

=back

The id generated by C<generate_id> will always be unique within the scope
of a particular XMetaL session.

It is conceivable that two users on different networks, with the same
user name, could start XMetaL at the exact same second, and thus generate
identical ids. However, this risk is so small as to be deemed negligible.

=item C<populate_element_with_id>

 $utilities->populate_element_with_id($element_node);

The C<populate_element_with_id> method takes an element node as an
argument and adds an ID attribute with an id value to it.

If the element does not have an ID attribute, or if the ID attribute
already has a value, nothing happens. Existing id values are I<not>
changed.

=item C<populate_id_attributes>

 $utilities->populate_id_attributes('Article');

The C<populate_id_attributes> method takes an element name as an argument
and populates all element nodes with the same name with ID attributes.

Existing ID attribute values are I<not> changed.

=item C<insert_element_with_id>

 my $inserted_node = $utilities->insert_element_with_id('VariableList');

The C<insert_element_with_id> method inserts an element, with a
populated ID attribute, at the insertion point of the currently active
document.

If successful, the method returns the inserted element node.

If the element could not be inserted, the method returns C<undef>.

=item C<word_count>

 my $word_count = $utilities->word_count($string);
 my $word_count = $utilities->word_count($element_node);

The word count takes either a text string or an element node as an
argument. It returns a word count.

If the argument is a string, markup in the string will be counted as
words.

If the argument is an element node, only words in text nodes and CDATA
sections will be counted.

=item C<get_application>

 my $xmetal_application = $utilities->get_application();

This accessor method returns the XMetaL application object.

=item C<get_active_document>

 my $active_document = $utilities->get_active_document();

This accessor method returns the currently active document.

=item C<get_selection>

 my $selection = $utilities->get_selection();

This accessor method returns a selection object representing the
current selection in the active document.

=back


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

The C<generate_id> method will generate illegal id values if the user
name contains characters that are illegal in an id, or if the user
name begins with a character that is not a letter.

This problem will be fixed in a future version.

There are almost certainly plenty of other bugs too.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
