package WWW::StatsMix;

$WWW::StatsMix::VERSION = '0.07';

=head1 NAME

WWW::StatsMix - Interface to StatsMix API.

=head1 VERSION

Version 0.07

=cut

use 5.006;
use JSON;
use Data::Dumper;

use WWW::StatsMix::Stat;
use WWW::StatsMix::Metric;
use WWW::StatsMix::UserAgent;
use WWW::StatsMix::Params qw(validate);

use Moo;
use namespace::clean;
extends 'WWW::StatsMix::UserAgent';

has format      => (is => 'ro', default => sub { return 'json' });
has metrics_url => (is => 'ro', default => sub { return 'http://api.statsmix.com/api/v2/metrics' });
has stats_url   => (is => 'ro', default => sub { return 'http://api.statsmix.com/api/v2/stats'   });
has track_url   => (is => 'ro', default => sub { return 'http://api.statsmix.com/api/v2/track'   });

=head1 DESCRIPTION

StatsMix provides an API that can be used to create, retrieve, update, and delete
metrics and stats resources. The API is built using RESTful principles.

The current version is 2.0.

To get an API key, you can sign up for a free Developer account L<here|http://www.statsmix.com/try?plan=developer>.

If you go over the number of API requests available to your account, the API will
return a 403 Forbidden error and an explanation. The number of API  requests  and
profiles  you  can  create is based on the type of account you have. For example,
Standard plans are limited to 300,000 API requests per month.

=head1 SYNOPSIS

    Use Strict; use warnings;
    use WWW::StatsMix;

    my $API_KEY = "Your API Key";
    my $api     = WWW::StatsMix->new(api_key => $API_KEY);

    my $metric_1 = $api->create_metric({ name => "Testing - 1" });
    my $metric_2 = $api->create_metric({ name => "Testing - 2", include_in_email => 0 });
    $api->update_metric($metric_2->id, { name => "Testing - 3", include_in_email => 1 });

    my $metrics  = $api->get_metrics;
    my $only_2   = $api->get_metrics({ limit => 2 });

=head1 METHODS

=head2 create_metric(\%params)

It creates new metric and returns the object of type L<WWW::StatsMix::Metric>.The
possible parameters for the method are as below:

   +------------------+---------------------------------------------------------+
   | Key              | Description                                             |
   +------------------+---------------------------------------------------------+
   | name             | The name of the metric. Metric names must be unique     |
   | (required)       | within a profile.                                       |
   |                  |                                                         |
   | profile_id       | The profile the metric belongs in.                      |
   | (optional)       |                                                         |
   |                  |                                                         |
   | sharing          | Sharing status for the metric. Either "public"          |
   | (optional)       | (unauthenticated users can view the metric at the       |
   |                  | specific URL) or "none" (default).                      |
   |                  |                                                         |
   | include_in_email | This specifies whether to include the metric in the     |
   | (optional)       | daily StatsMix email sent to users.                     |
   |                  |                                                         |
   | url              | Publicly accessible URL for the metric (only if sharing |
   | (optional)       | is set to "public").                                    |
   +------------------+---------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY = "Your_API_Key";
   my $api     = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric  = $api->create_metric({ name => "Testing API - 2" });

   print "Id: ", $metric->id, "\n";

=cut

sub create_metric {
    my ($self, $params) = @_;

    my $data = [
        { key => 'name'             , required => 1 },
        { key => 'profile_id'       , required => 0 },
        { key => 'url'              , required => 0 },
        { key => 'sharing'          , required => 0 },
        { key => 'include_in_email' , required => 0 },
        { key => 'format'           , required => 0 },
    ];
    validate($data, $params);

    if (exists $params->{sharing}
        && defined $params->{sharing}
        && ($params->{sharing} =~ /\bpublic\b/i)) {
        die "ERROR: Missing key 'url' since 'sharing' is provided."
            unless (exists $params->{url});
    }
    if (exists $params->{url} && defined $params->{url}) {
        die "ERROR: Missing key 'sharing' since 'url' is provided."
            unless (exists $params->{sharing});
    }

    $params->{format} = $self->format
        unless (exists $params->{format} && defined $params->{format});

    my $response = $self->post($self->metrics_url, [ %$params ]);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Metric->new($content->{metric});
}

