package YAPC::Europe::UGR;

use warnings;
use strict;

use feature qw(say switch);
use experimental qw(smartmatch);

use version;
our $VERSION = qv('0.9.1'); #Release candidate 2, Sunny Sunday 

use Exporter qw(import);
our @EXPORT_OK = qw(pick_best_venue);

sub pick_best_venue {
    my $year = shift // 2015;
    given ($year) {
        when ('2015') { # force string comparison
            return "Granada";
        }
    }
    default {
        # TODO: update this as new proposals come out
        return 'Cluj-Napoca';
    }
}

1;

__END__

=encoding utf8

=head1 NAME

YAPC::Europe::UGR - University of Granada proposal for YAPC::EU 2015

=head1 SYNOPSIS

    use YAPC::Europe::UGR qw(pick_best_venue);

    say "And the winner is... ", pick_best_venue(2015);


=head1 DESCRIPTION

This is the proposal presented for hosting YAPC::Europe 2015, which will be in Granada in 2015. What follows is the final version of the proposal. Feel free to re-use it under the same terms that Perl itself. While we set everything up, this is a hint on what awaits us in YAPC::Europe 2015.

The L<OSL|http://osl.ugr.es> (Oficina de Software Libre, Free Software
Office in Spanish) at the University of Granada with the support of
Madrid.pm and Barcelona.pm presents this bid for YAPC::EU 2015.

=head2 Organizers

We are the  OSL at the University of Granada, led by L<JJ
Merelo|http://search.cpan.org/~jmerelo/>. Under the name of Granada.pm
we have traditionally had a great involvement in the Spanish Perl Community.

We have organized the virtual course L<Perl|http://cevug.ugr.es/perl>
for 14 editions and lately also the course L<Perl Avanzado (Advanced
Perl)|http://cevug.ugr.es/perl_avanzado>, already in its second edition.

We organized the first Perl workshop in Spain L<the Granada Perl
Workshop|http://workshop.granada.pm>, which took place in Granada on
the 27th of June, 2014 and we are involved with the next L<Perl Workshop
in Barcelona|http://workshop.barcelona.pm>.

The OSL is also supported by the two strongest Perl Monger groups in
Spain, L<Madrid.pm|http://madrid.pm.org/> and
L<Barcelona.pm|http://barcelona.pm>, and by several other Spanish Perl
hackers.

The key local persons supporting the proposal are these:

=over 4

=item * JJ Merelo

He has already organized other conferences in the past such as PPSN
2002 and ECAL 1995, in the evolutionary algorithm area and has also
collaborated in the organization of other conferences such as CEC 2011
or L<EvoStar 2014|http://evostar.org> (~150 persons), and many events
such as NotBarraLibreCamp. He collaborated also with the organization
of CIG 2012 (~100 persons), JENUI 2008 (local
conference on Informatics Teaching, ~100 persons).

He has attended several Perl events in the past and made
presentations, including several YAPC::Europe (2002, 2010) and FOSDEM
Perl devrooms (2013, 2014).

=item * Antonio Mora

He was the local organizer for the L<Computational
Intelligence in Games conference|http://geneura.ugr.es/cig2012/> and 
the CoSECiVi 2014.
He is currently a postdoc at the University of Granada.

=item * Pedro Castillo

He is a long-time Perl hacker and instructor.

He is the head of the GeNeura research group who is also collaborating
in the organization of this conference, and has been involved in the 
organization of all CEDI conferences (big Spanish annual CS event), 
several PPSN, EvoStar, IWANN, JENUI2008 and the CIG2012.

=item * Maribel Garcia Arenas

She is assistant professor at the University of Granada, with a PhD in
Computer Science, and has been the organizer of several events, latest
one EvoStar 2014. She is sporadic Perl user, but makes up for that
with her organizational flair. 

=back

Other local organizations and groups of people supporting the event
are as follows:

=over 4

=item * OSL volunteers

Volunteers and other people attached to the
L<OSL|http://osl.ugr.es/about/quienes-somos/>.

=item * IT Delegation of the University of Granada

Additional help from the
L<IT delegation of the University of Granada|http://detic.ugr.es>
and L<Computer Science School|http://etsiit.ugr.es>.

=back

Other people not from Granada collaborating with the organization of
the event are Alex Muntada, Salvador FandiE<ntilde>o, Diego
Kuperman and other members of the local Perl Mongers groups.

=head3 Contact

For the time being, the contact email for any matter related to this
proposal is L<mailto:dirosl@ugr.es> (OSL direction address).

In case we win the bid, we will setup a new address @ugr.es specifically for
supporting the event.

=head2 Venue

