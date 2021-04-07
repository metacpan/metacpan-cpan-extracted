package Example;

use Catalyst;
use Valiant::I18N;

__PACKAGE__->setup_plugins([qw/
  Authentication
  Session
  Session::State::Cookie
  Session::Store::Cookie
  RedirectTo
  URI
  Errors
/]);

__PACKAGE__->config(
  disable_component_resolution_regex_fallback => 1,
  default_view => 'HTML',
  'Plugin::Session' => { storage_secret_key => 'abc123' },
  'Plugin::Authentication' => {
    default_realm => 'members',
    realms => {
      members => {
        credential => {
          class => 'Password',
          password_field => 'password',
          # password_type => 'self_check'
          password_type => 'clear',
        },
        store => {
          class => 'DBIx::Class',
          user_model => 'Schema::Person',
        },
      },
    },
  },
  'Model::Schema' => {
    traits => ['SchemaProxy'],
    schema_class => 'Example::Schema',
    connect_info => {
      dsn => "dbi:SQLite:dbname=@{[ __PACKAGE__->path_to('var','db.db') ]}",
    }
  },
);

use App::Sqitch;
use App::Sqitch::Config;
use App::Sqitch::Command::add;
use SQL::Translator;
use SQL::Translator::Diff;
use Digest::MD5;

sub create_migration {
  my ($class, $change, $notes) = @_;
  $change = 'test' unless defined $change;
  $notes = 'none' unless defined $notes;

  my $schema = $class->model('Schema');
  my $dir = $class->path_to;
  my $current_ddl = SQL::Translator->new(
   no_comments => 1, # comment has timestamp so that breaks the md5 checksum
   producer => 'SQLite',
   parser => 'SQL::Translator::Parser::DBIx::Class',
   parser_args => { dbic_schema => $schema },
  )->translate;

  my $current_checksum = Digest::MD5::md5_hex($current_ddl);
  my ($last_created_schema) =  map { $_ } sort { $b cmp $a } grep { $_=~/\.sql$/} $dir->subdir('sql','schemas')->children;

  if($last_created_schema) {
    my @lines = $last_created_schema->slurp(chomp=>1);
    my ($last_checksum) = ($lines[-1] =~m/^\-\-(.+)$/);
    if($current_checksum eq $last_checksum) {
      warn "No Change!";
      return;
    }
  }

  # Save the DDL since there's a change or its the first one.
  my @d = localtime;
  my $seconds_since_midnight = ($d[2] * 3600) + ($d[1] * 60) + $d[0];
  my $file_name = sprintf("%02d-%02d-%02d-%s-%s.sql", $d[5]+1900, $d[4]+1, $d[3], $seconds_since_midnight, $change);
  my $change_name = sprintf("%02d-%02d-%02d-%s-%s", $d[5]+1900, $d[4]+1, $d[3], $seconds_since_midnight, $change);
  my $file = $dir->subdir('sql','schemas')->file($file_name);
  my $current_ddl_with_checksum = $current_ddl . "\n\n" . "--" . "$current_checksum\n";
  $file->spew($current_ddl_with_checksum);

  # Generate a Diff
  my $last_ddl = $last_created_schema ? $last_created_schema->slurp : '';
  my $schema_last = SQL::Translator->new(
    parser => 'SQLite',
    data => $last_ddl,
  )->translate;

  my $schema_current = SQL::Translator->new(
    parser => 'SQLite',
    data => $current_ddl,
  )->translate;

  $schema_last = SQL::Translator::Schema->new unless $schema_last;
  
  my $deploy_diff = SQL::Translator::Diff->new({
    output_db => 'SQLite',
    ignore_constraint_names => 1,
    target_schema => $schema_current,
    source_schema => $schema_last,
  })->compute_differences->produce_diff_sql;

  my $revert_diff = SQL::Translator::Diff->new({
    output_db => 'SQLite',
    ignore_constraint_names => 1,
    target_schema => $schema_last,
    source_schema => $schema_current,
  })->compute_differences->produce_diff_sql;

  my $path = $dir->file('sqitch.conf');
  local $ENV{SQITCH_CONFIG} = $path; #ugly, I wonder if there's a better way

  my $cmd = App::Sqitch::Command::add->new(
    sqitch => App::Sqitch->new(
      config => App::Sqitch::Config->new()
    ),
    change_name => $change_name,
    note => [$notes],
    template_directory => $dir,
  );

  $cmd->execute;

  my $deploy_script = $dir->subdir('sql','deploy')->file("${change_name}.sql")->slurp;
  $deploy_script=~s/^\-\- XXX Add DDLs here\.$/$deploy_diff/smg;
  $dir->subdir('sql','deploy')->file("${change_name}.sql")->spew($deploy_diff);

  my $revert_script = $dir->subdir('sql','revert')->file("${change_name}.sql")->slurp;
  $revert_script=~s/^\-\- XXX Add DDLs here\.$/$revert_diff/smg;
  $dir->subdir('sql','revert')->file("${change_name}.sql")->spew($revert_diff);

  print "Migration created\n";
}

__PACKAGE__->setup();
__PACKAGE__->meta->make_immutable();

