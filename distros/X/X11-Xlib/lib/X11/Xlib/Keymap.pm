package X11::Xlib::Keymap;
use strict;
use warnings;
use Carp;
use X11::Xlib;
use Scalar::Util 'weaken';

# All modules in dist share a version
our $VERSION = '0.25';

=head1 NAME

X11::Xlib::Keymap - Object Oriented access to the X11 keymap

=head1 DESCRIPTION

For better or for worse, (hah, who am I kidding; worse) the X11 protocol gives
applications the direct keyboard scan codes from the input device, and
provides two tables to let applications do their own interpretation of the
codes.  The first table ("keymap") maps the scan codes (single byte) to one or
more symbolic constants describing the glyph on the key.  Choosing which of
the several symbols to use depends on which "modifiers" are in effect.
The second table is the "modifier map", which lists keys (scan codes, again)
that are part of each of the eight modifier groups.  Two modifier groups
(Shift and Control) have constant meaning, but the rest require some creative
logic to interpret.

The keymap can't be used without the modifier map, but the modifier map can't
be interpreted without the keymap, so both tables are rolled together into
this object.

While there are always less than 255 hardware scan codes, the set of device-
independent KeySym codes is huge (including Unicode as a subset).
Since the KeySym constants can't be practically exported by a Perl module,
this API mostly tries to let you use the symbolic names of keys, or Unicode
characters.  Translating KeySym names and characters to/from KeySym values is
a client-side operation.

=head1 ATTRIBUTES

=head2 display

Holds a weak-ref to the Display, used for the loading and saving operations.

=cut

sub display {
    my $self= shift;
    weaken( $self->{display}= shift ) if @_;
    $self->{display};
}

=head2 keymap

Arrayref that maps from a key code (byte) to an arrayref of KeySyms.

  [
    ...
    [ $normal_key, $key_with_shift, $mode2_normal_key, $mode2_key_with_shift, ... ]
    ...
  ]

Each KeyCode (up to 255 of them) is used as an index into the outer array,
and the inner array's elements correspond to different shift/mode states,
where "mode2" indicates a dynamic switch of key layout of some sort.
Each key's array can contain additional vendor-specific elements.

This table is stored exactly as loaded from the X11 server.

=head2 rkeymap

A hashref mapping from the symbolic name of a key to its scan code.

=cut

sub keymap {
    my $self= shift;
    if (@_) { $self->{keymap}= shift; delete $self->{rkeymap}; }
    $self->{keymap} ||= defined wantarray? $self->display->load_keymap : undef;
}

sub rkeymap {
    my $self= shift;
    $self->{rkeymap} ||= do {
        my %rkmap;
        my $kmap= $self->keymap;
        for (my $i= $#$kmap; $i >= 0; $i--) {
            next unless ref $kmap->[$i] eq 'ARRAY';
            defined $_ and $rkmap{$_}= $i for @{$kmap->[$i]};
        }
        \%rkmap;
    };
}

=head2 modmap

An arrayref of eight modifier groups, each element being the list
of key codes that are part of that modifier.

=head2 modmap_ident

A hashref of logical modifier group names to array index within the modmap.
On a modern US-English Linux desktop you will likely find:

  shift    => 0,
  lock     => 1, capslock => 1,
  control  => 2,
  alt      => 3, meta => 3,
  numlock  => 4,
  win      => 6, super => 6
  mode     => 7,

but the numbers 3..7 can be re-purposed by your particular key layout.
Note that X11 has a concept of "mode switching" where a modifier completely
changes the meaning of every key.  I think this is used by multi-lingual
setups, but I have not tested/confirmed this.

=cut

sub modmap {
    my $self= shift;
    if (@_) { $self->{modmap}= shift; delete $self->{modmap_ident}; }
    $self->{modmap} ||= defined wantarray? $self->display->XGetModifierMapping : undef;
}

