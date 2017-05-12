# $Id: load.t,v 1.1 2001/12/13 21:46:19 jgsmith Exp $

BEGIN { print "1..1\n"; }

eval {
    use Text::Domain qw: pushtextdomain poptextdomain :;
};

if($@) {
    print "not ok 1";
} else {
    print "ok     1";
}

1;
