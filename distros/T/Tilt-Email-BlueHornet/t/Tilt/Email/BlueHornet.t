use Test::Exception;
use Test::MockObject;
use Test::More;
use Tilt::Email::BlueHornet;
use t::lib::Tilt::Test;

my $error_response = <<'RESPONSE';
<methodResponse>
    <item>
        <methodName>transactional.updatetemplate</methodName>
        <error>1</error>
        <responseText>Missing variables</responseText>
        <responseData>
            <missing_vars>group_id</missing_vars>
        </responseData>
        <responseNum>1</responseNum>
        <totalRequests>1</totalRequests>
        <totalCompleted>0</totalCompleted>
    </item>
</methodResponse>
RESPONSE

my $rebuild_template_request = <<'REQUEST';
<api>
  <authentication>
    <api_key>fake_key</api_key>
    <no_halt>0</no_halt>
    <response_type>xml</response_type>
    <shared_secret>fake_secret</shared_secret>
  </authentication>
  <data>
    <methodCall>
      <methodName>transactional.rebuildTemplate</methodName>
      <template_id>1055589</template_id>
    </methodCall>
  </data>
</api>
REQUEST

my $rebuild_template_response = <<'RESPONSE';
<methodResponse>
   <item>
      <methodName>transactional.rebuildTemplate</methodName>
      <responseText>
         <item>Template ID 1055589-test cache has been rebuilt</item>
         <item>Sent Transaction</item>
      </responseText>
      <responseData>
         <template_id>1055589</template_id>
      </responseData>
   </item>
</methodResponse>
RESPONSE

my $send_test_request = <<'REQUEST';
<api>
  <authentication>
    <api_key>fake_key</api_key>
    <no_halt>0</no_halt>
    <response_type>xml</response_type>
    <shared_secret>fake_secret</shared_secret>
  </authentication>
  <data>
    <methodCall>
      <email>jsmith@example.com</email>
      <methodName>transactional.sendTest</methodName>
      <template_id>1055589</template_id>
      <var1>fake var1</var1>
    </methodCall>
  </data>
</api>
REQUEST

my $send_test_response = <<'RESPONSE';
<methodResponse>
   <item>
      <methodName>transactional.sendTest</methodName>
      <responseText>
         <item>Template ID 1055589-test cache has been rebuilt</item>
         <item>Sent Transaction</item>
      </responseText>
      <responseData>
         <template_id>1055589</template_id>
         <email>jsmith@example.com</email>
         <contact_id>test</contact_id>
      </responseData>
   </item>
</methodResponse>
RESPONSE

my $update_template_request = <<'REQUEST';
<api>
  <authentication>
    <api_key>fake_key</api_key>
    <no_halt>0</no_halt>
    <response_type>xml</response_type>
    <shared_secret>fake_secret</shared_secret>
  </authentication>
  <data>
    <methodCall>
      <methodName>transactional.updatetemplate</methodName>
      <subject><![CDATA[fake subject]]></subject>
      <template_data>
        <html><![CDATA[html]]></html>
        <plain><![CDATA[plain text]]></plain>
      </template_data>
      <template_id>1111</template_id>
    </methodCall>
  </data>
</api>
REQUEST

my $update_template_response = <<'RESPONSE';
<methodResponse>
   <item>
      <methodName>transactional.updatetemplate</methodName>
      <responseText>Template ID 1055589 has been updated.</responseText>
      <responseData>
         <template_id>1055589</template_id>
      </responseData>
   </item>
</methodResponse>
RESPONSE

sub _bluehornet {
  return Tilt::Email::BlueHornet->new(
    api_key    => 'fake_key',
    api_secret => 'fake_secret',
    @_
  );
}

sub _mock_successful_response {
  my $mock_response = Test::MockObject->new();
  $mock_response->set_true('is_success');
  $mock_response->set_always('code', 200);
  $mock_response->set_always('decoded_content', shift);
  return $mock_response;
}

sub _mock_http_error_response {
  my $mock_response = Test::MockObject->new();
  $mock_response->set_false('is_success');
  $mock_response->set_always('code', 400);
  $mock_response->set_always('decoded_content', 'decoded data');
  return $mock_response;
}

