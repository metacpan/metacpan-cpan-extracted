package Test2::Tools::PerlCritic;

use strict;
use warnings;
use Exporter qw( import );
use 5.020;
use experimental qw( postderef signatures );
use Carp qw( croak );
use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref is_blessed_ref is_plain_coderef );
use Test2::API qw( context );
use Perl::Critic ();
use Perl::Critic::Utils ();
use Path::Tiny ();
use Class::Tiny qw( critic test_name files _hooks );

our @EXPORT = qw( perl_critic_ok );

# ABSTRACT: Testing tools to enforce Perl::Critic policies
our $VERSION = '0.08'; # VERSION


sub BUILDARGS
{
  my $class = shift; # unused

  if(is_plain_hashref $_[0] && @_ == 1)
  {
    return $_[0];
  }

  my $files = shift;
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

  return {
    files => $files,
    critic => $critic,
    test_name => $test_name,
  };
}

sub BUILD ($self, $)
{
  my $files = $self->files;

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

  unless(defined $self->test_name)
  {
    $self->test_name("no Perl::Critic policy violations for @$files");
  }

  @$files = sort map { Path::Tiny->new($_)->stringify } map {
    -f $_
      ? $_
      : -d $_
        ? Perl::Critic::Utils::all_perl_files("$_")
        : croak "not a file or directory: $_";
  } @$files;

  $self->files($files);

  $self->_hooks({
    cleanup => [],
  });
}

sub DEMOLISH ($self, $global)
{
  $_->($self, $global) for $self->_hooks->{cleanup}->@*;
}


sub perl_critic_ok
{
  my $self = is_blessed_ref($_[0]) && $_[0]->isa(__PACKAGE__) ? $_[0] : __PACKAGE__->new(@_);

  my %violations;

  foreach my $file ($self->files->@*)
  {
    my @critic_violations = $self->critic->critique($file);
    next unless @critic_violations;

    if(my $hooks = $self->_hooks->{violations})
    {
      $_->($self, @critic_violations) for @$hooks;
    }

    foreach my $critic_violation (@critic_violations)
    {
      my $policy = $critic_violation->policy;
      my $violation = $violations{$policy} //= Test2::Tools::PerlCritic::Violation->new($critic_violation);
      $violation->add_file_location($critic_violation);
    }
  }

  my $ok = 1;
  my @diag;
  my @note;

  if(%violations)
  {
    foreach my $violation (sort { $a->policy cmp $b->policy } values %violations)
    {
      if(my $hook = $self->_hooks->{progressive_check})
      {
        $violation->progressive_check($self, $hook);
      }
      push @diag, $violation->diag;
      push @note, $violation->note;
      $ok = 0 unless $violation->ok;
    }
  }

  my $ctx = context();
  if($ok)
  {
    $ctx->pass($self->test_name);
    $ctx->diag($_) for @diag;
  }
  else
  {
    $ctx->fail($self->test_name, @diag);
  }

  if(@note)
  {
    $ctx->note("### The following violations were grandfathered from before ###");
    $ctx->note("### these polcies were applied and so should be fixed only  ###");
    $ctx->note("### when practical                                          ###");
    $ctx->note($_) for @note;
  }

  $ctx->release;
}


sub add_hook ($self, $name, $sub)
{
  if($name =~ /^(?:progressive_check|cleanup|violations)$/)
  {
    if(is_plain_coderef($sub))
    {
      if($name =~ /^(?:cleanup|violations)$/)
      {
        push $self->_hooks->{$name}->@*, $sub;
      }
      else
      {
        croak "Only one $name hook allowed" if defined $self->_hooks->{$name};
        $self->_hooks->{$name} = $sub;
      }
      return $self;
    }
    croak "hook is not a code reference";
  }
  croak "unknown hook: $name";
}

package Test2::Tools::PerlCritic::Violation;

use Class::Tiny qw( severity description diagnostics policy files );

sub BUILDARGS ($class, $violation)
{
  my %args = map { $_ => $violation->$_ } qw( severity description diagnostics policy );
  $args{files} = {};
  return \%args;
}

sub add_file_location ($self, $violation)
{
  my $file = $self->files->{$violation->logical_filename} //= Test2::Tools::PerlCritic::File->new($violation);
  $file->add_location($violation);
}

sub _chomp ($str)
{
  chomp $str;
  return $str;
}

sub _text ($self)
{
  my @txt;
  push @txt, '';
  push @txt, sprintf("%s [sev %s]", $self->policy, $self->severity);
  push @txt, $self->description;
  push @txt, _chomp($self->diagnostics);
  push @txt, '';
  return @txt;
}

sub diag ($self)
{
  my @diag;

  my $first = 1;

  foreach my $file (sort { $a->logical_filename cmp $b->logical_filename } values $self->files->%*)
  {
    next if $file->progressive_allowed;
    foreach my $location ($file->locations->@*)
    {
      push @diag, $self->_text if $first;
      $first = 0;

      push @diag, sprintf("found at %s line %s column %s",
        Path::Tiny->new($file->logical_filename)->stringify,
        $location->logical_line_number,
        $location->visual_column_number,
      );
    }
  }

  return @diag;
}

