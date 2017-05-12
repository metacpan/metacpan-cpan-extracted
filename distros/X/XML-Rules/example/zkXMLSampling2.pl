use strict;
use XML::Rules;

my $parser = XML::Rules->new(
	rules => {
		_default => 'content',
		'sampling,sports' => 'content array',
		dataName => sub {
			return delete($_[1]->{language}) => $_[1];
		},
		place => sub {
			return delete($_[1]->{country}) => $_[1];
		},
		request => 'pass',
	},
	stripspaces => 7
);

my $data = $parser->parse(\*DATA);

#use Data::Dumper;
#print Dumper($data);

print "Sampling: " . join( ', ', @{$data->{SouthAfrica}{English}{sampling}}) . "\n";

__DATA__
<?xml version="1.0" encoding="utf-8" ?>
<request>
  <place>
    <country>SouthAfrica</country>
    <sports>cricket</sports>
    <sports>rugby</sports>
      <dataName>
       <language>English</language>
       <sampling>16000</sampling>
       <sampling>11025</sampling>
      </dataName>
    <dataName>
      <language>Africans</language>
      <sampling>16000</sampling>
    </dataName>
  </place>
</request>