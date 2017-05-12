#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use X11::Xlib ':all';
sub err(&) { my $code= shift; my $ret; { local $@= ''; eval { $code->() }; $ret= $@; } $ret }

plan skip_all => "No X11 Server available"
    unless $ENV{DISPLAY};
plan tests => 8;

my $TEST_DESTRUTIVE= !!$ENV{TEST_DESTRUTIVE};
sub skip_destructive($) {
    skip "TEST_DESTRUTIVE is false; skipping destrutive tests", shift
        unless $TEST_DESTRUTIVE;
}

my $dpy= new_ok( 'X11::Xlib', [], 'connect to X11' );

my ($min, $max);
XDisplayKeycodes($dpy, $min, $max);
ok( $min > 0 && $min <= $max,    'Got Min Keycode' );
ok( $max >= $min && $max <= 255, 'Got Max Keycode' );

sub save_temp {
    my ($name, $data)= @_;
    my $fname= sprintf("%s-%d.txt", $name, time);
    open my $fh, ">", $fname or die "open: $!";
    print $fh $data;
    close $fh;
    diag "Saved diagnostics to $fname";
}

subtest keysym_mapping => sub {
    # These values should never change.  Just make sure character
    # and non-character values work.  On my Xlib, unicode values often
    # become the text "Uxxxx" but sometimes have a symbolic name, so
    # probably bad to depend on the list of unicode symbolic names.
    is( XKeysymToString(0xFF09), "Tab", 'XKeysymToString Tab' );
    is( XKeysymToString(0xFFBE), "F1",  'XKeysymToString F1' );
    is( XStringToKeysym("Tab"), 0xFF09, 'XStringToKeysym Tab' );
    is( XStringToKeysym("F1"),  0xFFBE, 'XStringToKeysym F1' );
    
    for (
        [ 0x000FF09 => 0x000009, 'Tab' ],
        [ 0x000FF1B => 0x00001B, 'Esc' ],
        [ 0x000FF8D => 0x00000D, 'KP_Enter' ],
        [ 0x000FFE1 => undef,    'Shift_L' ],
        [ 0x0000034 => 0x000034, '4' ],
        [ 0x000004D => 0x00004D, 'M' ],
        [ 0x00002C6 => 0x000108, 'Ccircumflex' ],
        [ 0x00004B6 => 0x0030AB, 'Katakana KA' ],
        [ 0x10030AB => 0x0030AB, 'Katakana KA (direct Ucode mapping)' ],
        [ 0x0000000 => undef,    'Invalid KeySym' ],
    ) {
        my ($keysym, $codepoint, $desc)= @$_;
        if (defined $keysym) {
            is( keysym_to_codepoint($keysym), $codepoint, "keysym_to_codepoint: $desc" );
            is( keysym_to_char($keysym), $codepoint? chr($codepoint) : undef, "keysym_to_char: $desc" );
        }
        if (defined $codepoint and $desc !~ /^KP_/) {
            my $sym= $codepoint < 0x20 || $codepoint > 0xFF? 0x1000000 | $codepoint
                : $codepoint;
            is( codepoint_to_keysym($codepoint), $sym, "codepoint_to_keysym: $desc" );
            is( char_to_keysym(chr($codepoint)), $sym, "char_to_keysym: $desc" );
        }
    }
    is( codepoint_to_keysym(-1), undef, 'Invalid unicode codepoint' );
    is( char_to_keysym(''),      undef, 'Char of empty string' );
    done_testing;
};

subtest modmap => sub {
    my $modmap;
    is( err{ $modmap= $dpy->XGetModifierMapping() }, '', 'XGetModifierMapping' )
     && is( ref $modmap, 'ARRAY', '...is an array' )
     && is( join('', map ref, @$modmap), 'ARRAY'x 8, '...of arrays' )
     or diag(explain $modmap), die "XGetModifierMapping failed.  Not continuing";
    
    SKIP: {
        skip_destructive 2;
        # Seems like a bad idea, but need to test....
        is( err{ $dpy->XSetModifierMapping($modmap) }, '', 'XSetModifierMapping' );

        # Make sure we didn't change it
        my $modmap2= $dpy->XGetModifierMapping();
        is_deeply( $modmap2, $modmap, 'same as last time' )
            or BAIL_OUT "SORRY! We changed your X11 key modifiers!";
    }
    done_testing;
};

subtest keymap => sub {
    my @keysyms;
    is( err{ @keysyms= XGetKeyboardMapping($dpy, $min) }, '', 'XGetKeyboardMapping' );
    ok( @keysyms > 0, "Got keysyms for $min" );
    
    my $mapping;
    is( err{ $mapping= $dpy->load_keymap }, '', 'load_keymap' );
    ok( ref($mapping) eq 'ARRAY' && @$mapping > 0 && ref($mapping->[-1]) eq 'ARRAY', '...is array of arrays' )
        or save_temp("keymap-before", explain $mapping);
    
    SKIP: {
        skip_destructive 2;
        # Fingers crossed!
        is( err{ $dpy->save_keymap($mapping) }, '', 'save_keymap' )
            or save_temp("keymap-before", explain $mapping);
        
        # Make sure we didn't change it
        my $kmap2= $dpy->load_keymap;
        is_deeply( $mapping, $kmap2, 'same as before' )
            or do { save_temp("keymap-before", explain $mapping); save_temp("keymap-after", explain $kmap2); BAIL_OUT "Sorry! We dammaged your keymap.  You might need to log out to fix it"; };
    }    
    done_testing;
};

subtest keymap_wrapper => sub {
    # TODO: this is sloppy and doesn't prove much
    ok( my $keymap= $dpy->keymap );
    is( err{ $keymap->keymap_reload }, '', 'keymap_reload' );
    SKIP: {
        skip_destructive 1;
        is( err{ $keymap->keymap_save   }, '', 'keymap_save' );
    }
    is( err{ $keymap->modmap_sym_list('shift') }, '', 'modmap_sym_list' );
    SKIP: {
        skip_destructive 1;
        is( err{ $keymap->modmap_save   }, '', 'modmap_save' );
    }
    is( err{ $keymap->modmap_add_syms(control => 'Control_L') }, '', 'modmap_add_syms' );
    is( err{ $keymap->modmap_del_syms(control => 'Control_L') }, '', 'modmap_del_syms' );
    done_testing;
};

subtest xlib_lookup => sub {
    # Pick some key from the modmap.  Probably every keyboard has at least shift or control?
    ok( my $keycode= $dpy->XKeysymToKeycode(XStringToKeysym('A')), 'XKeysymToKeycode' );
    my $key_event= { type => KeyPress, keycode => $keycode, display => $dpy };
    my ($name, $keysym);
    is( err{ XLookupString($key_event, $name, $keysym) }, '', 'XLookupString' );
    like( $name, qr/\w/, 'XLookupString returned a name' );
    ok( $keysym > 0, 'XLookupString returned a keysym' );
    
    done_testing;
};