=head2 update_metric($metric_id, \%params)

It updates the metric & returns the object of type L<WWW::StatsMix::Metric>. This
requires mandatory param 'metric_id' and atleast one of the following key as  ref
to hash format data. Possible parameters are as below:

   +------------------+---------------------------------------------------------+
   | Key              | Description                                             |
   +------------------+---------------------------------------------------------+
   | name             | The name of the metric. Metric names must be unique     |
   |                  | within a profile.                                       |
   |                  |                                                         |
   | sharing          | Sharing status for the metric. Either "public"          |
   |                  | (unauthenticated users can view the metric at the       |
   |                  | specific URL) or "none" (default).                      |
   |                  |                                                         |
   | include_in_email | This specifies whether to include the metric in the     |
   |                  | daily StatsMix email sent to users.                     |
   |                  |                                                         |
   | url              | Publicly accessible URL for the metric (only if sharing |
   |                  | is set to "public").                                    |
   +------------------+---------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY   = "Your_API_Key";
   my $api       = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id = <your_metric_id>;
   my $metric    = $api->update_metric($metric_id, { name => "Testing API - new" });

   print "Name: ", $metric->name, "\n";

=cut

sub update_metric {
    my ($self, $id, $params) = @_;

    die "ERROR: Missing the required metric id."  unless defined $id;
    die "ERROR: Invalid metric id [$id]."         unless ($id =~ /^\d+$/);

    if (defined $params && ref($params) eq 'HASH') {
        my $data = [
            { key => 'name'             , required => 0 },
            { key => 'url'              , required => 0 },
            { key => 'sharing'          , required => 0 },
            { key => 'include_in_email' , required => 0 },
        ];

        validate($data, $params);

        die "ERROR: Missing keys to update." unless (scalar(keys %$params));

        if (exists $params->{sharing}
            && defined $params->{sharing}
            && ($params->{sharing} =~ /\bpublic\b/i)) {
            die "ERROR: Invalid data for key 'url'."
                unless (exists $params->{url} && defined $params->{url});
        }
        if (exists $params->{url} && defined $params->{url}) {
            die "ERROR: Invalid data for key 'sharing'."
                unless (exists $params->{sharing}
                        && defined $params->{sharing}
                        && ($params->{sharing} =~ /\bpublic\b/i));
        }
    }
    else {
        die "ERROR: Parameters have to be hash ref.";
    }

    my $url      = sprintf("%s/%d.json", $self->metrics_url, $id);
    my $response = $self->put($url, [ %$params ]);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Metric->new($content->{metric});
}

=head2 delete_metric($metric_id)

It deletes the metric and returns the object of type L<WWW::StatsMix::Metric>. It
requires mandatory 'metric_id'.

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY   = "Your_API_Key";
   my $api       = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id = <your_metric_id>;
   my $metric    = $api->delete_metric($metric_id);

   print "Name: ", $metric->name, "\n";

=cut

sub delete_metric {
    my ($self, $id) = @_;

    die "ERROR: Missing the required key metric id."       unless defined $id;
    die "ERROR: Invalid the required key metric id [$id]." unless ($id =~ /^\d+$/);

    my $url      = sprintf("%s/%d.json", $self->metrics_url, $id);
    my $response = $self->delete($url);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Metric->new($content->{metric});
}

=head2 get_metrics(\%params)

The method get_metrics() will return a default of up to 50 records. The parameter
limit  can  be  passed  to specify the number of records to return. The parameter
profile_id  can also be used to scope records to a particular profile. Parameters
start_date &  end_date can be used to limit the date range based on the timestamp
in a stat's generated_at.
The result of the call is reference to list of L<WWW::StatsMix::Metric> objects.

   +------------+---------------------------------------------------------------+
   | Key        | Description                                                   |
   +------------+---------------------------------------------------------------+
   | limit      | Limit the number of metrics. Default is 50.                   |
   | (optional) |                                                               |
   |            |                                                               |
   | profile_id | Scope the search to a particular profile.                     |
   | (optional) |                                                               |
   |            |                                                               |
   | start_date | Limit the searh in date range against stats generated_at key. |
   | / end_date | Valid format is YYYY-MM-DD.                                   |
   | (optional) |                                                               |
   +------------+---------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY    = "Your_API_Key";
   my $api        = WWW::StatsMix->new(api_key => $API_KEY);
   my $profile_id = <your_profile_id>;
   my $limit      = <your_limit_count>;

   my $metrics_all        = $api->get_metrics;
   my $metrics_by_limit   = $api->get_metrics({ limit      => $limit      });
   my $metrics_by_profile = $api->get_metrics({ profile_id => $profile_id });

