package Weather::YR::Lang::Symbol;
use Moose;
use namespace::autoclean;

has 'number' => ( isa => 'Int', is => 'rw', required => 1 );
has 'lang'   => ( isa => 'Str', is => 'rw', required => 1 );

has 'text'   => ( isa => 'Str', is => 'ro', lazy_build => 1 );

our $TRANSLATIONS = {
    1 => {
        nb => 'Sol/klarvær',
    },
    2 => {
        nb => 'Lettskyet',
    },
    3 => {
        nb => 'Delvis skyet',
    },
    4 => {
        nb => 'Skyet',
    },
    5 => {
        nb => 'Lette regnbyger',
    },
    6 => {
        nb => 'Lette regnbyger og torden',
    },
    7 => {
        nb => 'Sluddbyger',
    },
    8 => {
        nb => 'Snøbyger',
    },
    9 => {
        nb => 'Regn',
    },
    10 => {
        nb => 'Kraftig regn',
    },
    11 => {
        nb => 'Regn og torden',
    },
    12 => {
        nb => 'Sludd',
    },
    13 => {
        nb => 'Snø',
    },
    14 => {
        nb => 'Snø og torden',
    },
    15 => {
        nb => 'Tåke',
    },
    20 => {
        nb => 'Sluddbyger og torden',
    },
    21 => {
        nb => 'Snøbyger og torden',
    },
    22 => {
        nb => 'Regnbyger og torden',
    },
    23 => {
        nb => 'Sludd og torden',
    },
    24 => {
        nb => 'Yrbyger og torden',
    },
    25 => {
        nb => 'Tordenbyger',
    },
    26 => {
        nb => 'Regnbyger og torden',
    },
    27 => {
        nb => 'Kraftige sluddbyger og torden',
    },
    28 => {
        nb => 'Lette snøbyger og torden',
    },
    29 => {
        nb => 'Kraftige snøbyger og torden',
    },
    30 => {
        nb => 'Yr og torden',
    },
    31 => {
        nb => 'Lette sluddbyger og torden',
    },
    32 => {
        nb => 'Kraftig sludd og torden',
    },
    33 => {
        nb => 'Lett snøfall og torden',
    },
    34 => {
        nb => 'Kraftig snøfall og torden',
    },
    40 => {
        nb => 'Yrbyger',
    },
    41 => {
        nb => 'Regnbyger',
    },
    42 => {
        nb => 'Lette sluddbyger',
    },
    43 => {
        nb => 'Kraftige sluddbyger',
    },
    44 => {
        nb => 'Lette snøbyger',
    },
    45 => {
        nb => 'Kraftige snøbyger',
    },
    46 => {
        nb => 'Yr',
    },
    47 => {
        nb => 'Lett sludd',
    },
    48 => {
        nb => 'Kraftig sludd',
    },
    49 => {
        nb => 'Lett snø',
    },
    50 => {
        nb => 'Kraftig snøfall',
    },

    # Polar night
    101 => {
        nb => 'Sol/klarvær (mørketid)',
    },
    102 => {
        nb => 'Lettskyet (mørketid)',
    },
    103 => {
        nb => 'Delvis skyet (mørketid)',
    },
    105 => {
        nb => 'Regnbyger (mørketid)',
    },
    106 => {
        nb => 'Regnbyger med torden (mørketid)',
    },
    107 => {
        nb => 'Sluddbyger (mørketid)',
    },
    108 => {
        nb => 'Snøbyger (mørketid)',
    },
    120 => {
        nb => 'Sluddbyger med torden (mørketid)',
    },
    121 => {
        nb => 'Snøbyger med torden (mørketid)',
    },
    124 => {
        nb => 'Yrbyger og torden (mørketid)',
    },
    125 => {
        nb => 'Tordenbyger (mørketid)',
    },
    126 => {
        nb => 'Regnbyger og torden (mørketid)',
    },
    127 => {
        nb => 'Kraftige sluddbyger og torden (mørketid)',
    },
    128 => {
        nb => 'Lette snøbyger og torden (mørketid)',
    },
    129 => {
        nb => 'Kraftige snøbyger og torden (mørketid)',
    },
    140 => {
        nb => 'Yrbyger (mørketid)',
    },
    141 => {
        nb => 'Regnbyger (mørketid)',
    },
    142 => {
        nb => 'Lette sluddbyger (mørketid)',
    },
    143 => {
        nb => 'Kraftige sluddbyger (mørketid)',
    },
    144 => {
        nb => 'Lette snøbyger (mørketid)',
    },
    145 => {
        nb => 'Kraftige snøbyger (mørketid)',
    },
};

sub _build_text {
    my $self = shift;

    return $TRANSLATIONS->{ $self->number }->{ $self->lang };
}

__PACKAGE__->meta->make_immutable;

1;
