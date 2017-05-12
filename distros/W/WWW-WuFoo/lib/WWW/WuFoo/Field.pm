package WWW::WuFoo::Field;
{
  $WWW::WuFoo::Field::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Fields API describes the hierarchy of your data. At the heart of this API is the listing of FieldId values. Each FieldId corresponds to a value in the Entries API.

has '_wufoo'            => (is => 'rw', isa => 'WWW::WuFoo');
has '_form'             => (is => 'rw', isa => 'WWW::WuFoo::Form');
has 'id'                => (is => 'rw', isa => 'Str', required => 1);
has 'type'              => (is => 'rw', isa => 'Str');
has 'title'             => (is => 'rw', isa => 'Str');
has 'label'             => (is => 'rw', isa => 'Str');
has 'defaultval'        => (is => 'rw', isa => 'Str');
has 'classnames'        => (is => 'rw', isa => 'Str');
has 'instructions'      => (is => 'rw', isa => 'Str');
has 'page'              => (is => 'rw', isa => 'Str');
has 'isrequired'        => (is => 'rw', isa => 'Str');
has 'title'             => (is => 'rw', isa => 'Str');
has 'subfields'         => (is => 'rw', isa => 'ArrayRef');
has 'choices'           => (is => 'rw', isa => 'ArrayRef');



1;