=cut

sub get_metrics {
    my ($self, $params) = @_;

    my $url = sprintf("%s?format=%s", $self->metrics_url, $self->format);
    if (defined $params) {
        my $data = [
            { key => 'limit'     , required => 0 },
            { key => 'profile_id', required => 0 },
            { key => 'start_date', required => 0 },
            { key => 'end_date'  , required => 0 },
        ];
        validate($data, $params);

        if (exists $params->{start_date} && defined $params->{start_date}) {
            die "ERROR: Missing param key 'end_date'."
                unless (exists $params->{end_date} && defined $params->{end_date});
            die "ERROR: Invalid param key 'start_date'."
                unless _is_valid_date($params->{start_date});
            die "ERROR: Invalid param key 'end_date'."
                unless _is_valid_date($params->{end_date});
        }
        elsif (exists $params->{end_date} && defined $params->{end_date}) {
            die "ERROR: Missing param key 'start_date'."
                unless (exists $params->{start_date} && defined $params->{start_date});
        }

        foreach (qw(limit profile_id start_date end_date)) {
            if (exists $params->{$_} && defined $params->{$_}) {
                $url .= sprintf("&%s=%s", $_, $params->{$_});
            }
        }
    }

    my $response = $self->get($url);
    my $content  = from_json($response->content);

    return _get_metrics($content);
}

=head2 create_stat(\%params)

The  method  create_stat() creates stat for the given metric. You can also create
stat with ref_id. It returns an object of type L<WWW::StatsMix::Stat>.

   +--------------+-------------------------------------------------------------+
   | Key          | Description                                                 |
   +--------------+-------------------------------------------------------------+
   | metric_id    | The metric id for which the stat would be created.          |
   | (required)   |                                                             |
   |              |                                                             |
   | value        | The numeric value of the stat with a decimal precision of   |
   | (required)   | two. Decimal (up to 11 digits on the left side of the       |
   |              | decimal point, two on the right).                           |
   |              |                                                             |
   | generated_at | Datetime for the stat. If not set, defaults to the current. |
   | (optional)   | timestamp. This is the datetime to be used in the charts.   |
   |              | Valid format is YYYY-MM-DD.                                 |
   |              |                                                             |
   | meta         | hash ref data (key,value pair) about anything associated    |
   | (optional)   | with the stat.                                              |
   |              |                                                             |
   | ref_id       | Optional reference id for a stat. If a stat already exists  |
   | (optional)   | for the named metric and the given ref_id, the value (and   |
   |              | optionally generated_at and meta) will be updated instead of|
   |              | created.                                                    |
   +--------------+-------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY   = "Your_API_Key";
   my $api       = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id = <your_metric_id>;
   my $value     = <your_new_stat_value>;
   my $params    = { metric_id => $metric_id, value => $value };
   my $stat      = $api->create_stat($params);

   print "Id: ", $stat->id, "\n";

=cut

sub create_stat {
    my ($self, $params) = @_;

    my $data = [
        { key => 'metric_id'   , required => 1 },
        { key => 'value'       , required => 1 },
        { key => 'generated_at', required => 0 },
        { key => 'meta'        , required => 0 },
        { key => 'ref_id'      , required => 0 }
    ];
    validate($data, $params);

    if (exists $params->{meta} && defined $params->{meta}) {
        die "ERROR: Invalid data format for key 'meta'."
            unless (ref($params->{meta}) eq 'HASH');
        $params->{meta} = to_json($params->{meta});
    }

    $params->{format} = $self->format;
    my $response = $self->post($self->stats_url, [ %$params ]);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Stat->new($content->{stat});
}

=head2 get_stat($metric_id, \%params)

