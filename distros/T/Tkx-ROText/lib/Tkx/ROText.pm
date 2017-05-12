package Tkx::ROText;
use strict;
use warnings;

use Carp qw'croak';
use Tkx;
use base qw(Tkx::widget Tkx::MegaConfig);

our $VERSION = '0.06';

__PACKAGE__->_Mega('tkx_ROText');

__PACKAGE__->_Config(
	-state  => ['METHOD'],
	DEFAULT => ['.text'],
);


#-------------------------------------------------------------------------------
# Method  : _Populate
# Purpose : Create a new Tkx::ROText widget
# Notes   : 
#-------------------------------------------------------------------------------
sub _Populate {
	my $class  = shift;
	my $widget = shift;
	my $path   = shift;
	my %opt    = (-state => 'readonly', @_);
	my $state  = delete $opt{-state}; # use custom handler for this option

	# create the widget
	my $self = $class->new($path)->_parent
		->new_frame(-name => $path, -class => 'Tkx_ROText');
	$self->_class($class);

	my $text = $self->new_text(-name => 'text', %opt);
	$text->g_pack(-fill => 'both', -expand => 1);

	# Rename the widget to make it private. This enables us to stub the
	# insert/delete methods and make it read-only. Calling _readonly() sets up
	# the handlers for public/private aliasing so that calls to the configure()
	# method work.
	Tkx::rename($text, $text . '.priv');
	$self->_readonly();

	$self->configure(-state => $state);

	return $self;
}


#-------------------------------------------------------------------------------
# Method  : _mpath
# Purpose : Delegate all method calls to the text subwidget.
# Notes   : 
#-------------------------------------------------------------------------------
sub _mpath { $_[0] . '.text' }


#-------------------------------------------------------------------------------
# Method  : insert/delete
# Purpose : Provide methods for programmatic insertions and deletions
# Notes   : The 'm_' prefix is to support method delegation from megawidgets
#           that embed this one.
#-------------------------------------------------------------------------------
sub m_insert { my $self = shift; Tkx::i::call($self . '.text.priv', 'insert', @_) }
sub m_delete { my $self = shift; Tkx::i::call($self . '.text.priv', 'delete', @_) }


#-------------------------------------------------------------------------------
# Method  : _config_state
# Purpose : Handler for configure(-state => <value>)
# Notes   :
#-------------------------------------------------------------------------------
sub _config_state {
	my $self  = shift;
	my $state = shift;
	my $path  = $self . '.text';

	if (defined $state) {

		if ($state eq 'readonly') {
			$self->_readonly(1);
			Tkx::i::call($path , 'configure', '-state', 'normal');
		}
		elsif ($state eq 'normal') {
			$self->_readonly(0);
			Tkx::i::call($path, 'configure', '-state', 'normal');
		}
		elsif ($state eq 'disabled') {
			Tkx::i::call($path, 'configure', '-state', 'disabled');
			# The readonly state doesn't matter when the widget is disabled.
		}
		else {
			croak qq'bad state value "$state": must be normal, disabled, or readonly';
		}

		$self->_data->{-state} = $state;
	}

	return $self->_data->{-state};
}


#-------------------------------------------------------------------------------
# Method  : _readonly
# Purpose : Control whether widget is read-only or read/write.
# Notes   : 
#-------------------------------------------------------------------------------
sub _readonly {
	my $self = shift;
	my $ro   = shift;
	my $path = $self . '.text';

	if ($ro) {

		Tkx::eval(<<EOT);
proc $path {args} [string map [list WIDGET $path] {
	switch [lindex \$args 0] {
		"insert" {}
		"delete" {}
		"default" { return [eval WIDGET.priv \$args] }
	}
}]
EOT

	}
	else {

		Tkx::eval(<<EOT);
proc $path {args} [string map [list WIDGET $path] {
	return [eval WIDGET.priv \$args]
}]
EOT

	}
}


1;

__END__

=pod

=head1 NAME

Tkx::ROText - Tkx text widget that supports a read-only state.

=head1 SYNOPSIS

	use Tkx::ROText;
	...
	my $text = $parent->new_tkx_ROText();

=head1 DESCRIPTION

Tk's text widget doesn't support the 'readonly' state, nor does Tk have a 
separate read-only text widget. This means that Tkx -- being a thin wrapper 
around Tcl/Tk -- doesn't either.

Instead of providing a text widget that is always read-only (like Perl/Tk's 
Tk::ROText) this module provides a text widget that supports the 'readonly' 
state. This makes it possible to switch the widget between being read-only and 
editable.

When the state is 'readonly' the widget's contents cannot be changed by the user 
but may be modified programmatically. In all other ways it behaves as (and in 
fact is) a standard text widget.

The default state is 'readonly.'

=head1 BUGS

Please report any bugs or feature requests to C<bug-tkx-rotext at rt.cpan.org> 
or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tkx-ROText>. I will be 
notified, and then you'll automatically be notified of progress on your bug as I 
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Tkx::ROText

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tkx-ROText>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tkx-ROText>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tkx-ROText>

=item * Search CPAN

L<http://search.cpan.org/dist/Tkx-ROText>

=back

=head1 AUTHOR

Michael J. Carman, C<< <mjcarman at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael J. Carman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
