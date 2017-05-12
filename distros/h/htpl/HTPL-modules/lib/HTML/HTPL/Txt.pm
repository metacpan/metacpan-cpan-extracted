package HTML::HTPL::Txt;

use HTML::HTPL::Orig;
use HTML::HTPL::Lib;
use strict;
use vars qw(@ISA);

@ISA = qw(HTML::HTPL::Orig);

sub new {
    my $class = shift;
    my @copy = @_;
    bless {'params' => \@copy}, $class;
}

# This method is overridable

sub realread {
    my ($self, $hnd) = @_;
    return scalar(<$hnd>);
}

sub realfetch {
    my $self = shift;

    my ($hnd, $linedel) = @{$self->{'params'}};

    my $savedel = $/;
    $/ = $linedel;
    my $l = $self->realread($hnd);
    unless ($l) {
        closedoc($hnd);
        return undef;
    }
    chomp $l;
    my $retval = $self->readln($l);
    $/ = $savedel;


    $retval;
}

1;
