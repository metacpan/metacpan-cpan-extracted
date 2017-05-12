package Tie::File::FixedRecLen::Store;
{
  $Tie::File::FixedRecLen::Store::VERSION = '2.112531';
}

use strict;
use warnings FATAL => 'all';

use 5.004;
use Carp;
use Symbol;
use Fcntl qw(:flock);

# ===========================================================================

sub TIEARRAY {
    my $class = shift;
    my $file  = shift;
    my %args  = @_;

    if (! defined $file or ! defined $args{record_length}
            or $args{record_length} =~ m/\D/) {
        croak "usage: tie \@ARRAY, '" . __PACKAGE__
            . "', record_length => \$reclen";
    }

    my $pad_char = $args{pad_char} || ' ';
    my $recsep   = $args{recsep}   || "\n";
    my $reclen   = $args{record_length};
    my $elemlen  = ($reclen + length $recsep);

    # open file for appending
    open (my $fh, '>>', $file)
        or croak "can't open filename '$file': $!\n";
    flock ($fh, LOCK_EX)
        or croak "can't lock file '$file': $!\n";

    # re-seek in case somebody wrote before we got the lock
    # and set other things up like buffering
    select ((select ($fh), $| = 1)[0]);
    seek ($fh, 0, 2);
    my $filesize = tell $fh;

    # check this looks like a FixedRecLen file
    croak "file size ($filesize) does not match element length ($elemlen)\n"
        if (($filesize % $elemlen) != 0);
    my $num_records = ($filesize / $elemlen);

    return bless {
        filename  => $file,
        fh        => $fh,
        pad_char  => $pad_char,
        reclen    => $reclen,
        recsep    => $recsep,
        recseplen => length $recsep,
        elemlen   => $elemlen,
        records   => $num_records, # will change
        filesize  => $filesize,    # will change
    }, $class;
}

sub PUSH {
    my $self = shift;
    my @list = @_;
    my $fh = $self->{fh};

    croak "length of value is greater than record length\n"
        if grep {length $_ > $self->{reclen}} @list;

    croak "value contains record separator\n"
        if grep {m/$self->{recsep}/} @list;

    # pad out (note: could run out of RAM doing this)
    @list = map {
        ($self->{pad_char} x ($self->{reclen} - length $_)) . $_
    } @list;

    my $value = join $self->{recsep}, @list;

    print $fh $value, $self->{recsep};
    $self->{records} += scalar @list;
    $self->{filesize} = $self->{records} * $self->{elemlen};

    return $self->{records};
}

sub STORE {
    my $self = shift;
    my ($index, $value) = @_;
    my $fh = $self->{fh};

    croak "length of value is greater than record length\n"
        if (length $value > $self->{reclen});

    croak "value contains record separator\n"
        if ($value =~ m/$self->{recsep}/);

    # random stores are not allowed, but PUSHes beyond file end are
    my $blanks = $index - $self->{records};
    croak "can only append to array, please see Tie::File::FixedRecLen\n"
        if $blanks < 0;

    $self->PUSH( (map {''} (1 .. $blanks)), $value );

    return undef; # just what should STORE return?
}

sub STORESIZE {
    my $self = shift;
    my ($count) = @_;

    return undef if $count == $self->{records};

    croak "cannot shorten, please see Tie::File::FixedRecLen\n"
        if $count < $self->{records};

    $self->PUSH( map {''} (1 .. ($count - $self->{records})) );

    return undef; # just what should STORESIZE return?
}

sub FETCHSIZE {
    return $_[0]->{records};
}

sub UNTIE {
    my $self = shift;
    my $fh = $self->{fh};

    flock ($fh, LOCK_UN);
    close $fh;
}

foreach my $meth (qw/SPLICE FETCH POP SHIFT UNSHIFT CLEAR DELETE EXISTS EXTEND/) {
    *{Symbol::qualify_to_ref($meth)} = sub {croak "unsupported method: '$meth'"};
}

1;
