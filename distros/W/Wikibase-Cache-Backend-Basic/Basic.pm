package Wikibase::Cache::Backend::Basic;

use base qw(Wikibase::Cache::Backend);
use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Text::DSV;

our $VERSION = 0.03;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	$self->_load_data;

	return $self;
}

sub _get {
	my ($self, $type, $key) = @_;

	if (exists $self->{static}->{$key}) {
		if (exists $self->{static}->{$key}->{$type}) {
			return $self->{static}->{$key}->{$type};
		} else {
			return;
		}
	} else {
		return;
	}
}

sub _load_data {
	my $self = shift;

	# Read data.
	my $kramerius_data;
	my $dsv = Text::DSV->new;
	while (my $data = <DATA>) {
		chomp $data;
		my ($qid, $label, $description) = $dsv->parse_line($data);
		$self->{'static'}->{$qid}->{'label'} = $label;
		$self->{'static'}->{$qid}->{'description'} = $description;
	}

	return;
}

sub _save {
	my ($self, $type, $key, $value) = @_;

	err __PACKAGE__." doesn't implement save() method.";
}

1;

__DATA__
# Basic properties
P21:sex or gender:sex or gender identity of human or animal. For human: male, female, non-binary, intersex, transgender female, transgender male, agender. For animal: male organism, female organism. Groups of same gender use subclass of (P279)
P31:instance of:that class of which this subject is a particular example and member
P50:author:main creator(s) of a written work (use on works, not humans); use P2093 when Wikidata item is unknown or does not exist
P98:editor:editor of a compiled work such as a book or a periodical (newspaper or an academic journal)
P106:occupation:occupation of a person; see also "field of work" (Property:P101), "position held" (Property:P39)
P110:illustrator:person drawing the pictures or taking the photographs in a book
P123:publisher:organization or person responsible for publishing books, periodicals, printed music, podcasts, games or software
P179:part of the series:series which contains the subject
P180:depicts:entity visually depicted in an image, literarily described in a work, or otherwise incorporated into an audiovisual or other medium; see also P921, 'main subject'
P212:ISBN-13:identifier for a book (edition), thirteen digit
P214:VIAF ID:identifier for the Virtual International Authority File database [format: up to 22 digits]
P243:OCLC control number:identifier for a unique bibliographic record in OCLC WorldCat
P248:stated in:to be used in the references field to refer to the information document or database in which a claim is made; for qualifiers use P805; for the type of document in which a claim is made use P3865
P279:subclass of:next higher class or type; all instances of these items are instances of those items; this item is a class (subset) of that item. Not to be confused with P31 (instance of)
P291:place of publication:geographical place of publication of the edition (use 1st edition when referring to works)
P393:edition number:number of an edition (first, second, ... as 1, 2, ...) or event
P407:language of work or name:language associated with this creative work (such as books, shows, songs, or websites) or a name (for persons use "native language" (P103) and "languages spoken, written or signed" (P1412))
P577:publication date:date or point in time when a work was first published or released
P655:translator:agent who adapts any kind of written text from one language to another
P691:NKCR AUT ID:identifier in the Czech National Authority Database (National Library of Czech Republic)
P735:given name:first name or another given name of this person; values used with the property should not link disambiguations nor family names
P813:retrieved:date or point in time that information was retrieved from a database or website (for use in online sources)
P957:ISBN-10:former identifier for a book (edition), ten digits. Used for all publications up to 2006 (convertible to ISBN-13 for some online catalogs; useful for old books or fac-similes not reedited since 2007)
P1104:number of pages:number of pages in an edition of a written work; see allowed units constraint for valid values to use for units in conjunction with a number
P1476:title:published name of a work, such as a newspaper article, a literary work, piece of music, a website, or a performance work
P1545:series ordinal:position of an item in its parent series (most frequently a 1-based index), generally to be used as a qualifier (different from "rank" defined as a class, and from "ranking" defined as a property for evaluating a quality).
P1680:subtitle:for works, when the title is followed by a subtitle
P1810:named as:name by which a subject is recorded in a database or mentioned as a contributor of a work
P2679:author of foreword:person who wrote the preface, foreword, or introduction of the book but who isn't an author of the rest of the book
P3184:Czech National Bibliography book ID:identifier for a book at the Czech National Library
P8752:Kramerius of Moravian Library UUID:UUID identifier for scanned item (book edition/periodical/page) in Moravian Library
# Some basic quantities
Q174728:centimetre:unit of length equal to 1/100 of a metre
Q11573:metre:SI unit of length
Q828224:kilometre:unit of length equal to 1,000 meters
Q3710:foot:unit of length
Q174789:millimetre:unit of length 1/1000th of a metre
Q218593:inch:unit of length
Q253276:mile:unit of length
Q200323:decimetre:unit of length
Q844338:hectometre:unit of length equal to 100m
Q848856:decametre:length unit equal to 10 metres
Q355198:pixel:physical point in a raster image
Q178674:nanometre:unit of length
Q7673190:table cell:grouping within a chart table used for storing information or data
Q70280567:Prussian foot:unit of length
# Time precision
Q12138:Gregorian calendar:arithmetic solar calendar system, with a 365-day year, plus one day intercalated into one of the 12 month during some years; internationally the most widely accepted civil calendar
Q1985727:proleptic Gregorian calendar:extension of the Gregorian calendar before its introduction
Q11184:Julian calendar:Calendar introduced by Julius Caesar in 45 BC
Q1985786:proleptic Julian calendar:extension of the regular Julian calendar
