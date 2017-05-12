#!/usr/bin/perl

use Test::More tests => 6;

use strict;
use warnings;
use cPanel::StateFile ();

eval {
    cPanel::StateFile->import( '-logger' );
};
like( $@, qr/even number/, 'Must have argument pairs.' );

eval {
    cPanel::StateFile->import( '-other' => 'one' );
};
like( $@, qr/Unrecognized/, 'Unknown policy handled.' );

eval {
    cPanel::StateFile->import( '-logger' => 'Fred::UnknownLogger' );
};
like( $@, qr/Can't locate/, 'Bad logger module.' );

eval {
    cPanel::StateFile->import( '-logger' => {} );
};
like( $@, qr/correct interface/, 'Bad logger object.' );

eval {
    cPanel::StateFile->import( '-filelock' => 'Fred::UnknownLocker' );
};
like( $@, qr/Can't locate/, 'Bad filelock module.' );

eval {
    cPanel::StateFile->import( '-filelock' => {} );
};
like( $@, qr/correct interface/, 'Bad locker object.' );

