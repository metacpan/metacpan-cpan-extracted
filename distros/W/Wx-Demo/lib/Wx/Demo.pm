#############################################################################
## Name:        lib/Wx/Demo.pm
## Purpose:     wxPerl demo main module
## Author:      Mattia Barbon
## Modified by:
## Created:     20/08/2006
## RCS-ID:      $Id: Demo.pm 3496 2013-04-23 00:23:19Z mdootson $
## Copyright:   (c) 2006-2011 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::Demo;

=head1 NAME

Wx::Demo - the wxPerl demo

=head1 DESCRIPTION

Every demo is a module in the Wx::DemoModules::* namespace.
On startup Wx::Demo collects the lits of Demo Modules, tries to load
each one of them and displays a list of them based on a categorization
within the Demo Modules.

You can also locate Demos based on the widget being use or based
on the event used in the example.

=head2 Demo Modules

Every Demo Module can supply a C<tags> method that should return
extra deep categorization. It should return a reference to a two element
array where the first element is the category hierarchy:  maincat/subcat
and the second element is the title of the given category.

The main categories are hard-coded in the Wx::Demo module
(new, controls, windows, etc...)

Every module can have an C<add_to_tags> method that should return
a list of names of the categories the module belongs to so these
should be strings such as "new", "control", etc... which are 
main categories or "control/xyz" which is a subcategory definde by
one of the Demo modules.

If there is no add_to_tags or if it does not return anything
then the demo can only be found from the list of widgets or events. 
Currently the reason that some packages might have not add_to_tags method
is that some of the demos are implemented as several packages in one file.
In such case only the main package has the add_to_tags method as only that
needs to be added to the list of demos.

Every module must have a C<title> method that returns its title. 
As far as I can see, the titles are usually the same as the filename.


When one of the Demo Modules is selected in the left pane, the Demo will
try to execute its C<window> and if it does not exists then the C<new>
method.

There is also an optional C<file> method in the Demo Modules. I think
it is used in case there are more than one Demo Packages in the same
file.

Some of the Demo Modules use L<Wx::DemoModules::lib::BaseModule> as
a base class.


=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use Wx;

use strict;
use base qw(Wx::Frame Class::Accessor::Fast);

use Wx qw(:textctrl :sizer :window :id);
use Wx qw(wxDefaultPosition wxDefaultSize wxTheClipboard wxWINDOW_VARIANT_SMALL
          wxDEFAULT_FRAME_STYLE wxNO_FULL_REPAINT_ON_RESIZE wxCLIP_CHILDREN);
use Wx::Event qw(EVT_TREE_SEL_CHANGED EVT_MENU EVT_CLOSE);
use File::Slurp;
use File::Basename qw();
use File::Spec;
use UNIVERSAL::require;
use Module::Pluggable::Object;

use Wx::Demo::Source;

our $VERSION = '0.22';

__PACKAGE__->mk_ro_accessors( qw(tree widget_tree events_tree source notebook left_notebook failwidgets) );
__PACKAGE__->mk_accessors( qw(search_term ) );

#if( Wx::wxMAC()) {
    #Modern Mac defaults look better than our settings
