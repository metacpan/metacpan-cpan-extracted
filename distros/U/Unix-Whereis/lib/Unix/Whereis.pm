package Unix::Whereis;

use strict;
use warnings;

$Unix::Whereis::VERSION = '0.1';

use File::Spec;

our $sep;
our $cache;

sub import {
    my $caller = caller();
    no strict 'refs';    ## no critic
    *{ $caller . '::whereis' } = \&whereis;

    if ( defined $_[1] && $_[1] eq 'whereis_everyone' ) {
        *{ $caller . '::whereis_everyone' } = \&whereis_everyone;
    }
}

sub pathsep {
    $sep = $_[0] if @_;

    if ( !defined $sep ) {

        # only use %Config::Config if loaded already (keys() is the key!):
        #     pkit -e 'd(scalar keys %Config::Config);require Config;d(scalar keys %Config::Config)'
        #     pkit -e 'd(scalar keys %Config::Config)'
        #     pkit -MConfig -e 'd(scalar keys %Config::Config)'
        if ( keys %Config::Config && exists $Config::Config{'path_sep'} && length $Config::Config{'path_sep'} ) {
            $sep = $Config::Config{'path_sep'};
        }
        else {
            $sep = ':';
        }
    }

    return $sep;
}

sub whereis {
    my ( $name, $conf_hr ) = @_;
    return if !defined $name || $name eq '';

    $conf_hr = {} if !defined $conf_hr || ref $conf_hr ne 'HASH';

    if ( $conf_hr->{'cache'} && $cache->{'whereis'}{$name} ) {
        delete $cache->{'whereis'}{$name} if $conf_hr->{'cache'} eq 'clear';
        return $cache->{'whereis'}{$name} if $conf_hr->{'cache'} && exists $cache->{'whereis'}{$name};
    }

    local $ENV{'PATH'} = _build_env_path($conf_hr);

    for my $PATH ( split( pathsep(), $ENV{'PATH'} ) ) {
        my $bin = File::Spec->catfile( $PATH, $name );
        if ( -f $bin && -x _ && -s _ ) {
            $cache->{'whereis'}{$name} = $bin if $conf_hr->{'cache'};
            return $bin;
        }
    }

    return $name if $conf_hr->{'fallback'};
    return;
}

sub whereis_everyone {
    my ( $name, $conf_hr ) = @_;
    $conf_hr = {} if !defined $conf_hr || ref $conf_hr ne 'HASH';

    if ( $conf_hr->{'cache'} && $cache->{'whereis_everyone'}{$name} ) {
        delete $cache->{'whereis_everyone'}{$name} if $conf_hr->{'cache'} eq 'clear';
        return @{ $cache->{'whereis_everyone'}{$name} } if $conf_hr->{'cache'} && exists $cache->{'whereis_everyone'}{$name};
    }

    my @found;

    local $ENV{'PATH'} = _build_env_path($conf_hr);

    for my $PATH ( split( pathsep(), $ENV{'PATH'} ) ) {
        my $bin = File::Spec->catfile( $PATH, $name );
        push( @found, $bin ) if -f $bin && -x _ && -s _;
    }

    $cache->{'whereis_everyone'}{$name} = \@found if $conf_hr->{'cache'};
    return @found;
}

sub _build_env_path {
    my ($conf_hr) = @_;

    $sep ||= pathsep();

    my $path = $ENV{'PATH'};
    $path = $conf_hr->{'mypath'} if exists $conf_hr->{'mypath'} && length $conf_hr->{'mypath'};
    $path =~ s/\Q$sep\E+$//;
    $path =~ s/^\Q$sep\E+//;

    if ( exists $conf_hr->{'prepend'} && length $conf_hr->{'prepend'} ) {
        $conf_hr->{'prepend'} =~ s/\Q$sep\E+$//;
        $conf_hr->{'prepend'} =~ s/^\Q$sep\E+//;
        $path = "$conf_hr->{'prepend'}$sep$path";
    }

    if ( exists $conf_hr->{'append'} && length $conf_hr->{'append'} ) {
        $conf_hr->{'append'} =~ s/\Q$sep\E+$//;
        $conf_hr->{'append'} =~ s/^\Q$sep\E+//;
        $path .= $sep . $conf_hr->{'append'};
    }

    return $path;
}

1;

__END__

=encoding utf8

=head1 NAME

Unix::Whereis - locate programs in standard binary directories and/or specified directories

=head1 VERSION

This document describes Unix::Whereis version 0.1

=head1 SYNOPSIS

    use Unix::Whereis;

    my $ffmpeg = whereis('ffmpeg');
    if ($ffmpeg) {
        system($ffmpeg, …) && die …;
    }
    else {
        die "Install ffmpeg into your PATH please.";
    }

=head1 DESCRIPTION

Same idea as the Unix whereis program but in perl function form. Should work on non-Unix systems that have a concept of PATH.

A few handy uses:

=over 4

=item Use a modified lookup PATH without affecting your actual environment (i.e. then the shell can then skip the lookup it’d have done).

=item Verify you have a binary installed to avoid unnecessary work and handle it gracefully if you don’t.

=back

Also, this will help when you’re not shelling out immediately, for example:

=over 4

=item Look up a value for a configuration option.

=item Look it up and do some checks on it/with it before you execute it.

=item Look it up once and execute it several times without making the shell do the same lookup each time.

=back

I find it handy, if you do to, cool!

=head1 INTERFACE

There are 3 functions:

=head2 whereis()

Exported via import().

Given a program name it looks for it in the environment’s PATH. Returns the first path found or nothing (i.e. false) if it is not found.

You can modify it by passing in an optional hashref with the following keys:

=over 4

=item 'fallback'

Boolean, when true will cause whereis() to return the program name (instead of nothing) if no specific path is found.

=item 'mypath'

PATH string to use instead of $ENV{PATH}

=item 'prepend'

PATH string to prepend to the base path.

=item 'append'

PATH string to append to the base path.

=item 'cache'

Boolean, default false.

When true it caches the results for the program name for subsequent calls that also have 'cache' set.

Caveat: The cache is not based on what is in the optional hash.

You can clear the current cached value first by giving it a value of 'clear'.

=back

=head2 whereis_everyone()

Exported on request:

    use Unix::Whereis 'whereis_everyone';

Given a program name it looks for it in the environment’s PATH. Returns a list of every one of the paths it finds.

It can take the same optional hashref that whereis() does, except 'fallback' is a no-op.

    print Dumper( [ Unix::Whereis::whereis_everyone('perl') ] );

=head2 pathsep()

Not exportable.

    my $sep = Unix::Whereis::pathsep();

Mainly internal but handy for introspection perhaps …

Returns the $PATH separator it will use.

If the separator has not yet been set it will set it to $Config::Config{'path_sep'} if you have loaded Config.pm, : otherwise.

You can pass it a value to set the separator to whatever you like (seems odd but hey its your code).

Passing undef() will make it redo the $Config::Config{'path_sep'}  or : logic.

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 DEPENDENCIES

L<File::Spec>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Unix-whereis@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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
