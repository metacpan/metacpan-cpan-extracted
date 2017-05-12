# RadiobuttonGroup.pl
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

$Tk::RadiobuttonGroup::VERSION = '0.2.2';
package Tk::RadiobuttonGroup;

use Data::Dumper;

use Tk::widgets qw( Frame Radiobutton );
use base qw( Tk::Frame );
use strict;

use Tie::IxHash;

Construct Tk::Widget 'RadiobuttonGroup';

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
	my $thing = undef;
	$self->{'_variable'} = \$thing;
	$self->{'_orientations'} = {
		horizontal => 'left',
		vertical => 'top'
	};
		
	$self->ConfigSpecs(
		DEFAULT => ['ADVERTISED'],
		-command => ['CALLBACK', 'command', 'Command', sub { }],
		-variable => ['METHOD', 'variable', 'Variable', { }],
		-list =>	['METHOD', 'list', 'List', { }],
		-orientation => ['METHOD', 'orientation', 'Orientation', 'horizontal'],
	);
	
#	$self->Delegates( );
	
}


sub list {
	my ($self, $val) = @_;

	if (defined($val)) {
		# Remove old children
		foreach my $child ($self->Descendants('Radiobutton')) {
			$child->destroy();	
		}
		# Add radiobuttons
		$val = $self->_newhash($val);
		foreach my $item (keys(%$val)) {
			$self->Component(
				Radiobutton => $item,
				-text => $item,
				-value => $val->{$item},
				-command => sub {
					$self->Callback('-command');
				},
				-variable => $self->{'_variable'},
			)->pack(
				-side => $self->{'_orientations'}{$self->{'_orientation'}},
				-anchor => 'w'
			);
		}
	} else {
		my $result = { };
		foreach my $child ($self->Descendants('Radiobutton')) {
			$result->{$child->cget('-text')} = $child->cget('-value');
		}
		return $result;
	}

}

sub variable {
	my ($self, $val) = @_;

#print Dumper($val);	
	if (defined($val)) {
		$self->{'_variable'} = $val;
	
		# Set the variable of all radiobuttons
		foreach my $child ($self->Descendants('Radiobutton')) {
			$child->configure(
				-variable => $self->{'_variable'}
			);
		}
		my $obj = $self->Subwidget($$val);
		if (defined($obj)) {
			$obj->select()
		}
	} else {
		my $result = $self->{'_variable'};
		return $result;
	}

}

sub orientation {
	my ($self, $val) = @_;
	
	if (defined($val)) {
		$self->{'_orientation'} = $val;
		foreach my $child ($self->Descendants('Radiobutton')) {
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
__END__
=head1 NAME

Tk::RadiobuttonGroup - widget displays and manages a group of related radiobuttons

=head1 SYNOPSIS

	use Tk::CheckbuttonGroup;

	my($top) = MainWindow->new();
	my $selected = 'two';
	my $radiobuttongroup = $top->RadiobuttonGroup (
		-list => [qw( one two three four five )],
		-orientation => 'vertical',
		-variable => \$selected,
		-command => sub {
			print @selected, "\n";
		}
	);

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<list>

=item Class: B<List>

=item Switch: B<-list>

The names for the radiobuttons to be contained in this widget. If given as a list reference, the same value is used for the radiobutton's label and its value.  If given as a hash reference, the keys are used as each radiobutton's label, and the values as their values.  If given a list reference whose first element is a list reference, the sublist will be treated as a set of ordered key value pairs which is then treated as an ordered hash.

=item Name: B<orientation>

=item Class: B<Orientation>

=item Switch: B<-orientation>

May be 'vertical' or 'horizontal'.  Specifies how the radiobuttones are stacked.

=item Name: B<variable>

=item Class: B<Variable>

=item Switch: B<-variable>

A reference to a scalar, whose value is that of the selected radiobutton, and is updated as the user interacts with the widget.  This variable is not watched, and so state of the widget is only updated by changing the -variable option.

=item Name: B<command>

=item Class: B<Command>

=item Switch: B<-command>

Specifies a perl/Tk callback to associate with all of the radiobuttons.

=back

=head1 DESCRIPTION

Displays a set of related radiobuttones with a frame in vertical or horizontal orientation.

All radiobuttones are advertised with the names given in the -list option.

Any additional options which are given to this widget are applied to all of the radiobuttons it manages.

=head1 BUGS

The reference passed in the -variable option is not watched, and so the radiobuttons will not automatically update themselves if the scalar given in that reference changes.

=head1 AUTHOR

By: Joseph Annino <jannino@jannino.com> http://www.jannino.com

Copyright (c) 2002 American Museum of Natural History. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
