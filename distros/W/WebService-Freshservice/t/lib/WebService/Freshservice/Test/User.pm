package WebService::Freshservice::Test::User;

use Dancer2;
use Scalar::Util 'reftype';
use Storable 'dclone';

our $putuser;

get '/agents/:id' => sub {
  if ( params->{id} eq '9999999999.json' ) {
    send_error('{"errors":{"error":"Record Not Found"}}', 404);
  }
  
  my $agent->{agent}    = config->{testdata}{agent};
  $agent->{agent}{user} = config->{testdata}{user};
  $agent->{agent}{user}{email} = 'agent@example.com';
  return $agent;
};

get '/agents.json' => sub {
  my $params = params;
  my $agent->{agent} = config->{testdata}{agent};
  $agent->{agent}{user} = config->{testdata}{user};
  my @query;
  if ( defined $params->{query} ) {
    @query = reftype \$params->{query} ne "SCALAR" ? @{$params->{query}} : $params->{query};
  }

  if ( 0+@query > 0 ) {
    foreach my $query (@query) {
      $query =~ /^(?<key>\w+)\sis\s(?<value>.+)$/;
      $agent->{agent}{user}{$+{key}} = $+{value};
    }
  }

  return [ $agent ];
};

post '/itil/requesters.json' => sub {
  my $user->{user} = config->{testdata}{user};
  return $user;
};

get '/itil/requesters/:id' => sub {
  if ( params->{id} eq '9999999999.json' ) {
    send_error('{"errors":{"error":"Record Not Found"}}', 404);
  }
 
  # Custom field testing 
  if ( params->{id} eq '1337.json' ) {
    $putuser->{user} = $putuser->{user} ? $putuser->{user} : dclone config->{testdata}{user};
    return $putuser;
  }
  if ( params->{id} eq '1338.json' ) {
    $putuser->{user} = $putuser->{user} ? $putuser->{user} : dclone config->{testdata}{user};
    $putuser->{user}{custom_field} = { };
    return $putuser;
  }

  my $user->{user} = config->{testdata}{user};
  return $user;
};

get '/itil/requesters.json' => sub {
  my $params = params;
  my $state = defined $params->{state} ? $params->{state} : "all";
  my $page = defined $params->{page} ? $params->{page} : 1;
  my @query;
  if ( defined $params->{query} ) {
    @query = reftype \$params->{query} ne "SCALAR" ? @{$params->{query}} : $params->{query};
  }

  my $user->{user} = config->{testdata}{user};
  $user->{user}{deleted}  = true if $state eq "deleted";
  $user->{user}{active}   = false if $state eq "unverified";
  $user->{user}{name}     = "Page $page" if $page > 1;
  
  if ( 0+@query > 0 ) {
    foreach my $query (@query) {
      $query =~ /^(?<key>\w+)\sis\s(?<value>.+)$/;
      $user->{user}{$+{key}} = $+{value};
    }
    return [ ] if $user->{user}{email} eq 'croak@example.com';
    return [ $user ];
  }
  
  my $users;
  push(@{$users}, $user);
  my $user2->{user} = dclone config->{testdata}{user};
  $user2->{user}{name}  = "Test 2";
  $user2->{user}{id}    = "0987654321";
  $user2->{user}{email} = 'test.2@example.com';
  push(@{$users}, $user2);
  return $users;
};

put '/itil/requesters/:id' => sub {
  my $data = from_json(request->body);
  $putuser->{user} = $putuser->{user} ? $putuser->{user} : dclone config->{testdata}{user};
  while ( my ( $key, $value ) = each %{ $data->{user} }) {
    $putuser->{user}{$key} = $value; 
  }
  return;
};

del '/itil/requesters/:id' => sub {
  send_as html => "deleted";
};

any '/invalid' => sub {
  send_as html => '{ invalid json }';
};

any '/error' => sub {
  send_error('{"errors":{"error":"Generic Error"}}', 404);
};

1;
