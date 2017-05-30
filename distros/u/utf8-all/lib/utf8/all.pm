package utf8::all;
use strict;
use warnings;
use 5.010; # state

# ABSTRACT: turn on Unicode - all of it
our $VERSION = '0.023'; # VERSION

#pod =head1 SYNOPSIS
#pod
#pod     use utf8::all;                      # Turn on UTF-8, all of it.
#pod
#pod     open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
#pod     print length 'føø bār';             # 7 UTF-8 characters
#pod     my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main)
#pod
#pod =head1 DESCRIPTION
#pod
#pod The C<use utf8> pragma tells the Perl parser to allow UTF-8 in the
#pod program text in the current lexical scope. This also means that you
#pod can now use literal Unicode characters as part of strings, variable
#pod names, and regular expressions.
#pod
#pod C<utf8::all> goes further:
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<C<charnames>|charnames> are imported so C<\N{...}> sequences can be
#pod used to compile Unicode characters based on names.
#pod
#pod =item *
#pod
#pod On Perl C<v5.11.0> or higher, the C<use feature 'unicode_strings'> is
#pod enabled.
#pod
#pod =item *
#pod
#pod C<use feature fc> and C<use feature unicode_eval> are enabled on Perl
#pod C<5.16.0> and higher.
#pod
#pod =item *
#pod
#pod Filehandles are opened with UTF-8 encoding turned on by default
#pod (including C<STDIN>, C<STDOUT>, and C<STDERR> when C<utf8::all> is
#pod used from the C<main> package). Meaning that they automatically
#pod convert UTF-8 octets to characters and vice versa. If you I<don't>
#pod want UTF-8 for a particular filehandle, you'll have to set C<binmode
#pod $filehandle>.
#pod
#pod =item *
#pod
#pod C<@ARGV> gets converted from UTF-8 octets to Unicode characters (when
#pod C<utf8::all> is used from the C<main> package). This is similar to the
#pod behaviour of the C<-CA> perl command-line switch (see L<perlrun>).
#pod
#pod =item *
#pod
#pod C<readdir>, C<readlink>, C<readpipe> (including the C<qx//> and
#pod backtick operators), and L<C<glob>|perlfunc/glob> (including the C<<
#pod <> >> operator) now all work with and return Unicode characters
#pod instead of (UTF-8) octets (again only when C<utf8::all> is used from
#pod the C<main> package).
#pod
#pod =back
#pod
#pod =head2 Lexical Scope
#pod
#pod The pragma is lexically-scoped, so you can do the following if you had
#pod some reason to:
#pod
#pod     {
#pod         use utf8::all;
#pod         open my $out, '>', 'outfile';
#pod         my $utf8_str = 'føø bār';
#pod         print length $utf8_str, "\n"; # 7
#pod         print $out $utf8_str;         # out as utf8
#pod     }
#pod     open my $in, '<', 'outfile';      # in as raw
#pod     my $text = do { local $/; <$in>};
#pod     print length $text, "\n";         # 10, not 7!
#pod
#pod Instead of lexical scoping, you can also use C<no utf8::all> to turn
#pod off the effects.
#pod
#pod Note that the effect on C<@ARGV> and the C<STDIN>, C<STDOUT>, and
#pod C<STDERR> file handles is always global and can not be undone!
#pod
#pod =head2 Enabling/Disabling Global Features
#pod
#pod As described above, the default behaviour of C<utf8::all> is to
#pod convert C<@ARGV> and to open the C<STDIN>, C<STDOUT>, and C<STDERR>
#pod file handles with UTF-8 encoding, and override the C<readlink> and
#pod C<readdir> functions and C<glob> operators when C<utf8::all> is used
#pod from the C<main> package.
#pod
#pod If you want to disable these features even when C<utf8::all> is used
#pod from the C<main> package, add the option C<NO-GLOBAL> (or
#pod C<LEXICAL-ONLY>) to the use line. E.g.:
#pod
#pod     use utf8::all 'NO-GLOBAL';
#pod
#pod If on the other hand you want to enable these global effects even when
#pod C<utf8::all> was used from another package than C<main>, use the
#pod option C<GLOBAL> on the use line:
#pod
#pod     use utf8::all 'GLOBAL';
#pod
#pod =head2 UTF-8 Errors
#pod
#pod C<utf8::all> will handle invalid code points (i.e., utf-8 that does
#pod not map to a valid unicode "character"), as a fatal error.
#pod
#pod For C<glob>, C<readdir>, and C<readlink>, one can change this
#pod behaviour by setting the attribute L</"$utf8::all::UTF8_CHECK">.
#pod
#pod =head1 COMPATIBILITY
#pod
#pod The filesystems of Dos, Windows, and OS/2 do not (fully) support
#pod UTF-8. The C<readlink> and C<readdir> functions and C<glob> operators
#pod will therefore not be replaced on these systems.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<File::Find::utf8> for fully utf-8 aware File::Find functions.
#pod
#pod =item *
#pod
#pod L<Cwd::utf8> for fully utf-8 aware Cwd functions.
#pod
#pod =back
#pod
#pod =cut

