use utf8;
package vendorlib;
our $AUTHORITY = 'cpan:RKITOVER';
$vendorlib::VERSION = '0.12';
use strict;
use warnings;
use Config;

=encoding UTF-8

=head1 NAME

vendorlib - Use Only Core and Vendor Libraries in @INC

=head1 SYNOPSIS

    #!/usr/bin/perl

    use vendorlib;
    use strict;
    use warnings;
    use SomeModule; # will only search in core and vendor paths
    ...

=head1 DESCRIPTION

In a system distribution such as Debian, it may be advisable for Perl programs
to ignore the user's CPAN-installed modules and only use the
distribution-provided modules to avoid possible breakage with newer and
unpackaged versions of modules.

To that end, this pragma will replace your C<@INC> with only the core and vendor
C<@INC> paths, ignoring site_perl and C<$ENV{PERL5LIB}> entirely.

It is recommended that you put C<use vendorlib;> as the first statement in your
program, before even C<use strict;> and C<use warnings;>.

=cut

sub import {
    my @paths = (($^O ne 'MSWin32' ? ('/etc/perl') : ()), @Config{qw/
        vendorarch
        vendorlib
        archlib
        privlib
    /});

    # This grep MUST BE on copies of the paths to not trigger Config overload
    # magic.
    @paths = grep $_, @paths;

    # remove duplicates
    my @result;
    while (my $path = shift @paths) {
        if (@paths && $path eq $paths[0]) {
            # ignore
        }
        else {
            push @result, $path;
        }
    }
    @paths = @result;

    # fixup slashes for @INC on Win32
    if ($^O eq 'MSWin32') {
        s{\\}{/}g for @paths;
    }

    # expand tildes
    if ($^O ne 'MSWin32') {
        for my $path (@paths) {
            if ($path =~ m{^~/+}) {
                my $home = (getpwuid($<))[7];
                $path =~ s|^~/+|${home}/|;
            }
            elsif (my ($user) = $path =~ /^~(\w+)/) {
                my $home = (getpwnam($user))[7];
                $path =~ s|^~${user}/+|${home}/|;
            }
        }
    }

    # remove any directories that don't actually exist
    # this will also remove /etc/perl on non-Debian systems
    @paths = grep -d, @paths;

    @INC = @paths;
}

=head1 ACKNOWLEDGEMENTS

Thanks to mxey, jawnsy and ribasushi for help with the design.

=head1 AUTHOR

Rafael Kitover <rkitover@gmail.com>

=cut

__PACKAGE__; # End of vendorlib
