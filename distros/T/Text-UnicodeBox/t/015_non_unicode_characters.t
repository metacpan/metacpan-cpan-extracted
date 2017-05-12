
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
	use_ok 'Text::UnicodeBox';
	use_ok 'Text::UnicodeBox::Control', qw(:all);
};

$Text::UnicodeBox::Utility::report_on_failure = 1;

my $box = Text::UnicodeBox->new(
	fetch_box_character => sub {
		return '-';
	},
);
$box->add_line( BOX_START( top => 1, bottom => 1 ), ' This is a header ', BOX_END() );

is $box->render, <<END_BOX, "Box is drawn with ASCII art rather then Unicode characters";
--------------------
- This is a header -
--------------------
END_BOX

$box = Text::UnicodeBox->new(
	fetch_box_character => sub {
		my %symbol = @_;
		my $segments = int keys %symbol;
		if ($segments == 2 && $symbol{down} && ($symbol{left} || $symbol{right})) {
			return '.';
		}
		elsif ($segments == 2 && $symbol{up} && ($symbol{left} || $symbol{right})) {
			return '\'';
		}
		elsif (
			($segments == 2 && $symbol{up} && $symbol{down}) ||
			($segments == 1 && $symbol{vertical})
		) {
			return '|';
		}
		elsif (
			($segments == 2 && $symbol{left} && $symbol{right}) ||
			($segments == 1 && $symbol{horizontal})
		) {
			return '-';
		}
		else {
			return '+';
		}
	},
);
$box->add_line( BOX_START( top => 1, bottom => 1 ), ' This is a header ', BOX_END() );

is $box->render, <<END_BOX, "Box is drawn with bit more complex ASCII art";
.------------------.
| This is a header |
'------------------'
END_BOX

done_testing;
