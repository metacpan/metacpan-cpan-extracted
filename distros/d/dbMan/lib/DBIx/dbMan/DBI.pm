package DBIx::dbMan::DBI;

use strict;
use locale;
use vars qw/$AUTOLOAD/;
use POSIX;
use DBIx::dbMan::Config;
use DBIx::dbMan::MemPool;
use DBI;

our $VERSION = '0.11';

1;

sub new {
	my $class = shift;
	my $obj = bless { @_ }, $class;
	$obj->clear_all_connections;
	$obj->load_groups();
	$obj->load_connections;
	return $obj;
}

sub connectiondir {
	my $obj = shift;

	return $ENV{DBMAN_CONNECTIONDIR} if $ENV{DBMAN_CONNECTIONDIR};
	return $obj->{-config}->connection_dir if $obj->{-config}->connection_dir;
	mkdir $ENV{HOME}.'/.dbman/connections' unless -d $ENV{HOME}.'/.dbman/connections';
	return $ENV{HOME}.'/.dbman/connections';
}

sub groupdir {
	my $obj = shift;
	return $ENV{DBMAN_GROUPDIR} if $ENV{DBMAN_GROUPDIR};
	mkdir $ENV{HOME}.'/.dbman/groups' unless -d $ENV{HOME}.'/.dbman/groups';
	return $ENV{HOME}.'/.dbman/groups';
}

sub clear_all_connections {
	my $obj = shift;
	$obj->{connections} = {};
}

sub load_group {
	my ($obj,$name) = @_;

	my $gdir = $obj->groupdir();
	return -1 unless -d $gdir;
	$gdir =~ s/\/$//;
	return -2 unless -f "$gdir/$name";

	return new DBIx::dbMan::Config -file => "$gdir/$name";
}

sub load_groups {
	my $obj = shift;

	my $sdir = $obj->groupdir;
	my %groups = ();

	if (-d $sdir) {
		opendir S,$sdir;
		for my $group ( grep !/^\.\.?/, readdir S ) {
			$groups{$group} = $obj->load_group($group);
		}
		closedir S;
	}

	$obj->{_groups} = \%groups;
}

sub get_group {
	my ($obj,$group) = @_;

	return $obj->{_groups}->{$group};
}

sub load_connections {
	my $obj = shift;

	my $cdir = $obj->connectiondir;
	return -1 unless -d $cdir;

	opendir D,$cdir;
	$obj->load_connection($_) for grep !/^\.\.?/,readdir D;
	closedir D;

	my $current = '';
	$current = $obj->{-config}->current_connection if $obj->{-config}->current_connection;
	$obj->{-interface}->add_to_actionlist({ action => 'CONNECTION',
		operation => 'use', what => $current });
}

sub load_connection {
	my ($obj,$name) = @_;

	my $cdir = $obj->connectiondir;
	return -1 unless -d $cdir;
	$cdir =~ s/\/$//;
	return -2 unless -f "$cdir/$name";

	my $lcfg = new DBIx::dbMan::Config -file => "$cdir/$name";
	if ($lcfg->group) {
		for ( $lcfg->group() ) {
			print STDERR "Error: Can't use group '$_' for connection '$name'\n" unless $lcfg->merge( $obj->get_group($_) );
		}
	}

	my %connection;
	$connection{$_} = $lcfg->$_ for $lcfg->all_tags;
	$obj->{connections}->{$name} = \%connection;
	
	$obj->{-interface}->add_to_actionlist({ action => 'CONNECTION',
		operation => 'open', what => $name }) if lc $lcfg->auto_login eq 'yes';
}

