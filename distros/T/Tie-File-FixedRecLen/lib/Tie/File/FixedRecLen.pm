package Tie::File::FixedRecLen;
{
  $Tie::File::FixedRecLen::VERSION = '2.112531';
}

use strict;
use warnings FATAL => 'all';

use 5.008;

use base 'Tie::File';
# v.0.97 says: "This version promises absolutely nothing about the internals,
# which may change without notice. A future version of the module will have a
# well-defined and stable subclassing API."

my $DEBUG = $ENV{FIXEDRECLEN_DEBUG} || 0;
my @good_opts = qw(record_length pad_dir pad_char);

# ===========================================================================

sub TIEARRAY {
    my ($class, $file, %opts) = @_;
    my %tmp_opts = (); # ugh, Tie::File is broken for subclassing

    for (@good_opts) {
        $tmp_opts{$_} = delete $opts{$_} if exists $opts{$_};
    }
    my $self = $class->SUPER::TIEARRAY(
        $file, %opts, autodefer => 0, memory => 0,
    );
    for (keys %tmp_opts) {
        $self->{$_} = $tmp_opts{$_};
    }

    die "Useless use of Tie::File::FixedRecLen without a record_length\n"
        if !exists $self->{record_length}
            or !defined $self->{record_length}
            or $self->{record_length} !~ m/^\d+$/
            or $self->{record_length} == 0;

    $self->{pad_dir}  = 'left' if !defined $self->{pad_dir};
    $self->{pad_char} = ' '    if !defined $self->{pad_char};
    return $self;
}

# ===========================================================================
# utility methods

sub _add_padding {
    my ($self, $rec) = @_;
    $rec = '' if !defined $rec;
    print STDERR "_add_padding(1) :$rec:\n" if $DEBUG;

    # deferred records may have already been terminated with recsep
    my $has_recsep = 0;
    while (index($rec, $self->{recsep}, (length($rec) - $self->{recseplen})) != -1) {
        substr($rec, - $self->{recseplen}) = ''; # temporary chomp
        $has_recsep = 1;
    }

    my $rl = length($rec);
    die "Record '$rec' ($rl) exceeds record length ($self->{record_length})\n"
        if $rl > $self->{record_length};

    if (length($rec) != $self->{record_length}) {
        my $pad
            = $self->{pad_char} x ($self->{record_length} - length($rec));

        if ($self->{pad_dir} eq 'right') {
            $rec .= $pad;
        }
        else {
            $rec = $pad . $rec;
        }
    }

    $rec .= $self->{recsep} if $has_recsep;
    print STDERR "_add_padding(2) :$rec:\n" if $DEBUG;

    return $rec;
}

sub _del_padding {
    my ($self, $rec) = @_;
    return undef if !defined $rec;
    print STDERR "_del_padding(1) :$rec:\n" if $DEBUG;

    my $has_recsep = 0;
    while (index($rec, $self->{recsep}, (length($rec) - $self->{recseplen})) != -1) {
        substr($rec, - $self->{recseplen}) = ''; # temporary chomp
        $has_recsep = 1;
    }

    my $rl = length($rec);
    die "Record '$rec' ($rl) is not set length ($self->{record_length})\n"
        if $rl != $self->{record_length};

    if ($self->{pad_dir} eq 'right') {
        while (index($rec,$self->{pad_char},(length($rec) - 1))
                    == (length($rec) - 1)) {
            substr($rec, -1, 1) = '';
        }
    }
    else {
        while (index($rec,$self->{pad_char},0) == 0) {
            substr($rec, 0, 1) = '';
        }
    }

    $rec .= $self->{recsep} if $has_recsep;
    print STDERR "_del_padding(2) :$rec:\n" if $DEBUG;

    return $rec;
}

# ===========================================================================

sub FETCH {
    my ($self, $n) = @_;

    my $rec = $self->SUPER::FETCH($n);
    return undef if !defined $rec;

    return $self->_del_padding($rec);
}

# SUPER->STORE will append record separator for us
sub STORE {
    my ($self, $n, $rec) = @_;
    $rec = $self->_add_padding($rec);

    return $self->SUPER::STORE($n, $rec);
}

# need to override this as it is called from STORESIZE with $self->{recsep}
# sadly it could be called from STORE as well but that can't be helped.
sub _store_deferred {
    my ($self, $n, $rec) = @_;
    $rec = $self->_add_padding($rec);

    return $self->SUPER::_store_deferred($n, $rec);
}

sub SPLICE {
    my ($self, $pos, $nrecs, @data) = @_;

    map {$_ = $self->_add_padding($_)} @data;
    my @result = $self->SUPER::SPLICE($pos, $nrecs, @data);

    # Yes, the return value of 'splice' *is* actually this complicated
    wantarray
        ? map {$self->_del_padding($_)} @result
        : @result ? $self->_del_padding($result[-1]) : undef;
}

