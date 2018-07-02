package voiceIt::voiceIt2;
use 5.006;
use strict;
use warnings;
require LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use HTTP::Request::Common qw(DELETE);
use HTTP::Request::Common qw(PUT);
use HTTP::Request::Common qw(GET);

my $self;
my $baseUrl = 'https://api.voiceit.io/';
my $apiKey;
my $apiToken;


sub new {
    my $package = shift;
    ($apiKey, $apiToken) = @_;
    $self = bless({apiKey => $apiKey, apiToken => $apiToken}, $package);
    return $self;
  }

  sub getAllUsers() {
    shift;
    my $ua = LWP::UserAgent->new();
    my $request = GET $baseUrl.'users';
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }

  sub createUser() {
    shift;
    my $ua = LWP::UserAgent->new();
    my $request = POST $baseUrl.'users';
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }

  sub getUser(){
    shift;
    my ($usrId) = @_;
    my $ua = LWP::UserAgent->new();
    my $request = GET $baseUrl.'users/'.$usrId;
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }

  sub deleteUser(){
    shift;
    my ($usrId) = @_;
    my $ua = LWP::UserAgent->new();
    my $request = DELETE $baseUrl.'users/'.$usrId;
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }

  sub getGroupsForUser(){
    shift;
    my ($usrId) = @_;
    my $ua = LWP::UserAgent->new();
    my $request = GET $baseUrl.'users/'.$usrId.'/groups';
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }

  sub getAllGroups(){
    shift;
    my $ua = LWP::UserAgent->new();
    my $request = GET $baseUrl.'groups';
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
  }


  sub getGroup(){
    shift;
    my ($groupId) = @_;
    my $ua = LWP::UserAgent->new();
    my $request = GET $baseUrl.'groups/'.$groupId;
    $request->authorization_basic($apiKey, $apiToken);
    my $reply = $ua->request($request);
     if ($reply->is_success){
       print "successs: ";
        return $reply->content();
    }
    elsif ($reply->is_error){
      print "error: ";
      return $reply->content().' status code: '.$reply->status_line;
    }
}

sub groupExists(){
  shift;
  my ($groupId) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = GET $baseUrl.'groups/'.$groupId.'/exists';
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub createGroup(){
  shift;
  my ($des)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/groups', Content => [
      description => $des
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub addUserToGroup(){
  shift;
  my ($grpId, $usrId)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = PUT $baseUrl.'/groups/addUser',
    Content => [
        groupId => $grpId,
        userId => $usrId,
    ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub removeUserFromGroup(){
  shift;
  my ($grpId, $usrId)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = PUT $baseUrl.'/groups/removeUser',
    Content => [
        groupId => $grpId,
        userId => $usrId,
    ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub deleteGroup(){
  shift;
  my ($grpId)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = DELETE $baseUrl.'/groups/'.$grpId;
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub getAllEnrollmentsForUser(){
  shift;
  my ($usrId)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = GET $baseUrl.'/enrollments/'.$usrId;
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub getAllFaceEnrollmentsForUser(){
  shift;
  my ($usrId)= @_;
  my $ua = LWP::UserAgent->new();
  my $request = GET $baseUrl.'/enrollments/face/'.$usrId;
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub createVoiceEnrollment(){
  shift;
  my ($usrId, $lang, $filePath) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/enrollments', Content_Type => 'form-data',  Content => [
        recording => [$filePath],
        userId => $usrId,
        contentLanguage => $lang,
    ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub createVoiceEnrollmentByUrl(){
  shift;
  my ($usrId, $lang, $fileUrl) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/enrollments/byUrl', Content_Type => 'form-data',  Content => [
        fileUrl => $fileUrl,
        userId => $usrId,
        contentLanguage => $lang,
    ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub createFaceEnrollment(){
  shift;
  my $blink = 0;
  my ($usrId, $filePath, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/enrollments/face', Content_Type => 'form-data',  Content => [
        video => [$filePath],
        userId => $usrId,
        doBlinkDetection => $blink
    ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub createVideoEnrollment(){
  shift;
  my $blink = 0;
  my ($usrId, $lang, $filePath, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/enrollments/video', Content_Type => 'form-data', Content => [
        video => [$filePath],
        userId => $usrId,
        contentLanguage => $lang,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}


sub deleteFaceEnrollment(){
  shift;
  my ($usrId, $faceEnrollmentId) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = DELETE $baseUrl.'/enrollments/face'.$usrId."/".$faceEnrollmentId, Content_Type => 'form-data';
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}


sub deleteEnrollment(){
  shift;
  my ($usrId, $enrollmentId) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = DELETE $baseUrl.'enrollments/'.$usrId."/".$enrollmentId, Content_Type => 'form-data';
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub voiceVerification(){
  shift;
  my ($usrId, $lang, $filePath) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/verification', Content_Type => 'form-data', Content => [
        recording => [$filePath],
        userId => $usrId,
        contentLanguage => $lang,
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub voiceVerificationByUrl(){
  shift;
  my ($usrId, $lang, $fileUrl) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/verification/byUrl', Content_Type => 'form-data', Content => [
        fileUrl => $fileUrl,
        userId => $usrId,
        contentLanguage => $lang,
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub faceVerification(){
  shift;
  my $blink = 0;
  my ($usrId, $filePath, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/verification/face', Content_Type => 'form-data', Content => [
        video => [$filePath],
        userId => $usrId,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub videoVerification(){
  shift;
  my $blink = 0;
  my ($usrId, $lang, $filePath, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/verification/video', Content_Type => 'form-data', Content => [
        video => [$filePath],
        userId => $usrId,
        contentLanguage => $lang,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}


sub videoVerificationByUrl(){
  shift;
  my $blink = 0;
  my ($usrId, $lang, $fileUrl, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/verification/video/byUrl', Content_Type => 'form-data', Content => [
        fileUrl => $fileUrl,
        userId => $usrId,
        contentLanguage => $lang,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub voiceIdentification(){
  shift;
  my ($grpId, $lang, $filePath) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/identification', Content_Type => 'form-data', Content => [
        recording => [$filePath],
        groupId => $grpId,
        contentLanguage => $lang,
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub voiceIdentificationByUrl(){
  shift;
  my ($grpId, $lang, $fileUrl) = @_;
  my $ua = LWP::UserAgent->new();
  my $request = POST $baseUrl.'/identification/byUrl', Content_Type => 'form-data', Content => [
        fileUrl => $fileUrl,
        groupId => $grpId,
        contentLanguage => $lang,
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

sub videoIdentification(){
  shift;
  my $blink = 0;
  my ($grpId, $lang, $filePath, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/identification/video', Content_Type => 'form-data', Content => [
        video => [$filePath],
        groupId => $grpId,
        contentLanguage => $lang,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}


sub videoIdentificationByUrl(){
  shift;
  my $blink = 0;
  my ($grpId, $lang, $fileUrl, $doBlink) = @_;
  my $ua = LWP::UserAgent->new();
  if($doBlink){
    $blink = $doBlink;
  }
  my $request = POST $baseUrl.'/identification/video/byUrl', Content_Type => 'form-data', Content => [
        fileUrl => $fileUrl,
        groupId => $grpId,
        contentLanguage => $lang,
        doBlinkDetection => $blink
  ];
  $request->authorization_basic($apiKey, $apiToken);
  my $reply = $ua->request($request);
   if ($reply->is_success){
     print "successs: ";
      return $reply->content();
  }
  elsif ($reply->is_error){
    print "error: ";
    return $reply->content().' status code: '.$reply->status_line;
  }
}

1;