#   Wx::SystemOptions::SetOptionInt('window-default-variant', wxWINDOW_VARIANT_SMALL);
#   Wx::SystemOptions::SetOptionInt('mac.listctrl.always_use_generic', 1);
#}

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new
      ( undef, -1, 'wxPerl demo', wxDefaultPosition, [ 800, 600 ],
        wxDEFAULT_FRAME_STYLE|wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );

    # $self->SetLayoutDirection( Wx::wxLayout_RightToLeft() );
    Wx::InitAllImageHandlers();

    # create menu bar
    my $bar  = Wx::MenuBar->new;
    my $file = Wx::Menu->new;
    my $help = Wx::Menu->new;
    my $edit = Wx::Menu->new;

    $file->Append( wxID_EXIT, '' );

    $help->Append( wxID_ABOUT, '' );

    $edit->Append( wxID_COPY,  '' );
    $edit->Append( wxID_FIND,  '' );
    my $find_again = $edit->Append( -1, "Find Again\tF3" );

    $bar->Append( $file, "&File" );
    $bar->Append( $edit, "&Edit" );
    $bar->Append( $help, "&Help" );

    $self->SetMenuBar( $bar );
    $self->{menu_count} = $self->GetMenuBar->GetMenuCount;

    # create splitters
    my $split1 = Wx::SplitterWindow->new
      ( $self, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );
    my $split2 = Wx::SplitterWindow->new
      ( $split1, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );
    my $left_nb = Wx::Notebook->new
      ( $split1, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );
      
    # As per rt#84591
    $split1->SetMinimumPaneSize( 30 );
    $split2->SetMinimumPaneSize( 30 );

    my $tree        = Wx::TreeCtrl->new( $left_nb, -1 );
    my $widget_tree = Wx::TreeCtrl->new( $left_nb, -1 );
    my $events_tree = Wx::TreeCtrl->new( $left_nb, -1 );
    $left_nb->AddPage( $tree,        'Categories', 0 );
    $left_nb->AddPage( $widget_tree, 'Widgets',    0 );
    $left_nb->AddPage( $events_tree, 'Events',     0 );

    my $text = Wx::TextCtrl->new
      ( $split2, -1, "", wxDefaultPosition, wxDefaultSize,
        wxTE_READONLY|wxTE_MULTILINE|wxNO_FULL_REPAINT_ON_RESIZE );
    my $log = Wx::LogTextCtrl->new( $text );
    $self->{old_log} = Wx::Log::SetActiveTarget( $log );

    my $nb = Wx::Notebook->new
      ( $split2, -1, wxDefaultPosition, wxDefaultSize,
        wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );
    my $code = Wx::Demo::Source->new( $nb );

    $nb->AddPage( $code, "Source", 0 );

    $split1->SplitVertically( $left_nb, $split2, 250 );
    $split2->SplitHorizontally( $nb, $text, 300 );

    $self->{tree}          = $tree;
    $self->{widget_tree}   = $widget_tree;
    $self->{events_tree}   = $events_tree;
    $self->{source}        = $code;
    $self->{notebook}      = $nb;
    $self->{left_notebook} = $left_nb;
    $self->{failwidgets}   = [];

    EVT_TREE_SEL_CHANGED( $self, $tree,        sub { on_show_module($tree, @_) } );
    EVT_TREE_SEL_CHANGED( $self, $widget_tree, sub { on_show_module($widget_tree, @_) } );
    EVT_TREE_SEL_CHANGED( $self, $events_tree, sub { on_show_module($events_tree, @_) } );
    EVT_CLOSE( $self, \&on_close );

    EVT_MENU( $self, wxID_ABOUT, \&on_about );
    EVT_MENU( $self, wxID_EXIT, sub { $self->Close } );
    EVT_MENU( $self, wxID_COPY, \&on_copy );
    EVT_MENU( $self, wxID_FIND, \&on_find );
    EVT_MENU( $self, $find_again, \&on_find_again );

    $self->populate_modules;
    $self->populate_widgets;

    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->Show;

    Wx::LogMessage( "Welcome to wxPerl!" );

    return $self;
}

sub on_find {
    my( $self ) = @_;
    $self->get_search_term;
    $self->search;

    return;
}

sub on_find_again {
    my( $self ) = @_;
    if (not $self->search_term) {
        $self->get_search_term;
    }
    $self->search;

    return;
}

sub get_search_term {
    my ($self) = @_;

    my $search_term = $self->search_term || '';
    my $dialog = Wx::TextEntryDialog->new( $self, "", "Search term", $search_term );
    if ($dialog->ShowModal == wxID_CANCEL) {
        $dialog->Destroy;
        return;
    }   
    $search_term = $dialog->GetValue;
    $self->search_term($search_term);
    $dialog->Destroy;
    return;
}
sub search {
    my ($self) = @_;

    my $search_term = $self->search_term;
    return if not $search_term;

    my $code = $self->{source};
    my ($from, $to) = $code->GetSelection;
    my $last = $code->isa( 'Wx::TextCtrl' ) ? $code->GetLastPosition()  : $code->GetLength();
    my $str  = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange(0, $last) : $code->GetTextRange(0, $last);
    my $pos = index($str, $search_term, $from+1);
    if (-1 == $pos) {
        $pos = index($str, $search_term);
    }
    if (-1 == $pos) {
        return; # not found
    }

    $code->SetSelection($pos, $pos+length($search_term));

    return;
}

