package DBIx::dbMan::Extension::InputCSV;

use strict;
use base 'DBIx::dbMan::Extension';
use Text::CSV_XS;
use FileHandle;

our $VERSION = '0.05';

1;

sub IDENTIFICATION { return "000001-000041-000005"; }

sub preference { return 0; }

sub known_actions { return [ qw/CSV_IN/ ]; }

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'CSV_IN') {
		$action{action} = 'NONE';
		my $csv = new Text::CSV_XS { quote_char => $action{opt_quote},
			eol => $action{opt_eol}, binary => 1,
			sep_char => $action{opt_separator},
			escape_char => $action{opt_escape},
			allow_loose_escapes => $action{opt_allow_loose_escapes},
			allow_loose_quotes => $action{opt_allow_loose_quotes} };

		my $file = new FileHandle "<$action{file}";
		unless (defined $file) {
			$obj->{-interface}->error("Can't load input CSV file $action{file}.");
			return %action;
		}
		local $/ = $action{opt_eol};
		my $now_head = 1;
		while (<$file>) {
			chomp;
			if ($csv->parse($_)) {
				my @f = $csv->fields();
				if ($now_head and $action{opt_headings} == 1) {
					$now_head = 0;  next;
				}
				$now_head = 0;
				my $newaction = { action => 'SQL', sql => $action{sql}, type => 'do', placeholders => \@f };
				$obj->{-interface}->add_to_actionlist($newaction);
			}
		}
		$file->close();
	}

	$action{processed} = 1;
	return %action;
}
