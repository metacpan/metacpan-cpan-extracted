use strict;
use warnings;
use Test2::V0;
use Test2::Require::Internet;

use lib 't/lib';
use TestTools qw/DEBUG gapi_json user/;
use WebService::GoogleAPI::Client;

my $gapi = WebService::GoogleAPI::Client->new(
  debug     => DEBUG,
  gapi_json => gapi_json,
  user      => user
);

my $options = {
  api_endpoint_id => 'drive.files.list',
  options         => {
    fields => 'files(id,name,parents)'
  }
};

sub build_req {
  $gapi->_process_params(shift);
}

build_req($options);
is $options->{path},
    'https://www.googleapis.com/drive/v3/files?fields=files%28id%2Cname%2Cparents%29',
    'Can interpolate globally available query parameters';

$options = {
  api_endpoint_id => "sheets:v4.spreadsheets.values.update",
  options         => {
    spreadsheetId           => 'sner',
    includeValuesInResponse => 'true',
    valueInputOption        => 'RAW',
    range                   => 'Sheet1!A1:A2',
    'values'                => [ [99], [98] ]
  },
  cb_method_discovery_modify => sub {
    my $meth_spec = shift;
    $meth_spec->{parameters}{valueInputOption}{location} = 'path';
    $meth_spec->{path} .= "?valueInputOption={valueInputOption}";
    return $meth_spec;
  }
};

build_req($options);

is $options->{path},
    'https://sheets.googleapis.com/v4/spreadsheets/sner/values/Sheet1!A1:A2?valueInputOption=RAW&includeValuesInResponse=true',
    'interpolation works with user fiddled path, too';

$options = {
  api_endpoint_id => "sheets:v4.spreadsheets.values.batchGet",
  options         => {
    spreadsheetId => 'sner',
    ranges        => [ 'Sheet1!A1:A2', 'Sheet1!A3:B5' ],
  },
};
build_req($options);
is $options->{path},
    'https://sheets.googleapis.com/v4/spreadsheets/sner/values:batchGet?ranges=Sheet1%21A1%3AA2&ranges=Sheet1%21A3%3AB5',
    'interpolates arrayref correctly';

subtest 'funky stuff in the jobs api' => sub {
  my $endpoint = 'jobs.projects.tenants.jobs.delete';

  subtest 'Testing {+param} type interpolation options' => sub {
    my @errors;
    my $interpolated = 'https://jobs.googleapis.com/v4/projects/sner/tenants/your-fez/jobs';

    $options = {
      api_endpoint_id => $endpoint,
      options         => {
        name => 'projects/sner/tenants/your-fez/jobs/bler'
      }
    };
    @errors = $gapi->_process_params($options);
    is $options->{path}, "$interpolated/bler", 'Interpolates a {+param} that matches the spec pattern', @errors;

    $options->{options} = { projectsId => 'sner', jobsId => 'bler' };
    @errors = $gapi->_process_params($options);

    is $options->{path}, "$interpolated/bler",
        'Interpolates params that match the flatName spec (camelCase)', @errors;

    $options->{options} = { projects_id => 'sner', jobs_id => 'bler' };
    @errors = $gapi->_process_params($options);

    is $options->{path}, "$interpolated/bler",
        'Interpolates params that match the names in the api description (snake_case)',
        @errors;

    $options = {
      api_endpoint_id => 'jobs.projects.tenants.list',
      options         => { parent => 'sner' }
    };
    @errors = $gapi->_process_params($options);
    is $options->{path}, $interpolated =~ s+/your-fez.*$++r,
        'Interpolates just the dynamic part of the {+param}, when not matching the spec pattern',
        @errors;
  };


  subtest 'Checking for proper failure with {+params} in unsupported ways' => sub {
    my @errors;
    $options = {
      api_endpoint_id => $endpoint,
      options         => { name => 'sner' }
    };
    @errors = $gapi->_process_params($options);
    is $errors[0], 'Not enough parameters given for {+name}.',
        "Fails if you don't supply enough values to fill the dynamic parts of {+param}";

    $options = {
      api_endpoint_id => 'jobs.projects.tenants.jobs.list',
      options         => { parent => 'sner' }
    };
    @errors = $gapi->_process_params($options);
    is $errors[0], 'Not enough parameters given for {+parent}.',
        "Fails if you don't supply enough values to fill the dynamic parts of {+param}";

    $options = {
      api_endpoint_id => $endpoint,
      options         => { jobsId => 'sner' }
    };
    @errors = $gapi->_process_params($options);
    is $errors[0], 'Missing a parameter for {projectsId}.',
        "Fails if you don't supply enough values to fill the flatPath";
  };

};


done_testing;
