#!/usr/bin/env perl

use Test::More;

use 5.12.0;
use warnings;

use Cpanel::JSON::XS;
use Data::Dumper;
use File::Path qw/remove_tree/;
use File::Slurp;
use MongoDB 1.0.4;
use Net::HTTP::Client;
use POSIX qw(setsid);
use Sys::Hostname;
use Try::Tiny::Retry;

use lib 'lib';
use Disbatch;
use Disbatch::Roles;
use Disbatch::Web;

my $use_ssl = $ENV{USE_SSL} // 1;
my $use_auth = $ENV{USE_AUTH} // 1;

unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'Skipping author tests';
    exit;
}

sub get_free_port {
    my ($port, $sock);
    do {
        $port = int rand()*32767+32768;
        $sock = IO::Socket::INET->new(Listen => 1, ReuseAddr => 1, LocalAddr => 'localhost', LocalPort => $port, Proto => 'tcp')
                or warn "\n# cannot bind to port $port: $!";
    } while (!defined $sock);
    $sock->shutdown(2);
    $sock->close();
    $port;
}

my $mongoport = get_free_port;

# define config and make up a database name:
my $config = {
    mongohost => "localhost:$mongoport",
    database => "disbatch_test$$" . int(rand(10000)),
    attributes => { ssl => { SSL_verify_mode => 0x00 } },
    auth => {
        disbatchd => 'qwerty1',		# { username => 'disbatchd', password => 'qwerty1' },
        disbatch_web => 'qwerty2',	# { username => 'disbatch_web', password => 'qwerty2' },
        task_runner => 'qwerty3',	# { username => 'task_runner', password => 'qwerty3' },
        plugin => 'qwerty4',		# { username => 'plugin', password => 'qwerty3' },
    },
    plugins => [ 'Disbatch::Plugin::Demo' ],
    web_root => 'etc/disbatch/htdocs/',
    task_runner => './bin/task_runner',
    testing => 1,	# for task_runner to use lib 'lib'
    gfs => 'auto',	# default
    log4perl => {
        level => 'TRACE',
        appenders => {
            filelog => {
                type => 'Log::Log4perl::Appender::File',
                layout => '[%p] %d %F{1} %L %C %c> %m %n',
                args => { filename => 'disbatchd.log' },
            },
            screenlog => {
                type => 'Log::Log4perl::Appender::ScreenColoredLevels',
                layout => '[%p] %d %F{1} %L %C %c> %m %n',
                args => { },
            }
        }
    },
};
delete $config->{auth} unless $use_auth;
delete $config->{attributes} unless $use_ssl;

mkdir "/tmp/$config->{database}";
my $config_file = "/tmp/$config->{database}/config.json";
write_file $config_file, encode_json $config;

say "database = $config->{database}";

my @mongo_args = (
    '--logpath' => "/tmp/$config->{database}/mongod.log",
    '--dbpath' => "/tmp/$config->{database}/",
    '--pidfilepath' => "/tmp/$config->{database}/mongod.pid",
    '--port' => $mongoport,
    '--noprealloc',
    '--nojournal',
    '--fork'
);
push @mongo_args, $use_auth ? '--auth' : '--noauth';
push @mongo_args, '--sslMode' => 'requireSSL', '--sslPEMKeyFile' => 't/test-cert.pem', if $use_ssl;
my $mongo_args = join ' ', @mongo_args;
say `mongod $mongo_args`;	# FIXME: use system or IPC::Open3 instead

# Get test database, authed as root:
my $attributes = {};
$attributes->{ssl} = $config->{attributes}{ssl} if $use_ssl;
if ($use_auth) {
    my $admin = MongoDB->connect($config->{mongohost}, $attributes)->get_database('admin');
    retry { $admin->run_command([createUser => 'root', pwd => 'kjfiwey76r3gjm', roles => [ { role => 'root', db => 'admin' } ]]) } catch { die $_ };
    $attributes->{username} = 'root';
    $attributes->{password} = 'kjfiwey76r3gjm';
}
my $test_db_root = retry { MongoDB->connect($config->{mongohost}, $attributes)->get_database($config->{database}) } catch { die $_ };

