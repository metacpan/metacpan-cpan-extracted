package VRML::Base;

############################## Copyright ##############################
#                                                                     #
# This program is Copyright 1996,1998 by Hartmut Palm.                #
# This program is free software; you can redistribute it and/or       #
# modify it under the terms of the GNU General Public License         #
# as published by the Free Software Foundation; either version 2      #
# of the License, or (at your option) any later version.              #
#                                                                     #
# This program is distributed in the hope that it will be useful,     #
# but WITHOUT ANY WARRANTY; without even the implied warranty of      #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       #
# GNU General Public License for more details.                        #
#                                                                     #
# If you do not have a copy of the GNU General Public License write   #
# to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,     #
# MA 02139, USA.                                                      #
#                                                                     #
#######################################################################

require 5.000;
use strict;
use vars qw($VERSION $PI $PI_2);

$VERSION = "1.07";
$PI = 3.1415926;
$PI_2 = $PI/2;

sub new {
    my $class = shift;
    my $tabs = shift;
    my $self = {};
    $self->{'TAB'} = defined $tabs ? "\t" x $tabs : "";
    $self->{'TAB_VIEW'} = "";
    $self->{'DEBUG'} = 0;
    $self->{'VERSION'} = 0; # VRML specification
    $self->{'CONVERT'} = 1; # convert degree to radiant
    $self->{'BROWSER'} = "";# Which VRML + HTML browser
    $self->{'VRML'} = [];   # THE VRML array
    $self->{'DEF'}  = {};   # remember DEFs
    $self->{'PROTO'} = {};  # remember PROTOs
    $self->{'XYZ'}  = [[0,0,0]];
    $self->{'Xmax'} = 0;
    $self->{'Ymax'} = 0;
    $self->{'Zmax'} = 0;
    $self->{'Xmin'} = 0;
    $self->{'Ymin'} = 0;
    $self->{'Zmin'} = 0;
    $self->{'DX'} = 0;
    $self->{'DY'} = 0;
    $self->{'DZ'} = 0;
    $self->{'ID'}  = 0;
    return bless $self, $class;
}

sub browser {
    my $self = shift;
    return unless $_[0]; # @_ wouldn't work on PC
    ($self->{'BROWSER'}) = join("+",@_);
    $self->_put("# Set Browser to: '$self->{'browser'}'\n")
      if $self->{'DEBUG'};
    return $self;
}

#####################################################################
#               Methods to modify the VRML array
#
#####################################################################

sub _init {
    my $self = shift;
    my $vrml = shift;
    $self->{'VRML'} = [$vrml];
    return $self;
}

