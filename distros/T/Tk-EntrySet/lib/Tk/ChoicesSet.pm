package Tk::ChoicesSet;
use strict;
use warnings;


=head1 NAME

Tk::ChoicesSet - display/edit a list of choices in a Set of single-selection Widgets.

=head1 SYNOPSIS

  require Tk::ChoicesSet;
  my $labels_and_values = [
      {label => 'foo', value => 1},
      {label => 'bar', value => 2},
      {label => 'baz', value => 3},
  ];
  my $instance = $main_window->ChoicesSet(-labels_and_values =>
                                           $labels_and_values)->pack;
  $instance->configure(-valuelist_variable => \$valuelist);
  $instance->valuelist([1,3]);


=head1 DESCRIPTION

Tk::ChoicesSet creates a Set of widgets to display/edit a list of choices.
Each widget allows for a single selection out of a given list of
options. The widget class is configurable.
Per default Tk::ChoicesSet uses Tk::MatchingBE which is included in the
Tk-EntrySet package. This can be changed to any widget that supports
index based access to the selection. Tk::ChoicesSet adds/removes widgets
to match the size of the valuelist. When a selection-widgets state becomes
undef (deselected), the value is deleted from the valuelist and the widget
is removed from the set on view update.
View updates are by default bound to the widgets -selectcmd for integration
with MatchingBE. This is configurable through the -callback_installer option.
The last widget in the Set is always empty to allow users to
append values to the list.
(If you need editable values with an optionlist for 'suggestions' and value
based access to the widgets in the set, you might want to use Tk::EntrySet.)
Tk::ChoicesSet handles label/value pairs or simple choices lists.
Tk::ChoicesSet is a Tk::EntrySet derived widget.



=head1 METHODS

B<Tk::ChoicesSet> supports the following methods:

=over 4

=item B<valuelist(>[qw/a list of selected values/]B<)>

Get/Set the valuelist (arrayref).

=item B<indexlist(>[qw/a list of selected indexes/]B<)>

Get/Set the indexlist (arrayref). For internal use primarily.

=item B<labels_and_values(>[{label=>'aLabel',value=>'aValue'},{},{}]B<)>

Get/Set the options list (arrayref of hashes). Sets label and value of each
element to the corresponding hash value.

=item B<choices(>[qw/a list of options to choose from/]B<)>

Get/Set the options list (arrayref). Sets label and value of each element
to the value in the list. When used as a getter returns the list of option
labels.

=back

=head1 OPTIONS

B<Tk::ChoicesSet> supports the following options:

=over 4

=item B<-entryclass>

A Tk widget class to be used for the entrywidgets. Defaults to 'MatchingBE'.

=item B<-entryoptions>

Options to be passed to each entry on creation (arrayref).

=item B<-getter>

A coderef which is used by Tk::ChoicesSet to read the Entrywidgets content.
It gets passed the Entrywidget instance and is expected to return its
selected index.
Defaults to
 sub{ $_[0]->get_selected_index }, which is suitable for
Tk::MatchingBE.

=item B<-setter>

A coderef which is used by Tk::ChoicesSet to write the Entrywidgets content.
It gets passed the Entrywidget instance and the new index value. Defaults to
 sub{ $_[0]->set_selected_index($_[1]) }, which is suitable for Tk::MatchingBE.

=item B<-callback_installer>

A coderef which is called after each Entrywidgets instantiation.
The callback_installer gets passed the Entrywidget and a coderef that will
update the Tk::ChoicesSet view when called.
Defaults to
 sub{$_[0]->configure(-selectcmd => $_[1])}, which is suitable for
Tk::MatchingBE.

=item B<-unique_values>

If set to true (default) duplicate elements will be removed on view updates.

=item B<-valuelist>

Get/Set the list of selected values (arrayref).

=item B<-valuelist_variable>

Ties a variable (scalarref) to the -valuelist atribute.
This is a Scalar Tie only.


=back

=head1 Examples

See the examples/ subdirectory.

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

our $VERSION = '0.11';