use Import::Into;
use parent qw(Encode charnames utf8 open warnings feature);
use Symbol qw(qualify_to_ref);
use Config;

# Holds the pointers to the original version of redefined functions
state %_orig_functions;

# Current (i.e., this) package
my $current_package = __PACKAGE__;

require Carp;
$Carp::Internal{$current_package}++; # To get warnings reported at correct caller level

#pod =attr $utf8::all::UTF8_CHECK
#pod
#pod By default C<utf8::all> marks decoding errors as fatal (default value
#pod for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
#pod setting C<$utf8::all::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
#pod the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
#pod ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
#pod I<always> enforced.
#pod
#pod Important: Only controls the handling of decoding errors in C<glob>,
#pod C<readdir>, and C<readlink>.
#pod
#pod =cut

use Encode ();
use PerlIO::utf8_strict;

our $UTF8_CHECK = Encode::FB_CROAK | Encode::LEAVE_SRC; # Die on encoding errors

# UTF-8 Encoding object
my $_UTF8 = Encode::find_encoding('UTF-8');

sub import {
    # Enable features/pragmas in calling package
    my $target = caller;

    # Enable global effects be default only when imported from main package
    my $no_global = $target ne 'main';

    # Override global?
    if (defined $_[1] && $_[1] =~ /^(?:(NO-)?GLOBAL|LEXICAL-ONLY)$/i) {
        $no_global = $_[1] !~ /^GLOBAL$/i;
        splice(@_, 1, 1); # Remove option from import's arguments
    }

    'utf8'->import::into($target);
    'open'->import::into($target, 'IO' => ':utf8_strict');

    # use open ':std' only works with some encodings.
    state $have_encoded_std = 0;
    unless ($no_global || $have_encoded_std++) {
        binmode STDERR, ':utf8_strict';
        binmode STDOUT, ':utf8_strict';
        binmode STDIN,  ':utf8_strict';
    }

    'charnames'->import::into($target, qw{:full :short});
    'warnings'->import::into($target, qw{FATAL utf8});
    'feature'->import::into($target, qw{unicode_strings}) if $^V >= v5.11.0;
    'feature'->import::into($target, qw{unicode_eval fc}) if $^V >= v5.16.0;

    unless ($no_global || $^O =~ /MSWin32|cygwin|dos|os2/) {
        no strict qw(refs); ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no warnings qw(redefine);

        # Replace readdir with utf8 aware version
        *{$target . '::readdir'} = \&_utf8_readdir;

        # Replace readdir with utf8 aware version
        *{$target . '::readlink'} = \&_utf8_readlink;

        # Replace glob with utf8 aware version
        *{$target . '::glob'} = \&_utf8_glob;

        # Set compiler hint to encode/decode in the redefined functions
        $^H{'utf8::all'} = 1;
    }

    # Make @ARGV utf-8 when, unless perl was launched with the -CA
    # flag as this already has @ARGV decoded automatically.  -CA is
    # active if the the fifth bit (32) of the ${^UNICODE} variable is
    # set.  (see perlrun on the -C command switch for details about
    # ${^UNICODE})
    unless ($no_global || (${^UNICODE} & 32)) {
        state $have_encoded_argv = 0;
        if (!$have_encoded_argv++) {
            $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
            $_ = ($_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_) for @ARGV;
        }
    }

    return;
}

