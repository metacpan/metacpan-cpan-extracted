#! /usr/bin/perl
use Modern::Perl;
use YAML;
use XML::Tag;

use Test::More skip_all => 'nothing testable yet';

# say tag eg => sub {+{qw(lang python)}, "haha"}, +{ lang => 'perl' };
# 
# [qw( s 45 45 )] 
# [ s => 45, 45 ]
# 
# s => [qw( width height )]
# c => [qw( cx cy )]
# 
# 
# 
# foo { qw( &c:cx,cy
#     )
# }

#     say tag eg => sub { +{ lang => 'python' }, qw< a b c d >}, +{ lang => 'perl' };


