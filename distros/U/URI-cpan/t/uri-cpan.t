use strict;
use warnings;
use Test::More tests => 15;
use URI;
use URI::cpan;

{
  my $url = URI->new('cpan:///distfile/RJBS/URI-cpan-1.00.tar.gz');

  isa_ok($url, 'URI::cpan::distfile', 'distfile with ver');
  is($url->author,       'RJBS',     "we can extract author");
  is($url->dist_name,    'URI-cpan', "we can extract dist_name");
  is($url->dist_version, '1.00',     "we can extract dist_version");
  is($url->dist_filepath, 'RJBS/URI-cpan-1.00.tar.gz',
                          "we can extract dist_filepath");
}

{
  my $url = URI->new('cpan:///distfile/RJBS/deep/path/URI-cpan-1.00.tar.gz');

  isa_ok($url, 'URI::cpan::distfile', 'distfile with path and ver');
  is($url->author,       'RJBS',     "we can extract author");
  is($url->dist_name,    'URI-cpan', "we can extract dist_name");
  is($url->dist_version, '1.00',     "we can extract dist_version");
}

{
  my $url = URI->new('cpan:///distfile/RJBS/URI-cpan-undef.tar.gz');

  isa_ok($url, 'URI::cpan::distfile', 'distfile with undef ver');
  is($url->author,       'RJBS',     "we can extract author");
  is($url->dist_name,    'URI-cpan', "we can extract dist_name");
  is($url->dist_version, undef,      "we can extract dist_version");
}

{
  my $url = URI->new("cpan:///author/RJBS");

  isa_ok($url, 'URI::cpan::author', 'author url');
  is($url->author,       'RJBS',     "we can extract author");
}
