package Tk::EntrySet;
use strict;
use warnings;
use Carp;
#use Data::Dumper;


=head1 NAME

Tk::EntrySet - display/edit a list of values in a Set of Widgets.

=head1 SYNOPSIS

  require Tk::EntrySet;

  my $valuelist = [];
  my $instance = $main_window->EntrySet()->pack;
  $instance->configure(-valuelist_variable => \$valuelist);
  $instance->valuelist([qw/foo bar baz/]);


=head1 DESCRIPTION

Tk::EntrySet creates a Set of widgets to display/edit a list of values.
The widget class is configurable. Tk::EntrySet adds/removes widgets to match
the size of the valuelist. If a user deletes an entrywidgets content, the
value is deleted from the valuelist and the entry is removed from the set
on view update. View updates are by default bound to <Return> events.
This is configurable through the -callback_installer option.
The last widget in the Set is always empty to allow users to append values
to the list.
 Tk::EntrySet is a Tk::Frame derived widget.



=head1 METHODS

B<Tk::EntrySet> supports the following methods:

=over 4

=item B<valuelist(>[qw/a list of values/]B<)>

Get/Set the valuelist (arrayref)

=back

=head1 OPTIONS

B<Tk::EntrySet> supports the following options:

=over 4

=item B<-entryclass>

A Tk widget class to be used for the entrywidgets. Defaults to 'Entry'.

=item B<-entryoptions>

Options to be passed to each entry on creation (arrayref).

=item B<-getter>

A coderef which is used by Tk::EntrySet to read the Entrywidgets content.
It gets passed the Entrywidget instance and is expected to return its content.
Defaults to
 sub{ $_[0]->get }, which is suitable for Tk::Entry.

=item B<-setter>

A coderef which is used by Tk::EntrySet to write the Entrywidgets content.
It gets passed the Entrywidget instance and the new value. Defaults to
 sub{ $_[0]->delete(0,'end');
      $_[0]->insert('end',$_[1])
 }, which is suitable for Tk::Entry.

=item B<-callback_installer>

A coderef which is called after each Entrywidgets instantiation.
The callback_installer gets passed the Entrywidget and a coderef that will
update the Tk::EntrySet view when called. Defaults to
 sub{$_[0]->bind('<Key-Return>',$_[1])}.

=item B<-empty_is_undef>

If set to true (default) empty strings will be treated like undef.
Undef elements will be removed from the list and from the EntrySet on
view updates. 

=item B<-unique_values>

If set to true (default) duplicate elements will be removed on view updates.

=item B<-valuelist>

Get/Set the list of values (arrayref).

=item B<-valuelist_variable>

Ties a variable (scalarref) to the -valuelist atribute.
This is a Scalar Tie only.

=item B<-changed_command>

A Callback that is called after the valuelist is updated on user interaction.
By default -changed_command is triggered if the user hits <Return> in any of
the Entries.
(See -callback_installer above if you want to change that.)


=back

=head1 Examples

  use strict;
  use warnings;

  use Tk;

  my $mw = MainWindow->new ;
  require Tk::EntrySet;

  my $valuelist = [];
  my $entryset = $mw->EntrySet()->pack;
  $entryset->configure(-valuelist_variable => \$valuelist);
  $entryset->valuelist([qw/foo bar baz/]);

  # use another entryclass:

  my $num_set = $mw->EntrySet(-entryclass => 'NumEntry')->pack;
  $num_set->valuelist([3,15,42]);

  # use a BrowseEntry  with custom get/set/callback_installer:

  my $getter = sub{ $_[0]->Subwidget('entry')->get};
  my $setter = sub{my $e = $_[0]->Subwidget('entry');
                   $e->delete(0,'end');
                   $e->insert('end', $_[1]);
              };
  my $inst = sub{$_[0]->bind('<Key-Return>' ,$_[1]);
                 $_[0]->configure(-browsecmd => $_[1]);
           };
  my $mbe = $mw->EntrySet(-entryclass   => 'BrowseEntry',
                          -entryoptions => [-choices => [qw/ a b c d /]],
                          -getter       => $getter,
                          -setter       => $setter,
                          -callback_installer => $inst,
                        )->pack(-fill   => 'both',
                                -expand => 1);
  $mbe->valuelist([qw/a c/]);

  MainLoop;




=head1 AUTHOR

Christoph Lamprecht, ch.l.ngre@online.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Christoph Lamprecht

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut

our $VERSION = '0.11';

our @ISA = 'Tk::Frame';
Tk::Widget->Construct('EntrySet');

sub default_entryclass{
    return 'Entry';
}
sub default_getter{
    return sub{$_[0]->get };
}
sub default_setter{
    return sub{
        $_[0]->delete(0,'end');
        $_[0]->insert('end',$_[1]);
    };
}
sub default_callback_installer{
    return sub{
        $_[0]->bind('<Key-Return>',$_[1])
    };
}

sub Populate{
    my ($self,$args) = @_;
    $self->{_EntrySet}{entry_pool}= [];
    $self->{_EntrySet}{entries}= [];
    $self->SUPER::Populate($args);
    my $default_entryclass          = $self->default_entryclass;
    my $default_getter              = $self->default_getter;
    my $default_setter              = $self->default_setter;
    my $default_callback_installer  = $self->default_callback_installer;
    $self->ConfigSpecs(-entryclass         => ['PASSIVE',undef,undef,
                                               $default_entryclass],
                       -entryoptions       => ['PASSIVE',undef,undef,[]],
                       -getter             => ['PASSIVE',undef,undef,
                                               $default_getter],
                       -setter             => ['PASSIVE',undef,undef,
                                               $default_setter],
                       -changed_command    => ['CALLBACK',undef,undef,undef],
                       -callback_installer => ['PASSIVE',undef,undef,
                                               $default_callback_installer],
                       -empty_is_undef     => ['PASSIVE',undef,undef,1],
                       -valuelist          => ['METHOD',undef,undef,undef],
                       -unique_values      => ['PASSIVE', undef,undef,1],
                       -valuelist_variable => ['METHOD',undef,undef,undef],
                   );
    my $valuelist= exists $args->{-valuelist}
        ? delete $args->{-valuelist}
            : undef;
    if( $valuelist ){
        $self->afterIdle(sub{$self->valuelist($valuelist)});
    }
    $self->OnDestroy(sub{$self->untie_valuelist_variable});

}


