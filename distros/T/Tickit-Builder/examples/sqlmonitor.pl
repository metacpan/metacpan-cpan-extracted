#!/usr/bin/perl 
use strict;
use warnings;
use lib './lib';

use DBI;
package Tickit::Widget::SQLStatement;
use parent qw(Tickit::Widget);
use Text::Tabs qw(expand);

sub cols { 1 }
sub lines { 1 }

sub render {
	my $self = shift;
	return unless my $win = $self->window;
	my $lines = $win->lines;
	my @text = split /\n/, <<'EOT';
select distinct	idtable
from		table t
inner join	other_table o
on		o.idtable = t.idtable
where		t.created > now()
group by	date(t.created),
		t.created,
		t.name;
having		t.refcount > 0
limit		30
EOT
	my $y = 0;
	while(@text && $lines) {
		my $line = expand(shift @text);
		$win->goto($y++, 0);
		$win->print($line);
		--$lines;
	}
}

$INC{'Tickit/Widget/SQLStatement.pm'} = 1;

package main;
use Tickit::Builder;

my $layout = Tickit::Builder->new;
$layout->run({
	# Provide a default example
	widget => {
		type => 'VBox',
		children => [
			{ widget => { id => 'menu', type => "Menu", bg => 'blue', children => [
				{ widget => { id => 'menu_file', type => "Menu::Item", text => "File" } },
				{ widget => { id => 'menu_edit', type => "Menu::Item", text => "Edit" } },
				{ widget => { type => "Menu::Spacer", text => " " }, expand => 1 },
				{ widget => { id => 'menu_help', type => "Menu::Item", text => "Help" } },
			] }},
			{ widget => { type => "HBox", text => "Static entry", children => [
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Tree", keybindings => {
							'C-r' => 'grab_focus',
						}, label => 'Root', is_open => 1, last => 1, children => [
						{ widget => { type => "Tree", label => 'Users', is_open => 0, children => [
							{ widget => { type => "Tree", label => 'Local', children => [
								{ widget => { type => "Tree", label => 'First user' } },
								{ widget => { type => "Tree", label => 'Second user' } },
								{ widget => { type => "Tree", label => 'Third user' } },
							] } },
							{ widget => { type => "Tree", label => 'Remote', last => 1, children => [ ] } },
						] } },
						{ widget => { type => "Tree", label => 'Groups', last => 1, children => [
						] } },
					] }, expand => 1 },
				] }, expand => 0.33 },
				{ widget => { type => "VBox", children => [
					{ widget => { type => "Frame", style => 'single', title => 'Main editing area', children => [
						{ widget => { type => "VBox", children => [
							{ widget => { type => "SQLStatement", text => "This is an example layout." }, expand => 1 },
						], fg => 'yellow' }, expand => 1 },
					] }, expand => 1 },
					{ widget => { type => "Frame", style => 'single', title => 'Log messages', children => [
						{ widget => { type => "Static", text => "Lower panel" } },
					] } },
				] }, expand => 0.67 },
			] }, expand => 1 },
			{ widget => { type => "Static", text => "Status bar", bg => 0x04, fg => 'white', } },
		],
	}
});

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.


