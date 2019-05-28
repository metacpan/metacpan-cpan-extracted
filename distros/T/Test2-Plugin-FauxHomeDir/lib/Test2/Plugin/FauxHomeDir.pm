package Test2::Plugin::FauxHomeDir;

use strict;
use warnings;
use 5.008001;
use File::Temp qw( tempdir );
use File::Spec;
use File::Path qw( mkpath );
use if $^O eq 'cygwin', 'File::Spec::Win32';
use Test2::API qw( test2_add_callback_post_load test2_stack test2_add_callback_exit );

# ABSTRACT: Setup a faux home directory for tests
our $VERSION = '0.05'; # VERSION


my $real;
my $faux;
my $user;
my @mocks;

sub real_home_dir
{
  $real;
}

sub import
{
  my @notes;

  unless(defined $faux)
  {
    if($^O eq 'MSWin32')
    {
      $real = $ENV{USERPROFILE};
      $real = File::Spec->catdir($ENV{HOMEDRIVE}, $ENV{HOMEPATH})
        unless defined $real;
      $user = $ENV{USERNAME};
    }
    else
    {
      $real = $ENV{HOME};
      $user = $ENV{USER};
    }

    $user = eval { getlogin } unless defined $user;
    $user = eval { scalar getpwuid($>) } unless defined $user;
    die "unable to determine username" unless defined $user;
  
    die "unable to determine 'real' home directory"
      unless defined $real && -d $real;
  
    delete $ENV{USERPROFILE};
    delete $ENV{HOME};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};
  
    $faux = File::Spec->catdir(tempdir( CLEANUP => 1 ), 'home', $user);
    mkpath $faux, 0, 0700;

    if($^O eq 'MSWin32')
    {
      $ENV{USERPROFILE} = $faux;
      ($ENV{HOMEDRIVE}, $ENV{HOMEPATH}) = File::Spec->splitpath($faux,1);
      if(eval { require Portable })
      {
        push @notes, "Portable strawberry detected";
        if(eval { require File::HomeDir })
        {
          # annoyingly, Strawberry Portable Perl patches
          # File::HomeDir, but not things like File::Glob
          # so since there isn't a good interface to override
          # this behavior, we need to patch the patch :(
          push @notes, "Patching File::HomeDir";
          require Test2::Mock;
          push @mocks, Test2::Mock->new(
            class => 'File::HomeDir',
            override => [
              my_home => sub { $faux },
            ],
          );
        }
      }
    }
    elsif($^O eq 'cygwin')
    {
      $ENV{USERPROFILE} = Cygwin::posix_to_win_path($faux);
      ($ENV{HOMEDRIVE}, $ENV{HOMEPATH}) = File::Spec::Win32->splitpath($ENV{USERPROFILE},1);
      $ENV{HOME} = $faux;
    }
    else
    {
      $ENV{HOME} = $faux;
    }

    push @notes, "Test2::Plugin::FauxHomeDir using faux home dir $faux";
    push @notes, "Test2::Plugin::FauxHomeDir real home dir is    $real";
    
    test2_add_callback_post_load(sub {
      test2_stack()->top;
      my($hub) = test2_stack->all;
      $hub->send(
        Test2::Event::Note->new(
          message => $_
        ),
      ) for @notes;
    });

    test2_add_callback_exit(sub {
      my ($ctx, $real, $new) = @_;
      if($INC{'File/HomeDir/Test.pm'})
      {
        my @message = (
          'File::HomeDir::Test was loaded.',
          'You probably do not want to load both File::HomeDir::Test and Test2::Plugin::FauxHomeDir',
        );
        if($real || ($new && $$new) || !$ctx->hub->is_passing)
        {
          $ctx->diag($_) for @message;
        }
        else
        {
          $ctx->note($_) for @message;
        }
      }
    });
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::FauxHomeDir - Setup a faux home directory for tests

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use Test2::Plugin::FauxHomeDir;
 use Test2::V0;

=head1 DESCRIPTION

This module sets up a faux home directory for tests. The home directory 
is empty, and will be removed when the test completes.  This can be 
helpful when you are writing tests that may be reading from the real 
user configuration files, or if it writes output to the user home 
directory.

At the moment this module accomplishes this by setting the operating 
system appropriate environment variables. In the future, it may hook 
into some of the other methods used for determining home directories 
(such as C<getpwuid> and friends).  There are many ways of getting 
around this faux module and getting the real home directory (especially
from C).  But if your code uses standard Perl interfaces then this 
plugin should fool your code okay.

This module sets the native environment variables for the home directory 
on your platform.  That means on Windows C<USERPROFILE>, C<HOMEDRIVE> 
and C<HOMEPATH> will be set, but C<HOME> will not.  This is important 
because your testing environment should match as closely as possible 
what the actual environment will look like.

You should load this module as early as possible.

This systems are actively developed and tested:

=over 4

=item Linux

=item Strawberry Perl (Windows)

=item cygwin

=back

I expect that it should work on most other modern UNIX platforms.  It 
probably will not work on more esoteric systems like VMS or msys2.  
Patches to address this will be eagerly accepted.

=head1 METHODS

=head2 real_home_dir

Returns the real home directory as detected during startup.  If
initialization hasn't happened then this will return C<undef>.

=head1 CAVEATS

Arguably your code shouldn't depend on or be affected by stuff in your 
home directory, or have a hook for your tests to alternate configuration 
files.

Strange things may happen if you try to use both this plugin and
L<File::HomeDir::Test>.  A notice or diagnostic (depending on if the
test is passing) will be raised at the end of the test if you attempt this.

=head1 SEE ALSO

=over 4

=item L<File::HomeDir::Test>

I used to use this module a lot.  It was good.  Unfortunately It has 
not, in this developers opinion, been actively maintained for years, with 
the very brief exception when it was broken by changes introduced in the 
Perl 5.25.x series when C<.> was removed from C<@INC>.

This module also comes bundled as part of L<File::HomeDir> which does a 
lot more than I really need.

This module also dies if it is C<use>d more than once which I think is 
unnecessary.

This module also sets C<HOME> on all platforms, even on ones where that 
is not the native environment variable for the home directory.  This can 
be a problem, because if your code is using C<HOME>, and your testing 
environment fakes it so that works, then your testing environment may be
hiding bugs.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Shawn Laffan (SLAFFAN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
