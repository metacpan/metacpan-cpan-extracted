use strict;
use warnings;
use Test::More;

use WWW::Honeypot::httpBL;

if ( !$ENV{HTTPBL_ACCESS_KEY} ) {
  plan skip_all => 'Need HTTPBL_ACCESS_KEY in %ENV to continue!';
} else {
  plan tests => 36;
}

my $bl = WWW::Honeypot::httpBL->new( { access_key => $ENV{HTTPBL_ACCESS_KEY} } );

# Simulate no record returned
is( $bl->fetch('127.0.0.1'), undef, ' no record found');

# Simulate varying threat levels
$bl->fetch('127.1.10.1');
is( $bl->threat_score(), '10', ' Threat score of 10');
$bl->fetch('127.1.20.1');
is( $bl->threat_score(), '20', ' Threat score of 20');
$bl->fetch('127.1.40.1');
is( $bl->threat_score(), '40', ' Threat score of 40'); 
$bl->fetch('127.1.80.1');
is( $bl->threat_score(), '80', ' Threat score of 80');

# Simulate varying days
$bl->fetch('127.10.1.1');
is( $bl->days_since_last_actvity(), '10', ' 10 days');
$bl->fetch('127.20.1.1');
is( $bl->days_since_last_actvity(), '20', ' 20 days');
$bl->fetch('127.40.1.1');
is( $bl->days_since_last_actvity(), '40', ' 40 days');
$bl->fetch('127.80.1.1');
is( $bl->days_since_last_actvity(), '80', ' 80 days');

# Try fetching by domain rather than IP address
is( $bl->fetch('cpan.org'), 'That doesn\'t look like an IP address!', ' Fetch by IP only');

# Simulate a search engine.  A really old search engine :)
$bl->fetch('127.1.1.0');
is ( $bl->is_search_engine(), 'Alta Vista', ' is_search_engine()' ); 
$bl->fetch('127.1.1.1');
is ( $bl->is_search_engine(),  undef,       ' is_search_engine()' ); 

# Various types of suspicious activity
$bl->fetch('127.1.1.0');
is ( $bl->is_suspicious(), undef, ' is_suspicious()' ); 
$bl->fetch('127.1.1.1');
is ( $bl->is_suspicious(), 1,     ' is_suspicious()' ); 
$bl->fetch('127.1.1.2');
is ( $bl->is_suspicious(), undef, ' is_suspicious()' ); 
$bl->fetch('127.1.1.3');
is ( $bl->is_suspicious(), 1,     ' is_suspicious()' ); 
$bl->fetch('127.1.1.4');
is ( $bl->is_suspicious(), undef, ' is_suspicious()' ); 
$bl->fetch('127.1.1.5');
is ( $bl->is_suspicious(), 1,     ' is_suspicious()' ); 
$bl->fetch('127.1.1.6');
is ( $bl->is_suspicious(), undef, ' is_suspicious()' ); 
$bl->fetch('127.1.1.7');
is ( $bl->is_suspicious(), 1,     ' is_suspicious()' ); 

# Various combinations of evil that include email harvesters
$bl->fetch('127.1.1.0');
is ( $bl->is_harvester(), undef, ' is_harvester()' ); 
$bl->fetch('127.1.1.1');
is ( $bl->is_harvester(), undef, ' is_harvester()' ); 
$bl->fetch('127.1.1.2');
is ( $bl->is_harvester(), 1,     ' is_harvester()' ); 
$bl->fetch('127.1.1.3');
is ( $bl->is_harvester(), 1,     ' is_harvester()' ); 
$bl->fetch('127.1.1.4');
is ( $bl->is_harvester(), undef, ' is_harvester()' ); 
$bl->fetch('127.1.1.5');
is ( $bl->is_harvester(), undef, ' is_harvester()' ); 
$bl->fetch('127.1.1.6');
is ( $bl->is_harvester(), 1,     ' is_harvester()' ); 
$bl->fetch('127.1.1.7');
is ( $bl->is_harvester(), 1,     ' is_harvester()' ); 

# Various combinations of evil that include comment spamming
$bl->fetch('127.1.1.0');
is ( $bl->is_comment_spammer(), undef, ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.1');
is ( $bl->is_comment_spammer(), undef, ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.2');
is ( $bl->is_comment_spammer(), undef, ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.3');
is ( $bl->is_comment_spammer(), undef, ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.4');
is ( $bl->is_comment_spammer(), 1,     ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.5');
is ( $bl->is_comment_spammer(), 1,     ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.6');
is ( $bl->is_comment_spammer(), 1,     ' is_comment_spammer()' ); 
$bl->fetch('127.1.1.7');
is ( $bl->is_comment_spammer(), 1,     ' is_comment_spammer()' ); 
