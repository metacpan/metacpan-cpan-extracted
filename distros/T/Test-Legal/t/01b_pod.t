use Test::More;


my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';

eval 'use Test::Pod' ;


SKIP: {        
		skip  'no Test::Pod', scalar 1    if $@ ;
	    my @files =   all_pod_files( "${dir}blib" );
		pod_file_ok( $_, )   for @files;
		done_testing( scalar @files);
};