# Create roles and users for a database:
my $plugin_perms = { reports => [ 'insert' ] };	# minimal permissions for Disbatch::Plugin::Demo
Disbatch::Roles->new(db => $test_db_root, plugin_perms => $plugin_perms, %{$config->{auth}})->create_roles_and_users if $use_auth;

# Create users collection:
for my $username (qw/ foo bar /) {
    retry { $test_db_root->coll('users')->insert({username => $username, migration => 'test'}) } catch { die $_ };
}

# Ensure indexes:
my $disbatch = Disbatch->new(class => 'Disbatch', config_file => $config_file);
$disbatch->load_config;
$disbatch->ensure_indexes;


#####################################
# Start web:
sub daemonize {
    open STDIN, '<', '/dev/null'  or die "can't read /dev/null: $!";
    open STDOUT, '>', '/dev/null' or die "can't write to /dev/null: $!";
    defined(my $pid = fork)       or die "can't fork: $!";
    return $pid if $pid;
    setsid != -1                  or die "Can't start a new session: $!";
    open STDERR, '>&', 'STDOUT'   or die "can't dup stdout: $!";
    0;
}

my $webport = get_free_port;

my $webpid = daemonize();
if ($webpid == 0) {
    Disbatch::Web::init(config_file => $config_file);
    Disbatch::Web::limp({workers => 5}, LocalPort => $webport);
    die "This shouldn't have happened";
} else {
    # Run tests:
    my $uri = "localhost:$webport";
    my ($res, $data, $content);

    my $queueid;	# OID
    my $threads;	# integer
    my $node;		# node name (host name)
    my $node_id;	# node _id
    my $name;	# queue name
    my $plugin;	# plugin name
    my $object;	# array of task parameter objects
    my $collection;	# name of the MongoDB collection to query
    my $filter;	# query. If you want to query by OID, use the key "id" and not "_id"
    my $params;	# object of task params. To insert a document value from a query into the params, prefix the desired key name with "document." as a value.
    my $limit;	# integer
    my $skip;	# integer
    my $count;	# boolean
    my $terse;	# boolean

    $name = 'test_queue';
    $plugin = $config->{plugins}[0];

    # make sure web server is running:
    retry { Net::HTTP::Client->request(GET => "$uri/") } catch { die $_ };

    ### BROWSER ROUTES ###

    # Returns the contents of "/index.html" – the queue browser page.
    $res = Net::HTTP::Client->request(GET => "$uri/");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'text/html', 'text/html';

    # Returns the contents of the request path.
    $res = Net::HTTP::Client->request(GET => "$uri/js/queues.js");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/javascript', 'application/javascript';

    ### GET JSON ROUTES ####

    # Returns array of queues.
    # Each item has the following keys: id, plugin, name, threads, queued, running, completed
    $res = Net::HTTP::Client->request(GET => "$uri/queues");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    is $res->content, '[]', 'empty array';

    # Returns an array of allowed plugin names.
    $res = Net::HTTP::Client->request(GET => "$uri/plugins");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    is $res->content, "[\"$plugin\"]", 'plugin array';

    # Returns hash with key 'nodes' and value array of nodes.
    # Each item has the following keys: id, _id, node, timestamp
    # and optionally: maxthreads and queues (array: maxthreads, constructor, name, tasks_doing, tasks_done, preemptive, tasks_todo, tasks_backfill, id)
    $res = Net::HTTP::Client->request(GET => "$uri/nodes");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    is $res->content, '[]', 'empty nodes';

    my $time_in_ms = time * 1000;
    # make sure node document exists:
    $disbatch->update_node_status;

    # Returns hash with key 'nodes' and value array of nodes.
    # Each item has the following keys: id, _id, node, timestamp
    # and optionally: maxthreads and queues (array: maxthreads, constructor, name, tasks_doing, tasks_done, preemptive, tasks_todo, tasks_backfill, id)
    $res = Net::HTTP::Client->request(GET => "$uri/nodes");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'ARRAY', 'nodes is ARRAY';
    is scalar @$content, 1, 'nodes has 1 entry';
    like $content->[0]{id}, qr/^[0-9a-f]{24}$/, 'id is 24 char hex string';
    like $content->[0]{_id}{'$oid'}, qr/^[0-9a-f]{24}$/, '_id is 24 char hex string';
    is $content->[0]{id}, $content->[0]{_id}{'$oid'}, 'id matches _id.$oid';
    cmp_ok $content->[0]{timestamp}, '>' , $time_in_ms, 'timestamp is in milliseconds';
    is $content->[0]{node}, hostname, 'node is hostname';
    $node = $content->[0]{node};
    $node_id = $content->[0]{id};
    my $node_hash = $content->[0];

    # Returns hash of a single node, by name
    $res = Net::HTTP::Client->request(GET => "$uri/nodes/$node");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is_deeply $content, $node_hash, 'content matches previous node hash';

    # Returns hash of a single node, by id
    $res = Net::HTTP::Client->request(GET => "$uri/nodes/$node_id");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is_deeply $content, $node_hash, 'content matches previous node hash';

    ### POST JSON ROUTES ####

    # Set maxthreads to 5 via node name
    $data = { maxthreads => 5 };
    $res = Net::HTTP::Client->request(POST => "$uri/nodes/$node", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::UpdateResult'}{matched_count}, 1, 'matched success';
    is $content->{'MongoDB::UpdateResult'}{modified_count}, 1, 'modified success';

    # Returns hash of a single node, by id
    $res = Net::HTTP::Client->request(GET => "$uri/nodes/$node_id");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    ok exists $content->{maxthreads}, 'maxthreads exists';
    is $content->{maxthreads}, 5, 'maxthreads is 5';

    # Set maxthreads to null via node _id
    $data = { maxthreads => undef };
    $res = Net::HTTP::Client->request(POST => "$uri/nodes/$node_id", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::UpdateResult'}{matched_count}, 1, 'matched success';
    is $content->{'MongoDB::UpdateResult'}{modified_count}, 1, 'modified success';

    # Returns hash of a single node, by name
    $res = Net::HTTP::Client->request(GET => "$uri/nodes/$node");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    ok exists $content->{maxthreads}, 'maxthreads exists';
    is $content->{maxthreads}, undef, 'maxthreads is null';

    # Returns array: C<< [ success, inserted_id, $reponse_object ] >>
    # Returns hash: C<< { ref $res: Object, id: $inserted_id } >>
    $data = { name => $name, plugin => $plugin };
    $res = Net::HTTP::Client->request(POST => "$uri/queues", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    ok defined $content->{'MongoDB::InsertOneResult'}{'inserted_id'}{'$oid'}, 'MongoDB::InsertOneResult inserted_id defined';
    ok defined $content->{id}{'$oid'}, 'id defined';
    $queueid = $content->{id}{'$oid'};

    # Returns {ref $res: Object}
    $data = [ {commands => 'a'}, {commands => 'b'}, {commands => 'c'} ];
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/$queueid", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::InsertManyResult'}{acknowledged}, 1, 'success';
    is scalar @{$content->{'MongoDB::InsertManyResult'}{inserted}}, 3, 'count';
    my @task_ids = map { $_->{_id}{'$oid'} } @{$content->{'MongoDB::InsertManyResult'}{inserted}};

    # Returns {ref $res: Object}
    $data = [ {commands => 'a'}, {commands => 'b'} ];
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/$name", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::InsertManyResult'}{acknowledged}, 1, 'success';
    is scalar @{$content->{'MongoDB::InsertManyResult'}{inserted}}, 2, 'count';
    push @task_ids, map { $_->{_id}{'$oid'} } @{$content->{'MongoDB::InsertManyResult'}{inserted}};

    # {filter: filter, options: options, count: count, terse: terse}
    $data = { filter => { queue => $queueid }, count => 1 };
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/search", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{count}, scalar @task_ids, 'count';

    $data = { filter => { queue => $queueid, 'params.commands' => 'b' }, count => 1 };
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/search", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{count}, 2, 'count';

    # Returns array of tasks (empty if there is an error in the query), C<< [ status, $count_or_error ] >> if "count" is true, or C<< [ 0, error ] >> if other error.
    # All parameters are optional.
    # "filter" is the query. If you want to query by Object ID, use the key "id" and not "_id".
    # "limit" and "skip" are integers.
    # "count" and "terse" are booleans.
    # {filter: filter, options: options, count: count, terse: terse}
    $data = { filter => { %{$filter // {}}, queue => $queueid }, options => { limit => $limit, skip => $skip }, terse => $terse };
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/search", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'ARRAY', 'content is ARRAY';
    is scalar @{$content}, scalar @task_ids, 'count';
    #say Dumper $content;

    # Returns {ref $res: Object}
    # "collection" is the name of the MongoDB collection to query.
    # "filter" is the query.
    # "params" is an object of task params. To insert a document value from a query into the params, prefix the desired key name with C<document.> as a value.
    $collection = 'users';
    $filter = { migration => 'test' };
    $params = { user1 => 'document.username', migration => 'document.migration', commands => '*' };
    $data =  { filter => $filter, params => $params };
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/$queueid/$collection", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::InsertManyResult'}{acknowledged}, 1, 'success';
    is scalar @{$content->{'MongoDB::InsertManyResult'}{inserted}}, 2, 'count';
    push @task_ids, map { $_->{_id}{'$oid'} } @{$content->{'MongoDB::InsertManyResult'}{inserted}};

    $res = Net::HTTP::Client->request(POST => "$uri/tasks/$name/$collection", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::InsertManyResult'}{acknowledged}, 1, 'success';
    is scalar @{$content->{'MongoDB::InsertManyResult'}{inserted}}, 2, 'count';
    push @task_ids, map { $_->{_id}{'$oid'} } @{$content->{'MongoDB::InsertManyResult'}{inserted}};

    $res = Net::HTTP::Client->request(GET => "$uri/queues");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'ARRAY', 'content is ARRAY';
    is scalar @$content, 1, 'size';
    is $content->[0]{id}, $queueid, 'id';
    is $content->[0]{plugin}, $plugin, 'plugin';
    is $content->[0]{name}, 'test_queue', 'name';
    is $content->[0]{threads}, undef, 'threads';
    is $content->[0]{queued}, scalar @task_ids, 'queued';

    is $content->[0]{running}, 0, 'running';
    is $content->[0]{completed}, 0, 'completed';

    # Returns C<< { ref $res: Object } >> or C<< { "success": 0, "error": error } >>
    $data = { threads => 1 };
    $res = Net::HTTP::Client->request(POST => "$uri/queues/$queueid", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::UpdateResult'}{matched_count}, 1, 'matched success';
    is $content->{'MongoDB::UpdateResult'}{modified_count}, 1, 'modified success';

    $res = Net::HTTP::Client->request(GET => "$uri/queues");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'ARRAY', 'content is ARRAY';
    is scalar @$content, 1, 'size';
    is $content->[0]{threads}, 1, 'threads';

    # This will run 1 task:
    $disbatch->validate_plugins;
    $disbatch->process_queues;

    # Returns C<< { ref $res: Object } >> or C<< { "success": 0, "error": error } >>
    $data = { threads => 0 };
    $res = Net::HTTP::Client->request(POST => "$uri/queues/$name", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::UpdateResult'}{matched_count}, 1, 'matched success';
    is $content->{'MongoDB::UpdateResult'}{modified_count}, 1, 'modified success';

    $res = Net::HTTP::Client->request(GET => "$uri/queues");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'ARRAY', 'content is ARRAY';
    is scalar @$content, 1, 'size';
    is $content->[0]{threads}, 0, 'threads';

    # Make sure queue count updated:
    # {filter: filter, options: options, count: count, terse: terse}
    $data = { filter => { queue => $queueid, status => -2 }, count => 1 };
    $res = Net::HTTP::Client->request(POST => "$uri/tasks/search", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{count}, scalar @task_ids - 1, 'count';

    # Get report for task:
    my $report = retry { $disbatch->mongo->coll('reports')->find_one() or die 'No report found' } catch { warn $_; {} };	# status done task_id
    is $report->{status}, 'SUCCESS', 'report success';

    # Get task of report:
    my $task = $disbatch->tasks->find_one({_id => $report->{task_id}});
    is $task->{status}, 1, 'task success';

    # Returns hash: {ref $res: Object}
    $res = Net::HTTP::Client->request(DELETE => "$uri/queues/$queueid");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::DeleteResult'}{deleted_count}, 1, 'count';

    # GFS TESTING

    $name = 'test_queue2';

    # Returns array: C<< [ success, inserted_id, $reponse_object ] >>
    # Returns hash: C<< { ref $res: Object, id: $inserted_id } >>
    $data = { name => $name, plugin => $plugin };
    $res = Net::HTTP::Client->request(POST => "$uri/queues", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    ok defined $content->{'MongoDB::InsertOneResult'}{'inserted_id'}{'$oid'}, 'MongoDB::InsertOneResult inserted_id defined';
    ok defined $content->{id}{'$oid'}, 'id defined';
    $queueid = $content->{id}{'$oid'};

    $data = { threads => 1 };
    $res = Net::HTTP::Client->request(POST => "$uri/queues/$name", 'Content-Type' => 'application/json', encode_json($data));
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::UpdateResult'}{matched_count}, 1, 'matched success';
    is $content->{'MongoDB::UpdateResult'}{modified_count}, 1, 'modified success';

    my $gfs_tests = {
        'e'   => { auto => ['STR','NUL'], 0 => ['STR','NUL'] }, # 15,   0       15
        'eb'  => { auto => ['OID','STR'], 0 => ['STR','STR'] }, # 15,   0+      15+
        'aE'  => { auto => ['OID','STR'], 0 => ['STR','STR'] }, #  0+, 15       15+
        'ea'  => { auto => ['OID','NUL'], 0 => ['STR','NUL'] }, # 15+,  0       15+
        'E'   => { auto => ['NUL','STR'], 0 => ['NUL','STR'] }, #  0,  15       15
        'eA'  => { auto => ['OID','STR'], 0 => ['STR','STR'] }, # 15,   1       16      stdout will have error msg for document too large
        '1E'  => { auto => ['OID','STR'], 0 => ['STR','STR'] }, #  1,  15       16      stdout will have error msg for document too large
        '7aC' => { auto => ['OID','STR'], 0 => ['STR','STR'] }, #  7+,  8       15+
        '7C'  => { auto => ['STR','STR'], 0 => ['STR','STR'] }, #  7,   8       15
        'Eb'  => { auto => ['OID','OID'], 0 => ['NUL','STR'] }, #  0,  15+      15+
    };

    note "GFS loop start";
    $disbatch->{config}{quiet} = 1;
    for my $gfs ('auto', 1, 0) {
        if (exists $ENV{GFS_TESTS}) {
            next unless $ENV{GFS_TESTS} eq "$gfs";
            note "GFS: $gfs";
        }
        $disbatch->{config}{gfs} = $gfs;
        for my $key (keys  %$gfs_tests) {
            #note "GFS: $gfs $key $gfs_tests->{$key}{$gfs}[0] $gfs_tests->{$key}{$gfs}[1]";
            $data = [ {commands => $key} ];
            $res = Net::HTTP::Client->request(POST => "$uri/tasks/$name", 'Content-Type' => 'application/json', encode_json($data));
            is $res->status_line, '200 OK', '200 status';
            $content = decode_json($res->content);
            is scalar @{$content->{'MongoDB::InsertManyResult'}{inserted}}, 1, 'count';
            my ($task_id) = map { $_->{_id} } @{$content->{'MongoDB::InsertManyResult'}{inserted}};

            # This will run 1 task:
            $disbatch->validate_plugins;
            $disbatch->process_queues;

            # get task, verify if stdout and stderr is in task or gfs
            $data = { filter => { _id => $task_id, queue => $queueid, 'params.commands' => $key }};
            my $max = 10;
            my $c = 0;
            do {
                select(undef, undef, undef, 0.5);
                $res = Net::HTTP::Client->request(POST => "$uri/tasks/search", 'Content-Type' => 'application/json', encode_json($data));
                $content = decode_json($res->content);
                note "status is $content->[0]{status}";
                if ($content->[0]{status} > 0) {
                    $c++;
                    BAIL_OUT("too many loops looking for complete") if $c >= $max;
                }
            } while (!exists $content->[0]{complete});
            is $res->status_line, '200 OK', '200 status';
            #is $res->content_type, 'application/json', 'application/json';
            is ref $content, 'ARRAY', 'content is ARRAY';
            is scalar @$content, 1, 'count';
            is $content->[0]{status}, 1, 'status 1';
            ok exists $content->[0]{stdout}, 'stdout exists';
            ok exists $content->[0]{stderr}, 'stderr exists';
            if (!$gfs) {
                if ($gfs_tests->{$key}{0}[0] eq 'NUL') {
                    ok !defined $content->[0]{stdout}, 'stdout undefined';
                } elsif ($gfs_tests->{$key}{0}[0] eq 'STR') {
                    ok((defined $content->[0]{stdout} and !ref $content->[0]{stdout}), 'stdout string');
                #} elsif ($gfs_tests->{$key}{0}[0] eq 'OID') {
                } else {
                    die;
                }
                if ($gfs_tests->{$key}{0}[1] eq 'NUL') {
                    ok !defined $content->[0]{stderr}, 'stderr undefined';
                } elsif ($gfs_tests->{$key}{0}[1] eq 'STR') {
                    ok((defined $content->[0]{stderr} and !ref $content->[0]{stderr}), 'stderr string');
                #} elsif ($gfs_tests->{$key}{0}[1] eq 'OID') {
                } else {
                    die;
                }
            } elsif ($gfs eq 'auto') {
                if ($gfs_tests->{$key}{auto}[0] eq 'NUL') {
                    ok !defined $content->[0]{stdout}, 'stdout undefined';
                } elsif ($gfs_tests->{$key}{auto}[0] eq 'STR') {
                    ok((defined $content->[0]{stdout} and !ref $content->[0]{stdout}), 'stdout string');
                } elsif ($gfs_tests->{$key}{auto}[0] eq 'OID') {
                    ok defined $content->[0]{stdout}{'$oid'}, 'stdout OID';
                } else {
                    die;
                }
                if ($gfs_tests->{$key}{auto}[1] eq 'NUL') {
                    ok !defined $content->[0]{stderr}, 'stderr undefined';
                } elsif ($gfs_tests->{$key}{auto}[1] eq 'STR') {
                    ok((defined $content->[0]{stderr} and !ref $content->[0]{stderr}), 'stderr string');
                } elsif ($gfs_tests->{$key}{auto}[1] eq 'OID') {
                    ok defined $content->[0]{stderr}{'$oid'}, 'stderr OID';
                } else {
                    die;
                }
            } else {
                ok defined $content->[0]{stdout}{'$oid'}, 'stdout OID';
                ok defined $content->[0]{stderr}{'$oid'}, 'stderr OID';
            }
        }
    }
    note "GFS loop end";

    # Returns hash: {ref $res: Object}
    $res = Net::HTTP::Client->request(DELETE => "$uri/queues/$name");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    $content = decode_json($res->content);
    is ref $content, 'HASH', 'content is HASH';
    is $content->{'MongoDB::DeleteResult'}{deleted_count}, 1, 'count';

    # Returns array of queues.
    # Each item has the following keys: id, plugin, name, threads, queued, running, completed
    $res = Net::HTTP::Client->request(GET => "$uri/queues");
    is $res->status_line, '200 OK', '200 status';
    is $res->content_type, 'application/json', 'application/json';
    is $res->content, '[]', 'empty array';


    done_testing;
}

END {
    # Cleanup:
    if (defined $config and $config->{database}) {
        kill -9, $webpid if $webpid;
        my $pidfile = "/tmp/$config->{database}/mongod.pid";
        if (-e $pidfile) {
            my $mongopid = read_file $pidfile;
            chomp $mongopid;
            kill 9, $mongopid;
        }
        remove_tree "/tmp/$config->{database}";
    }
}
