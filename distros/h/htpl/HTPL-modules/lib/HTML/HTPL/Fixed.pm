package HTML::HTPL::Fixed;

use HTML::HTPL::Lib;
use HTML::HTPL::Result;
use HTML::HTPL::Txt;
use Symbol;
use strict;
use vars qw(@ISA);

@ISA = qw(HTML::HTPL::Txt);

sub openfixed {
    my ($filename, @fields) = @_;

# substitute second parameter by a scalar REFERENCE
# to request subclass.

    my $sub;
    if (UNIVERSAL::isa($fields[0], 'SCALAR')) {
        $sub = ${shift @fields};
    }
    my $class = __PACKAGE__ . ($sub ? "::$sub" : "");
    my (@cols, @heads);
    foreach (@fields) {
        my ($name, $len) = split(/:/, $_);
        push(@cols, $name);
        push(@heads, $len);
    }

    my $hnd = &gensym;

    &HTML::HTPL::Lib'opendoc($hnd, $filename);

    my $orig = $class->new($hnd, \@heads);
    my $result = new HTML::HTPL::Result($orig, @cols);


    $result;
}

sub readln {
    my ($self, $line) = @_;
    my $re = $self->{'re'};
    $line = sprintf("%-$self->{'len'}s", $line);
    my @values = ($line =~ /$re/);
    my @dummy = map {s/[\0\s]+$//;} @values;
    \@values;
}

sub new {
    my ($class, $hnd, $lens) = @_;
    my $self = $class->SUPER::new($hnd, "\n");
    my $re = join("", map {"(.{$_})";} @$lens);
    $self->{'re'} = $re;
    $self->{'len'} = &HTML::HTPL::Lib::sum(@$lens);
    $self;
}

package HTML::HTPL::Fixed::IBM;
use vars qw(@ISA);
@ISA = qw(HTML::HTPL::Fixed);

sub realread {
    my ($self, $hnd) = @_;
    my $line;
    my $len = $self->{'len'};
    return undef unless (read($hnd, $line, $len) > $len / 2);
    $line;
}

1;
