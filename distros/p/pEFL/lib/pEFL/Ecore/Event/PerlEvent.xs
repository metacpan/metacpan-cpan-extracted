#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef struct {
    SV *perl_sv;
} PerlEvent;

typedef PerlEvent EcoreEventPerlEvent;



MODULE = pEFL::Ecore::Event::PerlEvent		PACKAGE = EcoreEventPerlEventPtr

SV *
perl_sv(event)
    EcoreEventPerlEvent *event
CODE:
    //SV* sv = newSVsv(event->perl_sv);
    //RETVAL = sv;
    // Wir geben den Original-SV zurück.Siehe ausführliche Erklärung unten
    // SvREFCNT_inc ist nötig, da Perl den Wert auf den Stack legt.
    // Das XS-Typemap macht den Rückgabewert danach automatisch "mortal".
    RETVAL = SvREFCNT_inc(event->perl_sv);
OUTPUT:
    RETVAL

=pod

Kurze Erklärung, warum wir hier SvREFCNT_inc machen und bei ecore_event_add mit newSVsv eine neue SV erstellen (die Perl SV also kopieren)

1. Bei ecore_event_add_pv (Das Speichern)
Hier ist das Kopieren gut, weil wir die Daten in die "C-Welt" übergeben.

* Das Problem ohne Kopie: Wenn wir in Perl $event = pEFL::Ecore::Event::add_pv($data) aufrufen, ist $data eine normale Perl-Variable. Wenn die Perl-Funktion endet, verlässt $data ihren Gültigkeitsbereich (Scope). Perl denkt: "Niemand braucht diese Variable mehr" und löscht sie aus dem Arbeitsspeicher.
* Die C-Struktur wäre korrupt: pe->perl_sv würde plötzlich auf gelöschten Speicher zeigen (ein sogenannter Dangling Pointer). Beim späteren Auslesen würde das Programm abstürzen.
* Die Lösung: Wir erstellen mit newSVsv eine unabhängige Kopie, die fest an die C-Struktur gebunden ist. Diese Kopie bleibt im Speicher am Leben, völlig egal, was Perl mit der ursprünglichen Variable $data macht.

------------------------------
2. Bei perl_sv (Das Auslesen)
Hier ist das Kopieren schlecht, weil wir die Daten zurück in die "Perl-Welt" geben, um damit zu arbeiten.

* Die Erwartung in Perl: Wenn wir in Perl $data = $s_ev->perl_sv() aufrufen, wollen wir exakt dieselbe Variable in der Hand halten, die im Event gespeichert ist.
* Das Problem mit der Kopie: Wenn wir hier erneut newSVsv nutzen, erstellen wir nur eine neue, anonyme Kopie im Speicher. Perl arbeitet ab jetzt mit dieser Kopie.
* Die Sackgasse: Wenn wir nun in Perl den Inhalt ändern (z. B. ein Element im Array hinzufügen), ändern wir nur die Kopie. Das im Event gespeicherte Original (event->perl_sv) bekommt von dieser Änderung niemals etwas mit. Die Änderung ist verloren, sobald die Zeile vorbei ist.

------------------------------
## Zusammenfassung: Wie man es sich merkt

* Rein in die C-Struktur (add): Kopieren! Damit die C-Struktur ihre eigenen Daten besitzt und Perl sie nicht unterm Hintern weglöschen kann.
* Raus aus der C-Struktur (get): Das Original hergeben (SvREFCNT_inc)! Damit Perl auf den echten, im Event gespeicherten Daten arbeitet und Änderungen auch dort wirksam werden.

=cut