sub on_close {
    my( $self, $event ) = @_;

    Wx::Log::SetActiveTarget( $self->{old_log} );
    $event->Skip;
}

sub on_about {
    my( $self ) = @_;
    use Wx qw(wxOK wxCENTRE wxVERSION_STRING);

    Wx::MessageBox( "wxPerl demo version $VERSION, (c) 2001-2011 Mattia Barbon\n" .
                    "wxPerl $Wx::VERSION, " . wxVERSION_STRING,
                    "About wxPerl demo", wxOK|wxCENTRE, $self );
}

# TODO: disallow copy when not the code is in focus
# or copy the text from the log window too.
sub on_copy {
    my( $self ) = @_;

    my $code = $self->{source};
    my ($from, $to) = $code->GetSelection;
    my $str = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange($from, $to) : $code->GetTextRange($from, $to);
    if (wxTheClipboard->Open()) {
        wxTheClipboard->SetData( Wx::TextDataObject->new($str) );
        wxTheClipboard->Close();
    }

    return;
}


sub on_show_module {
    my( $tree, $self, $event ) = @_;
    my $module = $tree->GetPlData( $event->GetItem );
    return unless $module;

    $self->show_module( $module );
}

sub _module_file {
    my( $module ) = @_;

    return $module->file if $module->can( 'file' );

    my $mod_file = $module;

    $mod_file =~ s{::}{/}g;
    $mod_file .= '.pm';

    return $INC{$mod_file}
}

sub _add_menus {
    my( $self, %menus ) = @_;

    while( my( $title, $menu ) = each %menus ) {
        $self->GetMenuBar->Insert( $self->{menu_count}, $menu, $title );
    }
}

sub _remove_menus {
    my( $self ) = @_;

    for ($self->{menu_count}+1 .. $self->GetMenuBar->GetMenuCount) {
        $self->GetMenuBar->Remove( $self->{menu_count} )->Destroy;
    }
}

sub activate_module {
    my( $self, $module ) = @_;

    my( $package ) = grep $_->title eq $module,
                     grep $_->can( 'title' ),
                          $self->plugins;
    return unless $package;
    $self->show_module( $package );
    $self->show_demo_window;
}

sub show_demo_window {
    my( $self ) = @_;

    $self->notebook->SetSelection( 1 ) if $self->notebook->GetPageCount == 2;
}

sub show_module {
    my( $self, $module ) = @_;

    $self->source->set_source( scalar read_file _module_file( $module ) );

    my $nb = $self->notebook;
    my $window = $module->can( 'window' ) ? $module->window( $nb ) :
                                            $module->new( $nb );
    my $sel = $nb->GetSelection;

    if( $nb->GetPageCount == 2 ) {
        $nb->SetSelection( 0 ) if $sel == 1;
        $nb->DeletePage( 1 );
        $self->_remove_menus;
    }
    if( ref( $window ) ) {
        if( !$window->IsTopLevel ) {
            $self->notebook->AddPage( $window, 'Demo' );
            $nb->SetSelection( $sel ) if $sel == 1;
        } else {
            $window->Show;
        }
        $self->_add_menus( $window->menu ) if $window->can( 'menu' );
    }
}

my @tags =
  ( [ new        => 'New' ],
    [ controls   => 'Controls' ],
    [ windows    => 'Windows' ],
    [ managed    => 'Managed Windows' ],
    [ dialogs    => 'Dialogs' ],
    [ sizers     => 'Sizers' ],
    [ dnd        => 'Drag & Drop' ],
    [ misc       => 'Miscellanea' ],
    );

