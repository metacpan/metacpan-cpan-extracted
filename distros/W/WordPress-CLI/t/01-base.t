use Test::Simple 'no_plan';
use strict;
use lib './lib';
use vars qw($_part $cwd);
use WordPress::CLI::Base ':all';

for my $datearg( 'June 8 2009', '07/31/2010', 'Wed Jun 30 08:12:08 EDT 2010' ){

   my $wordpress_compatible_date = _date2wordpressdate($datearg);
   ok( $wordpress_compatible_date, '_date2wordpressdate()');
}


if ( -f './t/login.dev' ){ # only for me
   my %OPT= qw/p 0 u 0 x 0/;
   ok( _opts_from_file(\%OPT,'./t/login.dev'), '_opts_from_file()');
   
   my $wp = _wordpress_xmlrpc_object_or_die(\%OPT); # dies otherwise so.. redundant to ok()
   ok( $wp, '_wordpress_xmlrpc_object_or_die()');  # but here for transparency

   ok( _resolve_cat_arg($wp, 'dev'), '_resolve_cat_arg()');

}












sub ok_part { printf STDERR "\n%s\nPART %s %s\n\n", '='x80, $_part++, "@_"; }