sub open {
	my ($obj,$name) = @_;

	return -3 unless exists $obj->{connections}->{$name};
	return -4 if $obj->{connections}->{$name}->{-logged};
	return -1 unless grep { $_ eq $obj->{connections}->{$name}->{driver} } $obj->driverlist;

	my %vars = qw/PrintError 0 RaiseError 0 AutoCommit 1 LongTruncOk 1/;
	if ( $obj->{connections}->{$name}->{config} ) {
		for ( split /;\s*/, $obj->{connections}->{$name}->{config} ) {
			if ( /^\s*(\S+?)\s*=\s*(\S+)\s*$/ ) {
				$vars{ $1 } = $2 unless $1 eq 'AutoCommit';		# everything unless transactions
			}
		}
	}

	my $dbi = DBI->connect('dbi:'.$obj->{connections}->{$name}->{driver}.
		':'.$obj->{connections}->{$name}->{dsn},
		$obj->{connections}->{$name}->{login},
		$obj->{connections}->{$name}->{password},
		\%vars );

	return -2 unless defined $dbi;

	$obj->{connections}->{$name}->{-dbi} = $dbi;
	$obj->{connections}->{$name}->{-mempool} = new DBIx::dbMan::MemPool;
	$obj->{connections}->{$name}->{-logged} = 1;
	$obj->{-interface}->add_to_actionlist({ action => 'AUTO_SQL', connection => $name });

	return 0;
}

sub driverlist {
	my $obj = shift;
	return DBI->available_drivers;
}

sub close {
	my ($obj,$name) = @_;

	return -1 unless exists $obj->{connections}->{$name};
	return -2 unless $obj->{connections}->{$name}->{-logged};

	$obj->set_current() if $obj->{current} eq $name;
	$obj->discard_profile_data();
	delete $obj->{connections}->{$name}->{-logged};
	$obj->{connections}->{$name}->{-dbi}->disconnect();
	undef $obj->{connections}->{$name}->{-dbi};
	undef $obj->{connections}->{$name}->{-mempool};

	return 0;
}

sub close_all {
	my $obj = shift;
	for my $name (keys %{$obj->{connections}}) {
		if ($obj->{connections}->{$name}->{-logged}) {
			$obj->close($name);
                	$obj->{-interface}->print("Disconnected from $name.\n");
			# we can't move this message to extension - close_all called when
			# destroying DBI object (handle event collapsed :(, no OUTPUT event exist)
		}
	}
}

sub DESTROY {
	my $obj = shift;
	$obj->close_all;
}

sub list {
	my ($obj,$what) = @_;
	my @returned = ();

	for my $name (keys %{$obj->{connections}}) {
		my %r = %{$obj->{connections}->{$name}};
		next if ($what eq 'inactive' and $r{-logged}) || ($what eq 'active' and ! $r{-logged});
		$r{name} = $name;
		push @returned, \%r;
	}

	return [ sort { $a->{name} cmp $b->{name} } @returned ];
}

sub autosql {
	my $obj = shift;

	return -1 unless $obj->{current};
	return -2 unless exists $obj->{connections}->{$obj->{current}};
	return $obj->{connections}->{$obj->{current}}->{autosql};
}

sub silent_autosql {
	my $obj = shift;

	return -1 unless $obj->{current};
	return -2 unless exists $obj->{connections}->{$obj->{current}};
	return $obj->{connections}->{$obj->{current}}->{silent_autosql};
}

sub set_current {
	my ($obj,$name) = @_;

	return 9999 if $obj->{current} eq $name;

	unless ($name) { delete $obj->{current};  return 1; }

	return -1 unless exists $obj->{connections}->{$name};
	return -2 unless $obj->{connections}->{$name}->{-logged};

	$obj->{current} = $name;
	return 0;
}

sub current {
	my $obj = shift;
	return $obj->{current};
}

sub drop_connection {
	my ($obj,$name) = @_;
	return -1 unless exists $obj->{connections}->{$name};
	$obj->close($name) if $obj->{connections}->{$name}->{-logged};
	delete $obj->{connections}->{$name};
	return 0;
}

