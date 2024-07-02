package Tradestie::WSBetsAPI::TTM_Squeeze_Stocks;

# ABSTRACT: TTM Squeeze Stocks class

use v5.38;
use strict;
use warnings;
use Moose;

has 'date' => (
    is  => 'rw',
    isa => 'Str',
);

has 'in_squeeze' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'no_of_days_in_squeeze' => (
    is  => 'rw',
    isa => 'Int',
);

has 'no_of_days_out_of_squeeze' => (
    is  => 'rw',
    isa => 'Int',
);

has 'out_of_squeeze' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'ticker' => (
    is  => 'rw',
    isa => 'Str',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tradestie::WSBetsAPI::TTM_Squeeze_Stocks - TTM Squeeze Stocks class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    [
        {
            'date': 'Fri, 18 Nov 2022 00:00:00 GMT',
            'in_squeeze': False,
            'no_of_days_in_squeeze': 0,
            'no_of_days_out_of_squeeze': 2,
            'out_of_squeeze': True,
            'ticker': 'AA'
        },
        ...
    ]

=head1 DESCRIPTION

L<TTM Squeeze Stocks Scanner API|https://tradestie.com/apps/ttm-squeeze-stocks-scanner/api/>

This Api returns stocks which are in TTM Squeeze or out of Squeeze

Change the date to find the stocks for a different date.

Note - The list gets updated every day around 6pm EST

=head1 ATTRIBUTES

=head2 date

Holds the date of the stocks associated with that time.

=head2 in_squeeze

Holds a boolean value (True - 1 or False - 0) indicating whether the ticker is in the squeeze.

=head2 no_days_in_squeeze

Holds the total number (or count) of days that the ticker is in the squeeze.

=head2 no_of_days_out_of_squeeze

Holds the total number (or count) of days that the ticker is out of the squeeze.

=head2 out_of_squeeze

Holds a boolean value (True - 1 or False - 0) indicating whether the ticker is out of the squeeze.

=head2 ticker

Holds the ticker's symbol.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Rayhan Alcena.

This is free software, licensed under:

  The MIT (X11) License

=cut
