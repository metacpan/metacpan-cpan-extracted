#!/usr/bin/env perl
# test asking questions

use warnings;
use strict;

use Test::More;

use XML::eXistDB::RPC;

#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#use Log::Report mode => 'DEBUG';

my $uri = $ENV{XML_EXIST_TESTDB}
    or plan skip_all => 'define XML_EXIST_TESTDB to run tests';

plan tests => 40;

my $db = XML::eXistDB::RPC->new(destination => $uri);
isa_ok($db, 'XML::eXistDB::RPC', "rpc to $uri");

my $collname = '/db/test-query';

$db->removeCollection($collname);  # result from test crash

my ($rc, $success) = $db->createCollection($collname);
cmp_ok($rc, '==', 0, "created collection $collname");
ok($success);

### query

my $question = <<'__Q';
xquery version "1.0";
let $message := 'Hello, World!'
return
<results>
   <message>{$message}</message>
</results>,
<aap />,
<complex>
   <a>42</a>
   <b t="12" />
</complex>
__Q

($rc, my $msg) = $db->query($question, 100);
cmp_ok($rc, '==', 0, 'query hello world');
is_deeply($msg, { count => 3, hits => 3, start => 1
 , aap => {}, results => {message => 'Hello, World!'}
 , complex => {a => 42, b => {t => 12}}});

($rc, my $ok) = $db->removeCollection($collname);
cmp_ok($rc, '==', 0, 'remove collection');
cmp_ok($ok, 'eq', 1);

### compile

($rc, my $stats) = $db->compile($question);
cmp_ok($rc, '==', 0, 'compile hello world');

#use Data::Dumper;
#warn $question;
#warn Dumper $stats;
#warn $db->trace->{request}->as_string;
#warn $db->trace->{response}->as_string;

($rc, my $descr) = $db->describeCompile($question);
cmp_ok($rc, '==', 0, 'describe compile');
is("$descr\n", <<'__STATS');
(
    (
        let  <2> 
            $message := "Hello, World!"
        return 
            element {"results"} {
                text {
                    
   
                }
                element {"message"} {
                    {
                        $message
                    }
                } 
                text {
                    

                }
            } , element {"aap"} {
            } 
        ), element {"complex"} {
            text {
                
   
            }
            element {"a"} {
                text {
                    42
                }
            } 
            text {
                
   
            }
            element {"b"} {
                attribute {t} {
                    12
                } 
                } 
                text {
                    

                }
            } 
        )
__STATS

### executeQuery

($rc, my $results) = $db->executeQuery($question);
cmp_ok($rc, '==', 0, "execute query, resultset $results");
ok(defined $results);

($rc, my $nr) = $db->numberOfResults($results);
cmp_ok($rc, '==', 0, 'nr results');
cmp_ok($nr, 'eq', 3);

($rc, $descr) = $db->describeResultSet($results);

TODO: {
   local $TODO = "broken in 1.4";

use Data::Dumper;
warn Dumper $descr;
cmp_ok($rc, '==', 0, 'descr results');
isa_ok($descr, 'HASH');
cmp_ok($descr->{hits}, '==', 3);
cmp_ok(scalar @{$descr->{documents}}, 'eq', 3);
cmp_ok($descr->{documents}[0]{hits}, '==', 1);
cmp_ok($descr->{documents}[1]{hits}, '==', 1);
cmp_ok(scalar @{$descr->{doctypes}}, '==', 1);
cmp_ok($descr->{doctypes}[0]{hits}, '==', 3);
cmp_ok($descr->{doctypes}[0]{class}, 'eq', 'temp');

     }; # END TODO

($rc, my $res0) = $db->retrieveResult($results, 0);
cmp_ok($rc, '==', 0, 'result 0');
is_deeply($res0, {message => 'Hello, World!'});

($rc, my $res1) = $db->retrieveResult($results, 1);
cmp_ok($rc, '==', 0, 'result 1');
is_deeply($res1, {});

($rc, my $res2) = $db->retrieveResult($results, 2);
cmp_ok($rc, '==', 0, 'result 2');
is_deeply($res2, {a => 42, b => {t => 12}});

($rc, $ok) = $db->releaseResultSet($results);
cmp_ok($rc, '==', 0, 'release results');
cmp_ok($ok, 'eq', 1);

# now all answers at once

($rc, $results) = $db->executeQuery($question);
cmp_ok($rc, '==', 0, "execute query for all, resultset $results");
ok(defined $results);

($rc, my $res) = $db->retrieveResults($results);
cmp_ok($rc, '==', 0, 'all results');
isa_ok($res, 'HASH');

is_deeply($res, { hitCount => 3,
  , aap => {}
  , complex => { a => '42', b => { t => '12' } }
  , results => { message => 'Hello, World!' }
  });

# queryXPath

my $doc1 = "$collname/doc1.xml";
($rc, $success) = $db->createCollection($collname);
$rc==0 or warn $success;
($rc, $success) = $db->uploadDocument($doc1, "<doc><a b='1'>2</a></doc>");
$rc==0 or warn $success;

($rc, $results) = $db->queryXPath("//a", $doc1, '');
is(join(' ', sort keys %$results), 'hash id results', 'queryXPath');
is(ref $results->{results}, 'ARRAY');
cmp_ok(scalar @{$results->{results} || []}, '==', 1);
is_deeply($results->{results}[0], { document => $doc1, node_id => '1.1' });

($rc, $success) = $db->removeCollection($collname);
$rc==0 or warn $success;