We will hold it at the most convenient place at the L<University of
Granada|http://www.ugr.es>, with campus all over the city of Granada
(Spain). Granada includes such beauties as the Alhambra, the Albayzin
neighborhood, natural park of Sierra Nevada and some of the most
beautiful graffiti in the country. Moreover, the beach is just 70
kilometers (35 minutes by highway) away from the city.

We have pre-acceptance for holding it at the L<Facultad de
Ciencias|http://fciencias.ugr.es> and L<ETSIIT|http://etsiit.ugr.es>
(Computer Science School), which is in the outskirts of the city but
has all the facilities needed for a multi-room conference and is,
anyway, well communicated with the rest of the city.  We will buy enough extension cords for conference users;
being a university building, it is well prepared for lots of people
using electricity. All university buildings fulfill EC rules regarding
accessibility, including access via wheelchairs or magnetic loops
systems for people with hearing difficulties. No wired connectivity is
previewed, in principle, but if needed a meeting room with access to
the university network will be arranged.

The IT services at the University of Granada provides an easy way to
set up WiFi guest access. EduRoam is also
available for those coming from an academic environment and it works
without a glitch. The network is able to support up to 5k devices
concurrently. If absolutely necessary, we can supply some physical
Ethernet connections, which will have to be shared by all the
attendees.

We will provide backups for audiovisual equipment just in case it
breaks down in the middle of the talk. Any of the university campuses
has fixed projectors, as well as a few portable ones that can be used
if needed.

Regardless of the university campus we choose, we will set up a
couple of additional rooms for organizational purposes, storage,
short meetings, BOFs and anything else that is needed.

We will use volunteers with good English skills (taken from our
student pool) to staff a help desk during the whole conference. We
have already done that successfully at previous events. If they are
from outside Granada, we will also pay (bus) trip and (student)
lodging, as well as registration. These students will be used as
technical support for all rooms, as well as countdown service.

All rooms that we will use in the conference are provided with air
conditioning; these are usually in the ground floor of the university
building. In some cases, and since classes are usually off during
summer, other rooms are not provided with it. However, we will not
need to use them for attendance below 1000 persons. 

=head3 Conference rooms

All rooms are equipped with public-address system, computer and FullHD
projectors. MAC and HDMI adapters will be available from the
organization upon request.

The biggest rooms are auditorium-style, with tiered seats. For talks
with smaller audiences, we will use regular class-rooms which can
hold up to fifty persons comfortably and are flat.

We will have almost no restrictions on the usage of the university
spaces as in August there is little, or none at all, academic
activity.

This means that we can easily run five parallel tracks. However, in
principle there are around 75 talk slots, 25 per day, which can be fit
easily into three or four tracks. 

=head3 Alternatives

As our request to use university buildings for the conference has
already been accepted by the University board, it is very unlikely
that we could need to move the event to a different venue.

In any case, these are the alternatives:

The University of Granada has at least L<three other
campuses|http://www.ugr.es/pages/centros> inside the city which could
fit conferences with up to five hundred attendees, including
the Facultad de Letras (Humanities) whose main hall has capacity for
five hundred and sixty persons.

If the conference blows up to epic proportions, we could move the
event to Granada Conference Center which can cope with attendances on
the thousands. The costs for this are non linear and have been
inserted in the tentative budget. 

=head3 Facilities at the UGR

Our first choice for a expected attendance of around 400 persons would be the Aula Magna at the L<Sciences
Faculty|http://fciencias.ugr.es> which has been recently renovated and
includes can hold up to 506 seats. This campus is right next to the
second one and also practically in the city center. It has many
classrooms with capacity from 60 to 150. These two places actually
have a tram stop nearby. That the tram will be actually passing by it
next year is a riddle. It might, having been under construction for 9
years and all, but then it might not. 

For up to 250 conference goers, Our preferred venue is the
L<ETSIIT|http://etsiit.ugr.es/pages/instalaciones_servicios/salas_aulas>,
whose biggest room can fit 196 people, with room for a few more in the
sidelines or standing up. If attendance is not more than 250 people,
we would go for this venue, since there is also a OSL storage room,
the offices of most organizers, and it is the obvious choice, being
the Computer Science School and all. There are air-conditioned
classrooms with capacity for 100 persons, and other rooms with 78 seats, 8 of each
+ 3 more classrooms, also air conditioned, with a capacity of 60 PAX. The
cafeteria can sit up to 120 people (but we would do the tapas crawl
for lunch, something we successfully did during EvoStar). This place
is conveniently linked by public transport to the city center, and not
far away from a tram stop.

