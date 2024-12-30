use 5.026;
use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use lib 't/lib';
use Test::SourceFile;
use Test::SpellCheck::Plugin::Combo;
use Path::Tiny qw( path );
use Ref::Util qw( is_plain_coderef );

subtest 'basic' => sub {

  is(
    Test::SpellCheck::Plugin::Combo->new,
    object {
      call [ isa => 'Test::SpellCheck::Plugin::Combo' ] => T();
      call [ can => 'primary_dictionary' ] => F();
    },
  );

};

subtest 'basic' => sub {

  is(
    Test::SpellCheck::Plugin::Combo->new(['Lang::EN::US']),
    object {
      call [ isa => 'Test::SpellCheck::Plugin::Combo' ] => T();
      call [ can => 'primary_dictionary' ] => T();
    },
  );

};

subtest 'primary-dictionary' => sub {

  my $affix1 = file( 'foo.afx' => 'foo.afx' );
  my $dic1   = file( 'foo.dic' => 'foo.dic' );
  my $affix2 = file( 'bar.afx' => 'bar.afx' );
  my $dic2   = file( 'bar.dic' => 'bar.dic' );

  is(
    Test::SpellCheck::Plugin::Combo->new(
      ['PrimaryDictionary', affix => $affix1, dictionary => $dic1 ],
      ['PrimaryDictionary', affix => $affix2, dictionary => $dic2 ],
    ),
    object {
      call_list primary_dictionary => [ $affix1, $dic1 ];
    },
  );

};

subtest 'dictionary' => sub {

  is(
    Test::SpellCheck::Plugin::Combo->new,
    object {
      call_list dictionary => [];
    },
  );

  my $dic1   = file( 'foo.dic' => 'foo.dic' );
  my $dic2   = file( 'bar.dic' => 'bar.dic' );

  is(
    Test::SpellCheck::Plugin::Combo->new(
      ['Dictionary', dictionary => $dic1],
      ['Dictionary', dictionary => $dic2],
    ),
    object {
      call_list dictionary => [$dic1,$dic2];
    },
  );


};

subtest 'stopwords' => sub {

  is(
    Test::SpellCheck::Plugin::Combo->new,
    object {
      call_list stopwords => [];
    },
  );

  is(
    Test::SpellCheck::Plugin::Combo->new(
      ['StopWords', word => [ 'one','two','foo' ]],
      ['StopWords', word => [ 'foo','bar','baz' ]],
    ),
    object {
      call_list stopwords => ['bar','baz','foo','one','two'];
    },
  );

};

sub code_returns ($value)
{
  return validator(sub (%params) {
    my $got = $params{got};
    return 0 unless is_plain_coderef($got);
    return $got->() eq $value;
  });
}

subtest 'splitter' => sub {

  package Test::SpellCheck::Plugin::Splitter1 {
    sub new ($class) { bless {}, $class }

    sub splitter($self)
    {
      return (foo => sub { 'foo' }, bar => sub { 'bar' });
    }
  }

  package Test::SpellCheck::Plugin::Splitter2 {
    sub new ($class) { bless {}, $class }

    sub splitter($self)
    {
      return (baz => sub { 'baz' });
    }
  }

  is(
    Test::SpellCheck::Plugin::Combo->new(
      ['Splitter1'],
      ['Splitter2'],
    ),
    object {
      call_list splitter => array {
        item 'foo';
        item code_returns('foo');
        item 'bar';
        item code_returns('bar');
        item 'baz';
        item code_returns('baz');
        end;
      };
    },
  );

};

subtest 'stream' => sub {

  subtest 'empty' => sub {

    my @events;

    my $plugin = Test::SpellCheck::Plugin::Combo->new;
    $plugin->stream('Foo.pm', splitter(), sub (@event) {
      push @events, \@event;
    });

    is \@events, [];

  };

  subtest 'two' => sub {

    my @events;

    my $plugin = Test::SpellCheck::Plugin::Combo->new(
      ['TestSource', events => [['word', 1, 'foo'],['word',2,'bar']]],
      ['TestSource', events => [['word', 3, 'baz']]],
    );

    $plugin->stream('Foo.pm', splitter(), sub (@event) {
      push @events, \@event;
    });

    is
      \@events,
      [
        ['word','Foo.pm',1,'foo'],
        ['word','Foo.pm',2,'bar'],
        ['word','Foo.pm',3,'baz'],
      ],
    ;

  };

};

done_testing;
