use strict;
use XML::Rules;

my $parser = XML::Rules->new(
	rules => {
		_default => 'content',
		'sampling,sports' => 'content array',
		dataName => sub {
			return unless $_[1]->{language} eq 'English';
			return $_[0] => $_[1];
		},
		place => sub {
			return unless $_[1]->{country} eq 'SouthAfrica';
			print "Sampling: " . join( ', ', @{$_[1]->{dataName}{sampling}}) . "\n";
			return;
		}
	}
);

$parser->parse(\*DATA);

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