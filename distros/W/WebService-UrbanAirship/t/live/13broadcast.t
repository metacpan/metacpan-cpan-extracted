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

  my $rc = $o->broadcast;

  ok (! $rc,
      'no rc for no device id');
}

{
  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->broadcast(badge => 0);

  is ($rc,
      200,
      'POST returned successfully');

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
        qr!\QSCRIPT_URL => /api/push/broadcast!,
        "found url");
  
  like ($content,
        qr!\QSCRIPT_URI => https://!,
        "request was https");
  
  like ($content,
        qr!\QHTTPS => on!,
        "request was really https");
  
  like ($content,
        qr!\QREQUEST_METHOD => POST!,
        "request was POST");
  
  like ($content,
        qr!\QWSAUTH => Basic a2V5OnB1c2ggc2VjcmV0!,
        "request used application push key for authentication");
  
  my $test = '{"aps":{"badge":0}}';

  like ($content,
        qr!\QWSBODY => $test!,
        "found found post body");

  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}

{
  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->broadcast(badge => 3,
                         alert => 'Whoa!',
                         sound => 'annoyme.caf');

  is ($rc,
      200,
      'POST returned successfully');

  my $outfile =  File::Spec->catfile(Apache::Test::vars('serverroot'),
                                     qw(test/output.txt));

  ok (-e $outfile,
      "output file $outfile exists");

  my $fh = IO::File->new($outfile);

  ok ($fh,
      "could open $outfile");

  my $content = do { local $/; <$fh> };

  my $test = '{"aps":{"alert":"Whoa!","badge":3,"sound":"annoyme.caf"}}';

  like ($content,
        qr!\QWSBODY => $test!,
        "found found post body");

  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}
