#!/usr/bin/perl -d:Trace

use lib 'lib', '../lib';	

eval q{
    use maybe 'Fcntl';
    use maybe 'No::Such::Package';
};