sub new_entry{
    my $self = shift;
    my $pool = $self->{_EntrySet}{entry_pool};
    my $entry = shift @$pool;
    unless ($entry){
        # we haven't got one - create
        my $class = $self->cget('-entryclass');
        my @options = @{$self->cget('-entryoptions')};
        $entry = $self->$class(@options);
        my $installer = $self->cget(-callback_installer);
        $installer->($entry,
                     sub{
                         $self->afterIdle(
                             sub{$self->valuelist;
                                 $self->Callback('-changed_command');
                             });
                     });
    }
    # add entry to the active entries list
    push @{$self->{_EntrySet}{entries}}, $entry;
    return $entry;
}

sub remove_entry{
    my $self = shift;
    my $entry = shift;
    croak "entry does not exist" unless Tk::Exists($entry);
    # remove from the list of active entries

    my $i = 0;
    my @entries = @{$self->{_EntrySet}{entries}};
    for my $each (@entries){
        if($each eq $entry){
            splice @{$self->{_EntrySet}{entries}},$i,1;
            last;
        }
        $i++ ;
    }
    # add to the pool
    my $pool = $self->{_EntrySet}{entry_pool};
    push @$pool, $entry;
    $entry->packForget;
    my $last_entry = $entries[$#entries];
    $last_entry->focus;

}


sub valuelist{ # get/set valuelist (Arrayref)
    my $self = shift;
    my ($valuelist) = @_;
    if ($valuelist){
        $self->set_valuelist($valuelist);
    }else{
        $valuelist = $self->get_valuelist;
    }
    return $valuelist;
}

### set_valuelist expects an arrayref of values to set.
### it creates a new entry for each value and adds an undefed
### entry to the end of the list
sub set_valuelist{
    my $self = shift;
    my ($valuelist) = @_;
    $self->clear_valuelist;
    for my $value (@$valuelist, undef){
        my $new = $self->new_entry;
        $self->write_entry($new,$value);
        $new->pack( -fill   => 'x',
                    -expand => 1 );
    }
}

### get_valuelist returns an arrayref of values
### it performs a 'cleanup' deleting undefed entries
### and adds an undefed entry to the end of the list
### if necessary
sub get_valuelist{
    my $self = shift;
    # operate on a copy
    my @entries = @{$self->{_EntrySet}{entries}};
    my $valuelist = [];
    # test index of last entry to see if we need a new one
    # (set to undef) at the end
    if (scalar @entries  == 0 # we have no entry displayed yet
        or(                   # or last entry has defined content:
           defined ( $self->read_entry($entries[$#entries]) )
       ) ){
            my $new = $self->new_entry;
            $self->write_entry($new,undef);
            $new->pack( -fill   => 'x',
                        -expand => 1 );
         #   print "adding a new entry at the bottom: $new\n";
    } else {
        # the last entry is empty - ignore its content
        # for the return list
        my $ignore = pop @entries;
       # print "ignoring last entry: $ignore\n";
    }
    my $unique = $self->cget('-unique_values');
    my %seen;
    my $empty_is_undef = $self->cget('-empty_is_undef');
    for my $entry (@entries) {
        my $value = $self->read_entry($entry);
        if ($empty_is_undef
            and (defined $value)
            and ($value eq '')){
            undef $value;
        }
        if (defined $value
            and ( (! $seen{$value}) || (! $unique) )
        ) {
            push @$valuelist , $value;
            $seen{$value} = 1;
        } else {
          #  print "removing entry[$entry] with value [$value]\n";
            $self->remove_entry($entry);
        }
    }
    return $valuelist;
}

sub clear_valuelist{
    my $self = shift;
    my @entries = @{$self->{_EntrySet}{entries}};
    for my $e (@entries){
        $self->remove_entry($e);
    }
}

sub valuelist_variable{
    my $self = shift;
    my $varref = shift;
    $self->untie_valuelist_variable;
    tie ($$varref, 'ESTier', $self);
    $self->{_EntrySet}{valuelist_variable_ref} = $varref;
}

sub untie_valuelist_variable{
    my $self = shift;
    my $oldref = $self->{_EntrySet}{valuelist_variable_ref} || \0;
    untie ($$oldref);
}

sub read_entry{
    my $self = shift;
    my $entry = $_[0];
    my $reader = $self->cget(-getter);
    return $reader->($entry);
}
sub write_entry{
    my $self = shift;
    my ($entry,$value) = @_;
    my $writer = $self->cget(-setter);
    $writer->($entry,$value);
}

package ESTier;

sub TIESCALAR{
    my $class = shift;
    my ( $w) = @_;
    my $tied = bless { es => $w,
                      }, $class;
    return $tied;
}

sub FETCH{
    my $self = shift; # tied instance
    return ($self->{es})->cget('-valuelist');
}

sub STORE{
    my $self = shift;
    my $val = shift;
    ($self->{es})->configure(-valuelist => $val);
    ($self->{es})->cget('-valuelist');
}

1;
