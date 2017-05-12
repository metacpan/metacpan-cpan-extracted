use strict;
use warnings FATAL => qw(all);

use My::TestUtil;
use IO::File;
use Apache::Test qw(-withtestmore);

My::TestUtil->write_echo();

plan tests => 21;

my $class = qw(My::Subclass);

use_ok($class);

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->batch;

  ok (! $rc,
      'no rc for no device id');
}

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->batch(device_tokens => 5,
                     aliases       => 'string',
                     badge         => 1);

  ok (! $rc,
      'bad arguments - not a href');
}

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->batch({ device_tokens => 5,
                       aliases       => 'string',
                       badge         => 1});

  ok (! $rc,
      'incomplete arguments');
}

{
  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->batch({ device_tokens => [],
                       aliases       => ['my device alias']});

  ok (! $rc,
      'no rc for missing payload');
}

{
  #local $WebService::UrbanAirship::APNS::DEBUG = 1;

  my $o = $class->new(application_key         => 'key',
                      application_secret      => 'secret',
                      application_push_secret => 'push secret');

  my $rc = $o->batch({ device_tokens => [qw(one two)],
                       aliases       => [qw(three four)],
                       badge         => 0});

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
        qr!\QSCRIPT_URL => /api/push/batch!,
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
  
  my $test = '[{"aps":{"badge":0},"aliases":["three","four"],"device_tokens":["one","two"]}]';

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

  my $rc = $o->batch({ device_tokens => [qw(one two)],
                       aliases       => [qw(three four)],
                       badge         => 0},
                     { aliases       => [qw(five six)],
                       alert         => 'gotcha!'},
                    );

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

  my $test = '[{"aps":{"badge":0},"aliases":["three","four"],"device_tokens":["one","two"]},{"aps":{"alert":"gotcha!"},"aliases":["five","six"]}]';

  like ($content,
        qr!\QWSBODY => $test!,
        "found found post body");

  unlink $outfile;

  ok (! -e $outfile,
      "removed $outfile");
}
