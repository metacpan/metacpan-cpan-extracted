use Test::More;
eval 'use Test::Pod::Coverage' ;

SKIP: {        
        skip  'no Test::Pod::Coverage', scalar 1    if $@ ;
		all_pod_coverage_ok( {trustme=>[qr/done_testing/]}  );
};
