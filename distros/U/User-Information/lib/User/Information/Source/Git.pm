# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from user accounts


package User::Information::Source::Git;

use v5.20;
use strict;
use warnings;

use Carp;

use User::Information::Path;

our $VERSION = v0.05;

use constant _LOAD_PATH_GLOBAL => User::Information::Path->new([qw(git global)]);

my %_keymap = (
    'user.email'    => User::Information::Path->new([qw(git global user email)]),
    'user.name'     => User::Information::Path->new([qw(git global user name)]),
);

# ---- Private helpers ----

sub _read_git_confg {
    my ($fh) = @_;
    my $section = 'BAD';
    my %res;

    while (defined(my $line = <$fh>)) {
        $line =~ s/\r?\n$//;
        $line =~ s/\s*[#;].*$//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next if $line eq '';

        next if $line =~ /["\\]/; # not supported

        if ($line =~ /^\[([0-9a-zA-Z\.\-]+)\]$/) {
            $section = lc($1);
        } elsif ($line =~ /^\[/) { # not supported
            $section = 'BAD'; 
        } elsif ($line =~ /^([0-9a-zA-F-]+)$/) {
            $res{$section.'.'.lc($1)} = 'true';
        } elsif ($line =~ /^([0-9a-zA-F-]+)\s*=\s*(\S.*)$/) {
            $res{$section.'.'.lc($1)} = $2;
        }
    }

    return \%res;
}

sub _load {
    my ($base, $info, $key) = @_;
    my $fh = $base->file(['aggregate', 'homedir'], extra => '.gitconfig', open => 'r');
    my $res = _read_git_confg($fh);

    foreach my $key (keys %_keymap) {
        if (defined(my $v = $res->{$key})) {
            $base->_value_add($_keymap{$key}, {raw => $v});
        }
    }

    die; # we are fine as we added all values above. So just terminating this to avoid overwrites.
}

sub _discover {
    my ($pkg, $base, %opts) = @_;
    my $root = User::Information::Path->new('env');
    my @info;

    foreach my $path (values %_keymap) {
        push(@info, {
                loadpath => _LOAD_PATH_GLOBAL,
                path => $path,
                loader => \&_load,
            });
    }

    return @info;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

User::Information::Source::Git - generic module for extracting information from user accounts

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use User::Information::Source::Git;

This is a provider using git.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