As you see, the main factor for choosing venue is the number of
simultaneous people it can hold at the same time. Since this will
depend on the attendance of the current YAPC as well as how many
people we are going to attract, we cannot commit ourselves to one of
them right now and we keep our options open; if chosen, we will make a pre-reservation of spaces in both and will discard the one that is finally not used. At any rate, any "big
room" mentioned before is inside the university building with the rest
of the rooms used close by, in the same building a few meters away. Toilettes are not far away either.

=head3 Catering

In previous events (EvoStar 2014) we have organized a Tapas
Experience for lunch and our intention is to organize it again this
time. There are several reasons for this, the main being that it is difficult to serve 400 people from a central location and simultaneously. It is a load-distribution algorithm, but also a way of sharing with the local community. It provides more choice for attendees and also more opportunities for networking.

We will provide every attendee with several "tapa" vouchers that they
can exchange in the pubs and bars around the venue (5 minutes away,
top) at their discretion in order to have lunch, dinners or well, anything at
any time they feel hungry.

A "Tapa" are a small dish usually served accompanied by a drink (it is actually the other way round, but you get the drift). Every
bar has its own specialties and style and as a whole they provide
great variety (including vegetarian and vegan). Granada's tapas are quite remarkable. They form part of
the essence of the essence and are at the center of its social life. You can have conference lunch anywhere, but nowhere but in Granada you can have a Conference Tapas Crawl. 

This is also a good way to increase networking, since you can have
a "tapa" in some bar, then go to another one where you can meet a
different set of people. The experience in EvoStar 2014 was very
positive in terms of quality and satisfaction. Not so much so for the speakers in the first session in the afternoon, but those never get the best deal anyway. 

We would ensure that we have enough bars to cope with the attendance
and that they all have offerings covering special needs, specifically
vegan dishes.

As an alternative to the "Tapas crawl" we can use the canteen located
on any of the two university buildings, supplemented with additional
space to fit all the attendees (probably in the hall or another
university canteen nearby).  In that case a buffet style lunch would
be served. Anyway, the university canteen will be included in the
tapas crawl for those people that do not want or cannot move from the
building. 

The conference dinner will take place in the city of Granada, with
enough supply of banqueting places for any kind of events. The Abba
hotel itself has enough space for several hundreds, but there are at
least 5 salons in the city of Granada that can hold up to 500 persons. 

=head3 Getting here

L<Granada is linked to Madrid, London and
Barcelona|http://www.skyscanner.es/vuelos-a/grx/companias-aereas-que-vuelan-a-granada-aeropuerto.html>
by regular daily and frequent flights and also to Mallorca and to
other places (but flight frequencies vary often and are sometimes
seasonal). L<ME<aacute>laga is roughly one hour away by car or 2 hours
by bus and is linked to all major European
cities|http://en.wikipedia.org/wiki/M%C3%A1laga_Airport#Airlines_and_destinations>
(and many minor, as long as they have enough sun-and-party-hungry
punters). There are also buses and trains to Madrid and Seville, but
coach is always the best option outside the plane.

The ETSIIT is linked to the city center (with many lodging options) by
three bus lines. Depending on the date, student residences might
also be available (July is the best date for that, since usual guests
will be on holiday; some might be available in September, and none in August). 

It is also possible, but not likely, that Granada
tram system will be working by August 2015. There is a station
close to the ETSIIT that would link it in minutes to the railway
station and other points of interest in the city, including hotel
areas.

=head2 Conference Details

It is going to be, AFAIK, the YAPC::EU southernmost conference, so this
fact will have to be taken into account in the details of the
conference.

=head3 Dates

Due to budgetary reasons, the university is locked during most of August; best date for YAPC, if that is workable for everybody, would be early September. However, if it is a requirement that it takes place in August, our chosen dates would be the last week of August. 

=head3 Theme

We propose I<The Art of Perl> as the conference theme.

We believe that coding is a mix between craft and Art.

As hackers, just solving problems is not enough for us. We also need
to do it in elegant and beautiful ways!

When we are programming we create Art!

When using code, when reading code, we enjoy it, and joy is the basis for art!

And Perl, because of its expressiveness, concision, flexibility,
stickiness (or rather glue-ness) and power, is one of the best languages for doing
it!

Because Perl bends around your mind and not the other way around!

On this conference we want to proclaim that programming in Perl is an
Art!

Also, there has been people using Perl for more traditional forms of
art such as Poetry for as far as our memory (Google) can reach.  There
would also be a place for that kind of art at the conference. Also procedural content generation, interactive art, writing novels using Perl (hey, people do that all the time) and so on. 

=head2 Website

In order to reuse the database from previous conferences, we will use
the Act! toolkit for the conference web. We have used it successfully for out Granada Perl Workshop and are starting to use it for the Barcelona Perl Workshop. 

=head2 Amusements

We will consider having for early birds a perl golf contest or a Perl
quiz; for those staying late we could also consider that. It is also
an option to consider during cocktail parties the first day. Any
suggestion will also be welcome.

