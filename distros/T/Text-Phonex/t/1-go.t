#!/usr/bin/perl -w
# -*- coding: UTF-8 -*-
#$Id: 1-go.t 429 2009-10-14 14:18:53Z gab $
use Test::More qw(no_plan);

BEGIN {
	use_ok('Text::Phonex');
}
is(phonex('go'),0.481404958677686);
is(phonex('PHILAURHEIMSMET'),0.292413615983392);
is(phonex('Jacques Martin'),'0.346054143542925');
is(phonex('Jacques Martain'),'0.346054143542913');
is(phonex('gengis khan'),'0.318880642337662');
is(phonex('appat du gain'),'0.625259518092057');
is(phonex("je vais à l'école est c'est super-chouette"),'0.329165453714965');
is(phonex("je vais à l'école est c'est super-chouette",2),'0.33');
is(phonex("je vais à l'école est c'est super-chouette",3),'0.329');
