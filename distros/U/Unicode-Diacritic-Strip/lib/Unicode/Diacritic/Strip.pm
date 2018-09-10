package Unicode::Diacritic::Strip;
use warnings;
use strict;
use utf8;
require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/strip_diacritics strip_alphabet fast_strip/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.11';
use Unicode::UCD 'charinfo';
use Encode 'decode_utf8';

sub strip_diacritics
{
    my ($diacritics_text) = @_;
    if ($diacritics_text !~ /[^\x{01}-\x{80}]/) {
        # All the characters in this text are ASCII, and so there are
        # no diacritics.
        return $diacritics_text;
    }
    my @characters = split //, $diacritics_text;
    for my $character (@characters) {
        # Leave non-word characters unaltered.
	if ($character =~ /\W/) {
	    next;
	}
        my $decomposed = decompose ($character);
        if ($character ne $decomposed) {
            $character = $decomposed;
        }
    }
    my $stripped_text = join '', @characters;
    return $stripped_text;
}

sub decompose
{
    my ($character) = @_;
    # Get the Unicode::UCD decomposition.
    my $charinfo = charinfo (ord $character);
    my $decomposition = $charinfo->{decomposition};
    # Give up if there is no decomposition for $character
    if (! $decomposition) {
	return $character;
    }
    # Get the first character of the decomposition
    my @decomposition_chars = split /\s+/, $decomposition;
    $character = chr hex $decomposition_chars[0];
    # A character may have multiple decompositions, so repeat this
    # process until there are none left.
    return decompose ($character);
}

sub strip_alphabet
{
    my ($diacritics_text, %options) = @_;
    my %swaps;
    if (! defined $diacritics_text || length ($diacritics_text) == 0) {
	return ($diacritics_text, {});
    }
    my @characters = split //, $diacritics_text;
    my %alphabet;
    for my $c (@characters) {
	$alphabet{$c} = 1;
    }
    my @c = keys %alphabet;

    for my $character (@c) {
	# Reject non-word characters
	if ($character !~ /\w/) {
	    if ($options{verbose}) {
		print "Not altering non-word character '$character'.\n";
	    }
	    next;
	}
	my $decomposed = decompose ($character, %options);
	if ($character ne $decomposed) {
	    my $boo = "$decomposed baba";
	    $swaps{$character} = $boo;
	    $swaps{$character} =~ s/ baba$//;
	}
    }

    # Make the version of the text with all the diacritics removed.

    my $stripped_text = $diacritics_text;
    for my $k (keys %swaps) {
	if ($options{verbose}) {
	    printf "Swapping $k for $swaps{$k} (%X).\n", ord ($swaps{$k});
	}
	$stripped_text =~ s/$k/$swaps{$k}/g;
    }
    return ($stripped_text, \%swaps);
}

sub fast_strip
{
    my ($word) = @_;
    # Expand ligatures.
    $word =~ s/œ/oe/g;
    # Thorn is "th".
    $word =~ s/Þ|þ/th/g;
    # Remove all diacritics
    $word =~ tr/ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿĀāĂăĄąĆćĈĉĊċČčĎďĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĨĩĪīĬĭĮįİĴĵĶķĹĺĻļĽľŁłŃńŅņŇňŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžƠơƯưǍǎǏǐǑǒǓǔǕǖǗǘǙǚǛǜǞǟǠǡǦǧǨǩǪǫǬǭǰǴǵǸǹǺǻȀȁȂȃȄȅȆȇȈȉȊȋȌȍȎȏȐȑȒȓȔȕȖȗȘșȚțȞȟȦȧȨȩȪȫȬȭȮȯȰȱȲȳøØḀḁḂḃḄḅḆḇḈḉḊḋḌḍḎḏḐḑḒḓḔḕḖḗḘḙḚḛḜḝḞḟḠḡḢḣḤḥḦḧḨḩḪḫḬḭḮḯḰḱḲḳḴḵḶḷḸḹḺḻḼḽḾḿṀṁṂṃṄṅṆṇṈṉṊṋṌṍṎṏṐṑṒṓṔṕṖṗṘṙṚṛṜṝṞṟṠṡṢṣṤṥṦṧṨṩṪṫṬṭṮṯṰṱṲṳṴṵṶṷṸṹṺṻṼṽṾṿẀẁẂẃẄẅẆẇẈẉẊẋẌẍẎẏẐẑẒẓẔẕẖẗẘẙẚẛẜẝẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹ/AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyyAaAaAaCcCcCcCcDdEeEeEeEeEeGgGgGgGgHhIiIiIiIiIJjKkLlLlLlLlNnNnNnOoOoOoRrRrRrSsSsSsSsTtTtUuUuUuUuUuUuWwYyYZzZzZzOoUuAaIiOoUuUuUuUuUuAaAaGgKkOoOojGgNnAaAaAaEeEeIiIiOoOoRrRrUuUuSsTtHhAaEeOoOoOoOoYyoOAaBbBbBbCcDdDdDdDdDdEeEeEeEeEeFfGgHhHhHhHhHhIiIiKkKkKkLlLlLlLlMmMmMmNnNnNnNnOoOoOoOoPpPpRrRrRrRrSsSsSsSsSsTtTtTtTtUuUuUuUuUuVvVvWwWwWwWwWwXxXxYyZzZzZzhtwyafffAaAaAaAaAaAaAaAaAaAaAaAaEeEeEeEeEeEeEeEeIiIiOoOoOoOoOoOoOoOoOoOoOoOoOoUuUuUuUuUuUuUuYyYyYyYy/;
    return $word;
}

1;
