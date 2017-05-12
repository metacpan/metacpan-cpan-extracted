#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long qw( :config no_ignore_case );
use Text::Autoformat qw( form );
use WWW::Marvel::Client;
use WWW::Marvel::Config::File;
use WWW::Marvel::Response;

my @FLAGS = (qw/ comics events series stories help /);
my %FILTERS = (
	name => 's',
	'nameStartsWith'	=> 's',
	'modifiedSince' => 's', # Date
#	comics => 'i',
#	series => 'i',
#	events => 'i',
#	stories => 'i',
	limit => 'i',
	offset => 'i',
);

sub commandline_options {
	my %opt = (
		config => undef,
		map({$_, 0} @FLAGS),
		map({$_, undef} keys %FILTERS),
		help => 0,
	);
	GetOptions(\%opt,
		'config=s',
		@FLAGS,
		map({"$_=$FILTERS{$_}"} keys %FILTERS),
	) or die "Error in cmdl args\n";

	if ($opt{help}) {
		print_help();
		exit 0;
	}

	return \%opt;
}

sub print_help {
	printf "Usage: %s [OPTIONS] [FILTERS] [FLAGS]\n", $0;
	printf "  OPTIONS:\n";
	printf "    --%-12s \t Config file\n", 'config <file>';
	printf "  FILTERS:\n";
	printf "    --%-12s \t Filter on %s [%s]\n", $_, $_, $FILTERS{$_} for (sort keys %FILTERS);
	printf "  FLAGS:\n";
	printf "    --%-12s \t Show %s\n", $_, $_ for (@FLAGS);
}

my $OPT = commandline_options();
my $cfg = WWW::Marvel::Config::File->new($OPT->{config});
my $client = WWW::Marvel::Client->new({
	public_key  => $cfg->get_public_key,
	private_key => $cfg->get_private_key,
});
my %filters =
	map { $_, $OPT->{$_} }
	grep { defined $OPT->{$_} }
	keys %FILTERS;

my $res_data = $client->characters(\%filters);
my $res = WWW::Marvel::Response->new($res_data);

my %FMT = (
	name => q{  >>>>>>>>>>>> <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< },
	desc => q{  >>>>>>>>>>>> [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[ },
	li   => q{               * <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< },
);

die("No results.\n", Dumper($res)) if $res->get_count < 1;

printf "Results: %s / %s\n", $res->get_count, $res->get_total;
while (my $c = $res->get_next_entity) {
	show_character($c);
}

sub show_character {
	my ($c) = @_;

	print form($FMT{name}, "Name:",        $c->get_name);
	print form($FMT{name}, "Id:",          $c->get_id);
	print form($FMT{desc}, "Picture:",     $c->get_picture);
	print form($FMT{desc}, "Description:", $c->get_description);
	print form($FMT{name}, "Uri:",         $c->get_resourceURI);
	print "\n";

	my $urls = $c->get_urls // [];
	for my $u (sort { $a->{type} cmp $b->{type} } @$urls) {
		print form($FMT{desc}, ucfirst($u->{type}).':', $u->{url});
	}
	print "\n";

	print_collection('Comics',   $c->get_comics)  if $OPT->{comics};
	print_collection('Events:',  $c->get_events)  if $OPT->{events};
	print_collection('Series:',  $c->get_series)  if $OPT->{series};
	print_collection('Stories:', $c->get_stories) if $OPT->{stories};
}

sub print_collection {
	my ($name, $c) = @_;
	print form($FMT{name}, $name, sprintf("%s/%s", $c->{returned}, $c->{available}));
	for my $i (@{ $c->{items} }) {
		print form($FMT{li}, $i->{name});
	}
	print form($FMT{name}, "Uri:", $c->{collectionURI});
	print "\n";
}

# urls : ARRAY(0x2b289e8)
# comics : HASH(0x2c3f790)
# events : HASH(0x2b273d8)
# series : HASH(0x320fca0)
# stories : HASH(0x2b269d0)
#	available : 11
# 	collectionURI : http://gateway.marvel.com/v1/public/characters/1009262/events
# 	returned : 11
# 	items : ARRAY(0x1b21e60)
#		name : Civil War
#		resourceURI : http://gateway.marvel.com/v1/public/events/238
#		...
#
# thumbnail : HASH(0x2c37c40)
#	extension : jpg
#	path : http://i.annihil.us/u/prod/marvel/i/mg/d/50/50febb79985ee
#
# description : Abandoned by his mother, Matt Murdock was raised by his father, boxer "Battling Jack" Murdock, in Hell's Kitchen. Realizing that rules were needed to prevent people from behaving badly, young Matt decided to study law; however, when he saved a man from an oncoming truck, it spilled a radioactive cargo that rendered Matt blind while enhancing his remaining senses. Under the harsh tutelage of blind martial arts master Stick, Matt mastered his heightened senses and became a formidable fighter.
# modified : 2013-07-01T16:44:00-0400
# resourceURI : http://gateway.marvel.com/v1/public/characters/1009262
# id : 1009262
# name : Daredevil

