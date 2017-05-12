use Test::More tests => 4;
use YAML::Perl 'emit';
use YAML::Perl::Events;

my $yaml1 = emit(
    [
        YAML::Perl::Event::StreamStart->new(),
        YAML::Perl::Event::DocumentStart->new(explicit => 0),
        YAML::Perl::Event::Scalar->new(value => "foo\nbar\n", style => '|'),
        YAML::Perl::Event::DocumentEnd->new(),
        YAML::Perl::Event::StreamEnd->new(),
    ]
);

is $yaml1, <<'...', 'Headerless literal scalar';
|
  foo
  bar
...

my $yaml2 = emit(
    [
        YAML::Perl::Event::StreamStart->new(),
        YAML::Perl::Event::DocumentStart->new(explicit => 1),
        YAML::Perl::Event::Scalar->new(value => "foo\nbar\n", style => '|'),
        YAML::Perl::Event::DocumentEnd->new(),
        YAML::Perl::Event::StreamEnd->new(),
    ]
);

is $yaml2, <<'...', 'Headered literal scalar';
--- |
  foo
  bar
...

my $yaml3 = emit(
    [
        YAML::Perl::Event::StreamStart->new(),
        YAML::Perl::Event::DocumentStart->new(),
        YAML::Perl::Event::Scalar->new(value => "foo\nbar\n", style => '|'),
        YAML::Perl::Event::DocumentEnd->new(),
        YAML::Perl::Event::StreamEnd->new(),
    ]
);

is $yaml3, <<'...', 'Default-Headered literal scalar';
--- |
  foo
  bar
...

my $yaml4 = emit(
    [
        YAML::Perl::Event::StreamStart->new(),
        YAML::Perl::Event::DocumentStart->new(),
        YAML::Perl::Event::Scalar->new(value => "foo\nbar\n", style => '"'),
        YAML::Perl::Event::DocumentEnd->new(),
        YAML::Perl::Event::StreamEnd->new(),
    ]
);

is $yaml4, <<'...', 'Double quoted scalar';
--- "foo\nbar\n"
...
