#===============================================================================
# Tie/Tk/Text.pm
#===============================================================================
package Tie::Tk::Text;
use strict;

use vars qw'$VERSION';
$VERSION = '0.92';

# Notes:
# * Text widgets use 1-based indexing so line number = array index + 1
# * Text widgets *always* have a newline at the end. It's returned by
#   $w->get('1.0', 'end') but isn't deleted by $w->delete('1.0', 'end')
# * $w->get('1.0', '1.0 lineend') doesn't include the trailing newline.
#   You need to use one of these instead:
#       $w->get('1.0', '2.0')
#       $w->get('1.0', '1.0 lineend + 1 chars)

sub TIEARRAY {
	my $class  = shift;
	my $widget = shift;
	return bless \$widget, $class;
}


sub CLEAR {
	my $self = shift;
	$$self->delete('1.0', 'end');
}


sub FETCH {
	my $self = shift;
	my $line = shift() + 1;
	return $$self->get("$line.0", "$line.end + 1 chars");
}


sub STORE {
	my $self = shift;
	my $idx  = shift;
	my $text = shift;
	my $line = $idx + 1;

	$$self->insert('end', "\n")	while ($self->FETCHSIZE <= $idx);
	$self->_delete($idx);
	$$self->insert("$line.0", $text);
}


sub FETCHSIZE {
	my $self = shift;
	my $c    = $$self->get('end - 1 chars');
	my $n    = $c eq "\n" ? 2 : 1; # cf. module notes
	my $l    = (split(/\./, $$self->index("end - $n chars")))[0];
	return $l;
}


sub STORESIZE {
	my $self = shift;
	my $size = shift;

	if ($self->FETCHSIZE > $size) {
		my $n = $size + 1;
		$$self->delete("$n.0", 'end');
	}
	else {
		$$self->insert('end', "\n") while ($self->FETCHSIZE < $size);
	}
}


sub EXISTS {
	my $self = shift;
	my $idx  = shift;
	return $idx < $self->FETCHSIZE;
}


sub DELETE {
	my $self = shift;
	my $idx  = shift;
	my $text = $self->EXISTS($idx) ? $self->FETCH($idx) : undef;

	my $l = $idx + 1;
	$$self->delete("$l.0", "$l.0 lineend"); # don't delete the \n

	# collapse trailing "undef" (\n) values
	while ($self->FETCH($self->FETCHSIZE - 1) eq "\n") {
		$self->POP;
	}
	
	return $text;
}


sub PUSH {
	my $self = shift;
	$$self->insert('end', $_) foreach @_;
}


sub POP {
	my $self = shift;
	return $self->_delete($self->FETCHSIZE - 1);
}


sub UNSHIFT {
	my $self = shift;
	$$self->insert('1.0', $_) foreach reverse @_;
}


sub SHIFT {
	my $self = shift;
	return $self->_delete(0);
}


sub SPLICE {
	my $self = shift;
	my $o    = shift; # offset
	my $l    = shift; # length
	
	$o = 0                          unless defined $o;
	$o = $self->FETCHSIZE + $o      if     $o < 0;
	$l = $self->FETCHSIZE - $o      unless defined $l;
	$l = $self->FETCHSIZE - $o + $l if     $l < 0;

	my @deleted;
	foreach my $i (reverse ($o .. $o + $l - 1)) {
		unshift @deleted, $self->_delete($i);
	}

	foreach my $r (reverse @_) {
		my $x = $o + $l - 1;
		$$self->insert("$x.0", $r);
	}

	return @deleted;
}


sub EXTEND {}

#-------------------------------------------------------------------------------
# Method  : Remove and (really) delete element
# Purpose : 
# Notes   : 
#-------------------------------------------------------------------------------
sub _delete {
	my $self = shift;
	my $idx  = shift;
	my $text = $self->FETCH($idx);
	my $line = $idx+1;

	$$self->delete("$line.0", "$line.end + 1 chars");
	return $text;
}

1;

__END__

=pod

=head1 NAME

Tie::Tk::Text - Access Tk text widgets as arrays.

=head1 SYNOPSIS

  use Tie::Tk::Text;

  my $w = $mw->Text()->pack();
  tie my @text, 'Tie::Tk::Text', $w;

  $w->insert('end', "foo\nbar\nbaz\n");
  
  print $text[1]; # "bar\n"

=head1 DESCRIPTION

This module defines a class for tie()ing Tk text widgets to an 
array, allowing them to be accessed as if they were an array of lines.

It's not expected that anyone will actually want to populate and manipulate 
their text widgets this way, though you are of course free to do so. This module 
was created to make text widgets accessible to functions that expect an array 
reference as their input. (e.g. Algorithm::Diff::sdiff) You can do that with 
read-only support (FETCH and FETCHSIZE). All of the methods (PUSH, POP, STORE, 
etc.) are included for completeness.

Note: This documentation refers to "Tk text" widgets rather than "Tk::Text" 
ones. That's because it supports anything that uses the same API as a Tk text 
widget. It works with Perl/Tk and Tkx and should work with Tcl::Tk as well.

=head1 CAVEATS

Arrays use zero-based indexing. Text widgets use one-based indexing. Ergo, line 
five is at index four.

Lines end in "\n". Be careful about what you add or you could get odd results. 
For example, doing C<$text[3] = 'foo'> will replace the contents of line four 
with 'foo' but will join lines four and five because you didn't include a 
newline at the end of the string. Similarly, C<$text[3] = "foo\nbar\n"> will 
replace line four with "foo\n" and B<insert> "bar\n" before line five.

=head1 LIMITATIONS

There's no support for tags or a lot of other things that you can do with text 
widgets. There isn't supposed to be. This is not a bug.

=head1 AUTHOR

Michael J. Carman C<< <mjcarman@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2009 by Michael J. Carman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