Returns the stat details of the given stat of the metric. The stat can  be either
search by stat id or ref id. The return data is of type L<WWW::StatsMix::Stat>.It
requires  mandatory  key  'metric_id'. If both 'id' and 'ref_id' are defined then
'id' takes the precedence.

   +--------+-------------------------------------------------------------------+
   | Key    | Description                                                       |
   +--------+-------------------------------------------------------------------+
   | id     | Id of the stat. Required only if 'ref_id' is undefined.           |
   |        |                                                                   |
   | ref_id | Ref id of the stat. Required only if 'id' is undefined.           |
   +--------+-------------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY     = "Your_API_Key";
   my $api         = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id   = <your_metric_id>;
   my $stat_id     = <your_metric_stat_id>;
   my $stat_ref_id = <your_metric_stat_ref_id>;

   my $stat_by_id     = $api->get_stat($metric_id, { id     => $stat_id     });
   my $stat_by_ref_id = $api->get_stat($metric_id, { ref_id => $stat_ref_id });

   print "Stat by Id (name)    : ", $stat_by_id->name,     "\n";
   print "Stat by Ref Id (name): ", $stat_by_ref_id->name, "\n";

=cut

sub get_stat {
    my ($self, $metric, $params) = @_;

    die "ERROR: Missing the required key metric id."           unless defined $metric;
    die "ERROR: Invalid the required key metric id [$metric]." unless ($metric =~ /^\d+$/);

    my $data = [
        { key => 'id'    , required => 0 },
        { key => 'ref_id', required => 0 }
    ];
    validate($data, $params);

    my $id       = _get_id($params);
    my $url      = sprintf("%s/%d.json?metric_id=%d", $self->stats_url, $id, $metric);
    my $response = $self->get($url);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Stat->new($content->{stat});
}

=head2 update_stat($metric_id, \%params)

Update the stat of the metric.Stat can be located by stat id or ref id.Parameters
for the method are as below. The return data is of type L<WWW::StatsMix::Stat>.It
requires mandatory key 'metric_id' and params as hash ref. Following keys can  be
passed  in  hash ref. If  both  'id' and 'ref_id' are defined then 'id' takes the
precedence.

   +------------+---------------------------------------------------------------+
   | Key        | Description                                                   |
   +------------+---------------------------------------------------------------+
   | value      | The numeric value of the stat with a decimal precision of two.|
   | (required) | Decimal (up to 11 digits on the left side of the decimal      |
   |            | point, two on the right).                                     |
   |            |                                                               |
   | id         | Id of the stat. Required only if 'ref_id' is undefined.       |
   |            |                                                               |
   | ref_id     | Ref id of the stat. Required only if 'id' is undefined.       |
   +------------+---------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY     = "Your_API_Key";
   my $api         = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id   = <your_metric_id>;
   my $value       = <your_stat_new_value>;
   my $stat_id     = <your_metric_stat_id>;
   my $stat_ref_id = <your_metric_stat_ref_id>;

   my $stat_by_id     = $api->update_stat($metric_id, { id     => $stat_id,     value => $value });
   my $stat_by_ref_id = $api->update_stat($metric_id, { ref_id => $stat_ref_id, value => $value });

   print "Stat by Id (value)    : ", $stat_by_id->value,     "\n";
   print "Stat by Ref Id (value): ", $stat_by_ref_id->value, "\n";

=cut

sub update_stat {
    my ($self, $metric, $params) = @_;

    die "ERROR: Missing the required key metric id."           unless defined $metric;
    die "ERROR: Invalid the required key metric id [$metric]." unless ($metric =~ /^\d+$/);

    my $data = [
        { key => 'value' , required => 1 },
        { key => 'id'    , required => 0 },
        { key => 'ref_id', required => 0 }
    ];
    validate($data, $params);

    my $id       = _get_id($params);
    my $value    = _get_value($params);
    my $_data    = { metric_id => $metric, value => $value };
    my $url      = sprintf("%s/%d.json", $self->stats_url, $id);
    my $response = $self->put($url, [ %$_data ]);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Stat->new($content->{stat});
}

=head2 delete_stat($metric_id, \%params)

