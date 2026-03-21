use strict;
use warnings;
use Test::More;
use Date::Language;

# Tue Sep  7 13:02:42 1999 GMT
# wday=2 (Tuesday), mon=8 (September, 0-indexed)
my $time = 936709362;

# Expected values for %A (full day), %a (short day), %B (full month), %b (short month)
# extracted from each language module's @DoW[2], @DoWs[2], @MoY[8], @MoYs[8]
my %expected = (
    Afar                 => { A => "Talaata",                                                              a => "Tal",                                        B => "Waysu",                                                                    b => "Way" },
    Amharic              => { A => "\x{121b}\x{12ad}\x{1230}\x{129e}",                                    a => "\x{121b}\x{12ad}\x{1230}",                   B => "\x{1234}\x{1355}\x{1274}\x{121d}\x{1260}\x{122d}",                        b => "\x{1234}\x{1355}\x{1274}" },
    Arabic               => { A => "\x{627}\x{644}\x{62b}\x{644}\x{627}\x{62b}\x{627}\x{621}",           a => "\x{627}\x{644}\x{62b}",                      B => "\x{633}\x{628}\x{62a}\x{645}\x{628}\x{631}",                              b => "\x{633}\x{628}\x{62a}" },
    Austrian             => { A => "Dienstag",                                                             a => "Di",                                         B => "September",                                                                b => "Sep" },
    Brazilian            => { A => "Ter\x{e7}a",                                                           a => "Ter",                                        B => "Setembro",                                                                 b => "Set" },
    Bulgarian            => { A => "\x{432}\x{442}\x{43e}\x{440}\x{43d}\x{438}\x{43a}",                  a => "\x{432}\x{442}",                             B => "\x{441}\x{435}\x{43f}\x{442}\x{435}\x{43c}\x{432}\x{440}\x{438}",        b => "\x{441}\x{435}\x{43f}" },
    Chinese              => { A => "\x{661f}\x{671f}\x{4e8c}",                                            a => "\x{661f}\x{671f}\x{4e8c}",                  B => "\x{4e5d}\x{6708}",                                                        b => "\x{4e5d}\x{6708}" },
    Chinese_GB           => { A => "\x{d0}\x{c7}\x{c6}\x{da}\x{b6}\x{fe}",                               a => "\x{d0}\x{c7}\x{c6}\x{da}\x{b6}\x{fe}",     B => "\x{be}\x{c5}\x{d4}\x{c2}",                                                b => "\x{be}\x{c5}\x{d4}\x{c2}" },
    Czech                => { A => "\x{fa}ter\x{fd}",                                                     a => "\x{da}t",                                    B => "z\x{e1}\x{f8}\x{ed}",                                                     b => "z\x{e1}\x{f8}\x{ed}" },
    Danish               => { A => "Tirsdag",                                                              a => "Tir",                                        B => "September",                                                                b => "Sep" },
    Dutch                => { A => "dinsdag",                                                              a => "di",                                         B => "september",                                                                b => "sep" },
    English              => { A => "Tuesday",                                                              a => "Tue",                                        B => "September",                                                                b => "Sep" },
    Finnish              => { A => "tiistai",                                                              a => "tiistai",                                    B => "syyskuu",                                                                  b => "syyskuu" },
    French               => { A => "mardi",                                                                a => "mar",                                        B => "septembre",                                                                b => "sep" },
    Gedeo                => { A => "Masano",                                                               a => "Mas",                                        B => "Canissa",                                                                  b => "Can" },
    German               => { A => "Dienstag",                                                             a => "Di",                                         B => "September",                                                                b => "Sep" },
    Greek                => { A => "\x{3a4}\x{3c1}\x{3af}\x{3c4}\x{3b7}",                                a => "\x{3a4}\x{3c1}",                             B => "\x{3a3}\x{3b5}\x{3c0}\x{3c4}\x{3b5}\x{3bc}\x{3c4}\x{3bf}\x{3c5}",       b => "\x{3a3}\x{3b5}\x{3c0}" },
    Hungarian            => { A => "Kedd",                                                                 a => "Ked",                                        B => "Szeptember",                                                               b => "Sze" },
    Icelandic            => { A => "\x{de}ri\x{f0}judagur",                                               a => "\x{de}ri",                                   B => "September",                                                                b => "Sep" },
    Italian              => { A => "Martedi",                                                              a => "Mar",                                        B => "Settembre",                                                                b => "Set" },
    Norwegian            => { A => "Tirsdag",                                                              a => "Tir",                                        B => "September",                                                                b => "Sep" },
    Occitan              => { A => "dimars",                                                               a => "dim",                                        B => "setembre",                                                                 b => "set" },
    Portuguese           => { A => "ter\x{e7}a-feira",                                                    a => "ter",                                        B => "setembro",                                                                 b => "set" },
    Oromo                => { A => "Qibxata",                                                              a => "Qib",                                        B => "Fuulbana",                                                                 b => "Fuu" },
    Romanian             => { A => "marti",                                                                a => "mar",                                        B => "septembrie",                                                               b => "sep" },
    Russian              => { A => "\x{f3}\x{d2}\x{c5}\x{c4}\x{c1}",                                     a => "\x{f3}\x{d2}",                               B => "\x{f3}\x{c5}\x{ce}\x{d4}\x{d1}\x{c2}\x{d2}\x{d1}",                       b => "\x{f3}\x{c5}\x{ce}" },
    Russian_cp1251       => { A => "\x{c2}\x{f2}\x{ee}\x{f0}\x{ed}\x{e8}\x{ea}",                               a => "\x{c2}\x{f2}\x{f0}",                    B => "\x{d1}\x{e5}\x{ed}\x{f2}\x{ff}\x{e1}\x{f0}\x{fc}",                       b => "\x{d1}\x{e5}\x{ed}" },
    Russian_koi8r        => { A => "\x{f7}\x{d4}\x{cf}\x{d2}\x{ce}\x{c9}\x{cb}",                         a => "\x{f7}\x{d4}\x{d2}",                         B => "\x{f3}\x{c5}\x{ce}\x{d4}\x{d1}\x{c2}\x{d2}\x{d8}",                       b => "\x{f3}\x{c5}\x{ce}" },
    Sidama               => { A => "Maakisanyo",                                                           a => "Maa",                                        B => "September",                                                                b => "Sep" },
    Somali               => { A => "Salaaso",                                                              a => "Sal",                                        B => "Bisha Sagaalaad",                                                          b => "Sag" },
    Spanish              => { A => "martes",                                                               a => "mar",                                        B => "septiembre",                                                               b => "sep" },
    Swedish              => { A => "tisdagen",                                                             a => "ti",                                         B => "september",                                                                b => "sep" },
    Tigrinya             => { A => "\x{1230}\x{1209}\x{1235}",                                            a => "\x{1230}\x{1209}\x{1235}",                   B => "\x{1234}\x{1355}\x{1274}\x{121d}\x{1260}\x{122d}",                        b => "\x{1234}\x{1355}\x{1274}" },
    TigrinyaEritrean     => { A => "\x{1230}\x{1209}\x{1235}",                                            a => "\x{1230}\x{1209}\x{1235}",                   B => "\x{1234}\x{1355}\x{1274}\x{121d}\x{1260}\x{122d}",                        b => "\x{1234}\x{1355}\x{1274}" },
    TigrinyaEthiopian    => { A => "\x{1230}\x{1209}\x{1235}",                                            a => "\x{1230}\x{1209}\x{1235}",                   B => "\x{1234}\x{1355}\x{1274}\x{121d}\x{1260}\x{122d}",                        b => "\x{1234}\x{1355}\x{1274}" },
    Turkish              => { A => "Sal\x{131}",                                                           a => "Sal",                                        B => "Eyl\x{fc}l",                                                              b => "Eyl" },
);

for my $lang (sort keys %expected) {
    my $l = Date::Language->new($lang);
    my $e = $expected{$lang};

    # Content checks
    is($l->time2str('%A', $time, 'GMT'), $e->{A}, "$lang: full day name (%A)");
    is($l->time2str('%a', $time, 'GMT'), $e->{a}, "$lang: short day name (%a)");
    is($l->time2str('%B', $time, 'GMT'), $e->{B}, "$lang: full month name (%B)");
    is($l->time2str('%b', $time, 'GMT'), $e->{b}, "$lang: short month name (%b)");

    # Structural checks
    no strict 'refs';
    my $pkg = "Date::Language::$lang";

    is(scalar @{"${pkg}::DoW"},  7,  "$lang: 7 day names");
    is(scalar @{"${pkg}::DoWs"}, 7,  "$lang: 7 short day names");
    is(scalar @{"${pkg}::MoY"},  12, "$lang: 12 month names");
    is(scalar @{"${pkg}::MoYs"}, 12, "$lang: 12 short month names");
    is(scalar @{"${pkg}::AMPM"}, 2,  "$lang: 2 AM/PM entries");
}

done_testing;
