package X11::Wallpaper;
# ABSTRACT: set X11 wallpaper using best available helper program

use strict;
use warnings;
use Carp;
use File::Which qw(which);
use IPC::System::Simple qw(systemx);

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(set_wallpaper set_wallpaper_command);
}

# Ordered by preference
my @SETTERS = (
    {
        name => 'feh',
        full => ['--bg-scale'],
        tile => ['--bg-tile'],
        center => ['--bg-center'],
        aspect => ['--bg-fill'],
    },
    {
        name => 'Esetroot',
        full => ['-scale'],
        tile => [],
        center => ['-c'],
        aspect => ['-fit'],
        require_ldd => 'libImlib',
    },
    {
        name => 'hsetroot',
        full => ['-fill'],
        tile => ['-tile'],
        center => ['-center'],
        aspect => ['-full'],
    },
    {
        name => 'habak',
        full => ['-full'],
        tile => [],
        center => ['-mC'],
        aspect => ['-mS'],
    },
    {
        name => 'imlibsetroot',
        full => [qw(-s f)],
        tile => [qw(-t -p c)],
        center => [qw(-p c)],
        aspect => [qw(-s a)],
    },
    {
        name => 'chbg',
        full => [qw(-once -mode maximize)],
        tile => [qw(-once -mode tile)],
        center => [qw(-once -mode center)],
        aspect => [qw(-once -mode smart -max_grow 1000 -max_size 100)],
    },
    {
        name => 'xsri',
        full => [qw(--center-x --center-y --scale-width=100 --scale-height=100)],
        tile => [qw(--tile)],
        center => [qw(--center-x --center-y --color=black)],
        aspect => [qw(--center-x --center-y --scale-width=100 --scale-height=100 --keep-aspect --color=black)],
    },
    {
        name => 'wmsetbg',
        full => ['-s', '-S'],
        tile => ['-t'],
        center => [qw(-b black -e)],
        aspect => [qw(-b black -a -S)],
    },
    {
        name => 'xsetbg',
        full => { fallback => 'aspect' },
        tile => [qw(-border black)],
        center => [qw(-center -border black)],
        aspect => [qw(-fullscreen -border black)],
    },
    {
        name => 'xli', # aka xloadimage
        full => { fallback => 'aspect' },
        tile => [qw(-onroot -quiet -border black)],
        center => [qw(-center -onroot -quiet -border black)],
        aspect => [qw(-fullscreen -onroot -quiet -border black)],
    },
    {
        name => 'icewmbg',
        full => { fallback => 'tile' },
        tile => ['-s'],
        center => { fallback => 'tile' },
        aspect => { fallback => 'tile' },
    },
    {
        name => 'qiv',
        full => ['--root_s'],
        tile => ['--root_t'],
        center => ['--root'],
        aspect => ['--root', '-m'],
        broken_transparency => 1,
    },
    {
        name => 'xv',
        full => [qw(-max -smooth -root -quit)],
        tile => [qw(-root -quit)],
        center => [qw(-rmode 5 -root -quit)],
        aspect => [qw(-maxpect -smooth -root -quit)],
        broken_transparency => 1,
    },
);
my %SETTER = map { $_->{name} => $_ } @SETTERS;

sub set_wallpaper {
    my ($image, %args) = @_;

    if (!defined $args{display} && (!defined $ENV{DISPLAY} || $ENV{DISPLAY} eq '')) {
        croak "You are not connected to an X session, consider setting the DISPLAY"
            . "environment variable or passing the 'display' option to set_wallpaper()";
    }

    my @command = set_wallpaper_command($image, %args);    
    return systemx(@command);
}

sub set_wallpaper_command {
    my ($image, %args) = @_;
    my $mode = $args{mode} || 'full';
    my $setter = $args{setter} || _find_setter($mode);
    my $display = $args{display};

    # Build command
    my @command = defined $display ? ('env', "DISPLAY=$display") : ();
    push @command, ($setter, _find_setter_args($setter, $mode), $image);

    return @command;
}

# Find the best available setter for the given 'mode'.
sub _find_setter {
    my $mode = shift;
    my $best;
    my $fallback = 0;

    for my $setter (@SETTERS) {
        next if !defined which($setter->{name});
        next if !defined $setter->{$mode};

        if (ref $setter->{$mode} eq 'HASH') {
            $fallback = 1;
        }

        $best = $setter->{name};
        last if !$fallback;  # else wait for a better one
    }

    if (!defined $best) {
        croak "No setter program found for mode '$mode'!";
    }

    return $best;
}

sub _find_setter_args {
    my ($setter, $mode) = @_;
    my $args = $SETTER{$setter}{$mode};
    if (ref $args eq 'HASH' && $args->{fallback}) {
        $args = $SETTER{$setter}{ $args->{fallback} };
    }
    ref $args eq 'ARRAY' or die "Expecting arguments for $setter/$mode. Fallback chain?";

    return @$args;
}

1;



=pod

=head1 NAME

X11::Wallpaper - set X11 wallpaper using best available helper program

=head1 VERSION

version 1.1

=head1 SYNOPSIS

  use X11::Wallpaper qw(set_wallpaper);
  set_wallpaper( "./foo.jpg", {
    mode => 'full',   # default, or: aspect, center, tile
    setter => 'feh',  # override setter
    display => ':0.0' # override X display
  } );

  my @cmd = set_wallaper_command(...); # just give me the command

=head1 DESCRIPTION

This module provides an interface for setting the background on X11
systems, by recruiting a suitable helper script (feh, Esetroot, hsetroot,
chbg, xli etc.) and providing appropriate options.

=head1 METHODS

=head2 set_wallpaper($image_path, %args)

Sets C<$image_path> as the desktop wallpaper. The following args are
supported:

=over

=item mode

May be 'full' (fullscreen, stretched to fit - the default), 'tile',
'center' (do not stretch) or 'aspect' (fullscreen, preserving
aspect ratio). For the latter two options, the background for any
borders around the image is set to black.

=item setter

Manually specify the program to use, e.g. 'qiv', provided it is
in this module's dictionary of commands.

=item display

Override the X display to use, e.g. ':0.0'. Otherwise defaults to
the value of the DISPLAY environment variable.

=back

=head2 @cmd = set_wallpaper_command($image_path, %args)

As with C<set_wallpaper>, except returns the command (as a list of
arguments) instead of executing it.

=head1 CREDITS

Inspired by the C<awsetbg> shell script by Julian Danjou, which in turn
is derived from C<fbsetbg> by Han Boetes.

=head1 TODO

Skip the middle man and code against the X11 libraries directly. But
that wouldn't be quite as portable...

=head1 AUTHOR

Richard Harris <RJH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

