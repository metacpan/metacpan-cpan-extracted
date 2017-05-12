package DBIx::dbMan::Extension::Authors;

use strict;
use base 'DBIx::dbMan::Extension';

our $VERSION = '0.10';

# registered authornames
our %authorname = (
	'000001' => 'Milan Sorm <sorm@is4u.cz>',
	'000002' => 'Frantisek Darena <darena@mendelu.cz>',
	'000003' => 'Ales Kutin <kutin@is4u.cz>',
	'000004' => 'Ondrej \'Kepi\' Kudlik <kepi@igloonet.cz>',
	'000005' => 'Tomas Klein <klein@is4u.cz>',
);

1;

sub IDENTIFICATION { return "000001-000012-000010"; }

sub author { return 'Milan Sorm <sorm@is4u.cz>'; }

sub preference { return 0; }

sub known_actions { return [ qw/AUTHORS/ ]; }

sub menu {
	return ( { label => '_Help', submenu => [
			{ label => 'Authors', action => { action => 'AUTHORS' } }
		] } );
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'AUTHORS') {
		my %authors = ();
		for my $ext (@{$obj->{-core}->{extensions}}) {
			my $id = $ext->IDENTIFICATION;
			$id =~ s/-.*//;
			++$authors{$id};
			if ($ext->can('author')) {
				$authorname{$id} = $ext->author();
			}
		}
		my $authors = '';
		for (sort { $authors{$a} <=> $authors{$b} } keys %authors) {
			$authors .= "   ".((exists $authorname{$_})?$authorname{$_}:$_)." ($authors{$_} extension".($authors{$_}==1?"":"s").")\n";
		}

		$action{output} = "Program:\n   ".$authorname{'000001'}."\n\nExtensions:\n".$authors;

		if ($action{gui}) {
			$action{action} = 'NONE';
			$obj->{-interface}->infobox($action{output});
		} else {
			$action{action} = 'OUTPUT';
		}
	}

	$action{processed} = 1;
	return %action;
}
