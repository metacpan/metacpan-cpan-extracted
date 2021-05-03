use Test2::V0;

package t::default { use WebService::Solr::Tiny }

is [ sort keys %t::default:: ], ['BEGIN'];

package t::empty { use WebService::Solr::Tiny () }

is [ sort keys %t::empty:: ], ['BEGIN'], '()';

package t::explicit { use WebService::Solr::Tiny 'solr_escape' }

is [ sort keys %t::explicit:: ], [qw/BEGIN solr_escape/], '"solr_escape"';

is dies { WebService::Solr::Tiny->import('foo') }, <<EXP, '"foo"';
"foo" is not exported by the WebService::Solr::Tiny module
Can't continue after import errors at ${\__FILE__} line ${\( __LINE__ - 2 )}.
EXP

done_testing;