sub _mock_error_response {
  my $mock_response = Test::MockObject->new();
  $mock_response->set_true('is_success');
  $mock_response->set_always('code', 200);
  $mock_response->set_always('decoded_content', $error_response);
  return $mock_response;
}

sub _ua {
  my $ua_mock = Test::MockObject->new();
  $ua_mock->set_always('post', shift);
  return $ua_mock;
}

subtest 'rebuild_template succeeds' => sub {
  my $ua_mock = _ua _mock_successful_response($rebuild_template_response);
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  ok $bluehornet->rebuild_template(
    template_id => 1055589
  ), 'Successfully rebuilt template';

  is $ua_mock->call_pos(1), 'post',
    'LWP::UserAgent::post is called';
  is_deeply [$ua_mock->call_args(1)],
    [
      $ua_mock,
      'https://echo3.bluehornet.com/api/xmlrpc/index.php',
      Content => $rebuild_template_request,
      'Content-type' => 'application/xml; charset=\'utf8\''
    ],
    'LWP::UserAgent::post is called with the correct arguments';
};

subtest 'rebuild_template fails with HTTP error' => sub {
  my $ua_mock     = _ua _mock_http_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->rebuild_template(
        template_id => 1055589
      );
    }, qr/^BlueHornet API call failed with status 400 decoded data/;
};

subtest 'rebuild_template fails with BlueHornet error' => sub {
  my $ua_mock     = _ua _mock_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->rebuild_template(
        template_id => 1055589
      );
    }, qr/^BlueHornet API call failed with error Missing variables/;
};

subtest 'send_test succeeds' => sub {
  my $ua_mock = _ua _mock_successful_response($send_test_response);
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  ok $bluehornet->send_test(
    template_id => 1055589,
    email       => 'jsmith@example.com',
    var1        => 'fake var1'
  ), 'Successfully sent test';

  is $ua_mock->call_pos(1), 'post',
    'LWP::UserAgent::post is called';
  is_deeply [$ua_mock->call_args(1)],
    [
      $ua_mock,
      'https://echo3.bluehornet.com/api/xmlrpc/index.php',
      Content => $send_test_request,
      'Content-type' => 'application/xml; charset=\'utf8\''
    ],
    'LWP::UserAgent::post is called with the correct arguments';
};

subtest 'send_test fails with HTTP error' => sub {
  my $ua_mock     = _ua _mock_http_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->send_test(
        template_id => 1055589,
        email       => 'jsmith@example.com',
        var1        => 'fake var1'
      );
    }, qr/^BlueHornet API call failed with status 400 decoded data/;
};

subtest 'send_test fails with BlueHornet error' => sub {
  my $ua_mock     = _ua _mock_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->send_test(
        template_id => 1055589,
        email       => 'jsmith@example.com',
        var1        => 'fake var1'
      );
    }, qr/^BlueHornet API call failed with error Missing variables/;
};

subtest 'update_template succeeds' => sub {
  my $ua_mock     = _ua _mock_successful_response($update_template_response);
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  ok $bluehornet->update_template(
    template_id => 1111,
    subject     => 'fake subject',
    html        => 'html',
    plain_text  => 'plain text'
  ), 'Successfully updates template';

  is $ua_mock->call_pos(1), 'post',
    'LWP::UserAgent::post is called';
  is_deeply [$ua_mock->call_args(1)],
    [
      $ua_mock,
      'https://echo3.bluehornet.com/api/xmlrpc/index.php',
      Content => $update_template_request,
      'Content-type' => 'application/xml; charset=\'utf8\''
    ],
    'LWP::UserAgent::post is called with the correct arguments';
};

subtest 'update_template fails with HTTP error' => sub {
  my $ua_mock     = _ua _mock_http_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->update_template(
        template_id => 1111,
        subject     => 'fake subject',
        html        => 'html',
        plain_text  => 'plain text'
      );
    }, qr/^BlueHornet API call failed with status 400 decoded data/;
};

subtest 'update_template fails with BlueHornet error' => sub {
  my $ua_mock     = _ua _mock_error_response;
  my $bluehornet  = _bluehornet(ua => $ua_mock);

  throws_ok sub {
      $bluehornet->update_template(
        template_id => 1111,
        subject     => 'fake subject',
        html        => 'html',
        plain_text  => 'plain text'
      );
    }, qr/^BlueHornet API call failed with error Missing variables/;
};

done_testing;
