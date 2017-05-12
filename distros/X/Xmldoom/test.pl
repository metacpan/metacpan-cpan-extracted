#/usr/bin/perl -w

use test::Xmldoom::Schema::Parser;
use test::Xmldoom::Definition::Database;
use test::Xmldoom::Definition::Object;
use test::Xmldoom::Definition::SAXHandler;
use test::Xmldoom::Criteria;
use test::Xmldoom::Object;
use test::Xmldoom::Javascript;
use test::SQL::Translator::Parser::XML::Xmldoom;
use test::SQL::Translator::Producer::XML::Xmldoom;
use test::example::BookStore;

use Carp;

$SIG{__DIE__} = sub {
	Carp::confess(@_);
	#Carp::confess;
};

if ( @ARGV > 0 )
{
	my @spec;

	foreach my $s ( @ARGV )
	{
		my @t = split('::', $s);
		unshift @t, "Local";
		push @spec, join('::', @t);
	}

	Test::Class->runtests( @spec );
}
else
{
	# run 'em all!
	Test::Class->runtests;
}

