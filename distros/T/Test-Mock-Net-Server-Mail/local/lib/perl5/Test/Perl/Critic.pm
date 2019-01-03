package Test::Perl::Critic;

use 5.006001;

use strict;
use warnings;

use Carp qw(croak);
use English qw(-no_match_vars);

use Test::Builder qw();
use Perl::Critic qw();
use Perl::Critic::Violation qw();
use Perl::Critic::Utils;

#---------------------------------------------------------------------------

our $VERSION = '1.04';

#---------------------------------------------------------------------------

my $TEST = Test::Builder->new;
my $DIAG_INDENT = q{  };
my %CRITIC_ARGS = ();

my $CRITIC_OBJ = undef;
my $BUILD_CRITIC = sub {
    return $CRITIC_OBJ if defined $CRITIC_OBJ;
    $CRITIC_OBJ = Perl::Critic->new( @_ );
};

#---------------------------------------------------------------------------

sub import {

    my ( $self, %args ) = @_;
    my $caller = caller;

    {
        no strict 'refs';  ## no critic qw(ProhibitNoStrict)
        *{ $caller . '::critic_ok' }     = \&critic_ok;
        *{ $caller . '::all_critic_ok' } = \&all_critic_ok;
    }

    # -format is supported for backward compatibility.
    if ( exists $args{-format} ) { $args{-verbose} = $args{-format}; }
    %CRITIC_ARGS = %args;

    # Reset possibly lazy-initialized Perl::Critic.
    $CRITIC_OBJ = undef;

    $TEST->exported_to($caller);

    return 1;
}

#---------------------------------------------------------------------------

sub critic_ok {

    my ( $file, $test_name ) = @_;
    croak q{no file specified} if not defined $file;
    croak qq{"$file" does not exist} if not -f $file;
    $test_name ||= qq{Test::Perl::Critic for "$file"};

    my $critic = undef;
    my @violations = ();
    my $ok = 0;

    # Run Perl::Critic
    my $status = eval {
        $critic     = $BUILD_CRITIC->( %CRITIC_ARGS );
        @violations = $critic->critique( $file );
        $ok         = not scalar @violations;
        1;
    };

    # Evaluate results
    $TEST->ok($ok, $test_name );

    if (!$status || $EVAL_ERROR) {   # Trap exceptions from P::C
        $TEST->diag( "\n" );         # Just to get on a new line.
        $TEST->diag( qq{Perl::Critic had errors in "$file":} );
        $TEST->diag( qq{\t$EVAL_ERROR} );
    }
    elsif ( not $ok ) {              # Report Policy violations
        $TEST->diag( "\n" );         # Just to get on a new line.
        my $verbose = $critic->config->verbose();
        Perl::Critic::Violation::set_format( $verbose );
        for my $viol (@violations) { $TEST->diag($DIAG_INDENT . $viol) }
    }

    return $ok;
}

#---------------------------------------------------------------------------

sub all_critic_ok {

    my @dirs_or_files = @_ ? @_ : (-e 'blib' ? 'blib' : 'lib');
    my @files = Perl::Critic::Utils::all_perl_files(@dirs_or_files);
    croak 'Nothing to critique' if not @files;

    my $have_mce = eval { require MCE::Grep; MCE::Grep->import; 1 };
    return $have_mce ? _test_parallel(@files) : _test_serial(@files);
}

#---------------------------------------------------------------------------

sub _test_parallel {
      my @files = @_;

      # Since tests are running in forked MCE workers, test results could arrive
      # in any order. The test numbers will be meaningless, so turn them off.
      $TEST->use_numbers(0);

      # The parent won't know about any of the tests that were run by the forked
      # workers. So we disable the T::B sanity checks at the end of its life.
      $TEST->no_ending(1);

      my $okays = MCE::Grep->run( sub { critic_ok($_) }, @files );
      my $pass = $okays == @files;

      # To make Test::Harness happy, we must emit a test plan and a sensible exit
      # status. Usually, T::B does this for us, but we disabled the ending above.
      $pass || eval 'END { $? = 1 }'; ## no critic qw(Eval Interpolation)
      $TEST->done_testing(scalar @files);

      return $pass;
}

#---------------------------------------------------------------------------

sub  _test_serial {
  my @files = @_;

  my $okays = grep {critic_ok($_)} @files;
  my $pass = $okays == @files;

  $TEST->done_testing(scalar @files);

  return $pass;
}

