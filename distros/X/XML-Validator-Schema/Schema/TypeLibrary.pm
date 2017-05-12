package XML::Validator::Schema::TypeLibrary;
use strict;
use warnings;

use XML::Validator::Schema::Util qw(XSD _err);
use XML::Validator::Schema::SimpleType;
use base 'XML::Validator::Schema::Library';

=head1 NAME

XML::Validator::Schema::TypeLibrary

=head1 DESCRIPTION

Internal module used to implement a library of types, simple and
complex.

=head1 USAGE

  # get a new type library, containing just the builtin types
  $library = XML::Validator::Schema::TypeLibrary->new();

  # add a new type
  $library->add(name => 'myString',
                ns   => 'http://my/ns',
                obj  => $type_obj);

  # lookup a type
  my $type = $library->find(name => 'myString',
                            ns   => 'http://my/ns');

=cut

sub new {
    my $pkg = shift;
    my $self = $pkg->SUPER::new(what => 'type', @_);
    
    # load builtin simple types into XSD namespace
    $self->{stacks}{XSD()} = { %XML::Validator::Schema::SimpleType::BUILTIN };

    return $self;
}



1;

