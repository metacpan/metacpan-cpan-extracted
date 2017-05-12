package Tk::MatchingBE;
use strict;
use warnings;
use Carp;


=head1 NAME

Tk::MatchingBE - A single-selection BrowseEntry with 'matching' Entry widget

=head1 SYNOPSIS

  require Tk::MatchingBE;

  $mw->MatchingBE(-choices => [qw/foo bar baz/])->pack;


=head1 DESCRIPTION

Tk::MatchingBE is a Tk::BrowseEntry which allows for a single selection from
a given list of choices/options.
In order to find the right item in the choices list, the Entry widgets content
is matched against the lists elements as the user types. The first matching
item gets selected and the list is popped up if a match occurs.
Key-press events causing non-matching content of the Entry are ignored.
The only exception here are 'Delete' events. Matching is case insensitive
and metacharacters are disabled (\Q). '<Return>' will select the active entry,
popdown the list and trigger -selectcmd. Possible states of the widget
are undef or a single selection - accessible per value or index.
 Tk::MatchingBE is a Tk::BrowseEntry derived widget.

=head1 METHODS

B<Tk::MatchingBE> supports the following methods:

=over 4

=item B<choices(>[qw/a list of possible choices/]B<)>

Get/Set the choices list (arrayref).

=item B<labels_and_values(>[{label=>'aLabel',value=>'aValue'},{},{}]B<)>

Get/Set the choices list with value/label associations. Labels are displayed
in the Listbox. Selected value can be accessed with get_selected_value

=item B<get_selected_index>

Get the selected index.

=item B<set_selected_index(>anIntegerB<)>

Set the selected index.

=item B<get_selected_value>

Get the selected value. Returns the selected 'value' in case -labels_and_values
has been set. Returns the selected 'label' (Listbox entry) if -choices has
been set.

=item B<set_selected_value>

Sets the selected 'value' in case -labels_and_values has been set. Croaks otherwise.

=back

=head1 OPTIONS

B<Tk::MatchingBE> supports the following options:

=over 4

=item B<-choices>

Get/set the list of possible choices.

=item B<-labels_and_values>

Get/set the choices list with value/label associations (see above).

=item B<-value_variable>

Ties a variable to the widget using 'get/set_selected_value' methods.

=item B<-selectcmd>

A callback to be called when the user selects an entry.

=back

=head1 EXAMPLE

  use Tk;
  use Tk::MatchingBE;

  my $mw = tkinit;
  my $be = $mw->MatchingBE(-choices=>[qw/aaa bbb ccc ddd asd/])->pack;
  $be->set_selected_index(0);
  $mw->Button(-text => 'selected',
              -command => sub{
                  for (qw/get_selected_index
                          get_selected_value/){
                      print $be->$_, "\n";
                  }
              },
          )->pack;

  $mw->Button(-text => 'next_item',
              -command => sub{
                  my $i = $be->get_selected_index;
                  $i = ($i+1) % 5 ;
                  $be->set_selected_index($i);
              },
          )->pack;
  MainLoop;


=head1 SEE ALSO

This module was written for Tk::ChoicesSet. There are others that offer more
flexibility like:

=over 4

=item B<JBrowseEntry>

=item B<JComboBox>

=item B<MatchEntry>

=back

=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

our $VERSION = '0.11';

require Tk::BrowseEntry;
our @ISA = 'Tk::BrowseEntry';
Tk::Widget->Construct('MatchingBE');


sub Populate{
    my ($self,$args) = @_;
    $self->SUPER::Populate($args);
    $self->{_MatchingBE}{selected_index} = undef;
    $self->{_MatchingBE}{value_variable_ref} = undef;
    $self->{_MatchingBE}{values} = undef;
    $self->{_MatchingBE}{value_to_index} = undef;

    my $lv = exists $args->{-labels_and_values} 
                         ? delete $args->{-labels_and_values}
                             : undef;
    my @config_lv;
    if (defined $lv){
        @config_lv = (-labels_and_values => $lv);
    }
    my $entry = $self->Subwidget('entry');
    my $lb    = $self->Subwidget('slistbox');
    $self->ConfigSpecs(-bg => [$entry,undef,undef,'white'],
                       -selectcmd   => ['CALLBACK',undef,undef,undef],
                       -labels_and_values => ['METHOD',undef,undef,undef],
                       -value_variable => ['METHOD',undef,undef,undef],
                   );

    $self->configure(@config_lv,
                     -validate        => 'key',
                     -validatecommand => [$self,'validate'],
                     
                 );
    $entry->bind('<Return>', [$self,'_key_return']);
    $entry->bind('<Up>', [$lb,'UpDown',-1]);
    $entry->bind('<Down>', [$lb,'UpDown',1]);
    $self->OnDestroy(sub{$self->_untie_value_variable});
}

