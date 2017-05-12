use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/ZooKeeper.pm';
readme_pod_from 'lib/ZooKeeper.pm';

homepage   'https://github.com/mark-5/p5-zookeeper';
bugtracker 'https://github.com/mark-5/p5-zookeeper/issues';
repository 'https://github.com/mark-5/p5-zookeeper.git';

cc_assert_lib header => 'zookeeper/zookeeper.h', lib => 'zookeeper_mt';

use_ppport;
cc_include_paths 'include';
cc_libs '-lzookeeper_mt', '-lpthread';
cc_src_paths 'src';

extra_tests;

cpanfile;

clean_files 'META.*';
WriteAll;
