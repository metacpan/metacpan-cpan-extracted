package VIC::PIC::Base;
use strict;
use warnings;

our $VERSION = '0.31';
$VERSION = eval $VERSION;

use Carp;
use Moo;
use VIC::PIC::Roles; # load all the roles
use namespace::clean;

sub doesrole {
    my $a = $_[0]->does('VIC::PIC::Roles::' . $_[1]);
    unless ($_[1]) { # no logging
        carp ref($_[0]) . " does not do role $_[1]" unless $a;
    }
    return $a;
}

sub doesroles {
    my $self = shift;
    foreach (@_) {
        return unless $self->doesrole($_);
    }
    return 1;
}

has chip_config => (is => 'ro', default => sub { {} });

sub print_pinout {
    my ($self, $fh) = @_;
    $fh = *STDOUT unless $fh;
    return unless $self->doesroles(qw(CodeGen Chip));
    my $pinref = $self->pins;
    my @pinnames = ();
    my $maxlen = 0;
    foreach (sort(keys %$pinref)) {
        next unless $_ =~ /^\d+$/;
        my $aa = $pinref->{$_};
        my $str = join('/', @{$aa}) if ref $aa eq 'ARRAY';
        $str = $aa unless ref $aa;
        $pinnames[$_ - 1] = $str;
        $maxlen = length($str) if $maxlen < length($str);
    }
    my $pdip = scalar(@pinnames) / 2;
    my $start = 5 + $maxlen;
    my $chip = uc($self->type);
    my $w = 14;
    my $notch = '__';
    my $w0 = ($w - length($notch)) / 2;
    print $fh "\n\n";
    print $fh ' ' x $start, '+', '=' x $w0, $notch, '=' x $w0, '+', "\n";
    my $pinline = '---';
    for (my $i = 0; $i < $pdip; ++$i) {
        my $s1 = $pinnames[$i];
        my $s2 = $pinnames[2 * $pdip - $i - 1];
        my $l1 = $start - 1 - length($pinline) - length($s1);
        my $p1 = sprintf "%d", ($i + 1);
        my $p2 = sprintf "%d", (2 * $pdip - $i);
        my $w1 = $w - length($p1) - length($p2);
        print $fh ' ' x $l1, $s1, ' ', $pinline, '|', $p1, ' ' x $w1, $p2, '|', $pinline, ' ', $s2, "\n";
        print $fh ' ' x $start, '|', ' ' x $w, '|', "\n";
        if (($i + 1) == int($pdip / 2)) {
            my $w2 = int(($w - length($chip)) / 2);
            my $w3 = $w - $w2 - length($chip);
            print $fh ' ' x $start, '|', ' ' x $w2, $chip, ' ' x $w3, '|', "\n";
            print $fh ' ' x $start, '|', ' ' x $w, '|', "\n";
        }
    }
    print $fh ' ' x $start, '+', '=' x $w, '+', "\n";
    print $fh "\n\n";
    1;
}

1;