sub validate{
    my $self = shift;
    my @args = @_;
    my $searchstr = $args[0];

    # don't care about programmatic changes of -textvariable
    # -validate => 'key' triggers more than it should...
    # $action == 7 in case of delete key
    # $action == 8 in case of insert key
    
    my $action = $args[4];
    return 1 if ($action < 7);
# print "validating for entry [$self] action is [$action]\n";
    my $is_delete = ($action == 7);

    my @entries = $self->choices;
    my $matched = 0;
    my $index = 0;
    my $allow = 0;

    # don't try to match an empty string
    if ((length $searchstr) > 0){
        for my $entry (@entries){
            eval{$matched =  $entry =~ m/\Q$searchstr/i};
            last if ($matched);
            $index ++;
        }
    }
    my $lb = $self->Subwidget('slistbox')->Subwidget('scrolled');

    if ($matched){
        # set the selection and popup
        $self->_select_index($index);
        $self->PopupChoices;
        $allow = 1;
    }elsif(length $searchstr == 0){
        # we didn't test - empty searchstring -
        # clear selection and popdown :
        $self->_select_index(undef);
        $self->Popdown;
        $allow = 1;
    }elsif($is_delete){
        # allow change in Entry in case of a Key-delete event
        # we didn't get a match so set index to undef
        $self->_select_index(undef);
        $allow = 1;
    }else{
        # we tested through the list without a match
        # don't change our lb selection
        # don't allow for the entries content to change
        $allow = 0; 
    }
    return $allow;
}

sub get_selected_index{
    my $self = shift;
    my $index = $self->{_MatchingBE}{selected_index};
    return $index;
}

sub set_selected_index{
    my $self = shift;
    my $index = shift;
    my $lb = $self->Subwidget('slistbox')->Subwidget('scrolled');
    # get last valid index of listbox
    # index('end') points to the last + 1 element:
    my $max = $lb->index('end') - 1;
    croak "index out of bounds" if ($index || 0) > $max;
    $self->{_MatchingBE}{suspend_selectcmd} = 1;
    eval{
        $self->_select_index($index);
        $self->LbCopySelection;
    };
    $self->{_MatchingBE}{suspend_selectcmd} = 0;
    return '';
}

sub get_selected_value{
    my $self = shift;
    unless ($self->{_MatchingBE}{value_to_index}){
        return  $self->get_selected_label;
    }
    my $index = $self->{_MatchingBE}{selected_index};
    return undef unless (defined $index);
    my $value = $self->{_MatchingBE}{values}[$index];
    return $value;
}

sub get_selected_label{
    my $self = shift;
    my $index = $self->{_MatchingBE}{selected_index};
    # keep listbox from croaking:
    return undef unless (defined $index);
    my $value = $self->Subwidget('slistbox')->get($index);
    return $value;
}
sub set_selected_value{
    my $self = shift;
    my $value = $_[0];
    unless ($self->{_MatchingBE}{value_to_index}){
        croak "no -labels_and_values specified, can't set value in MatchingBE";
    }
    my $index;
    if (! defined $value){
        $index = undef;
    }else{
        $index = $self->{_MatchingBE}{value_to_index}{$value};
        unless( defined $index ){
            croak "can't find index for value [$value],"
                ."can't set value in MatchingBE";
        }
    }
    $self->set_selected_index($index);
}

sub choices{
    my $self = shift;
    my $choices = $_[0];
    unless ($choices){return $self->SUPER::choices}
    $self->{_MatchingBE}{value_to_index} = undef;
    $self->{_MatchingBE}{values} = undef;
    $self->SUPER::choices($choices);
    $self->set_selected_index(undef);
}

