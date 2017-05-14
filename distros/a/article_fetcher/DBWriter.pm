package DBWriter;
use strict;
use warnings;
use DBI();
use DateTime;

sub get_dbh{
    my $class = shift;
    # Connect to the database.
    use Config::Properties;
    open PROPS, "< ora.props"
        or die "unable to open configuration file";
    my $properties = new Config::Properties();
    $properties->load(*PROPS);
    my $host = $properties->getProperty( "host" );
    my $sid = $properties->getProperty( "sid");;
    my $user =  $properties->getProperty( "user" );
    my $password = $properties->getProperty( "password" );
    my $dbh = DBI->connect("dbi:Oracle:host=$host;sid=$sid", $user, $password) || die $!;
    return $dbh;
}

sub insert_news{
    my $class =shift;
    my $dbh  =shift;
    my ($tag,$site_name,$uri, $title, $content)=@_;
    my $dt = DateTime->now;
    $dt->set_time_zone( 'Asia/Shanghai' );
    my $ctime = $dt->ymd." ".$dt->hms;
    my $id;
    my $sth = $dbh->prepare("select seq_all.nextval from dual");
    $sth->execute();
    ($id )=$sth->fetchrow();
#    print $id;
    $sth = $dbh->prepare( q{
        INSERT INTO t_news(id,tag,site_name,uri,title,content,ctime) VALUES (?,?,?,?,?,EMPTY_CLOB(),?)
        });
    use Encode;
    my $rc =$sth->execute($id,$tag,$site_name,$uri, $title,$ctime);
#    print "return code :",$rc,"\n";

    if(length $content ==0){
        return;
    }
    $sth = $dbh->prepare(q(SELECT content FROM t_news WHERE id = ? FOR UPDATE), { ora_auto_lob => 0 } );
    $sth->execute($id);
    my (  $char_locator ) = $sth->fetchrow_array();
    $sth->finish();
    my $offset = 1;   # Offsets start at 1, not 0
    $dbh->ora_lob_write( $char_locator, $offset, $content );
}
sub show_records{
    my $class = shift;
    my $dbh = shift;
    my $sth = $dbh->prepare("select title from t_news");
    $sth->execute();
    while ( my @row = $sth->fetchrow_array ) {
        my ($title) = @row;
        print $title,"\n";
         
    }
}



sub close_dbh {
    my $class = shift;
    my $dbh =shift;
    $dbh->disconnect() ;

}

1;
