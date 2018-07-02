use strict;
use warnings;
use 5.012;
use open ':std', ':encoding(utf8)';
use Test::More;
use WWW::Bugzilla::BugTree;

plan skip_all => 'landfill is no longer available';

my $ua;
if(eval q{ use LWP::UserAgent::Snapshot; 1 })
{
  LWP::UserAgent::Snapshot->record_to(undef);
  LWP::UserAgent::Snapshot->mock_from('t/data/1');
  $ua = LWP::UserAgent::Snapshot->new;
  note 'using LWP::UserAgent::Snapshot';
}
else
{
  require LWP::UserAgent;
  $ua = LWP::UserAgent->new;
  $ua->env_proxy;
  note 'using LWP::UserAgent';
}

foreach my $ver (qw( 4.2 4.4 5.0 ))
{
  my $tree = WWW::Bugzilla::BugTree->new(
    url => "https://landfill.bugzilla.org/bugzilla-$ver-branch/",
    ua  => $ua,
  );
  
  isa_ok $tree, 'WWW::Bugzilla::BugTree';
  isa_ok $tree->url, 'URI';

  SKIP: {
    skip "URL ".$tree->url." unreachable", 8
      unless $tree->ua->get($tree->url)->is_success;
    
    my $b = eval { $tree->fetch(1) };
    diag $@ if $@;
    
    isa_ok $b, 'WWW::Bugzilla::BugTree::Bug';
    isa_ok $b->url, 'URI', "b.url [".$b->url."]";
    isa_ok $b->res, 'HTTP::Response', 'b.res';
    is $b->id, 1, 'b.id = 1';
    
    isa_ok $b->as_hashref, 'HASH', 'b.as_hashref';
    
    ok $b->as_string, "b.summary = $b";
    
    isa_ok $b->summary_tree, 'ARRAY', 'b.summary_tree';
    
    # TODO: only do this if we have YAML
    if(eval q{ use YAML; 1 })
    {
      note YAML::Dump($b->summary_tree);
    }
  };
}

done_testing;