sub _select_index{
    my $self = shift;
    my $index = $_[0];
    my $lb = $self->Subwidget('slistbox')->Subwidget('scrolled');;
    $lb->selectionClear(0,'end');
    if (defined $index){
        $lb->selectionSet($index);
        $lb->see($index);
    }else{
        $lb->see(0);
    }
    $self->_cache_index($index);
}


sub LbCopySelection{
    # Copy the selected value from the listbox to the entry
    # if any, otherwise delete the entries content. Popdown...
    # This must be overridden to clear the entry in case of an
    # undefined selection.
    # Default in Tk::BrowseEntry was to select 0 (first element).
    my $self = shift;
    my $index = $self->LbIndex('emptyOK');
    #my $print_index = (defined $index) ? $index : 'undef';
    #print "LbCopySel found index [$print_index]in [$self]\n";
    $self->_cache_index($index);# needed here?
    if (defined $index){
        $self->SUPER::LbCopySelection;
    }else{
        #print "deleting entry content \n";
        $self->Subwidget('entry')->delete(0,'end');
        # handled by BrowseEntry...
        # if ($self->{'_BE_popped'}) {
        $self->Popdown;
	#}
    }
}

sub Popdown{
    # had to override this to call -selectcmd
    # this is the only place where we need to call it
    my $self = shift;
    $self->SUPER::Popdown(@_);
    
    unless ($self->{_MatchingBE}{suspend_selectcmd}){
        my $callback = $self->cget('-selectcmd');
        $callback->Call if $callback;
    }
}

sub _cache_index{
    my $self = shift;
    my $index = $_[0];
    $self->{_MatchingBE}{selected_index} = $index;
}

sub _key_return{
    my $self = shift;
    if ($self->{'_BE_popped'}) {
        $self->LbCopySelection;
    }else{
        # should this popup the list??
    }
    Tk->break;
}

sub value_variable{
    my $self = shift;
    my $varref = $_[0];
    unless ($varref){return $self->{_MatchingBE}{value_variable_ref}}
    $self->_untie_value_variable;
    unless (defined $self->{_MatchingBE}{values}){
        croak "Can't tie a -value_variable unless -labels_and_values "
            ."are set.";
    }
    $self->{_MatchingBE}{value_variable_ref} = $varref;
    my $value = $$varref;
    tie ($$varref, 'MatchingBETier',$self);
  #  if (defined $value){
        $self->set_selected_value($value);
   # }
}

sub _untie_value_variable{
    my $self = shift;
    my $varref = $self->{_MatchingBE}{value_variable_ref} || \0 ;
    untie $$varref;
}

sub labels_and_values{
    my $self = shift;
    my $l_v = $_[0];
    #expecting a structure like:
#      [
#       {label => 'foo', value => 1},
#       {label => 'bar', value => 2},
#       {label => 'baz', value => 3},
#   ];
    unless ($l_v){
        ### called as getter###
        my @labels = $self->SUPER::choices;
        my $values_ref = $self->{_MatchingBE}{values}||[];
        my @r_v;
        my $i = 0;
        for my $label(@labels){
            push @r_v ,{label=>$label, value=>$values_ref->[$i]};
            $i++;
        }
        return \@r_v;
    }
    ### called as setter ###
    my @choices;
    my $index = 0;
    ### untie the value_variable first?? ###
    #$self->_untie_value_variable;
    my $value_to_index = $self->{_MatchingBE}{value_to_index} = {};
    my $values = $self->{_MatchingBE}{values} = [];
    for my $element (@$l_v){
        if (exists $value_to_index->{$element->{value}}){
            croak "MatchingBE: -labels_and_values "
                ."must provide unique values [".$element->{value}."]\n" ;
        }
        $value_to_index->{$element->{value}}= $index;
        push @choices, $element->{label};
        push @$values, $element->{value};
        $index++;
    }
    $self->SUPER::choices(\@choices);
    $self->set_selected_index( undef );
}


package MatchingBETier;

sub TIESCALAR{
    my $class = shift;
    my ( $w) = @_;
    my $tied = bless { mbe => $w,
                      }, $class;
    return $tied;
}

sub FETCH{
    my $self = shift; # tied instance
    return ($self->{mbe})->get_selected_value;
}

sub STORE{
    my $self = shift;
    my $val = shift;
    ($self->{mbe})->set_selected_value($val);
}

1;