sub d($) { Wx::TreeItemData->new( $_[0] ) }

# poor man's insertion sort
sub add_item {
    my( $tree, $id, $module ) = @_;

    my $title = $module->title;
    my( $child, $cookie ) = $tree->GetFirstChild( $id );
    my $childtitle = $child ? $tree->GetItemText( $child ) : '';

    if( !$child || $childtitle gt $title ) {
        $tree->PrependItem( $id, $title, -1, -1, d $module );
    } else {
        my $pchild = $child;
        while( ( $child, $cookie ) = $tree->GetNextChild( $id, $cookie ) ) {
            last unless $child;
            $childtitle = $tree->GetItemText( $child );
            if( $childtitle lt $title ) {
                $pchild = $child;
            } else {
                $tree->InsertItem( $id, $pchild, $title, -1, -1, d $module );
                return;
            }
        }

        $tree->AppendItem( $id, $title, -1, -1, d $module );
    }
}

sub populate_widgets {
    my( $self ) = @_;

    my $widget_tree = $self->widget_tree;
    my $events_tree = $self->events_tree;
    my $widgets = $self->widgets;

    my $wt_root_id = $widget_tree->AddRoot( 'wxPerl', -1, -1 );
    my $et_root_id = $events_tree->AddRoot( 'wxPerl', -1, -1 );

    foreach my $widget (sort keys %$widgets) {
        if ($widget =~ /^EVT/) {
            my $parent_id = $events_tree->AppendItem( $et_root_id, $widget, -1, -1 );
            foreach my $name (sort keys %{ $widgets->{$widget} }) {
                my $id = $events_tree->AppendItem( $parent_id, $name, -1, -1, Wx::TreeItemData->new($name) );
            }
        } else {
            my $parent_id = $widget_tree->AppendItem( $wt_root_id, $widget, -1, -1 );
            foreach my $name (sort keys %{ $widgets->{$widget} }) {
                my $id = $widget_tree->AppendItem( $parent_id, $name, -1, -1, Wx::TreeItemData->new($name) );
            }
        }
    }

    $widget_tree->Expand( $wt_root_id );
    $events_tree->Expand( $et_root_id );
    return;
}

sub populate_modules {
    my( $self ) = @_;
    my $tree = $self->tree;
    my @modules = $self->plugins;

    my $root_id = $tree->AddRoot( 'wxPerl', -1, -1 );
    my %tag_map;

    foreach my $tag ( @tags, map $_->tags, grep $_->can( 'tags' ), @modules ) {
        my( $parent_id, $last );
        if( ( my $last_slash = rindex $tag->[0], '/' ) != -1 ) {
            $parent_id = $tag_map{ substr $tag->[0], 0, $last_slash };
        } else {
            $parent_id = $root_id;
        }
        die "'$tag' has no parent" unless $parent_id;
        next if $tag_map{$tag->[0]};
        my $id = $tree->AppendItem( $parent_id, $tag->[1], -1, -1 );
        $tag_map{$tag->[0]} = $id;
    }

    foreach my $module ( grep $_->can( 'add_to_tags' ), @modules ) {
        foreach my $tag ( $module->add_to_tags ) {
            my $parent_id = $tag_map{$tag};

            unless( $parent_id ) {
                Wx::LogWarning( 'Wrong parent: %s', $tag );
                next;
            }

            add_item( $tree, $parent_id, $module );
        }
    }
    
    if( @{ $self->failwidgets } ) {
    	my $id = $tree->AppendItem( $root_id, 'Not Loaded', -1, -1 );
		$tag_map{fail} = $id;
	}
    
    foreach my $module ( grep $_->can( 'add_to_tags' ), @{ $self->failwidgets } ) {
	    foreach my $tag ( $module->add_to_tags ) {
			my $parent_id = $tag_map{$tag};

			unless( $parent_id ) {
				Wx::LogWarning( 'Wrong parent: %s', $tag );
				next;
			}

			add_item( $tree, $parent_id, $module );
		}
    }
    
    
    

    $tree->Expand( $root_id );
}

