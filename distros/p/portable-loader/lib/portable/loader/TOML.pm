use 5.008008;
use strict;
use warnings;

package portable::loader::TOML;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use portable::lib;

our $decoder;

sub load {
	my $me = shift;
	my ($collection) = @_;
	my ($filename) = grep defined,
		portable::lib->search_inc("$collection.portable.toml"),
		portable::lib->search_inc("$collection.portable");
	if ($filename) {
		require JSON::Eval;
		$decoder ||= JSON::Eval->new($me->_get_parser);
		my $tomltext = do {
			open my $fh, '<', $filename
				or die "Could not open $filename: $!";
			local $/;
			<$fh>;
		};
		$me->_munge_toml(\$tomltext);
		my $decoded = $decoder->decode($tomltext);
		return ($filename => $decoded);
	}
	return;
}

sub _munge_toml {
	my $ref = $_[1];
	$$ref =~ s{
		\{\{\{
			(.*?)
		\}\}\}
	}{ \{\"\$eval\"=''' sub \{ $1 \} ''' \} }xsgo;
	return;
}

# create method alias
my $p;
sub _get_parser {
	$p ||= eval q{
		package portable::loader::TOML::_Parser;
		require TOML::Parser;
		our @ISA = 'TOML::Parser';
		sub decode { shift->parse(@_) };
		__PACKAGE__->new;
	};
}

1;

