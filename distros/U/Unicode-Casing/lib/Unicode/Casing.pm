package Unicode::Casing;    # pod is after __END__ in this file

require 5.010;  # Because of Perl bugs; can work on earlier Perls with care
use strict;
use warnings;
use Carp;
use B::Hooks::OP::Check; 
use B::Hooks::OP::PPAddr; 

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();

our @EXPORT = ();

our $VERSION = '0.16';

require XSLoader;
XSLoader::load('Unicode::Casing', $VERSION);

# List of references to functions that are overridden by this module
# anywhere in the program.  Each gets a unique id, which is its index
# into this list.
my @_function_list;

our @recursed;
local @recursed;

# The way it works is that each function that is overridden has a
# reference stored to it in the array.  The index in the array to it is
# stored in %^H with the key being the name of the overridden function,
# like 'uc'.  This keeps track of scoping.  A .xs function is set up to
# intercept calls to the overridden-functions, and it calls _dispatch
# with the name of the function which was being called and the string to
# change the case of. _dispatch looks up the function name in %^H to
# find the index which in turn yields the function reference.  If there
# is no overridden function, the core one is called instead.  (This can
# happen when part of the core code processing a call to one of these
# functions itself calls a casing function, as happens with Unicode
# table look-ups.)

my $fc_glob;

# This is a work-around, suggested by Matt S. Trout, to the problem that
# CORE::fc() is a syntax error on Perls prior to v5.15.8.  We have to avoid
# compiling that expression on those Perls, but we want the compile-time
# version of it on Perls that handle it.  Another solution would be to put it
# in a sub module that is loaded with a 'use if,'.  We want CORE:: to get the
# official version.  We can't do a string eval or otherwise defer this to
# runtime, because by the time _dispatch is called, the op has been replaced,
# and we would get infinite recursion.
# Actually, I'm not sure the CORE:: is actually needed at all, but am leaving
# it in just to be safe.
BEGIN {
    no strict;
    $fc_glob = \*{"CORE::fc"} if $^V ge v5.15.8;
}

sub _dispatch {
    my ($string, $function) = @_;

    # Called by the XS op-interceptor to look for the correct user-defined
    # function, and call it.
    #   $string is the scalar whose case is being changed
    #   $function is the generic name, like 'uc', of the case-changing
    #       function.

    return if ! defined $string;

    # This is the key that should be stored in the hash hints for this
    # function if overridden
    my $key = id_key($function);

    # For reasons I don't understand, the intermediate $hints_hash_ref cannot
    # be skipped; in 5.13.11 anyway.
    my $hints_hash_ref = (caller(0))[10];

    my $index = $hints_hash_ref->{$key};

    if (! defined $index # Not overridden
        || defined $recursed[$index])
    {
        return CORE::uc($string) if $function eq 'uc';
        return CORE::lc($string) if $function eq 'lc';
        return CORE::ucfirst($string) if $function eq 'ucfirst';
        return CORE::lcfirst($string) if $function eq 'lcfirst';
        return &$fc_glob($string) if $function eq 'fc';
    }

    local $recursed[$index] = $string;

    # Force scalar context and returning exactly one value;
    my $ret = &{$_function_list[$index]}($string);
    return $ret;
}

sub setup_key { # key into %^H for value returned from setup();
    return __PACKAGE__ . "_setup_" . shift;
}

sub id_key { # key into %^H for index into @_function_list
    return __PACKAGE__ . "_id_" . shift;
}

sub import {
    shift;  # Ignore 'casing' parameter.

    my %args;

    while (my $function = shift) {
        return if $function eq '-load';
        my $user_sub;
        if (! defined ($user_sub = shift)) {
            croak("Missing CODE reference for $function");
        }
        if (ref $user_sub ne 'CODE') {
            croak("$user_sub (for $function) is not a CODE reference");
        }
        if ($function ne 'uc' && $function ne 'lc'
            && $function ne 'ucfirst' && $function ne 'lcfirst'
            && ! ($function eq 'fc' && $^V ge v5.15.8))
        {
            my $msg = "$function must be one of: 'uc', 'lc', 'ucfirst', 'lcfirst'";
            $msg .= ", 'fc'" if $^V ge v5.15.8;
            croak($msg);
        }
        elsif (exists $args{$function}) {
            croak("Only one override for \"$function\" is allowed");
        }
        $args{$function} = 1;
    
        push @_function_list, $user_sub;
        $^H{id_key($function)} = scalar @_function_list - 1;

        # Remove any existing override in the current scope
        my $setup_key = setup_key($function);
        teardown($function, $^H{$setup_key}) if exists $^H{$setup_key};

        # Save code returned so can tear down upon unimport();
        $^H{$setup_key} = setup($function);
    }

    croak("Must specify at least one case override") unless %args;
    return;
}

