use 5.010000;
use Test::More ;

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
##plan skip_all => "Spelling tests only for author" unless -d 'inc/.author';
my $filter = sub {
		my $_ = shift;
		! (/_ja.pod$/ || /_es.pad$/ )
};

eval 'use Test::Spelling' ;

SKIP: {        
		done_testing(1)                        if $@ ;
        skip  'no Test::Spelling', scalar 1    if $@ ||  ! -d "${dir}inc/.author" ;
		add_stopwords(<DATA>);
		set_pod_file_filter($filter) ;
		my @files = all_pod_files ( "${dir}blib"  );
		pod_file_spelling_ok( $_, ) for @files;
		done_testing( scalar @files );
};

__END__
dirs
dist
msg
ref
deannotated
Tambouras
perms
dir
json
yml
Ioannis
