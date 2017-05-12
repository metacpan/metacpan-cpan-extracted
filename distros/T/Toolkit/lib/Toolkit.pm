package Toolkit;

use version; $VERSION = qv('0.0.2');

use warnings;
use strict;
use Carp;

use File::Spec::Functions qw( catfile splitpath );
use Filter::Simple;

sub _uniq {
    my %seen;
    return grep { !$seen{$_}++ } @_;
}

# Read in an entire file given the filename...
sub _slurp {
    my ($file_path) = @_;

    open my $fh, '<', $file_path
        or croak "Toolkit couldn't open $file_path\n$!";

    local $/;
    return <$fh>;
}

# Cache of module names using this module
my @callers;

my @MANDATORY_KITS = qw(ALWAYS);
my @DEFAULT_KITS   = qw(ALWAYS DEFAULT);
my @ANY_KITS       = ();

# Handle the macro kits and prepare for run-time kits...
FILTER {
    my ($class, @args) = @_;

    # Remember where we came in...
    my ($caller, $file, $line) = caller(1);
    $line++;
    my $location = qq{\n#line $line "$file"\n};

    # Are we looking for something in particular?
    my @only_these_macro_kits 
        = _uniq(@args ? (@MANDATORY_KITS, @args) : @DEFAULT_KITS);
    ### @only_these_macro_kits
    my @only_these_runtime_kits 
        = _uniq(@args ? (@MANDATORY_KITS, @args) : @ANY_KITS);

    # Cache the module that invoked this filter (for run-time kits)..
    push @callers, $caller;

    # Get a list of run-time kits...
    my @subs_runtime
        = _kit_names( _find_all_kits(['Runtime'], \@only_these_runtime_kits) );

    # Load up all the compile-time macros (with line numbering)...
    my $macros = q{};
    for my $macro_path ( _find_all_kits(['Macros'], \@only_these_macro_kits) ) {
        $macros .= qq{#line 1 "$macro_path"\n} . _slurp $macro_path;
    }

    # Insert the macros and pre-declarations for run-time subs...
    $_ = $macros . _declarations_for(@subs_runtime) . $location . $_;
    ### Filtered source: $_
};

# Strip directory paths from kits...
sub _kit_names {
    return map {
        my (undef, undef, $file_name) = splitpath($_);
        $file_name;
    } @_;
}

# Locate all kits in the specified subdirectory by searching include path...
sub _find_all_kits {
    my ($sub_path_ref, $only_these_kits_ref) = @_;
    ### $sub_path_ref
    ### $only_these_kits_ref
    return map {
            _glob_plain_files(
                catfile($_, 'Toolkit',  @{$sub_path_ref}),
                $only_these_kits_ref,
            )
           } @INC;
}

# Return full paths of all plain files under root directory...
sub _glob_plain_files {
    my ($root_dir, $only_these_kits_ref) = @_;
    return () if ! -d $root_dir;

    ### Globbing: $root_dir
    my @files;
    use File::Find;
    my @root_dirs = @{$only_these_kits_ref}
                        ? map { catfile $root_dir, $_ } @{$only_these_kits_ref}
                        : $root_dir;
    ### Searching: @root_dirs
    ROOT:
    for my $root (@root_dirs) {
        next ROOT if ! -e $root;
        find(
            sub {
                return if -d; push @files, $File::Find::name
            },
            $root,
        );
    }
    ### @files
    return @files;
}

# Create declarations for run-time kits...
sub _declarations_for {
    return join q{}, map { "sub $_;" } @_;
}

# Install a subroutine from a run-time kit...
sub _install_kit_for {
    my ($full_sub_name) = @_;
    my ($package, $sub_name) = ($full_sub_name =~ m/(.*) :: (.*)/xms);

    # Which kit (if any)?
    my $file_path = _find_kit_for(qw(Toolkit Runtime), $sub_name);
    return if !$file_path;

    # Install it...
    return _install_kit_from($file_path, $full_sub_name, $sub_name);
}

# Load and install a subroutine from the specified kit...
sub _install_kit_from {
    my ($file_path, $full_sub_name, $sub_name) = @_;

    # First try to install it in the sandbox...
    package Toolkit::Sandbox;
    use Carp;
    do $file_path;

    # Verify that it was installed...
    no strict 'refs';
    if (! *{$sub_name}{CODE} ) {
        carp "Toolkit could not load &$sub_name\n",
                "(running $file_path didn't install it)\n",
                "Problem was detected";
        return; # failure
    }

    # Then move it to the requested location...
    *{$full_sub_name} = \&{$sub_name};

    return 1; # success
}

# Return the first kit matching the specified path...
sub _find_kit_for {
    my (@path) = @_;
    for my $dir (@INC) {
        my $file_path = catfile($dir,@path);
        return $file_path if -r $file_path;
    }
    return;
}

# Install AUTOLOADs in every module that used this one...
CHECK {
    for my $package (@callers) {
        my $full_AUTOLOAD_name = $package.'::AUTOLOAD';

        no strict 'refs';
        our $AUTOLOAD;

        # Save any existing AUTOLOAD in the same namespace...
        my $orig_AUTOLOAD_ref
            = *{$full_AUTOLOAD_name}{CODE}
           || sub { croak "Undefined subroutine &$AUTOLOAD called" };

        # Install a replacement that defaults to the original...
        no warnings 'redefine';
        *{$package.'::AUTOLOAD'} = sub {
            # First try to load the requested subroutine from a kit...
            if ( _install_kit_for($AUTOLOAD) ) {
                goto &{$AUTOLOAD};
            }

            # Otherwise default to the "real" AUTOLOAD...
            ${$package.'::AUTOLOAD'} = $AUTOLOAD;
            goto &{$orig_AUTOLOAD_ref};
        };
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Toolkit - Keep your handy modules organized


=head1 VERSION

This document describes Toolkit version 0.0.2


=head1 SYNOPSIS

    use Toolkit;

    # All your favorites are now available 

  
=head1 DESCRIPTION

The Toolkit module provides a standard location to store modules that you use
all the time, and then loads them for you automatically. For example, instead
of always writing:

    use strict;
    use warnings;
    use Carp;
    use Smart::Comments;

in every program/module, you can just write:

    use Toolkit;

and put all your favorite modules in a file:

    > cat $PERL5LIB/Toolkit/Macros/ALWAYS/Modules

    use strict;
    use warnings;
    use Carp;
    use Smart::Comments;

You can also specify load-on-demand subroutines:

    > cat $PERL5LIB/Toolkit/Runtime/prompt

    use IO::Prompt qw( prompt );

    > cat $PERL5LIB/Toolkit/Runtime/say

    sub say { print @_, "\n" }

in which case Toolkit will install an C<AUTOLOAD> that installs these
subroutines the first time they're called.


=head1 INTERFACE 

Calling:

    use Toolkit;

with no arguments loads any files in the directories:

    $PERL5LIB/Toolkit/Macros/ALWAYS/
    $PERL5LIB/Toolkit/Macros/DEFAULT/

or any of their subdirectories.

Calling:

    use Toolkit qw(foo bar);

any files in the directories:

    $PERL5LIB/Toolkit/Macros/ALWAYS/
    $PERL5LIB/Toolkit/Macros/foo/
    $PERL5LIB/Toolkit/Macros/bar/

or any of their subdirectories.

Using the Toolkit module in any way also installs an C<AUTOLOAD> subroutine
which looks in:

    $PERL5LIB/Toolkit/Runtime/

for a file of the same name as the subroutine that is being autoloaded. That
is, if you write:

    use Toolkit;

    baz();

Then the module looks for a file:

    $PERL5LIB/Toolkit/Runtime/baz

and executes it in a special namespace. After the file executes, Toolkit
expects that the special namespace will now have a subroutine of the required
name, which it then calls.

=head1 DIAGNOSTICS

=over

=item Toolkit couldn't open %s

You specified a particular macro for Toolkit to load, but it wasn't able to
read the corresponding file. Usually a file permissions problem or a
non-existent macro.


=item Undefined subroutine %s called

You used a subroutine that Toolkit couldn't autoload. Did you misspell
the subroutine name, or fail to install a file of the same name in your
C<$PERL5LIB/Toolkit/Runtime/> subdirectory.

=item Toolkit could not load %s (running %s didn't install it).

You used a subroutine that Toolkit tried to autoload. It found the
corresponding file in the C<$PERL5LIB/Toolkit/Runtime/> subdirectory, but
executing that file didn't produce a subroutine of the correct name.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Toolkit uses the following directories and files to configure its behaviour:

=over

=item $PERL5LIB/Toolkit/Macros/ALWAYS/

Files in this directory are prepended to your source code whenever Toolkit is
used

=item $PERL5LIB/Toolkit/Macros/DEFAULT/

Files in this directory are prepended to your source code whenever Toolkit is
used without arguments

=item $PERL5LIB/Toolkit/Macros/I<any file name>

These files are prepended to your source code whenever Toolkit is used and
their name is specified after the C<use Toolkit>.

=item $PERL5LIB/Toolkit/Runtime/

Files in this directory are executed to whenever Toolkit is used and a
subroutine of the same name is called. They are expected to define the
required subroutine.

=back

=head1 DEPENDENCIES

Requires:

=over

=item *

File::Spec::Functions

=item *

Filter::Simple

=item *

version

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-tool-kit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
