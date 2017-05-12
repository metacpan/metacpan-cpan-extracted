# CheckbuttonGroup.pl
# Version: 0.2.2
#
# By: Joseph Annino - jannino@jannino.com - http://www.jannino.com
# Copyright 2002 American Museum of Natural History
#
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

$Tk::CheckbuttonGroup::VERSION = '0.2.2';
package Tk::CheckbuttonGroup;

use Tk::widgets qw( Frame Checkbutton );
use base qw( Tk::Frame );
use strict;

use Tie::IxHash;

Construct Tk::Widget 'CheckbuttonGroup';

sub ClassInit {
	my ($class, $mw) = @_;
	$class->SUPER::ClassInit($mw);
}

sub Populate {
	my ($self, $args) = @_;
		
	$self->SUPER::Populate($args);	
	
	#
	# configure the mega-widget
	#

	$self->{'_orientations'} = {
		'horizontal' => 'left',
		'h' => 'left',
		'vertical' => 'top',
		'v' => 'top',	
	};
	$self->{'_orientation'}	= 'horizontal';
	
	$self->ConfigSpecs(
		DEFAULT => ['ADVERTISED'],
		-command => ['CALLBACK', 'command', 'Command', sub { }],
		-variable => ['METHOD', 'variable', 'Variable', [ ]],
		-list =>	['METHOD', 'list', 'List', { }],
		-orientation => ['METHOD', 'orientation', 'Orientation', 'horizontal'],
	);
	
#	$self->Delegates( );
	
}


sub list {
	my ($self, $val) = @_;

	if (defined($val)) {
		# Remove old children
		foreach my $child ($self->Descendants('Checkbutton')) {
			$child->destroy();	
		}
		# Add checkboxes
		$val = $self->_newhash($val);
		foreach my $item (keys(%$val)) {
			$self->Component(
				Checkbutton => $item,
				-text => $item,
				-onvalue => $val->{$item},
				-command => sub {
					my $widget = $Tk::widget;
					my $onvalue = $widget->cget('-onvalue');
					my @todelete = ( );
					for (my $i = 0; $i < @{$self->{'_variable'}}; $i ++) {
						if ($self->{'_variable'}[$i] eq $onvalue) { push(@todelete, $i); }  
					}
					foreach (@todelete) {
						splice(@{$self->{'_variable'}}, $_, 1);
					}
					if (${$widget->cget('-variable')} eq $onvalue) {
						push (@{$self->{'_variable'}}, $onvalue);
					}
					$self->Callback('-command');	
				}
			)->pack( 
				-side => $self->{'_orientations'}{$self->{'_orientation'}},
				-anchor => 'w'
			);
		}
		$self->configure( -variable => $self->{'_variable'} );
	} else {
		my $result = { };
		foreach my $child ($self->Descendants('Checkbutton')) {
			$result->{$child->cget('-text')} = $child->cget('-onvalue');
		}
		return $result;
	}

}

sub variable {
	my ($self, $val) = @_;

	if (defined($val)) {
		if ( ref($val) ne 'ARRAY' ) { 
			$val = [ split(',',$$val) ];
		}
#print Dumper('--set', $val);	
	
		# Turn off all checkboxes
		foreach my $child ($self->Descendants('Checkbutton')) {
			$child->deselect();
		}
		# Turn on the ones asked for
		foreach my $item (@$val) {
			my $obj = $self->Subwidget($item);
			if (defined($obj)) {
				$obj->select();
			}
		}
		# Save the variable
		$self->{'_variable'} = $val;
	} else {
#print Dumper('--get', $self->{'_variable'});
		return $self->{'_variable'};
	}

}

sub orientation {
	my ($self, $val) = @_;
	
	if (defined($val)) {
		$self->{'_orientation'} = $val;
		foreach my $child ($self->Descendants('Checkbutton')) {
			$child->packForget();
			$child->pack(
				-side => $self->{'_orientations'}{$self->{'_orientation'}},
				-anchor => 'w'
			);
		}			
	} else {
		return $self->{'_orientation'};
	}

}


sub _newhash {
	my ($self, $var) = @_;

	my %hash;
	my @list; 

	if (ref($var) eq 'HASH') {
		tie(%hash, 'Tie::IxHash', %{$var});
		return \%hash;
	}
	if (ref($var) eq 'ARRAY') {
		if (ref($var->[0]) eq 'ARRAY') {
			# ( one => 1, two => 2 ) format
			tie(%hash, 'Tie::IxHash', @{$var->[0]});
			return \%hash;
		} else {
			foreach my $item (@{$var}) {
				push(@list, $item, $item);
			}
		}
	}
	if (!ref($var)) {
		foreach my $item (split(',',$var)) {
			push(@list, $item, $item);			
		}
	}
	tie(%hash, 'Tie::IxHash', @list);
	return \%hash;
	
}

1;
# Preloaded methods go here.

1;
__END__

=head1 NAME

Tk::CheckbuttonGroup - widget displays and manages a group of related checkbuttons

=head1 SYNOPSIS

	use Tk::CheckbuttonGroup;

	my($top) = MainWindow->new();
	my @selected = qw(two four);
	my $checkbuttongroup = $top->CheckbuttonGroup (
		-list => [qw( one two three four five )],
		-orientation => 'vertical',
		-variable => \@selected,
		-command => sub {
			print @selected, "\n";
		}
	);

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<list>

=item Class: B<List>

=item Switch: B<-list>

The names for the checkbuttons to be contained in this widget. If given as a list reference, the same value is used for the checkbutton's label and its value.  If given as a hash reference, the keys are used as each checkbutton's label, and the values as their values.  If given a list reference whose first element is a list reference, the sublist will be treated as a set of ordered key value pairs which is then treated as an ordered hash.

=item Name: B<orientation>

=item Class: B<Orientation>

=item Switch: B<-orientation>

May be 'vertical' or 'horizontal'.  Specifies how the checkboxes are stacked.

=item Name: B<variable>

=item Class: B<Variable>

=item Switch: B<-variable>

A reference to an array, whose elements contain the values of all checked checkbuttons, and is updated as the user interacts with the widget.  May also be a comma delimited string scalar.  This variable is not watched, and so state of the widget is only updated by changing the -variable option.

=item Name: B<command>

=item Class: B<Command>

=item Switch: B<-command>

Specifies a perl/Tk callback to associate with all of the checkbuttons.

=back

=head1 DESCRIPTION

Displays a set of related checkboxes with a frame in vertical or horizontal orientation.

All checkboxes are advertised with the names given in the -list option.

Any additional options which are given to this widget are applied to all of the checkbuttons it manages.

=head1 BUGS

The reference passed in the -variable option is not watched, and so the checkbuttons will not automatically update themselves if the list given in that reference changes.

=head1 AUTHOR

Joseph Annino <jannino@jannino.com> http://www.jannino.com

Copyright (c) 2002 American Museum of Natural History. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
