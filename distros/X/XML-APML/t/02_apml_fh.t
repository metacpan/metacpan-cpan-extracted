use Test::More tests => 54;

use_ok("XML::APML");

my $path = 't/sample/apml.xml';

open(my $fh, $path);

my $apml = XML::APML->parse_fh($fh);

isa_ok($apml, "XML::APML");
is($apml->title, "Example APML file for apml.org");
is($apml->generator, "Written by Hand");
is($apml->user_email, 'sample@apml.org');
is($apml->date_created, '2007-03-11T01:55:00Z');
is($apml->defaultprofile, 'Work');

my $profiles = $apml->profiles;

is(@$profiles, 2);

my $profile1 = $profiles->[0];
isa_ok($profile1, "XML::APML::Profile");
is($profile1->name, "Home");
my @p1i_concepts = $profile1->implicit->concepts;
is(@p1i_concepts, 14);
my $p1i_concept1 = $p1i_concepts[0];
isa_ok($p1i_concept1, 'XML::APML::Concept');
is($p1i_concept1->key, 'attention');
is($p1i_concept1->value, 0.99);
is($p1i_concept1->from, 'GatheringTool.com');
is($p1i_concept1->updated, '2007-03-11T01:55:00Z');
my @p1i_sources = $profile1->implicit->sources;
is(@p1i_sources, 1);
my $p1i_source1 = $p1i_sources[0];
isa_ok($p1i_source1, 'XML::APML::Source');
is($p1i_source1->key, 'http://feeds.feedburner.com/apmlspec');
is($p1i_source1->value+0, 1.00);
is($p1i_source1->name, 'APML.org');
is($p1i_source1->type, 'application/rss+xml');
is($p1i_source1->from, 'GatheringTool.com');
is($p1i_source1->updated, '2007-03-11T01:55:00Z');
my @p1e_concepts = $profile1->explicit->concepts;
is(@p1e_concepts, 1);
my $p1e_concept1 = $p1e_concepts[0];
isa_ok($p1e_concept1, 'XML::APML::Concept');
is($p1e_concept1->key, 'direct attention');
is($p1e_concept1->value+0, 0.99);
my @p1e_sources = $profile1->explicit->sources;
is(@p1e_sources, 1);
my $p1e_source1 = $p1e_sources[0];
isa_ok($p1i_source1, 'XML::APML::Source');
is($p1e_source1->key, 'http://feeds.feedburner.com/TechCrunch');
is($p1e_source1->name, 'Techcrunch');
is($p1e_source1->type, 'application/rss+xml');
is($p1e_source1->value, 0.4);
my $profile2 = $profiles->[1];
isa_ok($profile2, "XML::APML::Profile");
is($profile2->name, "Work");
my @p2i_concepts = $profile2->implicit->concepts;
is(@p2i_concepts, 0);
my @p2i_sources = $profile2->implicit->sources;
is(@p2i_sources, 0);
my @p2e_concepts = $profile2->explicit->concepts;
is(@p2e_concepts, 1);
my $p2e_concept1 = $p2e_concepts[0];
isa_ok($p2e_concept1, "XML::APML::Concept");
is($p2e_concept1->key, 'Golf');
is($p2e_concept1->value, '0.2');
my @p2e_sources = $profile2->explicit->sources;
is(@p2e_sources, 1);
my $p2e_source1 = $p2e_sources[0];
isa_ok($p2e_source1, 'XML::APML::Source');
is($p2e_source1->key, 'http://feeds.feedburner.com/TechCrunch');
is($p2e_source1->name, 'Techcrunch');
is($p2e_source1->type, 'application/atom+xml');
is($p2e_source1->value, 0.4);
my $p2e_author1 = $p2e_source1->authors->[0];
isa_ok($p2e_author1, "XML::APML::Author");
is($p2e_author1->key, "ProfessionalBlogger");
is($p2e_author1->value+0, 0.5);
my $applications = $apml->applications;

is(@$applications, 1);

my $application = $applications->[0];
isa_ok($application, "XML::APML::Application");
is($application->name, "sample.com");