Delete the stat of the metric.Stat can be located by stat id or ref id.Parameters
for the method are as below. The return data is of type L<WWW::StatsMix::Stat>.It
requires mandatory key 'metric_id' and params as hash ref. The hash  ref can have
either 'id' or 'ref_id'. If both specified then 'id' takes the precedence.

   +--------+-------------------------------------------------------------------+
   | Key    | Description                                                       |
   +--------+-------------------------------------------------------------------+
   | id     | Id of the stat. Required only if 'ref_id' is undefined.           |
   |        |                                                                   |
   | ref_id | Ref id of the stat. Required only if 'id' is undefined.           |
   +--------+-------------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY     = "Your_API_Key";
   my $api         = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id   = <your_metric_id>;
   my $stat_id     = <your_metric_stat_id>;
   my $stat_ref_id = <your_metric_stat_ref_id>;

   my $stat_by_id     = $api->delete_stat($metric_id, { id     => $stat_id     });
   my $stat_by_ref_id = $api->delete_stat($metric_id, { ref_id => $stat_ref_id });

=cut

sub delete_stat {
    my ($self, $metric, $params) = @_;

    die "ERROR: Missing the required key metric id."           unless defined $metric;
    die "ERROR: Invalid the required key metric id [$metric]." unless ($metric =~ /^\d+$/);

    my $data = [
        { key => 'id'    , required => 0 },
        { key => 'ref_id', required => 0 }
    ];
    validate($data, $params);

    my $id       = _get_id($params);
    my $url      = sprintf("%s/%d.json?metric_id=%d", $self->stats_url, $id, $metric);
    my $response = $self->delete($url);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Stat->new($content->{stat});
}

=head2 get_stats(\%params)

The method get_stats() will return a default of up to 50  records.  The parameter
limit  can  be  passed  to specify the number of records to return. The parameter
metric_id  can also be used to scope records to a particular profile. Parameters
start_date &  end_date can be used to limit the date range based on the timestamp
in a stat's generated_at.

   +------------+---------------------------------------------------------------+
   | Key        | Description                                                   |
   +------------+---------------------------------------------------------------+
   | limit      | Limit the number of metrics. Default is 50.                   |
   | (optional) |                                                               |
   |            |                                                               |
   | metric_id  | Scope the search to a particular metric.                      |
   | (optional) |                                                               |
   |            |                                                               |
   | start_date | Limit the searh in date range against stats generated_at key. |
   | / end_date | Valid format is YYYY-MM-DD.                                   |
   | (optional) |                                                               |
   +------------+---------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY   = "Your_API_Key";
   my $api       = WWW::StatsMix->new(api_key => $API_KEY);
   my $metric_id = <your_metric_id>;
   my $limit     = <your_limit_count>;

   my $stats = $api->get_stats();
   my $stats_by_metric = $api->get_stats({ metric_id => $metric_id });
   my $stats_by_metric_by_limit = $api->get_stats({ metric_id => $metric_id, limit => $limit });

=cut

sub get_stats {
    my ($self, $params) = @_;

    my $url = sprintf("%s?format=%s", $self->stats_url, $self->format);
    if (defined $params) {
        my $data = [
            { key => 'limit'     , required => 0 },
            { key => 'metric_id' , required => 0 },
            { key => 'start_date', required => 0 },
            { key => 'end_date'  , required => 0 },
        ];
        validate($data, $params);

        if (exists $params->{start_date} && defined $params->{start_date}) {
            die "ERROR: Missing param key 'end_date'."
                unless (exists $params->{end_date} && defined $params->{end_date});
            die "ERROR: Invalid param key 'start_date'."
                unless _is_valid_date($params->{start_date});
            die "ERROR: Invalid param key 'end_date'."
                unless _is_valid_date($params->{end_date});
        }
        elsif (exists $params->{end_date} && defined $params->{end_date}) {
            die "ERROR: Missing param key 'start_date'."
                unless (exists $params->{start_date} && defined $params->{start_date});
        }

        foreach (qw(limit metric_id start_date end_date)) {
            if (exists $params->{$_} && defined $params->{$_}) {
                $url .= sprintf("&%s=%s", $_, $params->{$_});
            }
        }
    }

    my $response = $self->get($url);
    my $content  = from_json($response->content);

    return _get_stats($content);
}

=head2 track(\%params)

