package WWW::WuFoo::Entry;
{
  $WWW::WuFoo::Entry::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Entries API is used to gather the data that users have submitted to your form. In this section we’ll describe the hierarchy of the entries element as well as describe the syntax for filtering this data.

has '_wufoo'            => (is => 'rw', isa => 'WWW::WuFoo');
has '_form'             => (is => 'rw', isa => 'WWW::WuFoo::Form');
has '_original'         => (is => 'rw', isa => 'HashRef');
has 'entryid'           => (is => 'rw', isa => 'Int');
has 'datecreated'       => (is => 'rw', isa => 'Str');
has 'createdby'         => (is => 'rw', isa => 'Str');
has 'dateupdated'       => (is => 'rw', isa => 'Str');
has 'updatedby'         => (is => 'rw', isa => 'Str');



sub data {
    my ($self) = @_;
    return $self->_original;
}

sub val_hash {
    my ($self) = @_;

    my $hash;
    my $fields = $self->_form->fields;
    foreach my $f (@$fields) {
        if (my $subs = $f->subfields) {
            foreach my $subfield (@$subs) {
                $hash->{$subfield->{Label}} = $self->_original->{$subfield->{ID}};
            }
        }

        else {
            $hash->{$f->title || $f->label || $f->id} = $self->_original->{$f->id};
        }
    }

    return $hash;
}


1;
