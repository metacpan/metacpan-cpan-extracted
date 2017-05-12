package TestDataTables;
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Mojo::Base 'Mojolicious';

use Data::Dump qw(ddx pp dd);
no warnings;
*Data::Dump::quote = sub { return qq("$_[0]"); };
use warnings;

has 'dbh';
use DBI;

sub connectDB {
	my $c      = shift;
	my $app    = ( UNIVERSAL::isa( $c, 'Mojolicious::Controller' ) ) ? $c->app : $c;
	my $dbfile = 'TestDataTables.db';

	unless ( UNIVERSAL::isa( $app->dbh, "DBI::db" ) && $app->dbh->ping() ) {
		$app->dbh( DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "", { AutoCommit => 0, } ) );
	} ## end unless ( UNIVERSAL::isa( $app...))

	unless ( -f $dbfile && $app->dbh->selectrow_array('select count(*) from datatable') ) {
		# если надо создадим тестовую базу
		warn("Creating test database...");
		$app->dbh->do(<<END);
    CREATE TABLE datatable (
        id INTEGER,
        col_int INTEGER,
        col_text TEXT,
        col_real REAL,
        CONSTRAINT PK_datatable PRIMARY KEY (id)
    )
END

		my $query = "INSERT INTO datatable(id,col_int,col_text,col_real) VALUES (?,?,?,?)";
		my $sth   = $app->dbh->prepare($query);

		my $id = 0;
		my @chars = ( ' ', ' ', ' ', ' ', 'a' .. 'z', 0 .. 9 );
		foreach my $i ( 1 .. 1000 ) {
			$id++;
			my ( $col_int, $col_text, $col_real ) = ( rand(1000), '', rand() );
			$col_text .= $chars[ int( rand( $#chars + 1 ) ) ] foreach ( 1 .. rand(100) );
			$sth->execute( $id, $col_int, $col_text, $col_real );
		} ## end foreach my $i ( 1 .. 1000 )

		$app->dbh->commit();
	} ## end unless ( -f $dbfile && $app...)

} ## end sub connectDB

sub startup {
	my $self = shift;
	$self->secret('dfasdfa;sdlf;asdf9as');
	$self->addPlugins();
	$self->addHooks();
	$self->addRoutes();
} ## end sub startup

sub addPlugins {
	my $self = shift;
	$self->plugin( charset => { charset => 'utf8' } );

} ## end sub addPlugins

sub addHooks {
	my $self = shift;
	$self->hook(
		after_static_dispatch => sub {
			my ($c) = @_;
			my $type = $c->res->headers->content_type;
			connectDB($c) unless $type;

			if ( $type && $c->res->code ) {
				if ( $type =~ /^text\/css/o || $type =~ /^image\//o || $type =~ /javascript/o || $type =~ m{audio/x-wav}o ) {
					$c->res->headers->cache_control('max-age=86400, must-revalidate');
				} ## end if ( $type =~ /^text\/css/o...)
			} ## end if ( $type && $c->res->code)
		}
	);
} ## end sub addHooks

sub addRoutes {
	my $self = shift;

	my $r = $self->routes;

	$r->route('/datatables/table')->name('datatables_table')->to('datatables#table');
	$r->route('/')->to( 'cb' => sub { shift->redirect_to('/index.html'); } );

} ## end sub addRoutes
1;

