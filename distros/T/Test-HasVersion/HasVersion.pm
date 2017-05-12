
package Test::HasVersion;

use strict;
use warnings;

our $VERSION = '0.014';

=head1 NAME

Test::HasVersion - Check Perl modules have version numbers

=head1 SYNOPSIS

C<Test::HasVersion> lets you check a Perl module has a version 
number in a C<Test::Simple> fashion.

  use Test::HasVersion tests => 1;
  pm_version_ok("M.pm", "Valid version");

Module authors can include the following in a F<t/has_version.t> 
file and let C<Test::HasVersion> find and check all 
installable PM files in a distribution.

  use Test::More;
  eval "use Test::HasVersion";
  plan skip_all => 
       'Test::HasVersion required for testing for version numbers' if $@;
  all_pm_version_ok();

=head1 DESCRIPTION

Do you wanna check that every one of your Perl modules in
a distribution has a version number? You wanna make sure
you don't forget the brand new modules you just added?
Well, that's the module you have been looking for.
Use it!

Do you wanna check someone else's distribution
to make sure the author have not committed the sin of
leaving Perl modules without a version that can be used
to tell if you have this or that feature? C<Test::HasVersion>
is also for you, nasty little fellow.

There's a script F<test_version> which is installed with
this distribution. You may invoke it from within the
root directory of a distribution you just unpacked,
and it will check every F<.pm> file in the directory 
and under F<lib/> (if any).

  $ test_version

You may also provide directories and files as arguments.

  $ test_version *.pm lib/ inc/
  $ test_version . 

(Be warned that many Perl modules in a F<t/> directory
do not receive versions because they are not used 
outside the distribution.)

Ok. That's not a very useful module by now.
But it will be. Wait for the upcoming releases.

=head2 FUNCTIONS

=over 4

=cut

# most of the following code was borrowed from Test::Pod

use Test::Builder;
use ExtUtils::MakeMaker;    # to lay down my hands on MM->parse_version

my $Test = Test::Builder->new;

our @EXPORTS = qw( pm_version_ok all_pm_version_ok all_pm_files );

sub import {
    my $self   = shift;
    my $caller = caller;

    for my $func (@EXPORTS) {
        no strict 'refs';
        *{ $caller . "::" . $func } = \&$func;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}

# from Module::Which

#=begin private

=item PRIVATE B<_pm_version>

  $v = _pm_version($pm);

Parses a PM file and return what it thinks is $VERSION
in this file. (Actually implemented with 
C<< use ExtUtils::MakeMaker; MM->parse_version($file) >>.)
C<$pm> is the filename (eg., F<lib/Data/Dumper.pm>).

=cut

#=end private

sub _pm_version {
    my $pm = shift;
    my $v;
    eval { $v = MM->parse_version($pm); };
    return $@ ? undef : $v;
}

=item B<pm_version_ok>

  pm_version_ok('Module.pm');
  pm_version_ok('M.pm', 'Has valid version');

Checks to see if the given file has a valid 
version. Actually a valid version number is
defined and not equal to C<'undef'> (the string)
which is return by C<_pm_version> if a version
cannot be determined.

=cut

sub pm_version_ok {
    my $file = shift;
    my $name = @_ ? shift : "$file has version";

    if ( !-f $file ) {
        $Test->ok( 0, $name );
        $Test->diag("$file does not exist");
        return;
    }

    my $v  = _pm_version($file);
    my $ok = _is_valid_version($v);
    $Test->ok( $ok, $name );

    #$Test->diag("$file $v ") if $ok && $noisy;
}

sub _is_valid_version {
    defined $_[0] && $_[0] ne 'undef';
}

=item B<all_pm_version_ok>

  all_pm_version_ok();
  all_pm_version_ok(@PM_FILES);

Checks every given file and F<.pm> files found
under given directories to see if they provide
valid version numbers. If no argument is given,
it defaults to check every file F<*.pm> in
the current directory and recurses under the
F<lib/> directory (if it exists).

If no test plan was setted, C<Test::HasVersion> will set one
after computing the number of files to be tested. Otherwise,
the plan is left untouched.

=cut

sub all_pm_version_ok {
    my @pm_files = all_pm_files(@_);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $Test->plan( tests => scalar @pm_files ) unless $Test->has_plan;
    for (@pm_files) {
        pm_version_ok($_);
    }
}

#=begin private

=item PRIVATE B<_list_pm_files>

  @pm_files = _list_pm_files(@dirs);

Returns all PM files under the given directories.

=cut

#=end private

# from Module::Which::List -   eglob("**/*.pm")

use File::Find qw(find);

sub _list_pm_files {
    my @INC = @_;
    my @files;

    my $wanted = sub {
        push @files, $_ if /\.pm$/;
    };

    for (@INC) {
        my $base = $_;
        if ( -d $base ) {
            find( { wanted => $wanted, no_chdir => 1 }, $base );
        }
    }
    return sort @files;
}

=item B<all_pm_files>

  @files = all_pm_files()
  @files = all_pm_files(@files_and_dirs);

Implements finding the Perl modules according to the
semantics of the previous function C<all_pm_version_ok>.

=cut

sub all_pm_files {
    my @args;
    if (@_) {
        @args = @_;
    }
    else {
        @args = ( grep( -f, glob("*.pm") ), "lib/" );
    }
    my @pm_files;
    for (@args) {
        if (-f) {
            push @pm_files, $_;
        }
        elsif (-d) {
            push @pm_files, _list_pm_files($_);
        }
        else {
            # not a file or directory: ignore silently
        }
    }
    return @pm_files;

}

=back

=head1 USAGE

Other usage patterns besides the ones given in the synopsis.

  use Test::More tests => $num_tests;
  use Test::HasVersion;
  pm_version_ok($file1);
  pm_version_ok($file2);

Obviously, you can't plan twice.

  use Test::More;
  use Test::HasVersion;
  plan tests => $num_tests;
  pm_version_ok($file);

C<plan> comes from C<Test::More>.

  use Test::More;
  use Test::HasVersion;
  plan 'no_plan';
  pm_version_ok($file);

C<no_plan> is ok either.

=head1 SEE ALSO

  Test::Version

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-HasVersion

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, 2016 by Adriano R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

