#!/usr/bin/perlml

use strict;
use warnings;
use HTML::Entities;

my $instructions = '
 ┌───────────────────────────────────────────────────────────────────────────────────┐
 │  								INSTRUCTIONS                                     │
 │                                                                                   │
 │    In the scripts cal_agenda_html.pl and cal_grid_html.pl you will                │
 │    find a stylesheet (or two) linked in the <head></head> section                 │
 │    of the output. These need to point to THIS file:                               │
 │                                                                                   │
 │    <link rel="stylesheet" href="calendar_css.pl?file=demo1&prefix=demo&pid=$$">   │
 │                                                                                   │
 │    The query string needs to key/value pairs:                                     │
 │                                                                                   │
 │      file => This will be the key you set in the hash %file_paths below.          │
 │              If you do not have the CSS file in the same path as this script,     │
 │    		    then make sure you enter a valid relative path or absolute path.     │
 │                                                                                   │
 │    prefix => This will be a string that you define for your CSS class names       │
 │              that will provide the styling for the calendar that refernces        │
 │    		    them. You will need to have the *.css file styling completed         │
 │    		    BUT you do not not need to rename the <prefix> tags in the file.     │
 │    		    This script will do that for you as it ouputs the content to         │
 │    		    the browser. Please read and understand the instructions in the      │
 │    		    CSS file as well at this file.                                       │
 │                                                                                   │
 └───────────────────────────────────────────────────────────────────────────────────┘
';
undef $instructions;

my %file_paths = (
    demo1 => 'demo_calendar.css'
);

my %css = (
    '-agenda-day-today' => 'background-color: #fffcad;'
);

###################################################################

my %qs;
my @qstring = split(/\&/, $ENV{QUERY_STRING});
foreach my $qspair (@qstring) {
	my ($k, $v) = split(/=/, decode_entities($qspair));
	$qs{$k} = $v;
}

$qs{prefix} =~ s/^\.+//;

($qs{prefix} && $qs{file}) or print '' && exit;

my $pfx = '.' . $qs{prefix};

my $pfx_rp = qr/\<PREFIX\>/i;

my @lines;

my $css = \%css;

print "Content-type: text/css\n\n";

if (open(my $fh, '<', $file_paths{$qs{file}})) {
		{
			local $/;             # temporarily slurp mode
			my $all = <$fh>;      # whole file in one scalar
			$all =~ s{/\*.*?\*/}{}gs;  # remove all /* ... */ comments, across lines
			@lines = split /\n/, $all; # split back into lines
		}
		foreach my $line (@lines) {
		    $line =~ s/$pfx_rp/$pfx/g;
			foreach my $css_line (keys %$css) {
				if($line =~ /^\.\Q$pfx$css_line\E\b/) {
					$line = $pfx . $css_line . ' {' . $css->{$css_line} . '}';
				}
			}
			print $line, "\n";
		}
    close $fh;
} else {
    warn "Could not open file '$file_paths{$qs{file}}' $!";
}

exit;