It combines the functions create_stat() and create_metric() (if necessary) into a
single method call. If no value is passed, the default of 1 is returned.  Returns
an object of type L<WWW::StatsMix::Stat>.

   +--------------+-------------------------------------------------------------+
   | Key          | Description                                                 |
   +--------------+-------------------------------------------------------------+
   | name         | The name of the metric you are tracking. If a metric with   |
   | (required)   | that name does not exist in your account, one will be       |
   |              | created automatically,                                      |
   |              |                                                             |
   | value        | The numeric value of the stat with a decimal precision of   |
   | (optional)   | two. Decimal (up to 11 digits on the left side of the       |
   |              | decimal point, two on the right). If missing default value  |
   |              | 1 is assigned.                                              |
   |              |                                                             |
   | generated_at | Datetime for the stat. If not set, defaults to the current  |
   | (optional)   | timestaamp. This is the datetime to be used in the charts.  |
   |              | Valid format is YYYY-MM-DD.                                 |
   |              |                                                             |
   | meta         | hashref data (key,value pair) about anything associated with|
   | (optional)   | the stat.                                                   |
   |              |                                                             |
   | ref_id       | Optional reference id for a stat. If a stat already exists  |
   | (optional)   | for the named metric and the given ref_id, the value (and   |
   |              | optionally generated_at and meta) will be updated instead of|
   |              | created.                                                    |
   |              |                                                             |
   | profile_id   | The unique id of the profile this stat belongs to. If not   |
   | (optional)   | set, the metric will use the first profile_id created in    |
   |              | your account. (Developer, Basic and Standard plans only have|
   |              | one profile.)                                               |
   +--------------+-------------------------------------------------------------+

   use strict; use warnings;
   use WWW::StatsMix;

   my $API_KEY = "Your_API_Key";
   my $api     = WWW::StatsMix->new(api_key => $API_KEY);
   my $name    = <your_metric_name>;
   my $params  = { name => $metric_name };
   my $stat    = $api->track($params);

   print "Id: ", $stat->id, "\n";

=cut

sub track {
    my ($self, $params) = @_;

    my $data = [
        { key => 'name'        , required => 1 },
        { key => 'value'       , required => 0 },
        { key => 'generated_at', required => 0 },
        { key => 'meta'        , required => 0 },
        { key => 'ref_id'      , required => 0 },
        { key => 'profile_id'  , required => 0 }
    ];
    validate($data, $params);

    $params->{meta} = to_json($params->{meta})
        if (exists $params->{meta} && defined $params->{meta});

    $params->{format} = $self->format;
    my $response = $self->post($self->track_url, [ %$params ]);
    my $content  = from_json($response->content);

    return WWW::StatsMix::Stat->new($content->{stat});
}

# PRIVATE METHODS
#
#

sub _get_id {
    my ($params) = @_;

    if (defined $params && (ref($params) eq 'HASH')) {
        if (exists $params->{id} && defined $params->{id}) {
            return $params->{id};
        }
        elsif (exists $params->{ref_id} && defined $params->{ref_id}) {
            return $params->{ref_id};
        }
    }

    die "ERROR: Missing required key id/ref_id";
}

sub _get_value {
    my ($params) = @_;

    return $params->{value}
        if (defined $params && exists $params->{value} && defined $params->{value});

    die "ERROR: Missing required key 'value'.";
}

sub _get_metrics {
    my ($content) = @_;

    my $metrics = [];
    foreach (@{$content->{metrics}->{metric}}) {
        push @$metrics, WWW::StatsMix::Metric->new($_);
    }

    return $metrics;
}

sub _get_stats {
    my ($content) = @_;

    my $stats = [];
    foreach (@{$content->{stats}->{stat}}) {
        push @$stats, WWW::StatsMix::Stat->new($_);
    }

    return $stats;
}

sub _now_yyyy_mm_dd_hh_mi_ss {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+=1900, ++$mon, $mday, $hour, $min, $sec);
}

sub _now_yyyy_mm_dd {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
    return sprintf("%04d-%02d-%02d", $year+=1900, ++$mon, $mday);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/WWW-StatsMix>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-statsmix at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-StatsMix>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::StatsMix

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-StatsMix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-StatsMix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-StatsMix>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-StatsMix/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::StatsMix
