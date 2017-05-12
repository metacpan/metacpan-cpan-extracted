### AUTHOR TEST ###
use strict;
use warnings;

use Test::More tests => 1;
use Data::Dumper;
use Encode;
use IO::File;
use URI;
use utf8;

SKIP: {
	skip "tests only for author", 1 if !$ENV{TWITPIC_FETCH_AUTHOR_TEST};
	
	use WWW::Twitpic::Fetch;
	my $tp = WWW::Twitpic::Fetch->new;
	ok $tp;
	my $username = $ENV{TWITPIC_FETCH_AUTHOR_TEST};
	my $f = IO::File->new("test.txt", "w") or die "$!";
	$f->print("### list of mine (page1)\n");
	_dump($f, $tp->list('turugina', 1));
	$f->print("### list of mine (page2)\n");
	_dump($f,$tp->list('turugina', 2));
	$f->print("### certain photo (scaled)\n");
	_dump($f,my $photo = $tp->photo_info('2f2du7'));
	$f->print("### certain photo (full)\n");
	_dump($f,$tp->photo_info('4rukf', 1));
	$f->print("### public timeline\n");
	_dump($f,$tp->public_timeline);

	my $photouri=URI->new($photo->{url});
	my $filename = (split(m{/}, $photouri->path))[-1];
	my $idx = index($filename, "?");
	if ( $idx >= 0 ) {
		$filename = substr($filename, 0, $idx);
	}
	diag("using filename: $filename");
		
	$tp->ua->mirror($photouri, $filename);

	$f->printf("### tagged photos\n");
	_dump($f, $tp->tagged('cat'));
}


sub _dump
{
	my ($f, $v) = @_;
	if (ref $v eq "ARRAY") {
		$f->print("[\n");
		_dump($f, $_) for @$v;
		$f->print("]\n");
	}
	elsif (ref $v eq "HASH") {
		$f->print("{\n");
		while (my ($k,$v) = each %$v) {
			$f->print(encode_utf8($k), ": ");
			_dump($f, $v);
		}
		$f->print("}\n");
	}
	else {
		$f->print(encode_utf8($v),"\n");
	}
}