sub modmap_ident {
    my $self= shift;
    $self->{modmap_ident} ||= do {
        my $km= $self->keymap;
        my $mm= $self->modmap;
        my %ident= ( shift => 0, lock => 1, control => 2, mod1 => 3, mod2 => 4, mod3 => 5, mod4 => 6, mod5 => 7 );
        # "lock" is either 'capslock' or 'shiftlock' depending on keymap.
        # for each member of lock, see if its member keys include XK_Caps_Lock
        if (grep { $_ && $_ eq 'Caps_Lock' } map { ($_ && defined $km->[$_])? @{ $km->[$_] } : () } @{ $mm->[1] }) {
            $ident{capslock}= 1;
        # Else check for the XK_Shift_Lock
        } elsif (grep { $_ && $_ eq 'Shift_Lock' } map { ($_ && defined $km->[$_])? @{ $km->[$_] } : () } @{ $mm->[1] }) {
            $ident{shiftlock}= 1;
        }
        # Identify the group based on what keys belong to it
        for (3..7) {
            my @syms= grep { $_ } map { ($_ && defined $km->[$_])? @{ $km->[$_] } : () } @{ $mm->[$_] };
            $ident{alt}=  $_    if grep { /^Alt/ } @syms;
            $ident{meta}= $_    if grep { /^Meta/ } @syms;
            $ident{hyper}= $_   if grep { /^Hyper/ } @syms;
            $ident{numlock}= $_ if grep { $_ eq 'Num_Lock' } @syms;
            $ident{mode}= $_    if grep { $_ eq 'Mode_switch' } @syms;
            if (grep { /^Super/ } @syms) {
                $ident{super}= $_;
                $ident{win}= $_;
            }
        }
        \%ident;
    };
}

=head1 METHODS

=head2 new

  my $keymap= X11::Xlib::Keymap->new(display => $dpy, %attrs);

Initialize a keymap with the list of parameters.  L</display> is required
for any load/save operations.  You can use most of the class with just the
L</keymap> and L</modmap> attributes.

=cut

sub new {
    my $class= shift;
    my %args= (@_ == 1 and ref($_[0]) eq 'HASH')? %{ $_[0] }
        : ((@_ & 1) == 0)? @_
        : croak "Expected hashref or even-length list";
    weaken( $args{display} ) if defined $args{display};
    bless \%args, $class;
}

=head2 find_keycode

  my $keycode= $display->find_keycode( $key_sym_or_char );

Return a keycode for the parameter, which is either a KeySym name
(L<XStringToKeysym|X11::Xlib/XStringToKeysym>) or a string holding a Unicode character
(L<char_to_keysym|X11::Xlib/char_to_keysym>).  If more than one key code can map to
the KeySym, this returns an arbitrary one of them.  Returns undef if
no matches were found.

=head2 find_keysym

  my $sym_name= $display->find_keysym( $key_code, $modifier_bits );
  my $sym_name= $display->find_keysym( $XKeyEvent );

Returns the symbolic name of a key, given its scan code and current modifier bits.

For convenience, you can pass an L<XKeyEvent|X11::Xlib::XEvent/XKeyEvent> object.

If you don't have modifier bits, pass 0.

=cut

sub find_keycode {
    my ($self, $sym)= @_;
    my $code= $self->rkeymap->{$sym};
    return $code if defined $code;
    # If length==1, assume it is a character and then try the name and symbol value
    if (length $sym == 1) {
        my $sym_val= X11::Xlib::char_to_keysym($sym);
        my $sym_name= X11::Xlib::XKeysymToString($sym_val);
        $code= $self->rkeymap->{$sym_name} if $sym_val && defined $sym_name;
        $code= $self->rkeymap->{$sym_val} if $sym_val && !defined $code;
    }
    # Else assume it is a symbol name and try to find the symbol character
    else {
        my $sym_val= X11::Xlib::XStringToKeysym($sym);
        my $sym_char= X11::Xlib::keysym_to_char($sym_val);
        $code= $self->rkeymap->{$sym_char} if $sym_val && defined $sym_char;
        $code= $self->rkeymap->{$sym_val} if $sym_val && !defined $code;
    }
    return $code;
}