sub unimport { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    # Disable features/pragmas in calling package
    # Note: Does NOT undo the effect on @ARGV,
    #       nor on the STDIN, STDOUT, and STDERR file handles!
    #       These effects are always "global".

    my $target = caller;
    'utf8'->unimport::out_of($target);
    'open'->import::into($target, qw{IO :bytes});

    unless ($^O =~ /MSWin32|cygwin|dos|os2/) {
        $^H{'utf8::all'} = 0; # Reset compiler hint
    }

    return;
}

sub _utf8_readdir(*) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $pre_handle = shift;
    my $hints = (caller 0)[10];
   my $handle = ref($pre_handle) ? $pre_handle : qualify_to_ref($pre_handle, caller);
    if (not $hints->{'utf8::all'}) {
        return CORE::readdir($handle);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        if (wantarray) {
            return map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } CORE::readdir($handle);
        } else {
            my $r = CORE::readdir($handle);
            return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
        }
    }
}

sub _utf8_readlink(_) { ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    my $arg = shift;
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::readlink($arg);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        $arg = $arg ? $_UTF8->encode($arg, $UTF8_CHECK) : $arg;
        my $r = CORE::readlink($arg);
        return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
    }
}

sub _utf8_glob {
    my $arg = $_[0]; # Making this a lexical somehow is important!
    my $hints = (caller 0)[10];
    if (not $hints->{'utf8::all'}) {
        return CORE::glob($arg);
    } else {
        $UTF8_CHECK |= Encode::LEAVE_SRC if $UTF8_CHECK; # Enforce LEAVE_SRC
        $arg = $arg ? $_UTF8->encode($arg, $UTF8_CHECK) : $arg;
        if (wantarray) {
            return map { $_ ? $_UTF8->decode($_, $UTF8_CHECK) : $_ } CORE::glob($arg);
        } else {
            my $r = CORE::glob($arg);
            return $r ? $_UTF8->decode($r, $UTF8_CHECK) : $r;
        }
    }
}

#pod =head1 INTERACTION WITH AUTODIE
#pod
#pod If you use L<autodie>, which is a great idea, you need to use at least
#pod version B<2.12>, released on L<June 26,
#pod 2012|https://metacpan.org/source/PJF/autodie-2.12/Changes#L3>.
#pod Otherwise, autodie obliterates the IO layers set by the L<open>
#pod pragma. See L<RT
#pod #54777|https://rt.cpan.org/Ticket/Display.html?id=54777> and L<GH
#pod #7|https://github.com/doherty/utf8-all/issues/7>.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

utf8::all - turn on Unicode - all of it

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use utf8::all;                      # Turn on UTF-8, all of it.

    open my $in, '<', 'contains-utf8';  # UTF-8 already turned on here
    print length 'føø bār';             # 7 UTF-8 characters
    my $utf8_arg = shift @ARGV;         # @ARGV is UTF-8 too (only for main)

=head1 DESCRIPTION

The C<use utf8> pragma tells the Perl parser to allow UTF-8 in the
program text in the current lexical scope. This also means that you
can now use literal Unicode characters as part of strings, variable
names, and regular expressions.

C<utf8::all> goes further:

=over 4

=item *

L<C<charnames>|charnames> are imported so C<\N{...}> sequences can be
used to compile Unicode characters based on names.

=item *

On Perl C<v5.11.0> or higher, the C<use feature 'unicode_strings'> is
enabled.

=item *

C<use feature fc> and C<use feature unicode_eval> are enabled on Perl
C<5.16.0> and higher.

=item *

Filehandles are opened with UTF-8 encoding turned on by default
(including C<STDIN>, C<STDOUT>, and C<STDERR> when C<utf8::all> is
used from the C<main> package). Meaning that they automatically
convert UTF-8 octets to characters and vice versa. If you I<don't>
want UTF-8 for a particular filehandle, you'll have to set C<binmode
$filehandle>.

