package Text::OutputFilter;

use strict;
use warnings;

our $VERSION = "0.24";

=head1 NAME

OutputFilter - Enable post processing of output without fork

=head1 SYNOPSIS

 use Text::OutputFilter;

 my $bucket = "";
 tie *STDOUT, "Text::OutputFilter";
 tie *HANDLE, "Text::OutputFilter", 4;
 tie *HANDLE, "Text::OutputFilter", 4,  *STDOUT;
 tie *STDOUT, "Text::OutputFilter", 4, \$bucket;
 tie *OUTPUT, "Text::OutputFilter", 4,  *STDOUT, sub { "$_[0]" };

=head1 DESCRIPTION

This interface enables some post-processing on output streams,
like adding a left margin.

The tied filehandle is opened unbuffered, but the output is line
buffered. The C<tie> takes three optional arguments:

=over 4

=item Left Margin

The left margin must be a positive integer and defaults to C<4> spaces.

=item Output Stream

The output stream must be an already open stream, with writing
enabled. The default is C<*STDOUT>. All input methods on the new
stream are disabled. If a reference to a scalar is passed, it will
be opened as PerlIO::scalar - in-memory IO, scalar IO. No checks
performed to see if your perl supports it. If you want it, and your
perl does not, upgrade.

Using C<binmode ()> on the new stream is allowed and supported.

OPEN, SEEK, and WRITE are not (yet) implemented.

=item Line Modifying Function

The output is line buffered, to enable line-modifier functions.
The line (without newline) is passed as the only argument to the
sub-ref, whose output is printed after the prefix from the first
argument. A newline is printed after the sub-ref's output.

To B<filter> a line, as in I<remove> it from the stream, make the
sub return I<undef>.

=back

=head1 TODO

Tests, tests, tests.
Tests with older perls

=head1 AUTHOR

H.Merijn Brand <h.m.brand@procura.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2022 H.Merijn Brand for PROCURA B.V.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

perl(1), perlopen(1), 'open STDOUT, "|-"', Text::Filter

=cut

use Carp;

sub TIEHANDLE {
    my ($class, $lm, $io, $ref, $fno) = @_;

    defined $lm  or $lm  = 4;
    defined $io  or $io  = *STDOUT;
    defined $ref or $ref = sub { shift };

    ref $lm || $lm !~ m/^\d+$/	and
	croak "OutputFilter tie's 1st arg must be numeric";
    ref $ref eq "CODE"		or
	croak "OutputFilter tie's 3rd arg must be CODE-ref";

    my $fh;
    if (ref $io eq "GLOB" and ref *{$io}{IO} eq "IO::Handle") {
	open $fh, ">&", *{$io}{IO};
	}
    elsif (ref $io eq "SCALAR") {
	open $fh, ">", $io;
	}
    else {
	eval { $fno = fileno $io };
	defined $fno && $fno >= 0 or
	    croak "OutputFilter tie's 2nd arg must be the output handle\n";
	open $fh, ">&", $fno;
	}
    $fh or croak "OutputFilter cannot dup the output handle: $!";
    select ((select ($fh), $| = 1)[0]);

    bless {
        pfx	=> " " x $lm,
        sb	=> $ref,
        io	=> $fh,

        line	=> "",

        closed	=> 0,
        }, $class;
    } # TIEHANDLE

sub BINMODE {
    my $self = shift;
    $self->{closed} and croak "Cannot set binmode on closed filehandle";
    if (@_) {
	my $mode = shift;
	binmode $self->{io}, $mode;
	}
    else {
	binmode $self->{io};
	}
    } # BINMODE

sub FILENO {
    my $self = shift;
    fileno $self->{io};
    } # FILENO

sub _Filter_ {
    my ($nl, $pfx, $sub, $line) = @_;
    my $l = $sub->($line);
    defined $l ? $pfx . $l . ($nl ? "\n" : "") : "";
    } # _Filter_

sub PRINT {
    my $self = shift;
    my ($pfx, $io, $sub) = @{$self}{qw( pfx io sb )};

    $self->{closed} and croak "Cannot print to closed filehandle";

    my $fsep = defined $, ? $, : "";
    my $rsep = defined $\ ? $\ : "";
    my $line = $self->{line} . (join $fsep => @_) . $rsep;
    my @line = split m/\n/, $line, -1;
    $self->{line} = pop @line;
    print { $io } map { _Filter_ (1, $pfx, $sub, $_) } @line;
    } # PRINT

sub PRINTF {
    my $self = shift;
    my ($pfx, $io, $sub) = @{$self}{qw( pfx io sb )};

    # Do not delegate this to PRINT, so we can prevent sprintf side effects
    $self->{closed} and croak "Cannot print to closed filehandle";

    my $fmt = shift;
    $self->PRINT (sprintf $fmt, @_);
    } # PRINTF

sub TELL {
    my $self = shift;
    $self->{closed} and croak "Cannot tell from a closed filehandle";
    tell $self->{io};
    } # TELL

sub EOF {
    my $self = shift;
    $self->{closed};
    } # EOF

sub CLOSE {
    my $self = shift;
    my ($pfx, $io, $sub, $line) = @{$self}{qw( pfx io sb line )};
    defined $line && $line ne "" and
	print { $io } _Filter_ (0, $pfx, $sub, $line);
    $self->{closed} or close $io;
    $self->{line} = "";
    $self->{closed} = 1;
    } # CLOSE

sub UNTIE {
    my $self = shift;
    $self->{closed} or $self->CLOSE;
    $self;
    } # UNTIE

sub DESTROY {
    my $self = shift;
    $self->{closed} or $self->CLOSE;
    %$self = ();
    undef $self;
    } # DESTROY

### ###########################################################################

sub _outputOnly {
    my $name = shift;
    sub { croak "No support for $name method: File is output only" };
    } # _outputOnly

*read		= _outputOnly ("read");
*READ		= _outputOnly ("READ");
*readline	= _outputOnly ("readline");
*READLINE	= _outputOnly ("READLINE");
*getc		= _outputOnly ("getc");
*GETC		= _outputOnly ("GETC");

sub _NYI {
    my $name = shift;
    sub { croak "Support for $name method NYI" };
    } # _NYI

*open		= _NYI ("open");
*OPEN		= _NYI ("OPEN");
*seek		= _NYI ("seek");
*SEEK		= _NYI ("SEEK");
*write		= _NYI ("write");
*WRITE		= _NYI ("WRITE");

=begin comment

We do not want to document these:

=over 4

=item getc

=item open

=item read

=item readline

=item seek

=item write

=back

=end comment

=cut

1;