sub find_keysym {
    my $self= shift;
    my ($keycode, $modifiers)=
        @_ == 1 && ref($_[0]) && ref($_[0])->can('pack')? ( $_[0]->keycode, $_[0]->state )
        : @_ == 2? @_
        : croak "Expected XKeyEvent or (code,modifiers)";
    my $km= $self->keymap->[$keycode]
        or return undef;
    # Shortcut
    return $km->[0] unless $modifiers;
    
    my $mod_id=    $self->modmap_ident;
    my $shift=     $modifiers & 1;
    my $capslock=  $mod_id->{capslock}  && ($modifiers & (1 << $mod_id->{capslock}));
    my $shiftlock= $mod_id->{shiftlock} && ($modifiers & (1 << $mod_id->{shiftlock}));
    my $numlock=   $mod_id->{numlock}   && ($modifiers & (1 << $mod_id->{numlock}));
    my $mode=      ($mod_id->{mode} && ($modifiers & (1 << $mod_id->{mode})))? 2 : 0;
    # If numlock and Num keypad KeySym...
    if ($numlock && ($km->[1] =~ /^KP_/)) {
        return (($shift || $shiftlock)? $km->[$mode+0] : $km->[$mode+1]);
    } elsif (!$shift && !$capslock && !$shiftlock) {
        return $km->[$mode];
    } elsif (!$shift && $capslock) {
        return uc($km->[$mode]);
    } elsif ($shift && $capslock) {
        return uc($km->[$mode+1]);
    } else { # if ($shift || $shiftlock)
        return $km->[$mode+1];
    }
}

=head2 keymap_reload

  $keymap->keymap_reload();        # reload all keys
  $keymap->keymap_reload(@codes);  # reload range from min to max

Reload all or a portion of the keymap.
If C<@codes> are given, then only load from C<min(@codes)> to C<max(@codes)>.
(The cost of loading the extra codes not in the list is assumed to be
 less than the cost of multiple round trips to the server to pick only
 the specific codes)

=head2 keymap_save

  $keymap->keymap_save(@codes);    # Save changes to keymap (not modmap)

Save any changes to L</keymap> back to the server.
If C<@codes> are given, then only save from C<min(@codes)> to C<max(@codes)>.

See L</save> to save both the L</keymap> and L</modmap>.

=cut

sub keymap_reload {
    my ($self, @codes)= @_;
    my ($min, $max)= @codes? ($codes[0], $codes[0]) : (0,255);
    for (@codes) { $min= $_ if $_ < $min; $max= $_ if $_ > $max; }
    my $km= $self->display->load_keymap(2, $min, $max);
    splice(@{$self->keymap}, $min, $max-$min+1, @$km);
    $self->keymap;
}