=head2 Promotion

The OSL maintains a presence in social networks (identi.ca, Twitter,
Facebook), and the people in the organization do have that too.
We would use email, local free software events (there is a Free Software in Administration conference planned for October, small framework and OS-focused events during all the year), FOSDEM devrooms, and a sandwich man walking around
inconspicuously around PHP and Python developer conferences.

=head2 Survey

We are developing an app for creating a personal schedule, and as in
past conferences, we will use whatever people have scheduled
for creating a preference. Which will be probably for those
dressed as Star Trek fleet ensigns or anything that is not
simultaneous to talks by Damian, brian or Mark. This app will be connected to the services available in Act.

=head2 Additional Program

Granada offers a great amount of options for people from 2 to
22. Sorry, to 222. We will organize a tapas crawl in the
best watering holes of Granada, artistic trips through the
graffiti art in Granada streets. And, yes, also Alhambra
and all those things. We will also organize courses for those
interested and beginning courses in Spanish.

=head3 Courses and tutorials

No innovation here. We will provide space during or preferably before
the conference so that people that want to give tutorial or
courses can pay trip expenses giving them. The organization
will only collect a racket, sorry, a cut for, you know,
protection.

For a boost of visibility (or outing) of the Spanish Perl community,
we will also offer courses in several levels in Spanish. Any
other languages can also be arranged, specially English

=head3 Side Trips

Any side trip within a reasonable distance of Granada can be arranged; we will
contact a travel agency so that they can offer packages for a good
price. But the usual thing is:

=over 4

=item *

Alhambra and Generalife.

=item *

Sunset in front of the Alhambra, through the world heritage quarter
called Generalife.

=item *

Renaissance in Granada: cathedral and other churches and palaces.

=item *

Tapas crawl including fried fish, meat and everything you can include
in a little dish.

=item *

In previous conferences, JJ Merelo has organized a L<tour of graffiti
in
Granada|https://medium.com/@jjmerelo/graffiti-in-granada-6a79d3cff72d>. He
will be happy to offer it again, just for the conference attendees and
buddies. 

=back

=head2 Budget

Now we are talking business. We have tried to stick to the same registration costs as the
last conference. Part of the venue is low cost, since it is organized as an
institutional (meaning university, as belonging to the
University of Granada) event. The University of Granada covers insurance costs too.
This will leave us some
leeway to give a better attendees dinner.

We are talking of a ballpark of 30K E<euro> for the regular and expected scenario. We will also apply to local
science funding agencies and the university to defray part of the
cost. The Free Software Office will absorb any deficit if there is one. 
Since funding agencies pay the grant after
expenses have been incurred, in some cases years later, temporary
deficit will have to be absorbed by the OSL and any
surplus that is obtained after the conference also will go to the Free
Software Office operating costs and a  local L<Free Software
Prize|http://concursosoftwarelibre.org> to fund a special Perl-based
application prize. Any surplus obtained from
registration fees and sponsors will be returned to the YAPC::Europe
Foundation. The full budget is published in L<a Google Drive
document|http://goo.gl/yVhPJK>. 

=head3 Income

Main income will be levied on attendees. Planned attendance fees are
in the same ballpark as previous events:

=over 4

=item Guests, Speakers, Organizers: 0E<euro>

=item Full-time students: 70E<euro>

=item Early-bird: 90E<euro>

=item Regular price: 120E<euro>

=item Corporate tariff: 240E<euro>

=back

Final fees have to be announced.  We will request any amount from
sponsors, and past events have gathered around 6000E<euro> exclusively from local
sponsors. A minimum of 1000E<euro> can be expected from those sources.

=head3 Costs

There are several costs per attendee. Please check the
L<budget|http://goo.gl/yVhPJK> for values and different scenarios, including
must have and nice-to-have items and scenarios. 

This is around 75E<euro> per attendee, fully covered by early-bird fee
and with a deficit for speakers and students.  This will be balanced
with the surplus provided by late arrivals, corporate fees and
sponsors.

The budget will be adjusted mainly by changing the number of lunches
and coffee breaks, but also taking into account the other nice-to-have
features. 

The L<spreadsheet|http://goo.gl/yVhPJK> provides different scenarios
with associated costs. In any case we have room for cutting some corners and if
we run into a deficit it will be covered by asking for support from
the local official organism. 

 
=head2 Sponsors

Granada is being pushed as a technological city by consortiums such as
L<On Granada Tech City|http://www.ongranada.com/>
which is supported by major technological companies and
local institutions.

