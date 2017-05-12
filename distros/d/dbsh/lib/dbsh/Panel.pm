package dbsh::Panel;

use vars qw/$VERSION/;

$VERSION = '0.01';

use Tk;
use DBI;
use DBIx::SystemCatalog;

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	my %pack = %{$obj->{-pack}};
	$pack{-expand} = 1;
	$pack{-fill} = 'both';
	my @pack = %pack;
	my $f = $obj->{-in}->Frame()->pack(@pack);

	$f->Frame()->pack(-side => 'top', -fill => 'x');
	$obj->{list} = $f->Scrolled('HList', -header => 1,
		-columns => 1, -scrollbars => 'se',
		-command => sub { $obj->cd(@_); })
		->pack(-side => 'top', -expand => 1, -fill => 'both');
	$obj->{list}->header('create',0,-text => 'Not connected.');

	$obj->{-menubar}->command(-label => 'Connect...', -underline => 0,
		-command => sub { $obj->connect; });
	return $obj;
}

sub connect {
	my $obj = shift;

	$obj->{dbh}->disconnect if $obj->{dbh};
	$obj->{list}->delete('all');
	$obj->{list}->configure(-columns => 1);
	$obj->{list}->header('create',0,-text => 'Not connected.');

	my @driver_names = DBI->available_drivers;

	my $driver = $driver_names[0];
	my $database = '';
	my $login = '';
	my $password = '';

	my $d = $obj->{-in}->DialogBox(-title => 'Connect to database',
		-buttons => [ 'Connect', 'Cancel' ]);

	$d->Label(-justify => 'left', -text => 'Driver:')
		->grid(-column => 2, -row => 1, -sticky => 'w');
	$d->Optionmenu(-options => \@driver_names, -textvariable => \$driver)
		->grid(-column => 3, -row => 1, -sticky => 'ew');
	$d->Label(-justify => 'left', -text => 'DSN for database:')
		->grid(-column => 2, -row => 2, -sticky => 'w');
	$d->Entry(-textvariable => \$database)
		->grid(-column => 3, -row => 2, -sticky => 'ew');
	$d->Label(-justify => 'left', -text => 'Login:')
		->grid(-column => 2, -row => 3, -sticky => 'w');
	$d->Entry(-textvariable => \$login)
		->grid(-column => 3, -row => 3, -sticky => 'ew');
	$d->Label(-justify => 'left', -text => 'Password:')
		->grid(-column => 2, -row => 4, -sticky => 'w');
	$d->Entry(-textvariable => \$password, -show => '*')
		->grid(-column => 3, -row => 4, -sticky => 'ew');

	$d->gridRowconfigure(1, -weight => 0, -minsize => 30);
	$d->gridRowconfigure(2, -weight => 0, -minsize => 30);
	$d->gridRowconfigure(3, -weight => 0, -minsize => 30);
	$d->gridRowconfigure(4, -weight => 0, -minsize => 30);
	
	$d->gridColumnconfigure(1, -weight => 0, -minsize => 10);
	$d->gridColumnconfigure(2, -weight => 0, -minsize => 30);
	$d->gridColumnconfigure(3, -weight => 0, -minsize => 166);
	$d->gridColumnconfigure(4, -weight => 0, -minsize => 13);

	return unless $d->Show eq 'Connect';

	my $dsn = 'dbi:'.$driver.':'.$database;
	$obj->{dbh} = DBI->connect($dsn,$login,$password,
		{ RaiseError => 0, PrintError => 0, AutoCommit => 1 });
	unless ($obj->{dbh}) {
		$obj->{-in}->messageBox(-icon => 'error', -type => 'OK', 
			-title => 'Database error', 
			-message => $DBI::errstr);
		return;
	}

	$obj->{catalog} = new DBIx::SystemCatalog $obj->{dbh};
	$obj->{cwd} = '/';
	$obj->ls;
}

sub ls {
	my $obj = shift;
	$obj->{list}->delete('all');
	if ($obj->{cwd} =~ /\/$/) {	# show objects
		$obj->{list}->configure(-columns => 1);
		$obj->{list}->header('create',0,-text => 'Name');
		my @lists = $obj->{catalog}->fs_ls($obj->{cwd});
		my $i = 0;
		for (@lists) {
			my $d = $_;
			$d =~ s/\/[^\/]+\/..\//\//g;
			my $row = $obj->{list}->addchild('', -data => $d);
			my $disp = $_;
			$disp =~ s/\/$//;
			$disp =~ s/^.*\///;
			$obj->{list}->itemCreate($row,0,
				-itemtype => 'text', -text => $disp);
		}
	}
}

sub cd {
	my $obj = shift;
	my $item = shift;
	my $data = $obj->{list}->info('data',$item);
	if ($data =~ /\/$/) {
		$obj->{cwd} = $data;
		$obj->ls;
	}
}

