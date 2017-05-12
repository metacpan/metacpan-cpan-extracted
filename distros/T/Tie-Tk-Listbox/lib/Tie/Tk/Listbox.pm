
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2003-2006 Steffen Mueller, all rights reserved.

package Tie::Tk::Listbox;

use 5.006;
use strict;
use warnings;
use Carp;

use vars qw/$VERSION/;
$VERSION = '1.02';


sub TIEARRAY  {
   my $proto = shift;
   my $class = ref $proto || $proto;
   my $listbox = shift;
   unless (defined $listbox) {
      croak "Missing listbox argument.";
   }
   unless (ref $listbox eq 'Tk::Listbox') {
      $listbox = $listbox->Subwidget('listbox');
      croak "Trouble finding listbox." if not defined $listbox;
   }

   bless \$listbox, $class;
}

sub STORE     {
   my $self    = shift;
   my $index   = shift;
   # value is $_[0] now.

   my $len     = $_[1] || $self->FETCHSIZE();
   if ($index > $len - 1) {
      $self->EXTEND($index+1, $len);
   } elsif ($index < 0) {
      $index += $len;
      croak "Index out of range." if $index < 0;
   }
   ${$self}->delete($index);
   ${$self}->insert($index, $_[0]);
}

sub FETCHSIZE {
   my $self = shift;
   return ${$self}->index('end');
}

sub STORESIZE {
   my $self  = shift;
   my $tolen = shift;
   my $len   = shift || $self->FETCHSIZE();
   if ($tolen > $len) {
      $self->EXTEND($tolen, $len);
   } elsif ($tolen < $len) {
      ${$self}->delete($tolen, $len-1);
   }
}

sub FETCH     {
   my $self = shift;
   my $ind  = shift;
   my $len  = shift || $self->FETCHSIZE();
   if ($ind < 0) {
      $ind += $len;
   }
   if ($ind >= $len) {
      return undef;
   }
   return ${$self}->get($ind);
}

sub CLEAR     {
   my $self = shift;
   $self->STORESIZE(0);
}

sub EXTEND  {
   my $self  = shift;
   my $tolen = shift;
   my $len   = shift || $self->FETCHSIZE();
   if ($tolen > $len) {
      my $diff = $tolen - $len;
      ${$self}->insert('end', ( (undef) x $diff ));
   }
}

sub DESTROY { }

sub SPLICE {
    my $self = shift;
    my $len  = $self->FETCHSIZE;
    my $off  = (@_) ? shift : 0;
    $off += $len if ($off < 0);
    my $diff = (@_) ? shift : $len - $off;
    $diff += $len - $off if $diff < 0;
    my @result;
    for (my $i = 0; $i < $diff; $i++) {
        push(@result,$self->FETCH($off+$i));
    }
    $off = $len if $off > $len;
    $diff -= $off + $diff - $len if $off + $diff > $len;
    if (@_ > $diff) {
        # Move items up to make room
        my $d = @_ - $diff;
        my $e = $off+$diff;
        $self->EXTEND($len+$d);
        for (my $i=$len-1; $i >= $e; $i--) {
            my $val = $self->FETCH($i);
            $self->STORE($i+$d,$val);
        }
    }
    elsif (@_ < $diff) {
        # Move items down to close the gap
        my $d = $diff - @_;
        my $e = $off+$diff;
        for (my $i=$off+$diff; $i < $len; $i++) {
            my $val = $self->FETCH($i);
            $self->STORE($i-$d,$val);
        }
        $self->STORESIZE($len-$d);
    }
    for (my $i=0; $i < @_; $i++) {
        $self->STORE($off+$i,$_[$i]);
    }
    return wantarray ? @result : pop @result;
}

sub UNSHIFT { scalar shift->SPLICE(0,0,@_) }
sub SHIFT { shift->SPLICE(0,1) }
sub PUSH {
   my $self = shift;
   my $i   = $self->FETCHSIZE;
   $self->STORE($i++, shift) while (@_);
}

sub POP {
   my $self = shift;
   my $newsize = $self->FETCHSIZE - 1;
   my $val;
   if ($newsize >= 0) {
      $val = $self->FETCH($newsize);
      $self->STORESIZE($newsize);
   }
   $val;
}

sub EXISTS {
    my $pkg = ref $_[0];
    croak "$pkg dosn't define an EXISTS method";
}

sub DELETE {
    my $pkg = ref $_[0];
    croak "$pkg dosn't define a DELETE method";
}


1;

__END__

=pod

=head1 NAME

Tie::Tk::Listbox - Access Tk::Listbox and similar widgets as arrays

=head1 VERSION

Current version is 1.01.

=head1 SYNOPSIS

  use Tk;
  use Tie::Tk::Listbox;
  
  $main = MainWindow->new;
  
  # Examples of scrollable and normal listboxes...
  $scroll = $main->Scrolled(qw/Listbox -height 25 -width 40 -selectmode
                   extended -scrollbars oseo/)->pack(-side => 'left');
  $listb  = $main->Listbox(qw/-height 25 -width 40 -selectmode
                   extended/)->pack(-side => 'right');
  
  # Tie Scrolled or Listbox widgets the same way...
  tie @scr_ary  => 'Tie::Tk::Listbox', $scroll;
  tie @list_ary => 'Tie::Tk::Listbox', $listb;
  
  # Initialize with data.
  @scr_ary  = map {"$_: " . ('x' x $_)} 1..100;
  @list_ary = 'a'..'z';
  
  # Do something with the arrays here or in callbacks...
  
  # Run
  MainLoop;

=head1 DESCRIPTION

The Tie::Tk::Listbox module allows you to tie the contents of a Tk::Listbox
widget to an ordinary Perl array for easy modification. Additionally,
you may tie a Tk::Scrolled widget or any other widget that advertises
a Tk::Listbox subwidget. Please see L<CAVEATS> about this.

Except the DELETE and EXISTS methods, whose purpose is somewhat opaque
to the author because they should not be used on arrays, all tied
methods have been implemented to behave exactly as the functions that
operate on ordinary Perl arrays. If you happen to find out that this
is not the case, please report your discovery to the author.

=head1 CAVEATS

When tying an array to widgets other than Tk::Listbox widgets,
the tying routines will extract the reference to the Tk::Listbox
widget using the Subwidget method on the enclosing widget. If that's
Greek to you, don't worry: Either read
L<Tk::mega/"Subwidget"> on how to use advertised widgets. Or
ignore this and don't use the tied function on the tied array
because you will get the Tk::Listbox widget back, not the enclosing
widget as you might expect.

=head1 AUTHOR

Steffen Mueller, E<lt>tklistbox-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Steffen Mueller. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::More> about the test suite

L<Tk> and L<Tk::Listbox>, as well as L<Tk::Scrolled>

=cut


