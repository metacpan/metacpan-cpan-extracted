package Fitnesse::Slim::Test::TableTableIncFirstCol;

use strict;
use warnings;

sub new { bless {}, $_[0] }

sub do_table {
    my ($self, $table) = @_;
    return [ map {
        my $value = $_->[0];
        die "java.lang.NullPointerException\n" unless defined $value;
        die "java.lang.NumberFormatException: For input string: \"$value\"\n"
            unless !ref($value) && $value =~ /\A[+-]?[0-9]+\z/
                && _fits_java_integer($value);
        my $next = 0 + $value;
        $next = $next == 2_147_483_647 ? -2_147_483_648 : $next + 1;
        [ 'no change', "pass:$next" ];
    } @$table ];
}

sub _fits_java_integer {
    my ($value) = @_;
    my $negative = $value =~ s/\A-//;
    $value =~ s/\A\+//;
    $value =~ s/\A0+(?=[0-9])//;
    my $limit = $negative ? '2147483648' : '2147483647';
    return 0 if length($value) > length($limit);
    return 0 if length($value) == length($limit) && $value gt $limit;
    return 1;
}

1;
