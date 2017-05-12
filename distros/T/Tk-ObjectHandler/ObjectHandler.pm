package Tk::ObjectHandler;

########################################################################
#                                                                      #
#              Tk::ObjectHandler, by Simon Parsons                     #
#                                                                      #
# This perl module is distributed under the terms of the GNU           #
# Public Licence and the Perl Artistic Licence.                        #
#                                                                      #
# Copyright (C) Simon Parsons, 2002                                    #
########################################################################

use strict;
use vars qw($VERSION $AUTOLOAD);
use Text::Wrap qw($columns wrap);
use Tk;
use Carp qw(carp croak);
$VERSION = '0.3';

use vars qw($AUTOLOAD);

sub new {
	my $class = shift;

	$class = ref($class) || $class;

	my $self = {
		'_OBJECT'   => new MainWindow(@_),
		'_COMMENT'  => '',
		'_CAN_LOOP' => 1,
	};

	bless $self, $class;

	return $self;
}

sub Loop {
	my $self = shift;

	if($self->{'_CAN_LOOP'} == 1) {
		MainLoop;
	}
}

sub add_widget {
	my $self = shift;
	my $type = shift;
	my $name = shift;

	my $class = ref($self) or croak '$self os not a valid object';

	return undef if(exists $self->{'_WIDGETS'}->{$name});

	$self->{'_WIDGETS'}->{$name} = {
		'_OBJECT' => $self->_make($type, @_),
		'_COMMENT'  => '',
		'_CAN_LOOP' => 0,
	};

	bless $self->{'_WIDGETS'}->{$name}, $class;

	return $self->{'_WIDGETS'}->{$name};
}	

sub comment {
	my $self = shift;
	my $comment = shift || undef;

	$self->{'_COMMENT'} = $comment if(defined $comment);
	$self->{'_COMMENT'} =~ s/\s+/ /g;
	return $self->{'_COMMENT'} || '';
}

sub getobj {
	return $_[0]->{'_OBJECT'};
}

# Syntax (class, type', {args}
sub _make {
	my $self = shift;
	my $type = shift;

	eval "require Tk::$type;";
	require "Tk/$type.pm" unless($@);
	
	if($_[0] and substr($_[0],0,1) ne '-') {
		eval "require Tk::$_[0];";
		require "Tk/$_[0].pm" unless($@);
	}

	$type = $self->{'_OBJECT'}->$type(@_);

	return $type;
}

sub report {
	my $self = shift;
	my $tab = shift || 0;

	my $result = '';
	my $count = 0;

	if($tab+0 == 0) {
		$result = "Structural layout of $0\n\n";
		$result .= _make_entry($tab, ref($self->getobj), $self->{'_COMMENT'});
	} else {
		$result = '';
	}

	foreach (keys(%{$self->{'_WIDGETS'}})) {
		$result .= _make_entry($tab, "$_ - " . ref($self->{'_WIDGETS'}->{$_}->getobj), $self->{'_WIDGETS'}->{$_}->{'_COMMENT'});
		$result .= $self->{'_WIDGETS'}->{$_}->report($tab + 1);
	}
	$result .= "\n" if(keys(%{$self->{'_WIDGETS'}}));

	return $result;
}


sub _make_entry {
	my $tab = shift || 0;
	my $message_text = shift || ' ';
	my $comments = shift || ' ';

	$columns = 39; # for wrap
	my @list = split(/\n/, wrap("", "", $message_text));
	my @list2 = split(/\n/, wrap("", "", $comments));

	my $big = $#list > $#list2 ? $#list : $#list2;
	my $line = '';
	for(my $i = 0; $i <= $big; $i++) {
		if(defined $list[$i]) {
			$line .= join('', " " x $tab, $list[$i], " " x (40 - $tab - length($list[$i])));
			if(defined $list2[$i]) {
				$line .= $list2[$i];
			}
		} else {
			$line .= join('', " " x 40, $list2[$i]);
		}
		$line .= "\n";
	}
	return $line;

}


