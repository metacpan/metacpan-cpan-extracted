package above;

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Spec qw();

our $VERSION = '0.03'; # No BumpVersion

sub import {
    my $package = shift;
    for (@_) {
        use_package($_);
    }
}

our %used_libs;
BEGIN {
    %used_libs = ($ENV{PERL_USED_ABOVE} ? (map { $_ => 1 } split(":", $ENV{PERL_USED_ABOVE})) : ());
    for my $path (keys %used_libs) {
        my $error = do {
            local $@;
            eval "use lib '$path';";
            $@;
        };
        die "Failed to use library path '$path' from the environment PERL_USED_ABOVE?: $error" if $error;
    }
};

sub _caller_use {
    my ($caller, $class) = @_;
    my $error = do {
        local $@;
        eval "package $caller; use $class";
        $@;
    };
    die $error if $error;
}

sub _dev {
    my $path = shift;
    return (stat($path))[0];
}

sub use_package {
    my $class  = shift;
    my $caller = (caller(1))[0];
    my $module = File::Spec->join(split(/::/, $class)) . '.pm';

    ## paths already found in %used_above have
    ## higher priority than paths based on cwd
    for my $path (keys %used_libs) {
        if (-e File::Spec->join($path, $module)) {
            _caller_use($caller, $class);
            return;
        }
    }

    my $xdev = $ENV{ABOVE_DISCOVERY_ACROSS_FILESYSTEM};
    my $cwd = getcwd();
    unless ($cwd) {
        die "cwd failed: $!";
    }
    my $dev = _dev($cwd);
    my $abort_crawl = sub {
        my @parts = @_;
        return 1 if (@parts == 0); # nothing left to try
        return 1 if (@parts == 1 && $parts[0] eq ''); # hit root dir
        my $path = File::Spec->join(@parts);
        return !($xdev || _dev($path) == $dev); # crossed device
    };
    my $found_module_at = sub {
        my $path = shift;
        return (-e File::Spec->join($path, $module));
    };

    my @parts = File::Spec->splitdir($cwd);
    my $path;
    do {
        $path = File::Spec->join(@parts);
        pop @parts;
    } until ($found_module_at->($path) || $abort_crawl->(@parts));

    if ($found_module_at->($path)) {
        while ($path =~ s:/[^/]+/\.\./:/:) { 1 } # simplify
        unless ($used_libs{$path}) {
            print STDERR "Using libraries at $path\n" unless $ENV{PERL_ABOVE_QUIET} or $ENV{COMP_LINE};
            my $error = do {
                local $@;
                eval "use lib '$path';";
                $@;
            };
            die $error if $error;
            $used_libs{$path} = 1;
            my $env_value = join(":", sort keys %used_libs);
            $ENV{PERL_USED_ABOVE} = $env_value;
        }
    }

    _caller_use($caller, $class);
};

1;

=pod

=head1 NAME

above - auto "use lib" when a module is in the tree of the PWD

=head1 SYNOPSIS

use above "My::Module";

=head1 DESCRIPTION

Used by the command-line wrappers for Command modules which are developer tools.

Do NOT use this in modules, or user applications.

Uses a module as though the cwd and each of its parent directories were at the beginnig of @INC.
If found in that path, the parent directory is kept as though by "use lib".

Set ABOVE_DISCOVERY_ACROSS_FILESYSTEM shell variable to true value to crawl past device boundaries.

=head1 EXAMPLES

# given
/home/me/perlsrc/My/Module.pm

# in
/home/me/perlsrc/My/Module/Some/Path/

# in myapp.pl:
use above "My::Module";

# does this ..if run anywhere under /home/me/perlsrc:
use lib '/home/me/perlsrc/'
use My::Module;

=head1 AUTHOR

Scott Smith
Nathaniel Nutter

=cut
