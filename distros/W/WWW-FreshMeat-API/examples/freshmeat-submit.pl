#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Perl6::Say;

use lib '../lib';
use WWW::FreshMeat::API;


my $proj = 'yourfreshmeatproject';
my $branch_name = 'Default';
my $version = '0.01';
my $cpanproj = 'Project'
my $cpan = 'id/C/CP/';
my $cpanuser = 'CPANNAME';

my $fm = WWW::FreshMeat::API->new( mock => 0 );
$fm->login( username => 'username', password => 'password' );
say "Sid: ", $fm->sid;

# say Dumper ( $fm );
# say "fetch_available_release_foci\n", Dumper ( $fm->fetch_available_release_foci );
# say "fetch_available_licenses\n", Dumper ( $fm->fetch_available_licenses );
say "fetch_project_list\n", Dumper ( $fm->fetch_project_list );
# say "fetch_branch_list\n", Dumper ( $fm->fetch_branch_list( project_name => $proj ) );
# say "fetch_release\n", Dumper( $fm->fetch_release( project_name => $proj, branch_name => $branch_name, version => $version) );

say "publish_release\n", Dumper ( $fm->publish_release( 
    project_name => $proj,
    branch_name  => $branch_name,
    version      => $version,
    changes      => 'Opps... Needed IO::WrapTie as well in builder_xml_output.t test  ;-(',
    release_focus => 6,
    hide_from_frontpage => 'N',
    license    =>  'Perl License',
    url_homepage => 'http://search.cpan.org/dist/$cpanproj/',
    url_tgz => "http://search.cpan.org/CPAN/authors/$cpan/$cpanuser/$cpanproj-$version.tar.gz",
    url_changelog  => "http://search.cpan.org/src/cpanuser/$cpanproj-$version/Changes",
));

# say "withdraw_release\n", Dumper ( $fm->withdraw_release( 
#     project_name => $proj,
#     branch_name  => $branch_name,
#     version      => $version,
# ));

say "logout\n", Dumper( $fm->logout );
