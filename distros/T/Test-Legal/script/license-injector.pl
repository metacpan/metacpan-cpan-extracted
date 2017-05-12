#!/usr/bin/env perl
# Copyright (C) 2011, Ioannis

use strict; 
use warnings;
use v5.10;
use Getopt::Compact;
use Data::Dumper;
use File::Slurp;
use Test::Legal::Util qw/ load_meta check_license_files  write_LICENSE license_types /; 
use Log::Log4perl ':easy';
our $VERSION = '0.10';

use constant { 
	LOG_PARAM  => { File=>'STDOUT', level=>$INFO, layout=>'%m%n', category=>'main'},
	LOG_MOD    => [('main', 'Test::Legal', 'Test::Legal::Util')],
};


our   $o;
our  $opts;
BEGIN {
#@ARGV = qw{ ../t/dat/bak -d check };

Log::Log4perl->easy_init( LOG_PARAM() , { %{LOG_PARAM()}, category=>'Test::Legal'} );

$o = new Getopt::Compact 
    modes  => [qw( yes licenses)],
	args   => 'dir  [check | add | remove | t]',
	struct => [ 
            [[qw(t type)], 'license type'],
            [[qw(a author)], 'copyright holder'],
			[[qw(d debug)],'debug','',sub{(Log::Log4perl->get_logger($_))->dec_level for @{LOG_MOD()}}],
			[[qw(q quiet)],'quiet','',sub{(Log::Log4perl->get_logger($_))->level($FATAL)for@{LOG_MOD()}}],
			];
}
$opts = $o->opts;

use constant {  BASE   => shift || '.' ,
			    ACTION => shift||'check',
};

## Option Processing
$opts->{licenses} and INFO join "\t", license_types and exit;
## Error Checking
load_meta BASE or ERROR qq(no META file found in dir ").BASE.qq(". Aborting...) and exit;

eval q(
use Test::Legal  qw/ disable_test_builder /,
                 license_ok=>{ base=>BASE ,
					           #actions => [qw/ fix /] ,
                 } ,
;
1;

DEBUG 'Scanning '. BASE ;
given (ACTION) {
	when (/^add$/i)   { disable_test_builder;
	                    write_LICENSE  BASE , @{$opts}{'author','type'};
	                  }
	when (/^remove$/i){ disable_test_builder;
						unlink BASE.'/LICENSE'  or warn "$!\n" and exit 1;
						DEBUG "unkinked" ;
	                  }
	when (/^check$/i) { disable_test_builder;
			            check_license_files( BASE );
                      }
	when (/^t$/i)     { license_ok ;
                      }
	default:            INFO	 $o->usage and exit; 
}

) or say $@;
