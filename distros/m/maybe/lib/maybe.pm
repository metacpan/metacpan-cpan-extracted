#!/usr/bin/perl -c

package maybe;

=head1 NAME

maybe - Use a Perl module and ignore error if can't be loaded

=head1 SYNOPSIS

  use Getopt::Long;
  use maybe 'Getopt::Long::Descriptive';
  if (maybe::HAVE_GETOPT_LONG_DESCRIPTIVE) {
    Getopt::Long::Descriptive::describe_options("usage: %c %o", @options);
  }
  else {
    Getopt::Long::GetOptions(\%options, @$opt_spec);
  }

  use maybe 'Carp' => 'confess';
  if (maybe::HAVE_CARP) {
    confess("Bum!");
  }
  else {
    die("Bum!");
  }

=head1 DESCRIPTION

This pragma loads a Perl module.  If the module can't be loaded, the
error will be ignored.  Otherwise, the module's import method is called
with unchanged caller stack.

The special constant C<maybe::HAVE_I<MODULE>> is created and it can be used
to enable or disable block of code at compile time.

=for readme stop

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0202';


## no critic (RequireArgUnpacking)

# Pragma handling
sub import {
    shift;

    my $package = shift @_;
    return unless $package;

    my $macro = $package;
    $macro =~ s{(::|[^A-Za-z0-9_])}{_}g;
    $macro = 'HAVE_' . uc($macro);

    (my $file = $package . '.pm') =~ s{::}{/}g;

    local $SIG{__DIE__} = '';
    eval {
        require $file;
    } or goto ERROR;

    # Check version if first element on list is a version number.
    if (defined $_[0] and $_[0] =~ m/^\d/) {
        my $version = shift @_;
        eval {
            $package->VERSION($version);
            1;
        } or goto ERROR;
    };

    # Package is just loaded
    {
        no strict 'refs';
        undef *{$macro} if defined &$macro;
        *{$macro} = sub () { !! 1 };
    };

    # Do not call import if list contains only empty string.
    return if @_ == 1 and defined $_[0] and $_[0] eq '';

    my $method = $package->can('import');
    return unless $method;

    unshift @_, $package;
    goto &$method;

    ERROR:
    {
        no strict 'refs';
        undef *{$macro} if defined &$macro;
        *{$macro} = sub () { !! '' };
    };

    return;
};


1;


=head1 USAGE

=over

=item use maybe I<Module>;

It is exactly equivalent to

  BEGIN { eval { require Module; }; Module->import; }

except that I<Module> must be a quoted string.

=item use maybe I<Module> => I<LIST>;

It is exactly equivalent to

  BEGIN { eval { require Module; }; Module->import( LIST ); }

=item use maybe I<Module> => I<version>, I<LIST>;

It is exactly equivalent to

  BEGIN { eval { require Module; Module->VERSION(version); } Module->import( LIST ); }

=item use maybe I<Module> => '';

If the I<LIST> contains only one empty string, it is exactly equivalent to

  BEGIN { eval { require Module; }; }

=back

=head1 CONSTANTS

=over

=item HAVE_I<MODULE>

This constant is set after trying to load the module.  The name of constant is
created from uppercased module name.  The "::" string and any non-alphanumeric
character is replaced with underscore.  The constant contains the true value
if the module was loaded or false value otherwise.

  use maybe 'File::Spec::Win32';
  return unless maybe::HAVE_FILE_SPEC_WIN32;

As any constant value it can be used to enable or disable the block code at
compile time.

  if (maybe::HAVE_FILE_SPEC_WIN32) {
      # This block is compiled only if File::Spec::Win32 was loaded
      do_something;
  }

=back

=head1 SEE ALSO

L<if>, L<all>, L<first>.

=head1 BUGS

The Perl doesn't clean up the module if it wasn't loaded to the end, i.e.
because of syntax error.

The name of constant could be the same for different modules, i.e. "Module",
"module" and "MODULE" generate maybe::HAVE_MODULE constant.

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=maybe>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
