#!/usr/bin/perl

use lib 'lib';

# something wrong with using a book before doing plugins->init
BEGIN {
	use dtRdr::Book::ThoutBook_1_0_jar;
	warn 1;
}
BEGIN {
	use dtRdr::Plugins;
	warn 2;
}
BEGIN {
	use dtRdr::Plugins::Book;
	warn 3;
}

warn 4;
dtRdr::Plugins->init;
warn 5;
