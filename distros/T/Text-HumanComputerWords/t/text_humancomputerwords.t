use Test2::V0 -no_srand => 1;
use 5.022;
use Text::HumanComputerWords;
use experimental qw( signatures );

subtest 'basic' => sub {

  is(
    Text::HumanComputerWords->new( Text::HumanComputerWords->default_perl ),
    object {
      call [ isa => 'Text::HumanComputerWords' ] => T();
      call_list [ split => 'one two https://metacpan.org mailto:plicease@cpan.org /usr/local/bin /etc c:\\foo D:/bar   three Foo::Bar::Baz YAML::XS\'s' ] => [
        [ word      => 'one'                      ],
        [ word      => 'two'                      ],
        [ url_link  => 'https://metacpan.org'     ],
        [ url_link  => 'mailto:plicease@cpan.org' ],
        [ path_name => '/usr/local/bin'           ],
        [ path_name => '/etc'                     ],
        [ path_name => 'c:\\foo'                  ],
        [ path_name => 'D:/bar'                   ],
        [ word      => 'three'                    ],
        [ module    => 'Foo::Bar::Baz'            ],
        [ module    => 'YAML::XS\'s'              ],
      ];
    },
  );

};

subtest 'multiple' => sub {

  is(
    Text::HumanComputerWords->new( foo_or_bar => sub ($word) { $word eq 'foo' }, foo_or_bar => sub ($word) { $word eq 'bar' }),
    object {
      call [ isa => 'Text::HumanComputerWords' ] => T();
      call_list [ split => 'foo bar baz' ] => [
        [ foo_or_bar => 'foo' ],
        [ foo_or_bar => 'bar' ],
        [ word       => 'baz' ],
      ];
    },
  );

};

subtest 'order matters' => sub {

  is(
    Text::HumanComputerWords->new( foo_or_bar => sub ($word) { $word eq 'foo' }, bar => sub ($word) { $word eq 'bar' }, foo_or_bar => sub ($word) { $word eq 'bar' }),
    object {
      call [ isa => 'Text::HumanComputerWords' ] => T();
      call_list [ split => 'foo bar baz' ] => [
        [ foo_or_bar => 'foo' ],
        [ bar        => 'bar' ],
        [ word       => 'baz' ],
      ];
    },
  );

};

subtest 'skip' => sub {

  is(
    Text::HumanComputerWords->new( skip => sub ($text) { $text eq 'foo/bar' } ),
    object {
      call [ isa => 'Text::HumanComputerWords' ] => T();
      call_list [ split => 'one two foo/bar three' ] => [
        [ word => 'one'   ],
        [ word => 'two'   ],
        [ word => 'three' ],
      ];
    },
  );

};

subtest 'substitute' => sub {

  is(
    Text::HumanComputerWords->new(
      substitute => sub {
        s/([A-Z]+)/ $1/g if /^[a-z]+$/i && lcfirst($_) ne lc $_;
      },
    ),
    object {
      call [ isa => 'Text::HumanComputerWords' ] => T();
      call_list [ split => 'FooBarBaz oneTwoThree' ] => [
        [ word => 'Foo' ],
        [ word => 'Bar' ],
        [ word => 'Baz' ],
        [ word => 'one' ],
        [ word => 'Two' ],
        [ word => 'Three' ],
      ];
    },
  );

};

subtest 'errors' => sub {

  local $@ = '';
  eval { Text::HumanComputerWords->new( qw( one two three ) ) };
  like "$@", qr/uneven arguments passed to constructor/;

  $@='';
  eval { Text::HumanComputerWords->new( foo => sub {}, undef, undef ) };
  like "$@", qr/argument 3 is undef/;

  $@='';
  eval { Text::HumanComputerWords->new( foo => sub {}, foo => undef ) };
  like "$@", qr/argument 4 is undef/;

  $@='';
  eval { Text::HumanComputerWords->new( foo => sub {}, sub {} => sub {} ) };
  like "$@", qr/argument 3 is not a plain string/;

  $@='';
  eval { Text::HumanComputerWords->new( foo => sub {}, foo => 'bar') };
  like "$@", qr/argument 4 is not a plain code reference/;

};

done_testing;
