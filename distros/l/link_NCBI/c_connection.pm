package connection;

use LWP;
sub Database_Retrieve
{
     my $url1=$_[0];
     $ua = new LWP::UserAgent;
     $ua ->proxy(['http','ftp'],"http://$_[1]");
     $req = new HTTP::Request GET => $url1;
     $req->content_type('application/x-www-form-urlencoded');
     $req->content;
     $res=$ua->request($req);
     if($res->is_success)
     {
          $content=$res->content;
          return $content;
        }
     else
     {
          print "Connection faliure !\n";
     }
}                                                                   

1;