sub create_connection {
	my ($obj,$name,$p) = @_;
	my %parms = %$p;

	return -1 if exists $obj->{connections}->{$name};

	$obj->{connections}->{$name} = \%parms;
	return 100+$obj->open($name) if lc $parms{auto_login} eq 'yes';
	return 0;
}

sub save_connection {
	my $obj = shift;
	my $name = shift;
	
	return -1 unless exists $obj->{connections}->{$name};

	my $cdir = $obj->connectiondir;
	mkdir $cdir unless -d $cdir;
	return -1 unless -d $cdir;
	$cdir =~ s/\/$//;
	CORE::open F,">$cdir/$name" or return -2;
	for (qw/driver dsn login password auto_login config/) {
		print F "$_ ".$obj->{connections}->{$name}->{$_}."\n"
			if exists $obj->{connections}->{$name}->{$_}
				and $obj->{connections}->{$name}->{$_} ne '';
	}	
	CORE::close F;
	chmod 0600,"$cdir/$name";
	return 0;
}

sub destroy_connection {
	my $obj = shift;
	my $name = shift;
	
	my $cdir = $obj->connectiondir;
	return -1 unless -d $cdir;
	$cdir =~ s/\/$//;
	return 1 unless -e "$cdir/$name";
	unlink "$cdir/$name";
	return -2 if -e "$cdir/$name";
	return 0;
}

sub is_permanent_connection {
	my $obj = shift;
	my $name = shift;
	my $cdir = $obj->connectiondir;
	return 0 unless -d $cdir;
	$cdir =~ s/\/$//;
	return -e "$cdir/$name";
}

sub trans_begin {
	my $obj = shift;
	return -1 unless $obj->{current};
	$obj->{connections}->{$obj->{current}}->{-dbi}->{AutoCommit} = 0;
}

sub longreadlen {
	my $obj = shift;
	my $long = shift;
	$obj->{connections}->{$obj->{current}}->{-dbi}->{LongReadLen} = $long if $long;
	return $obj->{connections}->{$obj->{current}}->{-dbi}->{LongReadLen};
}

sub trans_end {
	my $obj = shift;
	return -1 unless $obj->{current};
	$obj->{connections}->{$obj->{current}}->{-dbi}->{AutoCommit} = 1;
}

sub in_transaction {
	my $obj = shift;
	return 0 unless $obj->{current};
	return not $obj->{connections}->{$obj->{current}}->{-dbi}->{AutoCommit};
}

sub driver {
	my $obj = shift;
	return undef unless $obj->{current};
	return $obj->{connections}->{$obj->{current}}->{driver};
}

sub login {
	my $obj = shift;
	return undef unless $obj->{current};
	return $obj->{connections}->{$obj->{current}}->{login};
}

sub AUTOLOAD {
	my $obj = shift;

	$AUTOLOAD =~ s/^DBIx::dbMan::DBI:://g;
	return undef unless $obj->{current};
	return undef unless exists $obj->{connections}->{$obj->{current}};
	return undef unless $obj->{connections}->{$obj->{current}}->{-logged};
	return undef unless defined $obj->{connections}->{$obj->{current}}->{-dbi};
	my $dbi = $obj->{connections}->{$obj->{current}}->{-dbi};
	return $dbi->$AUTOLOAD(@_);
}

sub set {
	my ($obj,$var,$val) = @_;
	return unless $obj->{current};

	$obj->{connections}->{$obj->{current}}->{-dbi}->{$var} = $val;
}

sub get {
	my ($obj,$var) = @_;
	return undef unless $obj->{current};
	return $obj->{connections}->{$obj->{current}}->{-dbi}->{$var};
}

sub discard_profile_data {
	my $obj = shift;
	return unless $obj->{current};
#	$obj->{connections}->{$obj->{current}}->{-dbi}->{Profile}->{Data} = undef;
}

sub mempool {
	my $obj = shift;
	return undef unless $obj->{current};
	return $obj->{connections}->{$obj->{current}}->{-mempool};
}