We have contact with local tech companies will will be willing to help
with small amounts; we will have no minimum requirement for
sponsorship. Companies such as L<Codeko.com|http://codeko.com> or
L<Blulabs|http://blulabs.es> have supported OSL events in the past. We
will mainly look for direct support of tchotchkes such as t-shirts or
bags. Other companies contacted after the initial proposal such as
L<ElasticSearch|http://elasticsearch.com>, Qindel Group, Capside and
the local technology transfer office have answered positively to our support
requests. These offers have been included in the current version of
the budget.

Support will also be requested from institutions of all kinds. Being
the economy of Spain in the shape that it is, we don't
expect much from that, but we will do it anyways and have
obtained support in the past.

=head2 About Granada

Granada is a student city which has been the L<preferred destination of
Erasmus students
|http://elpais.com/elpais/2012/11/28/inenglish/1354114165_335994.html>
for a long time, and that accounts for something. 
It's a lively city with many services for visitors.

=head3 Getting here

Granada has an international airport, but easiest way to reach it is
to connect at Madrid or Barcelona. From July 2013, there is a L<five
times a week direct British Airways flight to London
City|http://www.britishairways.com/travel/fx/public/en_gb?to=Granada&fromPkg=LCY>,
which can be also used as a hub to reach us, although it is not the
cheapest or even the fastest way to get here (maybe cheaper if used as
a connection).

Some price for return tickets to Granada; these are for next September
2014, and of course might vary for  September 2015. You would have to
add 3L<euro> bus
ticket|http://www.aena-aeropuertos.es/csee/Satellite/Aeropuerto-Federico-Garcia-Lorca-Granada-Jaen/es/Page/1237554498674//Transporte-publico.html>
or around 30L<euro> for a taxi ride. These are prices obtained using
LastMinute.com, and to Granada itself. Going to Malaga would add
around two hours and around 15E<euro> bus fare. 

=over 4

=item London: lowest 226E<euro>, average around 275E<euro>. To Malaga: 128E<euro>.

=item Paris: lowest 206E<euro>, average around 300E<euro>. To Malaga: 137E<euro>.

=item Rome: lowest 226E<euro>, average around 260E<euro>. To Malaga:
more or less the same. 

=item Frankfurt: lowest 282E<euro>, average around 350E<euro>. To
Malaga: 184E<euro>.

=item Vienna: lowest 306E<euro>, average around 400E<euro>. To Malaga:
lowest 169E<euro>.

=back

Most flights are in the 200-400E<euro> range. After the MH17 incident,
flights to Moscow have shot up to the stratosphere, so I have
eliminated them. Flying to Malaga usually saves you some money,
between 50 and 100E<euro> but in some cases it would add time to the
trip (in most cases not, since it will be a direct flight).

There are many more options to Malaga, which is a big airport, 
including low-cost flights, but then you have to take a bus or 
train to the bus station and another bus (two hours) from there. 

The local bus company provides also a direct bus to Granada 
from Madrid airport, with two frequencies a day and a low price. 
Check out the L<ALSA|http://alsa.es> site for timetable.

Some sample prices and itineraries:

=over 4

=item Malaga Airport - Granada: 1h30m, 10E<euro>, 4 buses a day.

=item Malaga Bus Station-Granada, every hour on the hour 
(roughly, some exceptions) until
21:30. There are buses and trains from the airport to the bus station.

=item Madrid (Estacion Sur) - Granada: 5h (ALSA), 
several buses a day, roughly every hour; normal 5h and 17.53 
E<euro>, supra economy 4.5h and 26.81E<euro> and supra+ (with WiFi)
4.5h and 35-87E<euro> (only two of these 13:30, 19:30).

=item Seville-Granada and back, 41E<euro>, 3h15m. 

=back

Train trips:

=over 4

=item Madrid - Granada:  4.5h, 62E<euro>

=item Barcelona - Granada: 12h, 56E<euro>, really a long trip 
in wagon-lit, but an inexpensive option. Barcelona has rail links to
major European cities. 

=item Seville - Granada: 3h, 22E<euro>

=back 

There are L<buses also from Granada airport to the city
center|http://www.autocaresjosegonzalez.com/index.php/es/servicios.html>,
costing 3E<euro>; taxis are roughly 10 times more expensive.  We can
organize taxi pools if needed.


=head3 Sightseeing

Granada includes the Alhambra and Albayzin, an ensemble that has been
declared world heritage site by the UNESCO. That is only part of its
patrimony, that includes also Renaissance palaces, Gothic, Renaissance
and Baroque churches, and a rather unknown but no less beautiful set
of modernist buildings. 

Organized or self-organized options for tourism are available all year
round.  The beach is 70 kms and a bus run away. There are also many
opportunities for trekking up in Sierra Nevada or in the
Alpujarras. Granada is a prime touristic destination and it shows. 