# to work around _extend_file_to being called in many circumstances
sub STORESIZE {
    my ($self, $len) = @_;

    $len += ($len > $self->FETCHSIZE ? 1 : 0);
    print STDERR "STORESIZE $len\n" if $DEBUG;
    return $self->SUPER::STORESIZE($len);
}

sub EXTEND {
    my ($self, $len) = @_;

    $len += ($len > $self->FETCHSIZE ? 1 : 0);
    print STDERR "EXTEND $len\n" if $DEBUG;
    return $self->SUPER::EXTEND($len);
}

# ===========================================================================

# okay, according to the Tie::File code comments, the offset table has one
# more entry than the total number of records. I assume this means the last
# offset table entry is the seek position of the record which is next to be
# written in the file (or put another way, the size of the file).

sub _fill_offsets {
    my ($self) = @_;

    my $fh   = $self->{fh};
    my $size = -s $fh;
    my $off  = $self->{offsets};
    my $totreclen = $self->{record_length} + $self->{recseplen};

    # for development
    # seek $fh,0,0;
    # my $lines = join '',<$fh>;
    # print STDERR "OFFSETS(1) content is :$lines:\n" if $DEBUG;

    die "File ($size) does not appear to be using ".
        "fixed length records ($totreclen)\n" if ($size % $totreclen) != 0;

    @$off = map {$_ * $totreclen} (0 .. ($size / $totreclen));
    print STDERR "OFFSETS(2) offsets :@$off:\n" if $DEBUG;

    $self->_seek(-1); # position after the end of the last record
    $self->{eof} = 1;

    return $#{$off};
}

# populate the offsets table up to the beginning of record $n
# return the offset of record $n
sub _fill_offsets_to {
    my ($self, $n) = @_;

    $self->_fill_offsets;

    my $off = $self->{offsets};
    return undef if $n > $#{$off};
    return $off->[$n];
}

# We have read to the end of the file and have the offsets table
# entirely populated.  Now we need to write a new record beyond
# the end of the file.  We prepare for this by writing
# empty records into the file up to the position we want
#
# assumes that the offsets table already contains the offset of record $n,
# if it exists, and extends to the end of the file if not.
sub _extend_file_to {
    my ($self, $n) = @_;

    my $record = $self->{pad_char} x $self->{record_length};
    my $recs = $self->_fill_offsets;
        # a bit safer to just refresh this now
        # and also positions us at the end of the file
        # and gives us a starting counter for writing records

    print STDERR "_extend_file_to $n (-2)...\n" if $DEBUG;
    for ($recs .. ($n - 2)) {
        print STDERR
            "_extend_file_to $_ writing record '$record$self->{recsep}'\n"
                if $DEBUG;
        $self->_write_record($record . $self->{recsep});
    }
    $self->_fill_offsets; # refresh offsets table

    return undef; # not sure what Tie::File's version wants to return
}

1;

# ABSTRACT: Fixed Length Record support for Tie:File


__END__
=pod

=head1 NAME

Tie::File::FixedRecLen - Fixed Length Record support for Tie:File

=head1 VERSION

version 2.112531

=head1 SYNOPSIS

 # for typical read/write random access...

 use Tie::File::FixedRecLen;
 
 tie @array, 'Tie::File::FixedRecLen', $file, record_length => 20
     or die ...;
 
 # or for faster, sequential write-only use...
 
 use Tie::File::FixedRecLen::Store;
 
 tie @array, 'Tie::File::FixedRecLen::Store', $file, record_length => 20
     or die ...;

=head1 DESCRIPTION

Use Tie::File::FixedRecLen as a drop-in replacement to L<Tie::File> in order to
add support for fixed length records within your tied files. When tieing to a
file, you must specify the length of a record in the file. This length does
not include the record separator character(s).

Apart from the configuration parameters mentioned below, you should use
Tie::File::FixedRecLen in just the same way as Tie::File. This module is
designed to create files which are read/write compatible with Tie::File;

Please take just a minute to read the L</CAVEATS> section, below.

There is an ancilliary module, Tie::File::FixedRecLen::Store, which provides a
subset of the features of Tie::File::FixedRecLen. It is designed for fast,
write-only, sequential data logging. More information is given in the L</STORE MODULE>
section, below.

=head1 CAVEATS

=over 4

=item *

Tie::File::FixedRecLen is written for Tie::File 0.97, and cannot be used with
any other version of that module. This is because there is no formlized API
into Tie::File, so it's quite likely things will break as Tie::File's
internals are changed. Sorry about that.

=back

=over 4

=item *

Do B<not> try using cacheing or deferred writing, at least not yet. Tie::File
is quite a complicated beast, so to make life simpler for
Tie::File::FixedRecLen it does not try to cope with cacheing or deferring.

=back

=over 4

=item *

In Tie::File you could include the record separator character(s) I<within> a
record, and although the module might get confused, the file would still be
valid. In Tie::File::FixedRecLen this is a really bad thing to do, so please
don't. Indeed, trailing multiple record separator character(s) on a field will
be (sliently) stripped and replaced by a single record separator.

