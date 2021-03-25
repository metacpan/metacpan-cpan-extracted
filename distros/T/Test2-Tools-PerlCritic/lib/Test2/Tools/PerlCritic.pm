package Test2::Tools::PerlCritic;

use strict;
use warnings;
use base qw( Exporter );
use 5.020;
use experimental qw( postderef );
use Carp qw( croak );
use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref );
use Test2::API qw( context );
use Perl::Critic ();
use Perl::Critic::Utils ();
use Path::Tiny ();

our @EXPORT = qw( perl_critic_ok );

# ABSTRACT: Testing tools to enforce Perl::Critic policies
our $VERSION = '0.04'; # VERSION


sub _args
{
  my $files = shift;

  if(defined $files)
  {
    if(is_ref $files)
    {
      unless(is_plain_arrayref $files)
      {
        croak "file argument muse be a file/directory name or and array of reference of file/directory names";
      }
    }
    else
    {
      $files = [$files];
    }

    @$files = map { "$_" } @$files;

  }
  else
  {
    croak "no files provided";
  }

  my @opts;
  my $critic;

  if(defined $_[0] && is_ref $_[0]) {
    if(is_plain_arrayref $_[0])
    {
      @opts = @{ shift() };
    }
    elsif(is_plain_hashref $_[0])
    {
      @opts = %{ shift() };
    }
    elsif(eval { $_[0]->isa('Perl::Critic') })
    {
      $critic = shift;
    }
    else
    {
      croak "options must be either an array or hash reference";
    }
  }

  $critic ||= Perl::Critic->new(@opts);

  my $test_name = shift;

  $test_name //= "no Perl::Critic policy violations for @$files";

  @$files = sort map { Path::Tiny->new($_)->stringify } map {
    -f $_
      ? $_
      : -d $_
        ? Perl::Critic::Utils::all_perl_files("$_")
        : croak "not a file or directory: $_";
  } @$files;

  ($files, $critic, $test_name);
}

sub _chomp
{
  my $str = shift;
  chomp $str;
  $str;
}


sub perl_critic_ok
{
  my($files, $critic, $test_name) = _args(@_);

  my %violations;

  foreach my $file (@$files)
  {
    foreach my $violation ($critic->critique($file))
    {
      push $violations{$violation->policy}->@*, $violation;
    }
  }

  my $ctx = context();

  if(%violations)
  {
    my @diag;

    foreach my $policy (sort keys %violations)
    {
      my($first) = $violations{$policy}->@*;
      push @diag, '';
      push @diag, sprintf("%s [sev %s]", $policy, $first->severity);
      push @diag, $first->description;
      push @diag, _chomp($first->diagnostics);
      push @diag, '';
      foreach my $violation ($violations{$policy}->@*)
      {
        push @diag, sprintf("found at %s line %s column %s",
          Path::Tiny->new($violation->logical_filename)->stringify,
          $violation->logical_line_number,
          $violation->visual_column_number,
        );
      }
    }

    $ctx->fail_and_release($test_name, @diag);
    return 0;
  }
  else
  {
    $ctx->pass_and_release($test_name);
    return 1;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PerlCritic - Testing tools to enforce Perl::Critic policies

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Test2::V0;
 use Test2::Tools::PerlCritic;
 
 perl_critic_ok ['lib','t'], 'test library files';
 
 done_testing;

=head1 DESCRIPTION

Test for L<Perl::Critic> violations using L<Test2>.  Although this testing tool
uses the L<Test2> API instead of the older L<Test::Builder> API, the primary
motivation is to provide output in a more useful form.  That is policy violations
are grouped by policy class, and the policy class name is clearly displayed as
a diagnostic.  The author finds the former more useful because he tends to address
one type of violation at a time.  The author finds the latter more useful because
he tends to want to lookup or adjust the configuration of the policy as he is
addressing violations.

=head1 FUNCTIONS

=head2 perl_critic_ok

 perl_critic_ok $path, \@options, $test_name;
 perl_critic_ok \@path, \@options, $test_name;
 perl_critic_ok $path, \%options, $test_name;
 perl_critic_ok \@path, \%options, $test_name;
 perl_critic_ok $path, $critic, $test_name;
 perl_critic_ok \@path, $critic, $test_name;
 perl_critic_ok $path, $test_name;
 perl_critic_ok \@path, $test_name;
 perl_critic_ok $path;
 perl_critic_ok \@path;

Run L<Perl::Critic> on the given files or directories.  The first argument
(C<$path> or C<\@path>) can be either the path to a file or directory, or
a array reference to a list of paths to files and directories.  If C<\@options> or
C<\%options> are provided, then they will be passed into the
L<Perl::Critic> constructor.  If C<$critic> (an instance of L<Perl::Critic>)
is provided, then that L<Perl::Critic> instance will be used instead
of creating one internally.  Finally the C<$test_name> may be provided
if you do not like the default test name.

Only a single test is run regardless of how many files are processed.
this is so that the policy violations can be grouped by policy class
across multiple files.

As a convenience, if the test passes then a true value is returned.
Otherwise a false will be returned.

C<done_testing> or the equivalent is NOT called by this function.
You are responsible for calling that yourself.

Since we do not automatically call C<done_testing>, you can call C<perl_critic_ok>
multiple times, but keep in mind that the policy violations will only be grouped
in each individual call, so it is probably better to provide a list of paths,
rather than make multiple calls.

=head1 CAVEATS

L<Test::Perl::Critic> has been around longer, and probably does at least some things smarter.
The fact that this module groups policy violations for all files by class means that it has
to store more diagnostics in memory before sending them out I<en masse>, where as
L<Test::Perl::Critic> sends violations for each file as it processes them.  L<Test::Perl::Critic>
also comes with some code to optionally do processing in parallel.  Some of these issues may
or may not be addressed in future versions of this module.

Since this module formats it's output the C<-verbose> option is ignored at the C<set_format>
value is ignored.

=head1 SEE ALSO

=over 4

=item L<Test::Perl::Critic>

=item L<Perl::Critic>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
