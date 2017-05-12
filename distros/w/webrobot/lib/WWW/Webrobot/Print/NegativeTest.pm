package WWW::Webrobot::Print::NegativeTest;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


use WWW::Webrobot::Util qw/textify/;
use Test::More qw/no_plan/;


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub global_start {
    #my ($self) = @_;
}

sub item_pre {
    #my ($self, $arg) = @_;
}


sub bool_assert { $_[0] ? "FALSE" : "TRUE " }
sub bool { $_[0] ? "TRUE " : "FALSE" }

sub item_post {
    my ($self, $r, $arg) = @_;
    my $data = $arg->{data};
    my $out_ok = "$arg->{method} $arg->{url}";
    $out_ok .= " '$_'=>'$data->{$_}'" foreach (keys %$data);
    my $tmp = $arg->{fail_str};
    my $fail_str = !defined $tmp ? "" : (ref $tmp eq 'ARRAY') ? join("\n", @$tmp) : $tmp || "";
    my $ok = defined $arg->{fail} ? $arg->{fail} : 1;
    if (! ok($ok, textify $out_ok)) {
        diag " "x4 . textify "Request:     $arg->{method} $arg->{url}";
        diag " "x4 . textify "Description: $arg->{description}";
        if ($data && scalar keys %$data) {
            diag " "x4 . textify "Data:";
            diag " "x8 . textify "'$_' => '$data->{$_}'" foreach (keys %$data);
        }
        diag textify " "x4 . "Assertions:  " . bool_assert($arg->{fail});
        if (my $s = $fail_str) {
            $s =~ s/^(.)/ bool($1) /gme;
            $s =~ s/^/        /gm;
            diag textify $s;
        }
        if ($r && (my $c = $r->content)) {
            my $line = substr($c, 0, 132);
            diag " "x4 . textify "Content: [$line]" ;
        }
    }
}

sub global_end {
    #my $self = shift;
}

1;

=head1 NAME

WWW::Webrobot::Print::NegativeTest - Invert all assertions

=head1 DESCRIPTION

This class is for testing in C<t/*> only!
See C<t/assert-get-neg.t>.

=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=cut
