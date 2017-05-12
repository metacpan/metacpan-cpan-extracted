use strict;
use warnings;
use Test::More;

use Text::Tweet;
use utf8;

my $cnt = 0;

my $utf8_tweeter = Text::Tweet->new;

for (
	[
		[ "Bär Böcke Borg", \"http://www.perl.org/" ],
		[ "Bär", "Böcke", "Beer" ],
		"#Bär #Böcke Borg http://www.perl.org/ #beer"
	],
	[
		[ "Τη γλώσσα μου έδωσαν ελληνική", \"http://www.perl.org/" ],
		[ "έδωσαν" ],
		"Τη γλώσσα μου #έδωσαν ελληνική http://www.perl.org/"
	],
	[
		[ "ვეპხის ტყაოსანი შოთა რუსთაველი", \"http://www.perl.org/" ],
		[ "შოთა" ],
		"ვეპხის ტყაოსანი #შოთა რუსთაველი http://www.perl.org/"
	],
	[
		[ "நாமமது தமிழரெனக் கொண்டு இங்கு வாழ்ந்திடுதல் நன்றோ? சொல்லீர்!", \"http://www.perl.org/" ],
		[ "இங்கு" ],
		"நாமமது தமிழரெனக் கொண்டு #இங்கு வாழ்ந்திடுதல் நன்றோ? சொல்லீர்! http://www.perl.org/"
	],
    [
        [ "日本語でOKかなカナ！？", \"http://www.perl.org/" ],
        [ "日本語" ],
        "#日本語でOKかなカナ！？ http://www.perl.org/"
    ],
) {
	my ( $textparts, $keywords, $result ) = @{$_}; $cnt++;
	is($utf8_tweeter->make($keywords,@{$textparts}),$result,"Checking result of ".$cnt.". test.");
}

done_testing;