=head2 Summary

The bid from the Free Software Office at the University of Granada is
organized by a group of persons with experience in organizing events
including the Granada Perl Workshop in June 2014, some experience
attending YAPC::Europe events (including, possibly, this next Sofia
YAPC::Europe), will take place in an incredibly nice city, easily
accessible by plane, in a venue (the University of Granada) with all
needed facilities and with support from local university government,
local free software SMEs and enthusiastic Perl Mongers which, so far,
have not seen a single YAPC::Europe in Spain.

=head2 Questions and Answers

While we have not been asked these questions by the organization, they
were made to other proposers, so here are the questions that have not
been answered before and some that were asked in the previous
incarnation of the proposal. 

=over

=item B<What's the price of beer?>

In the bars around the ETSIIT, Facultad de Ciencias  and in town,
average price this year (2014) is a bit over 2E<euro> and that
includes the tapa, that is, a small dish with usually warm
food. That's the price of a tubo (1/3 liter). It's not usual in Spain
to have bigger portions; you just order a second one.

=item B<What's the weather like in August, September?>

It's definitely hot, with maximum that can go up to 40 degrees; it
goes down in September, but daily maximum are always over 30E<deg>.
September is milder, which is another reason why we intend to use it.

=item B<Can people get receipts?>

Whether we choose a professional services company to organize
registration or the university itself, there is no problem with
providing receipts. We will see what is the more convenient option in
terms of work needed, but also financially; the University can provide
VAT-free registration while the external company can not.

=item B<How easy is it for people to navigate the city without speaking
Spanish?>

If you have a good map and can orient yourself, it is pretty easy. In
pure geographical terms, Granada is not a difficult place; on the
other hand, the Spanish educational system has made sure that very
few, if any, speak other than the mother tongue. However, they will
speak loudly and kindly to you until they make themselves understood.

=item B<It would be nice to have more details on accommodation, with a
range of the prices that can be expected for different levels of
accommodation. Can most attendees fit in one hotel? Is Internet access
widely available in accommodations?>

I<This is taken almost verbatim from L<CIG 2012
site|http://geneura.ugr.es/cig2012/acommodation.html>, which Antonio
Mora organized too.> Prices should not have varied too much, although
they will post new prices starting September 2014. 

Granada is a city accustomed to a large touristic inflow, so its
offers a huge number of accommodation options for all budgets. In
addition, due to the number of students living in the city (more than
60000 during the year), there are a big amount of visitors in these
ages, so there are several economical lodgings.  So the city provides
dozens of hotels ranging from 5-star to 1-star ones. It must be noted
that hotels in Spain (and maybe more in Granada) are usually well
priced due to the competition among them. Thus, a 4-star hotel may
often be in the 75-100E<euro> range and a 3-star hotel in the 50-75
E<euro> range.  Of course, some fluctuations can happen depending on
the particular hotel and the zone where it is, but special packages
are also possible, allowing more economic prices.

As far as we know, there are no big events announced for dates (late
August or early September 2015). It is low season anyways and there
are thousands of rooms just in 4-5 star hotels, so no booking crunch
is previewed. 

=over

=item Recommended hotels (approximate prices)

=over

=item AC Palacio de Santa Paula - 5* (130E<euro> by night)

The best hotel in the city. Located at the main street (Gran
VE<iacute>a) in the city centre. Well communicated to reach the
ETSIIT.

=item Abba - 4* (75E<euro> by night)

New hotel (less than 3 years old), close to the train station and near
the city centre. Well placed to get to the ETSIIT (Avda
ConstituciE<oacute>n). Usually has good offers for University events,
including free WiFi and access to the spa, which we would arrange.

=item Vincci - 4* (80E<euro> by night)

Well-considered hotel in the city, close to the train station and near
the city centre. Well placed to get to the ETSIIT (Avda
ConstituciE<oacute>n).

=item Granada Center - 4* (65E<euro> by night)

Good hotel, not very expensive and close to a good tapas area (Severo
Ochoa street, in front of the Faculty of Sciences).

=item Carmen - 4* (55E<euro> by night)

Cheap hotel, but with good quality. It is near to the city centre.

=item Macia Gran Via - 3* (50E<euro> by night)

In the main street and quite cheap.

=item Puerta de las Granadas - 3* (70E<euro> by night)

Just below the Alhambra. Smack in the middle of the  tourist area. Only 14 rooms.

=item Juan Miguel - 3* (45E<euro> by night)

Cheap hotel in the city centre, close to the city hall.

=back

=item Student accommodation

