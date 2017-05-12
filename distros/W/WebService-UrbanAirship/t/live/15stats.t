use strict;
use warnings FATAL => qw(all);

use My::TestUtil;
use IO::File;
use Apache::Test qw(-withtestmore);

My::TestUtil->write_echo();

plan tests => 18;

my $class = qw(My::Subclass);

use_ok($class);

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->stats;

  ok (! $rc,
      'no rc for no date');
}

{
  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $return = $o->stats(start => '2009-06-01 13:00:00',
                         end   => '2009-07-01');

  is ($return,
      'all done!',
      'GET returned successfully');

  my $outfile =  File::Spec->catfile(Apache::Test::vars('serverroot'),
                                     qw(test/output.txt));

  ok (-e $outfile,
      "output file $outfile exists");

  my $fh = IO::File->new($outfile);

  ok ($fh,
      "could open $outfile");

  my $content = do { local $/; <$fh> };

  like ($content,
        qr!\QHTTP_USER_AGENT => WebService::UrbanAirship::APNS/0.\E\d+!,
        "found user agent");
  
  like ($content,
        qr!\QSCRIPT_URL => /api/push/stats/!,
        "found url");
  
  like ($content,
        qr!\QSCRIPT_URI => https://!,
        "request was https");
  
  like ($content,
        qr!\QHTTPS => on!,
        "request was really https");
  
  like ($content,
        qr!\QREQUEST_METHOD => GET!,
        "request was GET");
  
  like ($content,
        qr!\QWSAUTH => Basic a2V5OnB1c2ggc2VjcmV0!,
        "request used application push key for authentication");
  
  like ($content,
        qr!\QQUERY_STRING => start=2009-06-01%2013:00:00&end=2009-07-01!,
        "request had proper query string");
  
  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}

{
  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $return = $o->stats(start  => '2009-06-01 13:00:00',
                         end    => '2009-07-01',
                         format => 'csv');

  is ($return,
      'all done!',
      'GET returned successfully');

  my $outfile =  File::Spec->catfile(Apache::Test::vars('serverroot'),
                                     qw(test/output.txt));

  ok (-e $outfile,
      "output file $outfile exists");

  my $fh = IO::File->new($outfile);

  ok ($fh,
      "could open $outfile");

  my $content = do { local $/; <$fh> };

  like ($content,
        qr!\QQUERY_STRING => start=2009-06-01%2013:00:00&end=2009-07-01&format=csv!,
        "request had proper query string");
  
  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}