sub _add {
    my $self = shift;
    my $vrml = shift;
    ${$self->{'VRML'}}[$#{$self->{'VRML'}}] .= $vrml;
    return $self;
}

sub _put {
    my $self = shift;
    my $vrml = shift;
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

sub _row {
    my $self = shift;
    my ($row) = @_;
    my $vrml = $self->{'TAB'}.$row;
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

sub _swap {
    my $self = shift;
    my $element1 = pop @{$self->{'VRML'}};
    my $element2 = pop @{$self->{'VRML'}};
    push @{$self->{'VRML'}}, $element1;
    push @{$self->{'VRML'}}, $element2;
    return $self;
}

sub _pos {
    my $self = shift;
    return $#{$self->{'VRML'}};
}

sub _trim {
    my $self = shift;
    my ($index) = @_;
    $index = $#{$self->{'VRML'}} unless defined $index;
    $self->{'VRML'}[$index-1] =~ s/\s+$/ /;
    $self->{'VRML'}[$index] =~ s/^\s+//;
    return $self;
}

sub debug {
    my $self = shift;
    $self->{'DEBUG'} = shift;
    $self->_put("# Set Debug Level to $self->{'DEBUG'}\n");
    return $self;
}

sub display_vars {
    my $self = shift;
    my @keys = @_ ? @_ : sort keys %$self;
    my $key;
    foreach $key (@keys) {
        unless (defined $self->{$key}) {
            print "# $key => undef\n";
            next;
        }
        print "# $key => $self->{$key}";
        print " [".(join(', ',@{$self->{$key}}))."]" if defined
          ref($self->{$key}) && ref($self->{$key}) eq "ARRAY" &&
          $key ne "VRML";
        print " [".(join(', ',sort keys %{$self->{$key}}))."]"
          if defined ref($self->{$key}) && ref($self->{$key}) eq "HASH";
        print "\n";
    }
    return $self;
}

sub string_to_array  {
    my $self = shift;
    my $pt = shift;
    return @$pt if ref $pt eq 'ARRAY';
    # remove leading/trailing spaces!
    my $tmp = $pt; $tmp =~ s/^\s+//; $tmp =~ s/\s+$//;
    return split(/\s+/,$tmp);
}

#--------------------------------------------------------------------
#       Insert Comments
#--------------------------------------------------------------------
sub comment {
    my $self = shift;
    my ($comment) = @_;
    $comment = defined $comment ? "# ".$comment : "#";
    push @{$self->{'VRML'}}, $comment."\n";
    return $self;
}

#--------------------------------------------------------------------
#       In-/Output VRML
#--------------------------------------------------------------------
sub insert {
    my $self = shift;
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    $string = $self->{'TAB'}.$string;
    $string =~ s/\n/\n$self->{'TAB'}/g;
    push @{$self->{'VRML'}}, $string."\n";
    return $self;
}

sub insert__DATA__ {
    my $self = shift;
    $self->{'DATApos'} = tell(main::DATA) unless defined $self->{'DATApos'};
    print "     self->{'DATApos'}=$self->{'DATApos'}\n" if $self->{'DEBUG'};
    push @{$self->{'VRML'}}, <main::DATA>,"\n";
    seek(main::DATA,$self->{'DATApos'},0);
    return $self;
}

sub include {
    my $self = shift;
    my @filename = @_;
    return $self if !defined $filename[0] || $filename[0] eq "";
    foreach (@filename) {
        open(INCLUDE, "<$_") || die "Can't include \"$_\"\n$!\n";
        push @{$self->{'VRML'}}, <INCLUDE>;
        push @{$self->{'VRML'}}, "\n";
        close(INCLUDE);
    }
    return $self;
}

sub format {
    my $self = shift;
    my $format = shift;
    if (defined $format && $format eq "none") {
        map { s/^[\t ]+//; s/\n[\t ]+/\n/g; s/\t+/ /g; s/ +/ /g; } @{$self->{'VRML'}};
    } else {
        map { s/    / /g; s/\t/  /g; } @{$self->{'VRML'}};
    }
    return $self;
}

sub print {
    my $self = shift;
    my $mime = shift;
    my $pipe = shift;
    select STDOUT; $|=1;
    print "Content-type: $self->{'Content-type'}\n\n"
      if $self->{'Content-type'} && $mime;
    if ($pipe) {
        open(PIPE, "|$pipe") || die; select PIPE; $|=1;
        for (@{$self->{'VRML'}}) { print; }
        select STDOUT;
        close(PIPE);
    } else {
        for (@{$self->{'VRML'}}) { print; }
    }
    return $self;
}

sub save {
    my $self = shift;
    my $filename = shift;
    my $pipe = shift;
    unless (defined $filename) {
        ($filename) = $0 =~ m/(.*)\./;
        $filename .= ".wrl";
    }
    open(VRMLFILE, ">$filename") ||
      die "Can't create file: \"$filename\" ($!)\n";
    if ($pipe) {
        print VRMLFILE "Can't pipe to \"$pipe\"\n";
        close(VRMLFILE);
        open(VRMLFILE, "| $pipe > $filename") || die;
    }
    for (@{$self->{'VRML'}}) { print VRMLFILE; }
    close(VRMLFILE);
    return $self;
}

sub as_string {
    my $self = shift;
    my $vrml = "";
    for (@{$self->{'VRML'}}) { $vrml .= $_ };
    return $vrml;
}

#--------------------------------------------------------------------

sub escape {
    my $self = shift;
    shift;
}

sub ascii {
    my $self = shift;
    local $_ = undef;
    foreach (@_) {
        s/[\204\344\365]/ae/g;
        s/[\224\366]/oe/g;
        s/[\201\374]/ue/g;
        s/[\216\304]/Ae/g;
        s/[\231\305\326]/Oe/g;
        s/[\263\334]/Ue/g;
        s/[\257\337]/sz/g;
        s/[\000-\010\013-\037\177-\377]/_/g;
    }
    return (@_) if wantarray;
    return $_[0];
}

sub utf8 {
    my $self = shift;
    local $_ = undef;
    #foreach (@_) {
    #    s/[\201\374]/\x00\x75\x03\x08/g;
    #    s/(.)/\x00$1/g;
    #}
    return (@_) if wantarray;
    return $_[0];
}

sub xyz {
    my $self = shift;
    return $self unless @_;
    ($self->{'DX'}, $self->{'DY'}, $self->{'DZ'}) = @_;
    ${$self->{'XYZ'}[0]}[0] += $self->{'DX'};
    ${$self->{'XYZ'}[0]}[1] += $self->{'DY'};
    ${$self->{'XYZ'}[0]}[2] += $self->{'DZ'};
    print "XYZ = ".join(', ',@{$self->{'XYZ'}[0]})."\n"
      if $self->{'DEBUG'} == 2;
    $self->{'Xmax'} = ${$self->{'XYZ'}[0]}[0]
      if $self->{'Xmax'} < ${$self->{'XYZ'}[0]}[0];
    $self->{'Ymax'} = ${$self->{'XYZ'}[0]}[1]
      if $self->{'Ymax'} < ${$self->{'XYZ'}[0]}[1];
    $self->{'Zmax'} = ${$self->{'XYZ'}[0]}[2]
      if $self->{'Zmax'} < ${$self->{'XYZ'}[0]}[2];
    $self->{'Xmin'} = ${$self->{'XYZ'}[0]}[0]
      if $self->{'Xmin'} > ${$self->{'XYZ'}[0]}[0];
    $self->{'Ymin'} = ${$self->{'XYZ'}[0]}[1]
      if $self->{'Ymin'} > ${$self->{'XYZ'}[0]}[1];
    $self->{'Zmin'} = ${$self->{'XYZ'}[0]}[2]
      if $self->{'Zmin'} > ${$self->{'XYZ'}[0]}[2];
}

sub bboxCenter {
    my $self = shift;
    my ($x, $y, $z) = @_;
    $x = ($self->{'Xmax'} + $self->{'Xmin'})/2 unless defined $x;
    $y = ($self->{'Ymax'} + $self->{'Ymin'})/2 unless defined $y;
    $z = ($self->{'Zmax'} + $self->{'Zmin'})/2 unless defined $z;
    return ($x, $y, $z) if wantarray;
    return "$x $y $z";
}

sub bboxSize {
    my $self = shift;
    my ($dx, $dy, $dz) = @_;
    $dx = $self->{'Xmax'} - $self->{'Xmin'} unless defined $dx;
    $dy = $self->{'Ymax'} - $self->{'Ymin'} unless defined $dy;
    $dz = $self->{'Zmax'} - $self->{'Zmin'} unless defined $dz;
    return ($dx, $dy, $dz) if wantarray;
    return "$dx $dy $dz";
}

1;

__END__

=head1 NAME

VRML::Base.pm - common basic methods for VRML in/output

=head1 SYNOPSIS

    use VRML::Base;

=head1 DESCRIPTION

Following methods are implemented.

=over 4

=item new

C<new>

Creates a new VRML scene object.

=item comment

C<comment('string')>

Inserts a single comment line at the current position.
You don't need to write the # in front. If no string is given, the method
inserts only a #.

=item insert

C<insert('string')>

Inserts the string at the current position in the VRML scene.

=item insert__DATA__

C<insert__DATA__()>

Inserts the text block after __DATA__ of the current perl script
in the VRML scene. Remember there are two underscores in front and
at the end of the word DATA.

=item include

C<include('filename')>

Inserts the VRML code of the specified file in the current scene.

=item print

C<print('mime', 'pipe')>

Prints the VRML scene to STDOUT. If I<mime> (bool) is given, this method
prints the scene to STDOUT with the Content-type of the current scene. If
I<pipe> is given, then first the stream is send to the pipe and after that to
STDOUT. This is usefull to compress the VRML code with GNU-ZIP.

Example:

1.  I<$vrml-E<gt>print>

2.  I<$vrml-E<gt>print(1, 'gzip -f9')>


=item save

C<save('filename', 'pipe')>

Saves the VRML code to the specified name in I<filename>. If no filename is
given, this method uses the name of the perl script and changes the extension
against C<.wrl>. If I<pipe> is given, then first the stream is send to the pipe
and after that to STDOUT. This is usefull to compress the VRML code with
GNU-ZIP.

Example:

1.  I<$vrml-E<gt>save>

2.  I<$vrml-E<gt>save(undef, 'gzip -f9')>

3.  I<$vrml-E<gt>save('myScene.wrl')>


=item as_string

C<as_string>

Returns the VRML scene as string. Possible it uses too much memory to
build the string.

=back

=head1 Internals

You don't need the following 'native' methods.
If yet, tell it me and I'll describe it in the next version.

=over 4

=item debug

C<debug>

=item _init

C<_init('VRML')>

=item _add

C<_add>

=item _trim

C<_trim>

=item _swap

C<_swap>

=item _put

C<_put>

=item _row

C<_row>

=item _pos

C<_pos>

=item _format

C<_format>

=back

=head1 AUTHOR

Hartmut Palm F<E<lt>palm@gfz-potsdam.deE<gt>>

=cut

