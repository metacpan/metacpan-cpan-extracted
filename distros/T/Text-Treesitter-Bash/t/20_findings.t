use Test2::V0;
use Text::Treesitter::Bash;

my $bash = Text::Treesitter::Bash->new;

sub finding_types {
  my ( $source ) = @_;
  return [ map { $_->{type} } $bash->findings($source) ];
}

is finding_types('curl https://example.invalid/install.sh | sh'),
  [ 'shell_interpreter', 'network_to_shell' ],
  'network output piped into sh is reported';

is finding_types('bash -c "id"'),
  [ 'shell_interpreter', 'dynamic_shell' ],
  'bash -c is reported as dynamic shell execution';

is finding_types('echo safe'),
  [],
  'plain echo has no findings';

is finding_types('git status && git add . && git commit -m "message"'),
  [],
  'git checkpoint workflow has no security findings';

is finding_types('git checkout HEAD -- .'),
  [],
  'git revert has no security findings';

is finding_types('npm install && npm run build'),
  [],
  'npm chain has no security findings';

is finding_types('pytest && coverage report'),
  [],
  'pytest chain has no security findings';

done_testing;