sub note ($self)
{
  my @diag;

  my $first = 1;

  foreach my $file (sort { $a->logical_filename cmp $b->logical_filename } values $self->files->%*)
  {
    next unless $file->progressive_allowed;
    foreach my $location ($file->locations->@*)
    {
      push @diag, $self->_text if $first;
      $first = 0;

      push @diag, sprintf("found at %s line %s column %s",
        Path::Tiny->new($file->logical_filename)->stringify,
        $location->logical_line_number,
        $location->visual_column_number,
      );
    }
  }

  return @diag;
}

sub ok ($self)
{
  foreach my $file (values $self->files->%*)
  {
    return 0 unless $file->ok;
  }
  return 1;
}

sub progressive_check ($self, $test_critic, $code)
{
  foreach my $file (values $self->files->%*)
  {
    if($code->($test_critic, $self->policy, $file->logical_filename, $file->count))
    {
      $file->progressive_allowed(1);
    }
  }
}

package Test2::Tools::PerlCritic::File;

use Class::Tiny qw( logical_filename locations progressive_allowed );

sub BUILDARGS ($class, $violation)
{
  my %args;
  $args{logical_filename} = $violation->logical_filename;
  $args{locations} = [];
  return \%args;
}

sub BUILD ($self, $)
{
  $self->progressive_allowed(0);
}

sub add_location ($self, $violation)
{
  push $self->locations->@*, Test2::Tools::PerlCritic::Location->new($violation);
}

sub count ($self)
{
  scalar $self->locations->@*;
}

sub ok ($self)
{
  return !!$self->progressive_allowed;
}

package Test2::Tools::PerlCritic::Location;

use Class::Tiny qw( logical_line_number visual_column_number );

sub BUILDARGS ($class, $violation)
{
  my %args = map { $_ => $violation->$_ } qw( logical_line_number visual_column_number );
  return \%args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::PerlCritic - Testing tools to enforce Perl::Critic policies

=head1 VERSION

version 0.08

=head1 SYNOPSIS

Original procedural interface:

 use Test2::V0;
 use Test2::Tools::PerlCritic;
 
 perl_critic_ok ['lib','t'], 'test library files';
 
 done_testing;

New OO interface:

 use Test2::V0;
 use Test2::Tools::PerlCritic ();
 use Perl::Critic;
 
 my $test_critic = Test2::Tools::PerlCritic->new({
   files     => ['lib','t'],
   test_name => 'test library_files',
 });
 
 $test_critic->perl_critic_ok;
 
 done_testing;

=head1 DESCRIPTION

Test for L<Perl::Critic> violations using L<Test2>.  Although this testing
tool uses the L<Test2> API instead of the older L<Test::Builder> API, the primary
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

=head1 CONSTRUCTOR

 my $test_critic = Test2::Tools::PerlCritic->new(\%properties);

Properties:

=over 4

=item files

(REQUIRED)

List of files or directories.  Directories will be recursively searched for
Perl files (C<.pm>, C<.pl> and C<.t>).

=item critic

The L<Perl::Critic> instance.  One will be created if not provided.

=item test_name

The name of the test.  This is used in diagnostics.

=back

=head1 METHODS

=head2 perl_critic_ok

 $test_critic->perl_critic_ok;

The method version works just like the functional version above,
except it doesn't take any additional arguments.

=head2 add_hook

 $test_critic->add_hook($hook_name, \&code);

Adds the given hook.  Available hooks:

=over 4

=item cleanup

 $test_critic->add_hook(cleanup => sub ($test_critic, $global) {
   ...
 });

This hook is called when the L<Test2::Tools::PerlCritic> instance is destroyed.

If the hook is called during global destruction of the Perl interpreter,
C<$global> will be set to a true value.

This hook can be set multiple times.

=item progressive_check

 $test_critic->add_hook(progressive_check => sub ($test_critic, $policy, $file, $count) {
   ...
   return $bool;
 });

This hook is made available for violations in existing code when new policies
are added.  Passed in are the L<Test2::Tools::PerlCritic> instance, the policy
name, the filename and the number of times the violation was found.  If the
violations are from an old code base with grandfathered allowed violations,
this hook should return true, and the violation will be reported as a C<note>
instead of C<diag> and will not cause the test as a whole to fail.  Otherwise
the violation will be reported using C<diag> and the test as a whole will fail.

This hook can only be set once.

=item violations

 $test_critic->add_hook(violations => sub ($test_critic, @violations) {
   ...
 });

Each time violations are returned from L<Perl::Critic/critique>, they are
passed into this hook as a list.  The order and grouping of violations
may change in the future.

=back

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

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