#---------------------------------------------------------------------------

1;


__END__

=pod

=for stopwords API

=head1 NAME

Test::Perl::Critic - Use Perl::Critic in test programs

=head1 SYNOPSIS

Test one file:

  use Test::Perl::Critic;
  use Test::More tests => 1;
  critic_ok($file);

Or test all files in one or more directories:

  use Test::Perl::Critic;
  all_critic_ok($dir_1, $dir_2, $dir_N );

Or test all files in a distribution:

  use Test::Perl::Critic;
  all_critic_ok();

Recommended usage for CPAN distributions:

  use strict;
  use warnings;
  use File::Spec;
  use Test::More;
  use English qw(-no_match_vars);

  if ( not $ENV{TEST_AUTHOR} ) {
      my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
      plan( skip_all => $msg );
  }

  eval { require Test::Perl::Critic; };

  if ( $EVAL_ERROR ) {
     my $msg = 'Test::Perl::Critic required to criticise code';
     plan( skip_all => $msg );
  }

  my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
  Test::Perl::Critic->import( -profile => $rcfile );
  all_critic_ok();


=head1 DESCRIPTION

Test::Perl::Critic wraps the L<Perl::Critic> engine in a convenient subroutine
suitable for test programs written using the L<Test::More> framework.  This
makes it easy to integrate coding-standards enforcement into the build
process.  For ultimate convenience (at the expense of some flexibility), see
the L<criticism> pragma.

If you have an large existing code base, you might prefer to use
L<Test::Perl::Critic::Progressive>, which allows you to clean your code
incrementally instead of all at once..

If you'd like to try L<Perl::Critic> without installing anything, there is a
web-service available at L<http://perlcritic.com>.  The web-service does not
support all the configuration features that are available in the native
Perl::Critic API, but it should give you a good idea of what Perl::Critic can
do.

=head1 SUBROUTINES

=over

=item all_critic_ok( [ @FILES ] )

Runs C<critic_ok()> for all Perl files in the list of C<@FILES>. If a file is
actually a directory, then all Perl files beneath that directory (recursively)
will be run through C<critic_ok()>. If C<@FILES> is empty or not given, then the
F<blib/> is used if it exists, and if not, then F<lib/> is used. Returns true
if all files are okay, or false if any file fails.

This subroutine emits its own test plan, so you do not need to specify the
expected number of tests or call C<done_testing()>. Therefore, C<all_critic_ok>
generally cannot be used in a test script that includes other sorts of tests.

C<all_critic_ok()> is also optimized to run tests in parallel over multiple cores
(if you have them) so it is usually better to call this function than calling
C<critic_ok()> directly.

=item critic_ok( $FILE [, $TEST_NAME ] )

Okays the test if Perl::Critic does not find any violations in C<$FILE>.  If it
does, the violations will be reported in the test diagnostics.  The optional
second argument is the name of test, which defaults to "Perl::Critic test for
$FILE".

If you use this form, you should load L<Test::More> and emit your own test plan
first or call C<done_testing()> afterwards.

=back

=head1 CONFIGURATION

L<Perl::Critic> is highly configurable.  By default, Test::Perl::Critic
invokes Perl::Critic with its default configuration.  But if you have
developed your code against a custom Perl::Critic configuration, you will want
to configure Test::Perl::Critic to do the same.

Any arguments passed through the C<use> pragma (or via
C<< Test::Perl::Critic->import() >> )will be passed into the L<Perl::Critic>
constructor.  So if you have developed your code using a custom
F<~/.perlcriticrc> file, you can direct L<Test::Perl::Critic> to use your
custom file too.

  use Test::Perl::Critic (-profile => 't/perlcriticrc');
  all_critic_ok();

Now place a copy of your own F<~/.perlcriticrc> file in the distribution as
F<t/perlcriticrc>.  Then, C<critic_ok()> will be run on all Perl files in this
distribution using this same Perl::Critic configuration.  See the
L<Perl::Critic> documentation for details on the F<.perlcriticrc> file format.

Any argument that is supported by the L<Perl::Critic> constructor can be
passed through this interface.  For example, you can also set the minimum
severity level, or include & exclude specific policies like this:

  use Test::Perl::Critic (-severity => 2, -exclude => ['RequireRcsKeywords']);
  all_critic_ok();

See the L<Perl::Critic> documentation for complete details on its
options and arguments.

=head1 DIAGNOSTIC DETAILS

