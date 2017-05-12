package Test::Subroutines;
{
  $Test::Subroutines::VERSION = '1.113350';
}

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(load_subs);
@EXPORT_OK = qw(get_subref);

use strict;
use warnings FATAL => 'all';

use Devel::LexAlias qw(lexalias);
use PadWalker qw(closed_over peek_my);
use Symbol qw(qualify_to_ref);
use Devel::Symdump;
use File::Slurp;

our @used_modules;
BEGIN {
    unshift @INC, \&trace_use
        unless grep { "$_" eq \&trace_use . '' } @INC;
}

sub trace_use {
    my ($code, $module) = @_;
    (my $mod_name = $module) =~ s{/}{::};
    $mod_name =~ s/\.pm$//;

    push @used_modules, $mod_name;
    return undef;
}

sub load_subs {
    my $text = read_file( shift );
    $text =~ s/\n__DATA__\n.*//s;
    $text =~ s/\n__END__\n.*//s;

    # optional args
    my $pkg = scalar caller (0);
    my $opts = {};
    while (my $thing = shift) {
        if (ref $thing eq ref {}) {
            $opts = $thing;
            next;
        }
        if (ref $thing eq ref '') {
            die "custom namespace must not be nested (i.e. must not include ::)"
                if $thing =~ m/::/;
            $pkg = $thing;
            next;
        }
    }

    my $callpkg = scalar caller(0);
    my $key = 'jei8ohNe';

    $opts->{exit}   ||= sub { $_[0] ||= 0; die "caught exit($_[0])\n" };
    $opts->{system} ||= sub { system @_ };

    my $subs = 'use subs qw('. (join ' ', keys %$opts) .')';
    my @used;

    {
        local @used_modules = ();
        eval "package $pkg; $subs; sub $key { no warnings 'closure'; $text; }; 1;"
            or die $@;
        @used = @used_modules;
    }

    *{qualify_to_ref($_,$pkg)} = $opts->{$_} for (keys %$opts);
    my %globals = %{ [peek_my(1)]->[0] };

    foreach my $qsub ( Devel::Symdump->functions($pkg) ) {
        (my $sub = $qsub) =~ s/^${pkg}:://;
        next if $sub eq $key;

        my $subref = get_subref($sub, $pkg);
        my @vars = keys %{ [closed_over $subref]->[0] };

        foreach my $v (@vars) {
            if (not_external($pkg, $sub, @used)) {
                if (exists $globals{$v}) {
                    lexalias($subref, $v, $globals{$v});
                }
                else {
                    die qq(Missing lexical for "$v" required by "$sub");
                }
            }
        }
    }
}

sub not_external {
    my ($p, $s, @used) = @_;

    foreach my $pack (@used) {
        next unless scalar grep {$_ eq "${pack}::$s"}
                                (Devel::Symdump->functions($pack));
        return 0 if
            get_subref($s, $pack) eq get_subref($s, $p);
            # subref in used package equal to subref in hack package
    }
    return 1;
}

sub get_subref {
    my $sub = shift;
    my $pkg = shift || scalar caller(0);

    my $symtbl = \%{main::};
    foreach my $part(split /::/, $pkg) {
        $symtbl = $symtbl->{"${part}::"};
    }

    return eval{ \&{ $symtbl->{$sub} } };
}

1;

# ABSTRACT: Standalone execution of Perl program subroutines


__END__
=pod

=head1 NAME

Test::Subroutines - Standalone execution of Perl program subroutines

=head1 VERSION

version 1.113350

=head1 PURPOSE

You have a (possibly ancient) Perl program for which you'd like to write some
unit tests. The program code cannot be modified to accommodate this, and you
want to test subroutines but not actually I<run> the program. This module permits
running of the program subroutines standalone, and in relative safety.

=head1 SYNOPSIS

 use Test::Subroutines; # exports load_subs
 
 # set up any globals to match those in the Perl program
 my $global = 'foo';
 
 load_subs( $perl_program_file );
 # subs from $perl_program_file are now available for calling directly
 
 # OR
 
 load_subs( $perl_program_file, $namespace );
 # subs from $perl_program_file are now available for calling in $namespace

=head1 USAGE

You'll need to set-up any environment the subroutines may need, such as global
lexical variables, and also be aware that side effects from the subroutines
will still occur (e.g. database updates).

Load the module like so:

 use Test::Subroutines;

Then use C<load_subs()> to inspect your program and make available the
subroutines within it. Let's say your program is C</usr/bin/myperlapp>. The
simplest call exports the program's subroutines into your own namespace so you
can call them directly. Note use of the C<&> subroutine sigil which is
I<required>:

 load_subs( '/usr/bin/myperlapp' );
 # and then...
 $retval = &myperlapp_sub($a,$b);

If the subroutines happen to use global lexicals in the program, then you do
need to set these up in your own namespace, otherwise C<load_subs()> will
die with an error message. Note that they must be lexicals - i.e. using
C<my>.

If you don't want your own namespace polluted, then load the subroutines into
another namespace:

 load_subs( '/usr/bin/myperlapp', 'MyTestNamespace' );
 # and then...
 $retval = &MyTestNamespace::myperlapp_sub($a,$b);

Note that this namespace must not be nested, in other words it cannot contain
the C<::> characters. This is a simple limitation which could be patched.

=head2 Catching C<exit()> and other such calls

There's the potential for a subroutine to call C<exit()>, which would
seriously cramp the style of your unit tests. All is not lost, as by default
this module installs a hook which turns C<exit()> into C<die()>, and in turn
C<die()> can be caught by an C<eval> as part of your test. You can override
the hook by passing a HASH reference to C<load_subs>, like so:

 load_subs( '/usr/bin/myperlapp', {
     exit => sub { $_[0] ||= 0; die "caught exit($_[0])\n" }
 } );

In fact the example above is the default hook - it dies with that message.
Pass a subroutine reference as shown above and you can get C<exit()> to do
whatever you like. With the default hook, you might have this in your tests:

 # unit test
 eval { &sub_which_exits($a,$b) };
 is( $@, 'caught exit(0)', 'subroutine exit!' );

Finally, a similar facility to that described here for overriding C<exit()> is
available for the C<system()> builtin as well. The default hook for
C<system()> is a noop though - it just allows the call to C<system()> to go
ahead.

=head1 CAVEATS

=over 4

=item *

You have to call the subroutines with leading C<&> to placate strict mode.

=item *

Warnings of category C<closure> are disabled in your loaded program.

=item *

You have to create any required global lexicals in your own namespace.

=back

=head1 ACKNOWLEDGEMENTS

Some folks on IRC were particularly helpful with suggestions: C<batman>,
C<mst> and C<tomboh>. Thanks, guys!

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