=back

=over 4

=item *

Anyone with multi-byte character set experience is very welcome to lend
support in making this module work in those environments. Currently my best
guess is that things will break if this module is used with multi-byte
character set files.

=back

=head1 CONFIGURATION

There are three configuration parameters you can pass when tieing to a file
(in addition to those offered by L<Tie::File>). This module does not support
the fancy C<-> prefix to option names that you have with Tie::File.

=over 4

=item record_length

This parameter is B<required>. It specifies the length (in bytes) of a record
in the tied file. C<record_length> must be an integer, and it must be greater
than zero. Each time a record is read or written, it is compared to this
length, and an error is raised if there is a mismatch.

When writing records to the tied file, they are padded out to C<record_length>
if necessary. Be aware that this length does B<not> include the record
separator.

=item pad_char

This parameter is optional.

Records will be padded with this character until they are C<record_length>
bytes in length. You should make this a single byte character, otherwise
things are likely to break.

The default padding character is the space character. This allows the tied
file to remain readable by a human. If you use leading or trailing space
characters in your records, then select another character, and if you are not
bothered about human readability, it could be a control character (e.g. C<^G>).

=item pad_dir

This parameter is optional.

Records may be padded out to the record length either before the first
character or after the last character.

Set this option to "right" if you would prefer end padding; the default is to
pad with the C<pad_char> character before the first character of the record
data. For example with "right" padding, a record length of 10 and pad
character of '.':

 data: "abc123"
 written record: "abc123....\n"
 returned data when read back: "abc123"

And with the same settings except we'll use the module's default "left"
padding this time:

 data: "abc123"
 written record: "....abc123\n"
 returned data when read back: "abc123"

=back

=head1 DIAGNOSTICS

=over 4

=item C<Tie::File::FixedRecLen written for Tie::File 0.97>

The Tie::File programmers' API is not standardized, and may change in the
future. You must have version 0.97 of Tie::File to use this version of
Tie::File::FixedRecLen.

=item C<Useless use of Tie::File::FixedRecLen without a record_length>

You have forgotten to provide the C<record_length> parameter when tieing your
file, or it is there but is not a positive integer.

=item C<Record '...' does not match set length (...)>

When reading a record from the tied file, it is not the expected
C<record_length> in size. Are you sure the file was created and written by
Tie::File::FixedRecLen?

=item C<Record '...' exceeds fixed record length (...)>

When attempting to write a record to the tied file, you have passed data which
exceeds C<record_length> in size. Please don't do that.

=item C<File does not appear to be using fixed length records>

Internally, Tie::File and Tie::File::FixedRecLen compute offset markers for
each record in the file. This error indicates the file is not a whole multiple
of C<record_length> (+ C<recsep>'s length) in size, which probably means it is
not a Tie::File::FixedRecLen file.

=back

=head1 STORE MODULE

=head2 Rationale

The project for which Tie::File::FixedRecLen was written required very fast
logging of polled SNMP data, of the order of thousands of variables every
couple of minutes, to a remote networked server, for a period of many years.

This requires very fast writes indeed on the storage server, so you will find
Tie::File::FixedRecLen to be a lot quicker than Tie::File (for most
operations), at the obvious cost of storage space. However this module still
suffers in that by using the core of Tie::File, its write time is still
proportional to the size of the file. There is no easy way around this. Whilst
the effect is measured in the milliseconds as file size grows, it is not
suitable for use over a period of years.

Hence the ancilliary module Tie::File::FixedRecLen::Store was written, for
really fast writes in a file format compatible with Tie::File and
Tie::File::FixedRecLen, with some compromise in functionality.

=head2 Usage

Use Tie::File::FixedRecLen for write-only, sequential storage of fixed-length
record data.

Records can only be written (not read), and only at the end of an array
(C<push>), although this may be at the immediate end or at some further
point and the file will be suitably padded.

The module has a very simple interface:

 use Tie::File::FixedRecLen::Store;
 
 tie @store, 'Tie::File::FixedRecLen::Store', $filename, record_length => $record_length
    or die...

Note that Tie::File::FixedRecLen::Store accepts the C<record_length>,
C<recsep> and C<pad_char> options just like Tie::File::FixedRecLen. However,
padding in the elements is B<always> "left" (i.e. element start) and there is
currently no option to change this.

Other than that, you can use any write method on the array, for example:

 push @store, 'item';
 push @store, 'item1', 'item2', 'etc';
 $store[10] = 'value'; # only if $#store < 10
 $#store = 20; # again, only if $#store < 20

If you try to operate on the array in any other fashion, for instance to
C<pop> an element, the module will die.

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Naturally this would not be here without the excellent Tie::File module.

=item *

Tie::File::VERSION check bug - Tom Hukins

=item *

Thanks to my wife Suzanne, for her patience whilst I whined about not being
able to get the performance I wanted out of this project.

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