sub keymap_save {
    my ($self, @codes)= @_;
    my $km= $self->keymap;
    my ($min, $max)= @codes? ($codes[0], $codes[0]) : (0, $#$km);
    for (@codes) { $min= $_ if $_ < $min; $max= $_ if $_ > $max; }
    $self->display->save_keymap($km, $min, $max);
}

=head2 modmap_sym_list

  my @keysym_names= $display->modmap_sym_list( $modifier );
  
Get the default keysym names for all the keys bound to the C<$modifier>.
Modifier is one of 'shift','lock','control','mod1','mod2','mod3','mod4','mod5',
 'alt','meta','capslock','shiftlock','win','super','numlock','hyper'.

Any modifier after mod5 in that list might not be defined for your keymap
(and return an empty list, rather than an error).

=cut

sub modmap_sym_list {
    my ($self, $modifier)= @_;
    my $km= $self->keymap;
    my $mod_id= $self->modmap_ident->{$modifier};
    return unless defined $mod_id;
    return map { $km->[$_][0]? ( $km->[$_][0] ) : () } @{ $self->modmap->[$mod_id] };
}

=head2 modmap_add_codes

  my $n_added= $keymap->modmap_add_codes( $modifier, @key_codes );

Adds key codes (and remove duplicates) to one of the eight modifier groups.
C<$modifier> is one of the values listed above.

Throws an exception if C<$modifier> does not exist.
Returns the number of key codes added.

=head2 modmap_add_syms

  my $n_added= $keymap->modmap_add_syms( $modifier, @keysym_names );

Convert keysym names to key codes and then call L</modmap_add_codes>.

Warns if any keysym is not part of the current keyboard layout.
Returns the number of key codes added.

=cut

sub modmap_add_codes {
    my ($self, $modifier, @codes)= @_;
    my $mod_id= $self->modmap_ident->{$modifier};
    croak "Modifier '$modifier' does not exist in this keymap"
        unless defined $mod_id;
    
    my $modcodes= $self->modmap->[$mod_id];
    my %seen= ( 0 => 1 ); # prevent duplicates, and remove nulls
    @$modcodes= grep { !$seen{$_}++ } @$modcodes;
    my $n= @$modcodes;
    push @$modcodes, grep { !$seen{$_}++ } @codes;
    return @$modcodes - $n;
}

sub modmap_add_syms {
    my ($self, $modifier, @names)= @_;
    my $rkeymap= $self->rkeymap;
    my (@codes, @notfound);
    for (@names) {
        my $c= $rkeymap->{$_};
        defined $c? push(@codes, $c) : push(@notfound, $_);
    }
    croak "Key codes not found: ".join(' ', @notfound)
        if @notfound;
    $self->modmap_add_codes($modifier, @codes);
}

=head2 modmap_del_codes

  my $n_removed= $keymap->modmap_del_syms( $modifier, @key_codes );

Removes the listed key codes from the named modifier, or from all modifiers
if C<$modifier> is undef.

Warns if C<$modifier> does not exist.
Silently ignores key codes that don't exist in the modifiers.
Returns number of key codes removed.

=head2 modmap_del_syms

  my $n_removed= $display->modmap_del_syms( $modifier, @keysym_names );

Convert keysym names to key codes and then call L</modmap_del_codes>.

Warns if any keysym is not part of the current keyboard layout.
Returns number of key codes removed.

=cut

sub modmap_del_codes {
    my ($self, $modifier, @codes)= @_;
    my $count= 0;
    my %del= map { $_ => 1 } @codes;
    if (defined $modifier) {
        my $mod_id= $self->modmap_ident->{$modifier};
        croak "Modifier '$modifier' does not exist in this keymap"
            unless defined $mod_id;
        my $cur_codes= $self->modmap->[$mod_id];
        my $n= @$cur_codes;
        @$cur_codes= grep { !$del{$_} } @$cur_codes;
        $count= $n - @$cur_codes;
    }
    else {
        for (@{ $self->modmap }) {
            my $n= @$_;
            @$_ = grep { !$del{$_} } @$_;
            $count += $n - @$_;
        }
    }
    return $count;
}

sub modmap_del_syms {
    my ($self, $modifier, @names)= @_;
    my $rkeymap= $self->rkeymap;
    my (@codes, @notfound);
    for (@names) {
        my $c= $rkeymap->{$_};
        defined $c? push(@codes, $c) : push(@notfound, $_);
    }
    carp "Key codes not found: ".join(' ', @notfound)
        if @notfound;
    $self->modmap_del_codes($modifier, @codes);
}

=head2 modmap_save

  $keymap->modmap_save;

Call L<X11::Xlib/XSetModifierMapping> for the current L</modmap>.

=head2 save

  $keymap->save

Save the full L</keymap> and L</modmap>.

=cut

sub modmap_save {
    my ($self, $new_modmap)= @_;
    $self->{modmap}= $new_modmap if defined $new_modmap;
    $self->display->XSetModifierMapping($self->modmap);
}

sub save {
    my $self= shift;
    $self->keymap_save;
    $self->modmap_save;
}

1;

__END__

=head1 EXAMPLES

=head2 Press a Key

Suppose you have an old DOS game that you are playing in Dosbox, and you
find a neat trick to level up your character by pressing 'R' repeatedly.
You might bang out a quick perl one-liner like this:

  perl -e 'use X11::Xlib; $d= X11::Xlib->new;
     $r= $d->keymap->find_keycode("R") or die "No R key?";
     while (1) { $d->fake_key($r, 1); $d->fake_key($r, 0);
      $d->flush; sleep 1; }'

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2023 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