require Tk::EntrySet;
require Tk::MatchingBE;
our @ISA = 'Tk::EntrySet';
Tk::Widget->Construct('ChoicesSet');

sub default_entryclass{
    return 'MatchingBE';
}
sub default_getter{
    return sub{$_[0]->get_selected_index};
}
sub default_setter{
    return sub{$_[0]->set_selected_index($_[1])};
}
sub default_callback_installer{
    return sub{$_[0]->configure(-selectcmd => $_[1])};
}

#sub autoLabel{0}; # keep Frames -label and related options

sub Populate{
    my ($self,$args) = @_;
    $self->{_ChoicesSet}{entry_pool}= [];
    $self->{_ChoicesSet}{entries}= [];
    
    # need to hide this from Tk::Frame::Populate...
    my $l_v = exists $args->{-labels_and_values}
        ? delete $args->{-labels_and_values}
            : undef;
    
    $self->SUPER::Populate($args);

    if (defined $l_v){
        $args->{-labels_and_values}= $l_v;
    }
    my $empty = [{value => '',label => ''}];
    $self->ConfigSpecs(
                       -choices            => ['METHOD',undef,undef,undef],
                       -labels_and_values  => ['METHOD',undef,undef,$empty],

                   );
    $self->afterIdle(sub{$self->valuelist});
}

sub new_entry{
    my $self = shift;
    my $entry = $self->SUPER::new_entry;
    # propagate our cw's choices(labels) to the actual entry subwidget
    my $labels = $self->get_labels;
    ##print "configure entry with choices:\n";
    ##print Dumper $choices;
    $entry->configure(-choices => $labels);
    return $entry;
}


sub choices{
    my $self = shift;
    my $choices = $_[0];
    unless ($choices){
        return $self->get_labels;
    }
    #print "MBE choices: arg:\n";
    #print Dumper $choices;
    my @labels_and_values = map {{value => $_, label => $_}} @$choices;
    $self->labels_and_values(\@labels_and_values);
}



sub labels_and_values{
    my $self = shift;
    my $data = $_[0];
    unless ($data){
        return $self->{_ChoicesSet}{labels_and_values};
    }

    # we expect an arrayref structure like
    #           [ {value => 'aValue', label => 'aLabel'} ,
    #             {value => 'aValue', label => 'aLabel'},
    #           ...
    #           ]

    $self->{_ChoicesSet}{labels_and_values} = $data;
    my $i = 0;
    my %value_to_index = map {($_->{value},$i++)} @$data;
    $self->{_ChoicesSet}{value_to_index} = \%value_to_index;
   # print Dumper \%value_to_index;

    $self->clear_valuelist;

}

sub get_labels{
    my $self = shift;
    my $labels_and_values = $self->labels_and_values;
    my @labels = map {$_->{label}} @{$labels_and_values};
    return \@labels;
}

# ChoicesSet deals with indexable Option lists, therefore the default
# access via the -getter/-setter subs is per index - and that's how the
# default -getter/-setter are defined.
# We wrap the inherited 'valuelist' by 'indexlist' and define 'valuelist'
# get/set to behave as expected and deal with 'values'

sub indexlist{
    my $self = shift;
    my ($indexlist) = $_[0];
    if ($indexlist){
        $self->SUPER::set_valuelist($indexlist);
    }else{
        $indexlist = $self->SUPER::get_valuelist;
    }
    return $indexlist;
}

### set_valuelist expects an arrayref of values
### and maps it to indices
sub set_valuelist{
    my $self = shift;
    my $values = $_[0];
    my %value_to_index = %{$self->{_ChoicesSet}{value_to_index}};
    my @selected = map {$value_to_index{$_}} @$values;
    $self->indexlist(\@selected);
}

### read selected indexlist and map to values
sub get_valuelist{
    my $self = shift;
    my $selected = $self->indexlist;
    my $labels_and_values = $self->{_ChoicesSet}{labels_and_values};
    my @values = map {$labels_and_values->[$_]{value}} @$selected;
    return \@values;
}

1;