By default, Test::Perl::Critic displays basic information about each Policy
violation in the diagnostic output of the test.  You can customize the format
and content of this information by using the C<-verbose> option.  This behaves
exactly like the C<-verbose> switch on the F<perlcritic> program.  For
example:

  use Test::Perl::Critic (-verbose => 6);

  #or...

  use Test::Perl::Critic (-verbose => '%f: %m at %l');

If given a number, L<Test::Perl::Critic> reports violations using one of the
predefined formats described below. If given a string, it is interpreted to be
an actual format specification. If the C<-verbose> option is not specified, it
defaults to 3.

    Verbosity     Format Specification
    -----------   -------------------------------------------------------
     1            "%f:%l:%c:%m\n",
     2            "%f: (%l:%c) %m\n",
     3            "%m at %f line %l\n",
     4            "%m at line %l, column %c.  %e.  (Severity: %s)\n",
     5            "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n",
     6            "%m at line %l, near '%r'.  (Severity: %s)\n",
     7            "%f: %m at line %l near '%r'.  (Severity: %s)\n",
     8            "[%p] %m at line %l, column %c.  (Severity: %s)\n",
     9            "[%p] %m at line %l, near '%r'.  (Severity: %s)\n",
    10            "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n",
    11            "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n"

Formats are a combination of literal and escape characters similar to the way
C<sprintf> works. See L<String::Format> for a full explanation of the
formatting capabilities. Valid escape characters are:

    Escape    Meaning
    -------   ----------------------------------------------------------------
    %c        Column number where the violation occurred
    %d        Full diagnostic discussion of the violation (DESCRIPTION in POD)
    %e        Explanation of violation or page numbers in PBP
    %F        Just the name of the logical file where the violation occurred.
    %f        Path to the logical file where the violation occurred.
    %G        Just the name of the physical file where the violation occurred.
    %g        Path to the physical file where the violation occurred.
    %l        Logical line number where the violation occurred
    %L        Physical line number where the violation occurred
    %m        Brief description of the violation
    %P        Full name of the Policy module that created the violation
    %p        Name of the Policy without the Perl::Critic::Policy:: prefix
    %r        The string of source code that caused the violation
    %C        The class of the PPI::Element that caused the violation
    %s        The severity level of the violation


=head1 CAVEATS

Despite the convenience of using a test script to enforce your coding
standards, there are some inherent risks when distributing those tests to
others.  Since you don't know which version of L<Perl::Critic> the end-user
has and whether they have installed any additional Policy modules, you can't
really be sure that your code will pass the Test::Perl::Critic tests on
another machine.

B<For these reasons, we strongly advise you to make your perlcritic tests
optional, or exclude them from the distribution entirely.>

The recommended usage in the L<"SYNOPSIS"> section illustrates one way to make
your F<perlcritic.t> test optional.  Another option is to put F<perlcritic.t>
and other author-only tests in a separate directory (F<xt/> seems to be
common), and then use a custom build action when you want to run them.  Also,
you should B<not> list Test::Perl::Critic as a requirement in your build
script.  These tests are only relevant to the author and should not be a
prerequisite for end-use.

See L<http://chrisdolan.net/talk/2005/11/14/private-regression-tests/>
for an interesting discussion about Test::Perl::Critic and other types
of author-only regression tests.

=head1 FOR Dist::Zilla USERS

If you use Test::Perl::Critic with L<Dist::Zilla>, beware that some DZ plugins
may mutate your code in ways that are not compliant with your Perl::Critic
rules. In particular, the standard L<Dist::Zilla::Plugin::PkgVersion> will
inject a C<$VERSION> declaration at the top of the file, which will violate
L<Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict>. One solution
is to use the L<Dist::Zilla::Plugin::OurPkgVersion> which allows you to control
where the C<$VERSION> declaration appears.

=head1 EXPORTS

  critic_ok()
  all_critic_ok()

=head1 BUGS

If you find any bugs, please submit them to
L<https://github.com/Perl-Critic/Test-Perl-Critic/issues>.  Thanks.


=head1 SEE ALSO

L<Module::Starter::PBP>

L<Perl::Critic>

L<Test::More>

=head1 CREDITS

Andy Lester, whose L<Test::Pod> module provided most of the code and
documentation for Test::Perl::Critic.  Thanks, Andy.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@thaljef.org>

=head1 COPYRIGHT

Copyright (c) 2005-2018 Jeffrey Ryan Thalhammer.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