sub plugins {
    my( $self ) = @_;
    return @{$self->{plugins}} if $self->{plugins};

    ($self->{plugins}, $self->{widgets}) = $self->load_plugins(sub { Wx::LogWarning( @_ ) });

    return @{$self->{plugins}};
}

sub widgets {
    my( $self ) = @_;
    if (not $self->{widgets}) {
        $self->plugins;
    }

    return $self->{widgets};
}

# allow ignoring load failures
sub load_plugins {
    my( $self , $w ) = @_;
    my %skip;
    my %widgets;
    
    # allow modules to provide a hint module and
    # rplacement info module if they
    # should not be loaded
    my $hintfinder = Module::Pluggable::Object->new
	    ( search_path => [ qw(Wx::DemoHints) ],
	        require     => 0,
	        filename    => __FILE__,
        );
    
    my %hashints = map { 'Wx::DemoModules::' . (split(/::/, $_))[-1] => $_ } $hintfinder->plugins;
    
    # load the core hints
    my %corehints;
    require Wx::DemoHints::CoreHints;
    for my $hint ( Wx::DemoHints::CoreHints->hint_packages ) {
    	my $module = $hint;
    	$module =~ s/DemoHints/DemoModules/;
    	$corehints{$module} = $hint;
    }
        
    my $finder = Module::Pluggable::Object->new
      ( search_path => [ qw(Wx::DemoModules) ],
        require     => 0,
        filename    => __FILE__,
        );

    foreach my $package ( $finder->plugins ) {
        next if $skip{$package};
        my $f = "$package.pm"; $f =~ s{::}{/}g;
        
        # use file and core hints to avoid loading packages
        
        if( $hashints{$package} ) {
            if($hashints{$package}->require && !$hashints{$package}->can_load ) {
           		
           		push( @{ $self->{failwidgets} }, $hashints{$package} );
            	# and skip
            	$skip{$package} = 1;
            	next;
            }
        } elsif( $corehints{$package} ) {
			unless( $corehints{$package}->can_load ) {

				push( @{ $self->{failwidgets} }, $corehints{$package} );
				# and skip
				$skip{$package} = 1;
				next;
			}
        }
        
        if( $package->require ) {
            $self->parse_file($package, $f, $w, \%widgets);
        } else {
            $w->( "Skipping module '%s'", $package );
            $w->( $_ ) foreach split /\n/, $@;
#            delete $INC{$f}; # for Perl 5.10
#            $INC{$f} = 'skip it';
            $INC{$f} = 'skip it' unless exists $INC{$f};
            $skip{$package} = 1;
        };
    }

    # search inner packages (needed as there some files with multiple packages inside)
    my @plugins = Module::Pluggable::Object->new
      ( search_path => [ qw(Wx::DemoModules) ],
        require     => 1,
        filename    => __FILE__,
        except      => [ ( keys (%skip) ) ],
        )->plugins;
    return (\@plugins, \%widgets);
}

sub parse_file {
    my ($self, $package, $path, $w, $widgets) = @_;
    
    if (open my $fh, '<', $INC{$path}) {
        while (my $line = <$fh>) {
            for ($line =~ /\b(Wx(::\w+)+)\b/g) {
                my $name = $1;
                next if $name =~ /^Wx::DemoModules/;
                $widgets->{$name}{$package} = 1;
            }
            for ($line =~ /\b(wx\w+)\b/g) {
                $widgets->{$1}{$package} = 1;
            }
            for ($line =~ /\b(EVT_\w+)\b/g) {
                $widgets->{$1}{$package} = 1;
            }
        }
    } else {
        $w->("Could not open $INC{$path} for $path $!");
    }

    return;
}

sub get_data_file {
    my( $class, $file ) = @_;
    ( undef, my $filename ) = caller;

    my $dir = File::Basename::dirname( $filename );
    until( -d File::Spec->catdir( $dir, 'files' ) ) {
        $dir = File::Basename::dirname( $dir )
    }

    return File::Spec->catdir( $dir, 'files', $file );
}


1;
