#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/lib/criticism.pm $
#     $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 203 $
########################################################################

package criticism;

use strict;
use warnings;
use English qw(-no_match_vars);
use Carp qw(carp croak);

#-----------------------------------------------------------------------------

our $VERSION = 1.02;

#-----------------------------------------------------------------------------
# We could use the SEVERITY constants from Perl::Critic instead of magic
# numbers.  That would require us to load Perl::Critic, but this pragma
# must fail gracefully if Perl::Critic is not available.  Therefore, we're
# going to tolerate the magic numbers.

## no critic (ProhibitMagicNumbers);
my %SEVERITY_OF = (
    gentle => 5,
    stern  => 4,
    harsh  => 3,
    cruel  => 2,
    brutal => 1,
);
## use critic;

my $DEFAULT_MOOD = 'gentle';
my $DEFAULT_VERBOSE = "%m at %f line %l.\n";

#-----------------------------------------------------------------------------

sub import {

    my ($pkg, @args) = @_;
    my $file = (caller)[1];
    return 1 if not -f $file;
    my %pc_args = _make_pc_args( @args );
    return _critique( $file, %pc_args );
}

#-----------------------------------------------------------------------------

sub _make_pc_args {

    my (@args) = @_;
    my %pc_args = ();

    if (@args <= 1 ) {
        my $mood = $args[0] || $DEFAULT_MOOD;
        my $severity = $SEVERITY_OF{$mood} || _throw_mood_exception( $mood );
        %pc_args = (-severity => $severity, -verbose => $DEFAULT_VERBOSE);
    }
    else {
        %pc_args = @args;
        $pc_args{-verbose} ||= $DEFAULT_VERBOSE;
    }

    return %pc_args;
}

#-----------------------------------------------------------------------------

sub _critique {

    my ($file, %pc_args) = @_;
    my @violations = ();
    my $critic = undef;

    eval {
        require Perl::Critic;
        require Perl::Critic::Violation;
        $critic  = Perl::Critic->new( %pc_args );
        my $verbose = $critic->config->verbose();
        Perl::Critic::Violation::set_format($verbose);
        @violations = $critic->critique($file);
        print {*STDERR} @violations;
        1;
    }
    or do {
        if ($ENV{DEBUG} || $PERLDB) {
            carp qq{'criticism' failed to load: $EVAL_ERROR};
            return;
        }
    };

    die "Refusing to continue due to Perl::Critic violations.\n"
      if @violations && $critic->config->criticism_fatal();

    return @violations ? 0 : 1;
}

#-----------------------------------------------------------------------------

sub _throw_mood_exception {
    my ($mood) = @_;
    my @moods = keys %SEVERITY_OF;
    @moods = reverse sort { $SEVERITY_OF{$a} <=> $SEVERITY_OF{$b} } @moods;
    croak qq{"$mood" criticism not supported.  Choose from: @moods};
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords API Thalhammer perlcritic pragma pseudo-pragma

=head1 NAME

criticism - Perl pragma to enforce coding standards and best-practices

=head1 SYNOPSIS

  use criticism;

  use criticism 'gentle';
  use criticism 'stern';
  use criticism 'harsh';
  use criticism 'cruel';
  use criticism 'brutal';

  use criticism ( -profile => '/foo/bar/perlcriticrc' );
  use criticism ( -severity => 3, -verbose => '%m at %f line %l' );

=head1 DESCRIPTION

This pragma enforces coding standards and promotes best-practices by
running your file through L<Perl::Critic|Perl::Critic> before every
execution.  In a production system, this usually isn't feasible
because it adds a lot of overhead at start-up.  If you have a separate
development environment, you can effectively bypass the C<criticism>
pragma by not installing L<Perl::Critic|Perl::Critic> in the
production environment.  If L<Perl::Critic|Perl::Critic> can't be
loaded, then C<criticism> just fails silently.

Alternatively, the C<perlcritic> command-line (which is distributed
with L<Perl::Critic|Perl::Critic>) can be used to analyze your files
on-demand and has some additional configuration features.  And
L<Test::Perl::Critic|Test::Perl::Critic> provides a nice interface for
analyzing files during the build process.

If you'd like to try L<Perl::Critic|Perl::Critic> without installing
anything, there is a web-service available at
L<http://perlcritic.com>.  The web-service does not yet support all
the configuration features that are available in the native
Perl::Critic API, but it should give you a good idea of what it does.
You can also invoke the perlcritic web-service from the command line
by doing an HTTP-post, such as one of these:

  $> POST http://perlcritic.com/perl/critic.pl < MyModule.pm
  $> lwp-request -m POST http://perlcritic.com/perl/critic.pl < MyModule.pm
  $> wget -q -O - --post-file=MyModule.pm http://perlcritic.com/perl/critic.pl

Please note that the perlcritic web-service is still alpha code.  The
URL and interface to the service are subject to change.

=head1 CONFIGURATION

If there is B<exactly one> import argument, then it is taken to be a
named equivalent to one of the numeric severity levels supported by
L<Perl::Critic|Perl::Critic>.  For example, C<use criticism 'gentle';>
is equivalent to setting the C<< -severity => 5 >>, which reports only
the most dangerous violations.  On the other hand, C<use criticism
'brutal';> is like setting the C<< -severity => 1 >>, which reports
B<every> violation.  If there are no import arguments, then it
defaults to C<'gentle'>.

If there is more than one import argument, then they will all be
passed directly into the L<Perl::Critic|Perl::Critic> constructor.  So you can use
whatever arguments are supported by Perl::Critic.

The C<criticism> pragma will also obey whatever configurations you
have set in your F<.perlcriticrc> file.  In particular, setting the
C<criticism-fatal> option to a true value will cause your program to
immediately C<die> if any Perl::Critic violations are found.
Otherwise, violations are merely advisory.  This option can be set in
the global section at the top of your F<.perlcriticrc> file, like
this:

  # Top of your .perlcriticrc file...
  criticism-fatal = 1

  # per-policy configurations follow...

You can also pass C<< ('-criticism-fatal' => 1) >> as import
arguments, just like any other L<Perl::Critic|Perl::Critic> argument.
See L<Perl::Critic/"CONFIGURATION"> for details on the other
configuration options.

=head1 DIAGNOSTICS

Usually, the C<criticism> pragma fails silently if it cannot load
Perl::Critic.  So by B<not> installing Perl::Critic in your production
environment, you can leave the C<criticism> pragma in your production
source code and it will still compile, but it won't be analyzed by
Perl::Critic each time it runs.

However, if you set the C<DEBUG> environment variable to a true value
or run your program under the Perl debugger, you will get a warning
when C<criticism> fails to load L<Perl::Critic|Perl::Critic>.

=head1 NOTES

The C<criticism> pragma applies to the entire file, so it is not
affected by scope or package boundaries and C<use>-ing it multiple
times will just cause it to repeatedly process the same file.  There
isn't a reciprocal C<no criticism> pragma.  However,
L<Perl::Critic|Perl::Critic> does support a pseudo-pragma that directs
it to overlook certain lines or blocks of code.  See
L<Perl::Critic/"BENDING THE RULES"> for more details.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
