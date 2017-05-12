#!/usr/bin/perl -w

use strict;
use Getopt::Simple qw($switch);
use WebService::Images::Nofrag;
use File::HomeDir;
use DBI;

my $home   = File::HomeDir->my_home;
my $dbfile = $home . '/.upnofrag.db';

check_db();

my ( $options ) = {
    help => { type    => '',
              env     => '-',
              default => '',
              verbose => 'this help',
              order   => 1,
    },
    image => { type    => '=s',
               env     => '-',
               default => '',
               verbose => 'path to an image',
               order   => 2,
    },
    url => {
        type    => '=s',
        env     => '-',
        default => '',
        verbose => 'url to an image',
        order   => 2,

    },
    history => { type    => '=i',
                 env     => '-',
                 default => '',
                 verbose => 'list you uploded pics',
                 order   => 3,
    },
    resize => {
        type    => '=s',
        env     => '-',
        default => '',
        verbose => 'resize image before uploading it',
        order   => 4,

    },
    search => { type    => '=s',
                env     => '',
                default => '',
                verbose => 'search an uploaded pic',
                order   => 5,
    } };

my $o = Getopt::Simple->new();
if ( !$o->getOptions( $options, "Usage : $0 [options]" ) ) {
    exit( -1 );
}

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );

history() if ( $$switch{ 'history' } );
upload()  if ( $$switch{ 'image' } || $$switch{'url'});
search()  if ( $$switch{ 'search' } );

sub history {
    my $sth = $dbh->prepare(
                 "SELECT * FROM upload desc limit " . $$switch{ 'history' } );
    $sth->execute();
    while ( my $file = $sth->fetchrow_hashref ) {
        render_query( $file );
    }
}

sub upload {
    my $pix = WebService::Images::Nofrag->new();

	if ($$switch{image}){
    	$pix->upload( {file => $$switch{ image }, resize => $$switch{ resize }} );		
	}else{
    	$pix->upload( {url => $$switch{ url }, resize => $$switch{ resize }} );				
	}

    print "URL : " . $pix->url . "\n";
    print "image : " . $pix->image . "\n";
    print "thumb : " . $pix->thumb . "\n";

    my $sth = $dbh->prepare( "INSERT INTO upload values (?,?,?,?,?)" );
    $sth->execute( $$switch{ 'image' },
                   $pix->image, $pix->url, $pix->thumb, time() );
}

sub search {
    my $sth = $dbh->prepare( "SELECT * FROM upload where path like ?" );
    $sth->execute( '%' . $$switch{ 'search' } . '%' );
    while ( my $file = $sth->fetchrow_hashref ) {
        render_query( $file );
    }
}

sub check_db {
    if ( !-f $dbfile ) {

        #create database
        print "create database\n";
        open FH, '>' . $dbfile;
        close FH;
        my $sth = $dbh->prepare(
            "CREATE TABLE upload(path varchar(255), image varchar(255), url varchar(255), thumb varchar(255), date_upload datetime)"
        );
        $sth->execute;
    }
}

sub render_query {
    my ( $file )    = @_;
    my @time        = localtime( $file->{ date_upload } );
    my $string_time = ( $time[ 3 ] ) . "/"
        . ( $time[ 4 ] + 1 ) . "/"
        . ( $time[ 5 ] + 1900 ) . " - "
        . $time[ 2 ] . ":"
        . $time[ 1 ] . ":"
        . $time[ 0 ];
    print $file->{ path } . " (" . $string_time . ")\n";
    print "\tURL : " . $file->{ url } . "\n";
    print "\tIMAGE : " . $file->{ image } . "\n";
    print "\tTHUMB : " . $file->{ thumb } . "\n\n";
}
