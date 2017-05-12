#!perl

use strict;
use warnings;
use LWP::Online ':skip_all';
use Test::More tests => 16;
use File::Slurp;

use WWW::Freshmeat 0.20;

my $fm = WWW::Freshmeat->new();
isa_ok($fm,'WWW::Freshmeat');

my $xml=read_file((-e 't'?'t/':'').'hook_lexwrap.xml');
my $project = $fm->project_from_xml($xml);
#my $project = $fm->retrieve_project('hook_lexwrap');

isa_ok($project,'WWW::Freshmeat::Project');
isa_ok($project->www_freshmeat,'WWW::Freshmeat');
is($project->name(),'Hook::LexWrap');
is($project->version(),'0.22');
#is($project->url(),'http://search.cpan.org/dist/Hook-LexWrap/');
#is($project->license(),'Perl License');

=for cmt
my @trove=@{$project->trove_id()};
my %hash;
@hash{@trove}=();
foreach my $t (11,3,902,235,176,809,910) {
  ok(exists $hash{$t},"id $t is present");
}
#902 - OSI Approved :: Perl License
#176 - Perl
#910 - Software Development :: Libraries :: Perl Modules
=cut

is($project->projectname_short(),'hook_lexwrap');
my @list=$project->url_list1;
is(scalar(@list),2);
is_deeply($list[0],
 {
      label=>'Bug Tracker',
      redirector=>'http://freshmeat.net/urls/854d57e030b1b55bb959ab066144c62d',
      host=>'rt.cpan.org',
      www_freshmeat=>$project->www_freshmeat,
},'correct link to Bug Tracker');
is_deeply($list[1],
 {
      label=>'Website',
      redirector=>'http://freshmeat.net/urls/958a46b0fd68b07418a150fc730dd5a1',
      host=>'search.cpan.org',
      www_freshmeat=>$project->www_freshmeat,
},'correct link to Website');

my $hash=$project->detect_link_types(\@list);
ok(exists $hash->{'url_homepage'});
is($hash->{'url_homepage'}->host,'search.cpan.org');
is($hash->{'url_homepage'}->url,'http://search.cpan.org/dist/Hook-LexWrap/');

ok(exists $hash->{'url_bugtracker'});
is($hash->{'url_bugtracker'}->url,'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hook-LexWrap');

{
my @lang=$project->languages;
is($lang[0],'Perl');
}

is_deeply([$project->tags],['Software Development', 'Libraries', 'Perl Modules']);



=for cmt
is_deeply({$project->branches()},{'77120'=>'Default'},'branches');
my %pop=$project->popularity();
cmp_ok($pop{'record_hits'},'>=',442);
cmp_ok($pop{'url_hits'},'>=',216);
cmp_ok($pop{'subscribers'},'>=',0);
is($project->real_author(),'Damian Conway');
is_deeply([$project->maintainers],['Alexandr Ciornii']);
cmp_ok($project->release_date,'ge','2008-12-29 18:48:04');
=cut

