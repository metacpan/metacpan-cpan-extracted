package re::engine::Hooks;

use 5.010_001;

use strict;
use warnings;

=head1 NAME

re::engine::Hooks - Hookable variant of the Perl core regular expression engine.

=head1 VERSION

Version 0.06

=cut

our ($VERSION, @ISA);

sub dl_load_flags { 0x01 }

BEGIN {
 $VERSION = '0.06';
 require DynaLoader;
 push @ISA, qw<Regexp DynaLoader>;
 __PACKAGE__->bootstrap($VERSION);
}

=head1 SYNOPSIS

In your XS file :

    #include "re_engine_hooks.h"

    STATIC void dri_comp_node_hook(pTHX_ regexp *rx, regnode *node) {
     ...
    }

    STATIC void dri_exec_node_hook(pTHX_
       regexp *rx, regnode *node, regmatch_info *info, regmatch_state *state) {
     ...
    }

    MODULE = Devel::Regexp::Instrument    PACKAGE = Devel::Regexp::Instrument

    BOOT:
    {
     reh_config cfg;
     cfg.comp_node = dri_comp_node_hook;
     cfg.exec_node = dri_exec_node_hook;
     reh_register("Devel::Regexp::Instrument", &cfg);
    }

In your Perl module file :

    package Devel::Regexp::Instrument;

    use strict;
    use warnings;

    our ($VERSION, @ISA);

    use re::engine::Hooks; # Before loading our own shared library

    BEGIN {
     $VERSION = '0.02';
     require DynaLoader;
     push @ISA, 'DynaLoader';
     __PACKAGE__->bootstrap($VERSION);
    }

    sub import   { re::engine::Hooks::enable(__PACKAGE__) }

    sub unimport { re::engine::Hooks::disable(__PACKAGE__) }

    1;

In your F<Makefile.PL>

    use ExtUtils::Depends;

    my $ed = ExtUtils::Depends->new(
     'Devel::Regexp::Instrument' => 're::engine::Hooks',
    );

    WriteMakefile(
     $ed->get_makefile_vars,
     ...
    );

=head1 DESCRIPTION

This module provides a version of the perl regexp engine that can call user-defined XS callbacks at the compilation and at the execution of each regexp node.

=head1 C API

The C API is made available through the F<re_engine_hooks.h> header file.

=head2 C<reh_comp_node_hook>

The typedef for the regexp node compilation phase hook.
Currently evaluates to :

    typedef void (*reh_comp_node_hook)(pTHX_ regexp *, regnode *);

=head2 C<reh_exec_node_hook>

The typedef for the regexp node_execution phase hook.
Currently evaluates to :

    typedef void (*reh_exec_node_hook)(pTHX_ regexp *, regnode *, regmatch_info *, regmatch_state *);

=head2 C<reh_config>

A typedef'd struct that holds a set of all the different callbacks publicized by this module.
It has the following members :

=over 4

=item *

C<comp_node>

A function pointer of type C<reh_comp_node_hook> that will be called each time a regnode is compiled.
Allowed to be C<NULL> if you don't want to call anything for this phase.

=item *

C<exec_node>

A function pointer of type C<reh_exec_node_hook> that will be called each time a regnode is executed.
Allowed to be C<NULL> if you don't want to call anything for this phase.

=back

=head2 C<reh_register>

    void reh_register(pTHX_ const char *key, reh_config *cfg);

Registers the callbacks specified by the C<reh_config *> object C<cfg> under the given name C<key>.
C<cfg> can be a pointer to a static object of type C<reh_config>.
C<key> is expected to be a nul-terminated string and should match the argument passed to L</enable> and L</disable> in Perl land.
An exception will be thrown if C<key> has already been used to register callbacks.

=cut

my $RE_ENGINE = _ENGINE();

my $croak = sub {
 require Carp;
 Carp::croak(@_);
};

=head1 PERL API

=head2 C<enable>

    enable $key;

Lexically enables the hooks associated with the key C<$key>.

=head2 C<disable>

    disable $key;

Lexically disables the hooks associated with the key C<$key>.

=cut

sub enable {
 my ($key) = @_;

 s/^\s+//, s/\s+$// for $key;
 $croak->('Invalid key') if $key =~ /\s/ or not _registered($key);
 $croak->('Another regexp engine is in use') if  $^H{regcomp}
                                             and $^H{regcomp} != $RE_ENGINE;

 $^H |= 0x020000;

 my $hint = $^H{+(__PACKAGE__)} // '';
 $hint = "$key $hint";
 $^H{+(__PACKAGE__)} = $hint;

 $^H{regcomp} = $RE_ENGINE;

 return;
}

sub disable {
 my ($key) = @_;

 s/^\s+//, s/\s+$// for $key;
 $croak->('Invalid key') if $key =~ /\s/ or not _registered($key);

 $^H |= 0x020000;

 my @other_keys = grep !/^\Q$key\E$/, split /\s+/, $^H{+(__PACKAGE__)} // '';
 $^H{+(__PACKAGE__)} = join ' ', @other_keys, '';

 delete $^H{regcomp} if $^H{regcomp} and $^{regcomp} == $RE_ENGINE
                                     and !@other_keys;

 return;
}

=head1 EXAMPLES

Please refer to the F<t/re-engine-Hooks-TestDist/> directory in the distribution.
It implements a couple of simple examples.

=head1 DEPENDENCIES

Any stable release of L<perl> since 5.10.1, or a development release of L<perl> from the 5.19 branch.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<ExtUtils::Depends>.

=head1 SEE ALSO

L<perlreguts>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-re-engine-hooks at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=re-engine-Hooks>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command :

    perldoc re::engine::Hooks

=head1 COPYRIGHT & LICENSE

Copyright 2012,2013,2014 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Except for the contents of the F<src/5*> directories which are slightly modified versions of files extracted from the C<perl> distribution and are

Copyright 1987-2014, Larry Wall, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of either the GNU General Public License (version 1 or, at your option, any later version), or the Artistic License (see L<perlartistic>).

=cut

1;
