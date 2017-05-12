package Testing::Result;

use Test::Roo::Role;

use Scalar::Util 'blessed';

use Devel::Cycle 'find_cycle';

use Weather::OpenWeatherMap::Test;
use Test::File::ShareDir -share => {
  -dist => { 'Weather-OpenWeatherMap' => 'share' },
};


requires 'request_obj', 'result_obj', 'mock_json';


sub get_mock_json {
  my ($self, $type) = @_;
  get_test_data($type)
}

test 'handles API errors' => sub {
  my ($self) = @_;

  my $class = blessed $self->result_obj;
  my $mockjs = $self->get_mock_json('failure');

  my $res = $class->new(
    request => $self->request_obj,
    json    => $mockjs
  );

  ok !$res->is_success, 'is_success false';
  cmp_ok $res->response_code, '==', 404,
    'failure response_code ok';
  cmp_ok $res->error, 'eq', 'Not found',
    'error ok';
};

test 'missing constructor args' => sub {
  my ($self) = @_;
  my $class = blessed $self->result_obj;

  eval {; 
    $class->new(
      json => $self->mock_json
    )
  };
  like $@, qr/request/, 'missing request dies';

  eval {;
    $class->new(
      json    => $self->mock_json,
      request => 1,
    )
  };
  like $@, qr/request/, 'bad request dies';

  eval {;
    $class->new(
      request => $self->request_obj
    )
  };
  like $@, qr/json/, 'missing json dies';
};

test 'data hash has keys' => sub {
  my ($self) = @_;
  ok !$self->result_obj->data->is_empty
};

test 'error is false' => sub {
  my ($self) = @_;
  ok !$self->result_obj->error
};

test 'is_success is true' => sub {
  my ($self) = @_;
  ok $self->result_obj->is_success
};

test 'json looks correct' => sub {
  my ($self) = @_;
  ok $self->result_obj->json eq $self->mock_json
};

test 'response_code indicates success' => sub {
  my ($self) = @_;
  cmp_ok $self->result_obj->response_code, '==', 200
};

test 'request objects match' => sub {
  my ($self) = @_;
  ok $self->result_obj->request == $self->request_obj
};

test 'no memory cycles' => sub {
  my ($self) = @_;
  my $found = 0;
  find_cycle( $self->result_obj,
    sub { 
      ++$found;
      diag explain @_
    }
  ); 
  ok !$found, 'no memory cycles found';
};

1;
