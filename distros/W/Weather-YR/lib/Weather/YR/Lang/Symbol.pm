package Weather::YR::Lang::Symbol;
use utf8;
use Moose;
use namespace::autoclean;

has 'number' => ( isa => 'Int', is => 'rw', required => 1 );
has 'lang'   => ( isa => 'Str', is => 'rw', required => 1 );

has 'text'   => ( isa => 'Str', is => 'ro', lazy_build => 1 );

our $TRANSLATIONS = {
    1 => {
        de => 'Sonnig/Klar',
        en => 'Sun/clear',
        nb => 'Sol/klarvær',
    },
    2 => {
        de => 'Leicht bewölkt',
        en => 'Fair',
        nb => 'Lettskyet',
    },
    3 => {
        de => 'Teilweise bewölkt',
        en => 'Partly cloudy',
        nb => 'Delvis skyet',
    },
    4 => {
        de => 'Bedeckt',
        en => 'Cloudy',
        nb => 'Skyet',
    },
    5 => {
        de => 'Regenschauer',
        en => 'Light rain showers',
        nb => 'Lette regnbyger',
    },
    6 => {
        de => 'Regenschauer und Gewitter',
        en => 'Light rain showers and thunder',
        nb => 'Lette regnbyger og torden',
    },
    7 => {
        de => 'Schneeregenschauer',
        en => 'Snow flurries',
        nb => 'Sluddbyger',
    },
    8 => {
        de => 'Schneeschauer',
        en => 'Snow showers',
        nb => 'Snøbyger',
    },
    9 => {
        de => 'Regen',
        en => 'Rain',
        nb => 'Regn',
    },
    10 => {
        de => 'Starker Regen',
        en => 'Heavy rain',
        nb => 'Kraftig regn',
    },
    11 => {
        de => 'Starker Regen und Gewitter',
        en => 'Rain and thunder',
        nb => 'Regn og torden',
    },
    12 => {
        de => 'Schneeregen',
        en => 'Sleet',
        nb => 'Sludd',
    },
    13 => {
        de => 'Schnee',
        en => 'Snow',
        nb => 'Snø',
    },
    14 => {
        de => 'Schneegewitter',
        en => 'Snow and thunder',
        nb => 'Snø og torden',
    },
    15 => {
        de => 'Nebel',
        en => 'Fog',
        nb => 'Tåke',
    },
    20 => {
        de => 'Schneeregenschauer und Gewitter',
        en => 'Snow flurries and thunder',
        nb => 'Sluddbyger og torden',
    },
    21 => {
        de => 'Schneeschauer und Gewitter',
        en => 'Snow showers and thunder',
        nb => 'Snøbyger og torden',
    },
    22 => {
        de => 'Regen und Gewitter',
        en => 'Rain showers and thunder',
        nb => 'Regnbyger og torden',
    },
    23 => {
        de => 'Schneeregen und Gewitter',
        en => 'Sleet and thunder',
        nb => 'Sludd og torden',
    },
    24 => {
        de => 'Leichte Regenschauer und Gewitter',
        en => 'Drizzle showers and thunder',
        nb => 'Yrbyger og torden',
    },
    25 => {
        de => 'Starke Regenschauer und Gewitter',
        en => 'Thundershowers',
        nb => 'Tordenbyger',
    },
    26 => {
        de => 'Leichte Schneeregenschauer und Gewitter',
        en => 'Rain showers and thunder',
        nb => 'Regnbyger og torden',
    },
    27 => {
        de => 'Starke Schneeregenschauer und Gewitter',
        en => 'Heavy snow and thunder',
        nb => 'Kraftige sluddbyger og torden',
    },
    28 => {
        de => 'Leichte Schneeschauer und Gewitter',
        en => 'Light snow showers and thunder',
        nb => 'Lette snøbyger og torden',
    },
    29 => {
        de => 'Starke Schneeschauer und Gewitter',
        en => 'Heavy snow showers and thunder',
        nb => 'Kraftige snøbyger og torden',
    },
    30 => {
        de => 'Leichter Regen und Gewitter',
        en => 'Light drizzle and thunder',
        nb => 'Yr og torden',
    },
    31 => {
        de => 'Leichter Schneeregen und Gewitter',
        en => 'Light sleep showers and thunder',
        nb => 'Lette sluddbyger og torden',
    },
    32 => {
        de => 'Starker Schneeregen und Gewitter',
        en => 'Heavy sleet and thunder',
        nb => 'Kraftig sludd og torden',
    },
    33 => {
        de => 'Leichter Schneefall und Gewitter',
        en => 'Light snowfall and thunder',
        nb => 'Lett snøfall og torden',
    },
    34 => {
        de => 'Starker Schneefall und Gewitter',
        en => 'Heavy snowfall and thunder',
        nb => 'Kraftig snøfall og torden',
    },
    40 => {
        de => 'Leichte Regenschauer',
        en => 'Light rain showers',
        nb => 'Yrbyger',
    },
    41 => {
        de => 'Starke Regenschauer',
        en => 'Rain showers',
        nb => 'Regnbyger',
    },
    42 => {
        de => 'Leichte Schneeregenschauer',
        en => 'Light sleet showers',
        nb => 'Lette sluddbyger',
    },
    43 => {
        de => 'Starke Schneeregenschauer',
        en => 'Heavy sleet showers',
        nb => 'Kraftige sluddbyger',
    },
    44 => {
        de => 'Leichte Schneeschauer',
        en => 'Light snow showers',
        nb => 'Lette snøbyger',
    },
    45 => {
        de => 'Starke Schneeschauer',
        en => 'Heavy snow showers',
        nb => 'Kraftige snøbyger',
    },
    46 => {
        de => 'Leichter Regen',
        en => 'Drizzle',
        nb => 'Yr',
    },
    47 => {
        de => 'Leichter Schneeregen',
        en => 'Light sleet',
        nb => 'Lett sludd',
    },
    48 => {
        de => 'Starker Schneeregen',
        en => 'Heavy sleet',
        nb => 'Kraftig sludd',
    },
    49 => {
        de => 'Leichter Schneefall',
        en => 'Light snow fall',
        nb => 'Lett snø',
    },
    50 => {
        de => 'Starker Schneefall',
        en => 'Heavy snow fall',
        nb => 'Kraftig snøfall',
    },

    # Polar night
    101 => {
        de => 'Sonnig/Klar (Polarnacht)',
        en => 'Sun/clear (polar night)',
        nb => 'Sol/klarvær (mørketid)',
    },
    102 => {
        en => 'Fair (polar night)',
        nb => 'Lettskyet (mørketid)',
    },
    103 => {
        de => 'Teilweise bewölkt (Polarnacht)',
        en => 'Partly cloudy (polar night)',
        nb => 'Delvis skyet (mørketid)',
    },
    105 => {
        de => 'Regenschauer (Polarnacht)',
        en => 'Rain showers (polar night)',
        nb => 'Regnbyger (mørketid)',
    },
    106 => {
        de => 'Regenschauer und Gewitter (Polarnacht)',
        en => 'Rain showers with thunder (polar night)',
        nb => 'Regnbyger med torden (mørketid)',
    },
    107 => {
        de => 'Schneeregenschauer (Polarnacht)',
        en => 'Snow flurry showers (polar night)',
        nb => 'Sluddbyger (mørketid)',
    },
    108 => {
        de => 'Schneeschauer (Polarnacht)',
        en => 'Snow showers (polar night)',
        nb => 'Snøbyger (mørketid)',
    },
    120 => {
        de => 'Schneeregenschauer und Gewitter (Polarnacht)',
        en => 'Snow flurry showers with thunder (polar night)',
        nb => 'Sluddbyger med torden (mørketid)',
    },
    121 => {
        de => 'Schneeschauer und Gewitter (Polarnacht)',
        en => 'Snow showers with thunder (polar night)',
        nb => 'Snøbyger med torden (mørketid)',
    },
    124 => {
        de => 'Leichte Regenschauer und Gewitter (Polarnacht)',
        en => 'Drizzle and thunder (polar night)',
        nb => 'Yrbyger og torden (mørketid)',
    },
    125 => {
        de => 'Starke Regenschauer und Gewitter (Polarnacht)',
        en => 'Thundershowers (polar night)',
        nb => 'Tordenbyger (mørketid)',
    },
    126 => {
        de => 'Leichte Schneeregenschauer und Gewitter (Polarnacht)',
        en => 'Rain showers and thunder (polar night)',
        nb => 'Regnbyger og torden (mørketid)',
    },
    127 => {
        de => 'Starke Schneeregenschauer und Gewitter (Polarnacht)',
        en => 'Heavy snow sleet with thunder (polar night)',
        nb => 'Kraftige sluddbyger og torden (mørketid)',
    },
    128 => {
        de => 'Leichte Schneeschauer und Gewitter (Polarnacht)',
        en => 'Light snow showers and thunder (polar night)',
        nb => 'Lette snøbyger og torden (mørketid)',
    },
    129 => {
        de => 'Starke Schneeschauer und Gewitter (Polarnacht)',
        en => 'Heavy snow showers and thunder (polar night)',
        nb => 'Kraftige snøbyger og torden (mørketid)',
    },
    140 => {
        de => 'Leichte Regenschauer (Polarnacht)',
        en => 'Drizzle showers and thunder (polar night)',
        nb => 'Yrbyger (mørketid)',
    },
    141 => {
        de => 'Starke Regenschauer (Polarnacht)',
        en => 'Rain showers (polar night)',
        nb => 'Regnbyger (mørketid)',
    },
    142 => {
        de => 'Leichte Schneeregenschauer (Polarnacht)',
        en => 'Light sleet showers (polar night)',
        nb => 'Lette sluddbyger (mørketid)',
    },
    143 => {
        de => 'Starke Schneeregenschauer (Polarnacht)',
        en => 'Heavy sleet showers (polar night)',
        nb => 'Kraftige sluddbyger (mørketid)',
    },
    144 => {
        de => 'Leichte Schneeschauer (Polarnacht)',
        en => 'Light snow showers (polar night)',
        nb => 'Lette snøbyger (mørketid)',
    },
    145 => {
        de => 'Starke Schneeschauer (Polarnacht)',
        en => 'Heavy snow showers (polar night)',
        nb => 'Kraftige snøbyger (mørketid)',
    },
};

sub _build_text {
    my $self = shift;

    return $TRANSLATIONS->{ $self->number }->{ $self->lang };
}

__PACKAGE__->meta->make_immutable;

1;