=item *

C<@ARGV> gets converted from UTF-8 octets to Unicode characters (when
C<utf8::all> is used from the C<main> package). This is similar to the
behaviour of the C<-CA> perl command-line switch (see L<perlrun>).

=item *

C<readdir>, C<readlink>, C<readpipe> (including the C<qx//> and
backtick operators), and L<C<glob>|perlfunc/glob> (including the C<<
<> >> operator) now all work with and return Unicode characters
instead of (UTF-8) octets (again only when C<utf8::all> is used from
the C<main> package).

=back

=head2 Lexical Scope

The pragma is lexically-scoped, so you can do the following if you had
some reason to:

    {
        use utf8::all;
        open my $out, '>', 'outfile';
        my $utf8_str = 'føø bār';
        print length $utf8_str, "\n"; # 7
        print $out $utf8_str;         # out as utf8
    }
    open my $in, '<', 'outfile';      # in as raw
    my $text = do { local $/; <$in>};
    print length $text, "\n";         # 10, not 7!

Instead of lexical scoping, you can also use C<no utf8::all> to turn
off the effects.

Note that the effect on C<@ARGV> and the C<STDIN>, C<STDOUT>, and
C<STDERR> file handles is always global and can not be undone!

=head2 Enabling/Disabling Global Features

As described above, the default behaviour of C<utf8::all> is to
convert C<@ARGV> and to open the C<STDIN>, C<STDOUT>, and C<STDERR>
file handles with UTF-8 encoding, and override the C<readlink> and
C<readdir> functions and C<glob> operators when C<utf8::all> is used
from the C<main> package.

If you want to disable these features even when C<utf8::all> is used
from the C<main> package, add the option C<NO-GLOBAL> (or
C<LEXICAL-ONLY>) to the use line. E.g.:

    use utf8::all 'NO-GLOBAL';

If on the other hand you want to enable these global effects even when
C<utf8::all> was used from another package than C<main>, use the
option C<GLOBAL> on the use line:

    use utf8::all 'GLOBAL';

=head2 UTF-8 Errors

C<utf8::all> will handle invalid code points (i.e., utf-8 that does
not map to a valid unicode "character"), as a fatal error.

For C<glob>, C<readdir>, and C<readlink>, one can change this
behaviour by setting the attribute L</"$utf8::all::UTF8_CHECK">.

=head1 ATTRIBUTES

=head2 $utf8::all::UTF8_CHECK

By default C<utf8::all> marks decoding errors as fatal (default value
for this setting is C<Encode::FB_CROAK>). If you want, you can change this by
setting C<$utf8::all::UTF8_CHECK>. The value C<Encode::FB_WARN> reports
the encoding errors as warnings, and C<Encode::FB_DEFAULT> will completely
ignore them. Please see L<Encode> for details. Note: C<Encode::LEAVE_SRC> is
I<always> enforced.

Important: Only controls the handling of decoding errors in C<glob>,
C<readdir>, and C<readlink>.

=head1 INTERACTION WITH AUTODIE

If you use L<autodie>, which is a great idea, you need to use at least
version B<2.12>, released on L<June 26,
2012|https://metacpan.org/source/PJF/autodie-2.12/Changes#L3>.
Otherwise, autodie obliterates the IO layers set by the L<open>
pragma. See L<RT
#54777|https://rt.cpan.org/Ticket/Display.html?id=54777> and L<GH
#7|https://github.com/doherty/utf8-all/issues/7>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/doherty/utf8-all/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COMPATIBILITY

The filesystems of Dos, Windows, and OS/2 do not (fully) support
UTF-8. The C<readlink> and C<readdir> functions and C<glob> operators
will therefore not be replaced on these systems.

=head1 SEE ALSO

=over 4

=item *

L<File::Find::utf8> for fully utf-8 aware File::Find functions.

=item *

L<Cwd::utf8> for fully utf-8 aware Cwd functions.

=back

=head1 AUTHORS

=over 4

=item *

Michael Schwern <mschwern@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=item *

Hayo Baan <info@hayobaan.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Michael Schwern <mschwern@cpan.org>; he originated it.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