sub unimport {
    foreach my $function (qw(lc uc lcfirst ucfirst fc)) {
        my $id = $^H{setup_key($function)};
        teardown($function, $id) if defined $id;
    }
    return;
}
        
1;
__END__

=encoding utf8

=head1 NAME

Unicode::Casing - Perl extension to override system case changing functions

=head1 SYNOPSIS

  use Unicode::Casing
            uc => \&my_uc, lc => \&my_lc,
            ucfirst => \&my_ucfirst, lcfirst => \&my_lcfirst,
            fc => \&my_fc;
  no Unicode::Casing;

  package foo::bar;
    use Unicode::Casing -load;
    sub import {
        Unicode::Casing->import(
            uc      => \&_uc,
            lc      => \&_lc,
            ucfirst => \&_ucfirst,
            lcfirst => \&_lcfirst,
            fc => \&_fc,
        );
    }
    sub unimport {
        Unicode::Casing->unimport;
    }

=head1 DESCRIPTION

This module allows overriding the system-defined character case changing
operations.  Any time something in its lexical scope would ordinarily call
C<lc()>, C<lcfirst()>, C<uc()>, C<ucfirst()>, or C<fc()>, the corresponding
user-specified function will instead be called.  This applies to direct calls
(even those prefaced by C<CORE::>), and indirect calls via the C<\L>, C<\l>,
C<\U>, C<\u>, and C<\F> escapes in double-quoted strings and regular
expressions.

Each function is passed a string whose case is to be changed, and should
return the case-changed version of that string.  Within the function's
dynamic scope, references to the operation it is overriding use the
non-overridden version.  For example:
    
 sub my_uc {
    my $string = shift;
    print "Debugging information\n";
    return uc($string);
 }
 use Unicode::Casing uc => \&my_uc;
 uc($foo);

gives the standard upper-casing behavior, but prints "Debugging information"
first.  This also applies to the escapes.  Using, for example, C<\U> inside
the override function for C<uc()> will call the non-overridden C<uc()>.
Since this applies across the dynamic scope, if C<my_uc> calls function C<a>
which calls C<b> which calls C<c> which calls C<uc>, that C<uc> is the
non-overridden version.  Otherwise there would be the possibility of infinite
recursion.  And, it fits with the typical use of these functions, which is to 
use the standard case change except for a few select characters, as shown in
the example below.

It is an error to not specify at least one override in the "use" statement.
Ones not specified use the standard operation.  It is also an error to specify
more than one override for the same function.

C<use re 'eval'> is not needed to have the inline case-changing sequences
work in regular expressions.

Here's an example of a real-life application, for Turkish, that shows
context-sensitive case-changing.  (Because of bugs in earlier Perls, version
v5.12 is required for this example to work properly.)

 sub turkish_lc($) {
    my $string = shift;

    # Unless an I is before a dot_above, it turns into a dotless i (the
    # dot above being attached to the I, without an intervening other
    # Above mark; an intervening non-mark (ccc=0) would mean that the
    # dot above would be attached to that character and not the I)
    $string =~ s/I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/gx;

    # But when the I is followed by a dot_above, remove the dot_above so
    # the end result will be i.
    $string =~ s/I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/gx;

    $string =~ s/\x{130}/i/g;

    return lc($string);
 }

A potential problem with context-dependent case changing is that the routine
may be passed insufficient context, especially with the in-line escapes like
C<\L>.

F<90turkish.t>, which comes with the distribution includes a full implementation
of all the Turkish casing rules.

Note that there are problems with the standard case changing operation for
characters whose code points are between 128 and 255.  To get the correct
Unicode behavior, the strings must be encoded in utf8 (which the override
functions can force) or calls to the operations must be within the scope of C<use
feature 'unicode_strings'> (which is available starting in Perl version 5.12).

Also, note that C<fc()> and C<\F> are available only in Perls starting with
version v5.15.8.  Trying to override them on earlier versions will result in
a fatal error.

Note that there can be problems installing this (at least on Windows)
if using an old version of ExtUtils::Depends. To get around this follow
these steps:

=over

=item 1

upgrade ExtUtils::Depends

=item 2

force install B::Hooks::OP::Check

=item 3

force install B::Hooks::OP::PPAddr

=back

See L<http://perlmonks.org/?node_id=797851>.

=head1 BUGS

This module doesn't play well when there are other attempts to override the
functions, such as C<use subs qw(uc lc ...);> or
S<C<*CORE::GLOBAL::uc = sub { .... };>>.  Which thing gets called depends on
the ordering of the calls, and scoping rules break down.

=head1 AUTHOR

Karl Williamson, C<< <khw@cpan.org> >>,
with advice and guidance from various Perl 5 porters,
including Paul Evans, Burak Gürsoy, Florian Ragwitz, Ricardo Signes,
and Matt S. Trout.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Karl Williamson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