As you can check, the prices are quite cheap even in four star hotels,
but there are a L<huge amount of guest houses (Pensiones in Spanish)
in the
city|http://geneura.ugr.es/cig2012/brochures/guest_houses_granada.pdf>. Or
if you prefer, there is also a Youth hostel (Albergue in
Spanish). During July, student dorms might offer also cheap
accommodation; in September it is less likely. There are also two
university residences, which are very nice, but not so conveniently
located for accessing the ETSIIT (or other university venue we might
choose. However, they might be used for invited speakers, mainly if we
manage to pay them from university budget.

=back

=item B<Are there any plans to stream or record talks? If so, how will the recordings be made and
how will authorization be sought?>

The assets are there, and it would be possible to record at least one
of the tracks. That would be free for the conference, since the OSL is
part of the IT dept of the university which includes the virtual
department too. The ETSIIT includes also self-recording facilities in
some classes, which we could use for some tracks (but this is not
available in our preferred venue, Facultad de Ciencias). However, this is
additional work and/or cost, so except for keynotes no plans to do any
recording have been made.

=item B<Are any social events planned, other than the partner's program?>

We plan to do a pre-conference drink-up and post-conference
excursions. If sponsorship allows, we will organize a speakers' dinner
the first conference day.

=item B<Do you have any plans for an associated hackathon?>

In the OSL we organize hackathons to the tune of several every
year. We would love to organize one and try and attract local talent
to Perl. Our experience says that it is better to organize them with at
least one day and a half, which we would prefer to do before the
conference. The venue could change, since we have contact with local
coworking spaces that would provide the site and the connectivity, as
well as in some cases free drinks and coffee. They can even be used
overnight if needed.

We will make a call for proposals so that CPAN authors can submit their
modules for enhancements or bug quashing. We will contact authors of
major Perl projects such as perl5i or parrot in case they are
interested. This will be held either in the same place or, depending
on the number of people, in smaller venues such as the L<Free Software
Office|http://osl.ugr.es>, which is in a building with rooms varying
in capability from 12 to 40 persons.

=item B<Do you plan to provide anything to speakers? (Such as water, a person to time things and
keep the schedule on track, etc)>

We will have volunteers (students, GeNeura or OSL people) in every
room to fix any problem that can arise, from lack of electrical
outlets to swooning fans. Water will be provided for speakers, and
they will be heartily patted in the back after they finish. The
volunteer will also take care of time overruns by dancing a Spanish
jitterbug when the speaker has spent the allotted slot.

=item B<How many days do you expect the event to run, and what days of the week are you
considering?>

Wednesday until Friday, with Monday and Tuesday reserved for
hackaton. Weekend for social events.

=item B<Did you already approach to any potential sponsors?>

We have approached the sponsors included in the new budget. Some of
them have already expressed their will to support with an amount, some
of them just their will. 

=item B<How many meals a day are you going to provide?>

One meal, one coffee break, but as shown in the budget section, meals
and coffees will be reserved only when budget is secured for them.

=item B<Will catering be organized inside the venue or outside?>

Coffees, if eventually provided, will be inside. Lunch and dinner
outside. 

=item B<What is the deadline for early bird registrations?>

The usual four months before the conference.

=item B<How many attendees do you expect?>

As many as the other venues bidding for YAPC::EU. And then a few more. 

No, really. Granada is an attractive, history-laden city. In previous
conferences we have organized, some attendees have mentioned the fact
that they submitted papers to it because of the city. So attendance of
around 400 people ("Expected" column in the budget) would be
reasonable. But we have planned for any other scenario, including
"Student invasion" (remember Granada is #1 Erasmus
destination in Europe).

=item B<Can you roughly estimate the portion of speakers (you mention 75 of
them), early bird registrations, students, regular and business
attendees?>

Please check the budget with the different scenarios outlined. 

=item B<In case you have no money for lunches, will it be possible for
everybody to find food on their own in a reasonable time (90 minutes for
outside lunches seems to be the optimum)? You mentioned a few cafes
outside but are they capable to serve 300 people at the same time?>

Glad you ask that question, because whatever the place in the
University of Granada we celebrate YAPC, there are literally dozens of
places where you can have a quick snack, sandwiches or even a sit-down
proper lunch for old geezers. Even at the
L<ETSIIT|http://etsiit.ugr.es> there is a cafeteria and university
lunchroom, with the Fine Arts School cafeteria nearby and a
supermarket where you can buy salads or sandwiches and several bars
one block away, each one being able to hold from 20 to 60 persons. 

=item B<How many local attendees might appear at the conference?>

The usual Spanish crowd at the YAPCs amounts to around one dozen
people. There are two strong Perl Monger groups in Spain whose attendance
would be boosted. To help attendance by local students we would apply
for course credits to the university, so that they can get ECTS credits for
attending and/or volunteering at the conference. All in all, 50 is a
reasonable number. 


=back


=head2 NAQ (newly asked questions)

These questions have been asked by the committee after the submission

=over 

=item B<You write:
"We will have almost no restrictions on the usage of the university
spaces as in August there is little, or none at all, academic activity."
But further down below you say:
"best date for YAPC ... would be early September".
In case the dates of the conference are in September, will it
dramatically influence the availability of conference rooms, Wi-Fi
capacity and bar availability?>

Not really. Peek capacity of university buildings is fulfilled at class time, not during examinations, which usually have only one by degree per day or every other day. Ciencias hosts many degrees, but even so capacity will be 90% or more free at any particular day. So even if there are examinations taking place at that time, there will be plenty of room available. Of course, if booked in advance, which we will, we will be able to use prime real estate.

=item B<How far exactly is The Computer Science School from the city centre
and what public transport is available?>

It is not at walking distance, around 10 minutes by taxi, and your mileage by public transport might vary, but not too much. There are three bus lines that stop close to it, two of them linked to the high-capacity bus line that goes through the city center every 2-3 minutes. However, in this bid it is only our fallback option in case attendance hovers around 250 or less (which probably will not happen).

=item B<It looks like the attendees will be disappointed to find out that
Wi-Fi in the venue does not allow SSH connection (or allow it for a
limited number of connections). Is there a chance to change this?>

In fact we recently discovered that guest accounts do have access to a
reasonable amount of ports. We have changed the proposal to reflect
this. 


=item B<You say that if there will be less than 250 attendees, you might
choose a different venue? It sounds impossible to implement, as you
only will be able to know the exact (still, a bit vague) number a few
days before the conference, when you cannot change the venue. Even if
you pre-order more than one venue, attendees must know the address
well in advance so that they can book their hotels.>

We will have a first approximation after the conference in Sofia, which will be our guide. At any rate, we will reserve the biggest one and should see the others only as fallback options, much cheaper, in case those target is not met. 

Hotels will be pretty much the same ones in any case. The two first options are back to back, the third are a bit further away, but there are no hotels that cater to it specifically. In fact, the "official" hotel we have proposed is almost as far from one as from the other. 

=item B<How much time are you going to reserve for the lunch breaks? Will 60
minutes be enough or you need 90? 300+ people is a big crowd and even
if it is distributed between a few pubs, it is difficult to serve all
of them fast enough.>

The usual 2 hours in Spain. Our experience, however, tells us that it is no too difficult even in 90 minutes, but we will leave 2 hours, which is usual even if we have a buffet or a sit-down lunch. 


=item B<How difficult is serving lunches inside the venues and why you
consider it an alternative option, not the main one?>

Serving lunches in the venue should have to be buffet style, since
there is not sitting space in the cafeteria. A zone of the main hall
would have to be cordoned off to serve food and food would have to be
brought by a catering service from outside. This would all add to the
cost (since we would have to pay for the space, food and service) and
we would have international buffet-style food instead of the
quintessential tapas experience.  Not a big deal doing it if
absolutely required, only the budget would have to be up a bit. 


=item B<The conference theme you choose, "The Art of Perl", was already the
theme of the YAPC::Europe in 2000.>

Do you mean that the art of Perl was over in 2000? We do like the topic, and if possible, we would like to keep it. Maybe changing it a bit to "Art as engineering, engineering as art", or much better, Art ~~ Engineering.

=item B<Air tickets in the proposal are dated as "September 2013". Is it a
typo or the prices are outdated?>

Prices haven't changed much, except for Moscow, which is to all
effects unreachable (but the situation might change next year). I have
updated prices and also added estimation of prices to Malaga, which
are in most cases lower (except for Rome, for reasons we cannot fathom).

=item B<Can you give a rough estimation of the total door-to-door travel time
from a couple of European capitals outside Spain, including air and
land segments, waiting time for connections and time to get from the
airport to the train station, for example?>

No. Because we would have to ask the local taxi/Uber/blablacardrivers how much would we have to pay from the door of some individual person in some place, and European Union regulations forbid that.

However, we will provide an estimation of airport-to-hotel in Granada cost. 

=item B<Will you be able to provide a laptop for the speaker if he has none
(rare but still possible case)?>

Sure. Any of the places pre-selected have computers or laptops in every room, and the free software office always has 2-3 (recycled) laptops which we use for this kind of events. 

=item B<When are you planning to start and finish the conference day?>

In Spain times are usually 9 to 18-19, with around 2 hours in the middle for lunch and siesta. In principle, we will try to fit it to 9 to 18, but we will leave options open for light activity after 18 hours.

=item B<In case of failure, will you submit your proposal next year?>

Third is the charm, or so it's said. But, wait, is that a trick question?

=back

=cut


