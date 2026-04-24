use Test2::V0;
use Text::Treesitter::Bash::Security::Checker;

my $checker = Text::Treesitter::Bash::Security::Checker->new(
  rules => [qw( PathTraversal DangerousFlags SensitiveAccess EnvDangerousVars UnquotedExpansion MissingAbsolutePath )]
);

subtest 'PathTraversal - ../ in path' => sub {
  my @issues = $checker->check_source('cat /etc/../../etc/shadow');
  ok( scalar(grep { $_->{rule} eq 'PathTraversal' } @issues) == 1, 'detects ../ path traversal' );
};

subtest 'DangerousFlags - rm -rf' => sub {
  my @issues = $checker->check_source('rm -rf /tmp/dir');
  ok( scalar(grep { $_->{rule} eq 'DangerousFlags' } @issues) == 1, 'detects rm -rf' );
};

subtest 'SensitiveAccess - /etc/shadow' => sub {
  my @issues = $checker->check_source('cat /etc/shadow');
  ok( scalar(grep { $_->{rule} eq 'SensitiveAccess' } @issues) == 1, 'detects shadow file access' );
};

subtest 'SensitiveAccess - ~/.ssh/' => sub {
  my @issues = $checker->check_source('ls ~/.ssh/');
  ok( scalar(grep { $_->{rule} eq 'SensitiveAccess' } @issues) == 1, 'detects ssh dir access' );
};

subtest 'EnvDangerousVars - LD_PRELOAD' => sub {
  my @issues = $checker->check_source('LD_PRELOAD=/malicious.so ls');
  ok( scalar(grep { $_->{rule} eq 'EnvDangerousVars' } @issues) == 1, 'detects LD_PRELOAD' );
};

subtest 'UnquotedExpansion - unquoted var in path' => sub {
  my @issues = $checker->check_source('cat $HOME/.ssh/id_rsa');
  ok( scalar(grep { $_->{rule} eq 'UnquotedExpansion' } @issues) == 1, 'detects unquoted expansion' );
};

subtest 'no issues on safe command' => sub {
  my @issues = $checker->check_source('ls /tmp');
  is( \@issues, [], 'no issues for safe command' );
};

done_testing;