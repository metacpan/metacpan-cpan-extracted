package DBIx::dbMan::Extension::GuiCreateConnection;

use strict;
use base 'DBIx::dbMan::Extension';
use Curses::UI;


our $VERSION = '0.01';

1;

sub IDENTIFICATION { return "000001-000090-000001"; }

sub preference { return 800; }

sub known_actions { return [ qw/GUI/ ]; }

sub menu {
	return { label => 'Connection', submenu => [
			{ label => 'Create...', preference => -5, action => { action => 'GUI',
				operation => 'create_connection' } }
		] };
}

sub load_ok {
    my $obj = shift;

    return $obj->{-interface}->gui();
}

sub handle_action {
	my ($obj,%action) = @_;

	if ($action{action} eq 'GUI') {
		if ($action{operation} eq 'create_connection') {
			if ($obj->{-interface}->can('is_curses')
				and $obj->{-interface}->is_curses()) {
				$action{action} = 'NONE';

				my $ui = $obj->{-interface}->{ui};
				my $dialog = $ui->add('dialog','Window',
					-border => 1, -ipad => 1, -centered => 1,
					-title => 'Create new connection',
					-height => 18, -width => 50);

				$dialog->add('label1', 'Label', -text => 'Connection name',
					-x => 0, -y => 0);
				my $e_name = $dialog->add('e_name', 'TextEntry',
					-x => 20, -y => 0, -sbborder => 1);

				$dialog->add('label2', 'Label', -text => 'Database driver',
					-x => 0, -y => 2);
				my @drivers = sort { uc $a <=> uc $b } $obj->{-dbi}->driverlist;
				my $sel = 0;
				for my $driver (qw/Oracle Pg mysql XBase CSV/) {
					my $i = 0;
					for (@drivers) {
						last if $driver eq $_;
						++$i;
					}
					if ($i < @drivers) { $sel = $i;  last; }
				}
				my $e_driver = $dialog->add('e_driver', 'Popupmenu',
					-values => \@drivers,
					-labels => { map { $_ => $_ } @drivers },
					-selected => $sel,
					-x => 20, -y => 2);
				
				$dialog->add('label3', 'Label', -text => 'DSN',
					-x => 0, -y => 4);
				my $e_dsn = $dialog->add('e_dsn', 'TextEntry',
					-x => 20, -y => 4, -sbborder => 1);
				
				$dialog->add('label4', 'Label', -text => 'Login',
					-x => 0, -y => 6);
				my $e_login = $dialog->add('e_login', 'TextEntry',
					-x => 20, -y => 6, -sbborder => 1);
				
				$dialog->add('label5', 'Label', -text => 'Password',
					-x => 0, -y => 8);
				my $e_pass = $dialog->add('e_pass', 'PasswordEntry',
					-x => 20, -y => 8, -sbborder => 1);

				my $e_save = $dialog->add('e_save', 'Checkbox',
					-x => 0, -y => 10, -label => 'Make connection permanent',
					-checked => 1);
				
				my $e_open = $dialog->add('e_open', 'Checkbox',
					-x => 0, -y => 11, -label => 'Autoopen connection',
					-checked => 0);

				my $btns = $dialog->add('buttons', 'Buttonbox', -y => -1,
					-buttonalignment => 'right', -buttons => [ 
						{ -label => '< Create >', -value => 1 },
						{ -label => '< Cancel >', -value => 0 } ]);
				$btns->set_routine('press-button',
					sub { shift->parent->loose_focus(); });

				$e_name->focus();

				while (1) {
					$dialog->modalfocus();

					if ($btns->get()) {
						my $name = $e_name->get();
						my $driver = $e_driver->get();
						my $dsn = $e_dsn->get();
						my $login = $e_login->get();
						my $pass = $e_pass->get();
						my $save = $e_save->get();
						my $open = $e_open->get();

						$name =~ s/\s+//g;
						$dsn =~ s/\s+//g;
						$login =~ s/\s+//g;

						if ($name) {
							$action{action} = 'CONNECTION';
							$action{operation} = 'create';
							$action{what} = $name;
							$action{driver} = $driver;
							$action{dsn} = $dsn;
							$action{login} = $login;
							$action{password} = $pass;
							$action{auto_login} = 'yes' if $open;
							++$action{permanent} if $save;
							last;
						}

						$e_dsn->text($dsn);
						$e_name->text($name);
						$e_login->text($login);
					} else {
						last;
					}
				}

				$ui->delete('dialog');
			}
		}
	}

	$action{processed} = 1;
	return %action;
}