sub DESTROY {
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or croak '$self is not an object';

	my $name = $AUTOLOAD;
	$name =~ s/.*:://;

	if(exists $self->{'_WIDGETS'}->{$name}) { 
		return $self->{'_WIDGETS'}->{$name};
	} else {
		return $self->{'_OBJECT'}->$name(@_);
	}
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=pod

=head1 NAME

Tk::ObjectHandler - Perl extension for Tk

=head1 SYNOPSIS

  use Tk::ObjectHandler;
  my $tk = Tk::ObjectHandler->new();
  $tk->add_widget("Button","but1", -text, "Press Me", -command => sub{ $tk->destroy(); });
  $tk->but1->pack(-fill => "both");
  $tk->Loop;

=head1 ABSTRACT

Tk::ObjectHandler provides an automated method for creating, ordering and cataloging the
variables used to hold Tk widgets. Rather than having to use a confusing number of individual
holders ObjectHandler arranges the widgets so that widgets that are packed onto a parent
widget are called via the parent widget.

=head1 DESCRIPTION

Creating a program in Tk can sometimes become confusing due to the number of variables
needed to hold pointers to widgets. Tk::ObjectHandler is an attempt to provide a generic
method for providing a logical heirarchy for widgets, allowing easy reference through 
one entrance point.

When created, the Tk::ObjectHandler object sets up a Tk::Toplevel widget and wraps it in
it's own administration code. This code allows you to set up a heirarchy of widgets all
accessable through one entry point. For example, imagine a simple report window, say with
a couple of labels and a close button.  In traditional Tk you would create these like the
following:

	my $mw = new MainWindow();
	my $label1 = $mw->Label(-text => 'Title text');
	my $label2 = $mw->Label(-text => 'Body text of the message window');
	my $button = $mw->Button(-text => 'Close', -command => sub { $mw->destroy; });
	$label1->pack();
	$label2->pack();
	$button->pack();

Using ObjectHandler, there is only one variable used:

	my $mw = Tk::ObjectHandler->new();
	$mw->add_widget('Label', 'Label1', -text => 'Title text');
	$mw->add_widget('Label', 'Label2', -text => 'Body text of the message window');
	$mw->add_widget('Button', 'button', -text => 'Close', -command => sub { $mw->destroy; });
	$mw->Label1->pack();
	$mw->Label2->pack();
	$mw->button->pack();

So, what is the difference? Well, in the example above, not much really, but in larger programs the number
of variables required can become hard to keep track of leading to duplication and slowing development time
while you play 'hunt the variable'. ObjectHandler overcoes this problem in two ways. First, objects are refered
to in a structured format, you can only refer to a widget through its parent, like below:

	$mw->frame->label1->configure(...) 

...would configure the widget label1 that is attatched to the frame that is attatched to the main window. 

Using this heirarcal method of naming means that you can use the following as valid widget names:

	$mw->frame1->label1...
	$mw->frame2->label1...
	$mw->frame3->label1...
	$mw->frame4->label1...

...which can save wear and tear on the brain when thinking of variable names ;)

The second method in which ObjectHandler helps is with it's self-documenting code. Using the report method
you can automatically generate reports on the widgets and sub widgets (and sub-sub widgets etc) of 
the whole program or any section thereof. As well as names and widget types, ObjectHandler also allows you
to inser comments into the tree.

=head1 CONSTRUCTOR

=over 4

=item new([ARGS])

New initiates the ObjectHandler and creates a standard Tk::Toplevel widget. See C<Tk::TopLevel>
for ARGS.

=back

=head1 METHODS

=over 4

=item $obj->add_widget(type, name[, ARGS])

Add widget creates an object of the type I<type> and adds it as a sub object of the object I<$obj>
with a name I<name>. In other words:

	$obj->add_widget('Frame', 'Frame1');

Creates a frame widget under $obj that can be accessed by $obj->Frame1:

	$obj->Frame1->add_widget('Label', 'L1', -text => 'This is a test');

This would create another widget, a label this time, under the Frame1 frame and give it the text
'This is a test'. For a description of ARGS see the perldoc or manpage for the widget you wish to
create.

=item $obj->comment([text])

If called with an argument this method attatches the argument to the object. If called without an argument
it returns any existing argument. This comment is included in the widget report. See I<report> below.

=item $obj->report()

This method returns a string containing a report of the current widget and all widgets below it. Included for
each widget is it's name, it's type and any comment attatched to it with the I<$obj->comment> method. This is
a documentation tool, allowing for a simple method to describe the structure of your program. A sample report
is as follows:

Structural layout of snake.pl

MainWindow
reportwin - Tk::Toplevel                 
 title - Tk::Label                       
 text - Tk::Label                        
 close - Tk::Button                      

 field - Tk::Canvas                       
  score - Tk::Frame                        
  snake_length - Tk::Label                
  score - Tk::Label                       
  l1 - Tk::Label                          
  l3 - Tk::Label                          

  message - Tk::Frame                      
   messages - Tk::Label                    

  menu - Tk::Frame                      This  comment could describe 
  					this menubar, telling us about the
					buttons.
   help - Tk::Menubutton                   
   game - Tk::Menubutton                   
   rep - Tk::Menubutton                    


	   

=item $obj->getobj()

This returns the windget in Tk form. This is intended for use with things like fonts, etc, that
are included as arguments in other widgets.

=back

=head1 STANDARD TK COMMANDS

All commands that a widget could normally use can still be used by a widget created with object handler.
Grid, pack, configure etc are accessed in the normal way, I<$mw-E<gt>widget-E<gt>configure()> for example.

=head1 AUTHOR

Simon Parsons caillte@ityen.freeserve.co.uk

=head1 COPYRIGHT

Copyright (C) 2001-2002, Simon Parsons.
This module is distributed under the terms and conditions of the GNU public licence
and the Perl Artistic Licence

=head1 SEE ALSO

perl(1), Tk.

=head1 TODO

Add variable storage to the object heirarchy.

=cut


