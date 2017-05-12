package Tk::TipEntry;

use 5.008008;
use strict;
use warnings;
use Tk;
use Tk::Entry;

our $VERSION = '0.06';

use base qw(Tk::Derived Tk::Entry);

Construct Tk::Widget 'TipEntry';

=head1 NAME

Tk::TipEntry - An entry with tooltip in the entry if it's empty

=head1 SYNOPSIS

  use strict;
  use Tk::TipEntry;
  
  my $entry = $parent->FilterEntry(
	-tip => 'Search...', # will be the default hint text when entry is empty
  );
  $entry->pack();

=head1 DESCRIPTION

This widget is derived from L<Tk::Entry>. It implements an other kind of
tooltip, that is displayed inside the entry when it's empty.
The tooltip will be removed, if the entry gets the focus and reinserted, if
the entry loses the focus and it's value is empty (C<$entry-E<gt>get() eq ''>).

In addition, the entry evaluates the escape key. If the entry has the focus
and the escape key is pressed, the original input will be restored. If there
is no previous input, the tooltip will be displayed again.


=head1 OPTIONS

Any option exept the C<-tip> will be passed to the construktor of the
L<Tk::Entry>. The -text option is altered minimally.


=head2 -tip
(new option)

Specify the tooltip, that will be displayed. 

The default value is 'Search...'.


=head2 -text
(altered option)

If there is no C<-text> attribute for the Entry, the tooltip will be set initially
as default text. Specify C<-text> if you want another initial input.

The default value is the same as for -tip.


=head1 METHODS

=cut

# ClassInit( $class, $mw )
#
# Bind FocusIn, FocusOut and Escape to events.

sub ClassInit {
	my ($class, $mw) = @_;

	$class->SUPER::ClassInit($mw);

	$mw->bind($class, '<FocusIn>'	=> \&FocusIn);
	$mw->bind($class, '<FocusOut>'	=> \&FocusOut);
	$mw->bind($class, '<Escape>'	=> \&Escape);
} # /ClassInit




# Populate( %args )
# 
# Sets default for -tip, unless specified. Set -text initially to -tip,
# if there is -tip, but no -text.

sub Populate {
	my ($self, $args) = @_;

	# -- check for undef tip value
	my $default_tip = 'Search...';
	if( !exists($args->{-tip}) or ( exists($args->{-tip}) and !defined($args->{-tip})) ) {
		$args->{-tip} = $default_tip;
	}

	unless( exists $args->{-text} ) {
		$args->{-text} = $args->{-tip};
	}

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		-tip			=> ['PASSIVE', 'tip', 'Tip', $default_tip],
		-previous		=> ['PASSIVE', 'previous', undef, undef],
	);
} # /Populate




=head2 FocusIn()

When the entry gets the focus, the tooltip will be removed.

=cut

sub FocusIn {
	my $self = shift;

	my $default_text	= $self->cget('-tip');
	
	if( $self->get() eq $default_text ) {
		$self->delete(0, 'end');
		$self->configure(-previous => undef);
	}else{
		$self->configure(-previous => $self->get());
	}
	
	return 1;
} # /FocusIn




=head2 FocusOut()

When the entry loses the focus and if it's empty, the tooltip will be inserted.

=cut

sub FocusOut {
	my $self = shift;

	my $default_text = $self->cget('-tip');

	if( $self->get() eq '' ) {
		$self->insert(0, $default_text);
		$self->configure(-previous => undef);
	}elsif( $self->get() eq $default_text ) {
		$self->configure(-previous => undef);
	}else{
		$self->configure(-previous => $self->get());
	}
	
	return 1;
} # /FocusOut




=head2 Escape()

If the escape key is pressed, the current input will be discarded. The
previous input will be inserted. If there is no previous input, the -tip will
be the new input.

=cut

sub Escape {
	my $self = shift;

	my $default_text	= $self->cget('-tip');
	my $previous_input	= $self->cget('-previous');

	if( defined($previous_input) and $self->get() ne $previous_input ) {
		$self->delete(0, 'end');
		$self->insert(0, $previous_input);
	}

	$self->parent->focus();
	
	return 1;
} # /Escape




=head1 SEE ALSO

L<Tk>, L<Tk::Entry>, L<Tk::FilterEntry>

=head1 CREDITS

POD for C<Populate()> partially taken from L<Tk::Wizard>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.12.2 or, at your option,
any later version of Perl 5 you may have available.

=head1 AUTHOR

This module was designed after L<Tk::FilterEntry>.

Alexander Becker, L<asb@cpan.org>

=cut

1; # /Tk::TipEntry