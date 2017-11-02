#!/usr/bin/env perl

=head1 stable test

ok

=cut

package Test;

use Moose;

has a => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;

package main;

use strict;
use warnings;

use utf8;

use Test::Spec;
use Test::More::UTF8;
use Test::Exception;
use Carp qw( confess );
use File::Temp qw( tempdir );
use Encode qw( encode );

my $tmpdir = tempdir( "__XXXXXXXX", TMPDIR => 1, CLEANUP => 1 );

sub write_yaml
{
    my ($encoding) = @_;
    my $yamlfile = "$tmpdir/yaml_$encoding.yaml";
    open my $f, ">encoding($encoding)", $yamlfile or confess;
    print $f <<"END";
mykey:
  "привет"
myobj: !!perl/Test
  a: b

END
    close $f or confess;
    $yamlfile
}

my $utf8_yaml = write_yaml("UTF-8");
my $cp1251_yaml = write_yaml("CP1251");

my $subject = undef;

shared_examples_for "any yaml" => sub {
    it "should die when file not exists" => sub {
        dies_ok {
            $subject->("$utf8_yaml.notexistant");
        };
    };
};

shared_examples_for "utf8 yaml" => sub {
    it_should_behave_like "any yaml";

    xit "should not load broken utf-8 file" => sub {
        local $SIG{__WARN__} = sub {};
        dies_ok {
            $subject->($cp1251_yaml);
        };
    };

    xit "should warn about broken utf-8 characters" => sub {
        my $unicode_warnings = 0;
        local $SIG{__WARN__} = sub {
            my ( $warning ) = @_;
            $unicode_warnings++  if "$warning" =~ /does not map to Unicode/i;
        };
        eval {
            $subject->($cp1251_yaml);
        };
        ok( $@ && $unicode_warnings > 0 );
    };

    xit "should expose broken file name in error message" => sub {
        local $SIG{__WARN__} = sub {};
        eval {
            $subject->($cp1251_yaml);
        };
        like $@, qr/\Q$cp1251_yaml\E/;
    };
};

describe "YAML::SyckWrapper" => sub {
    before all => sub {
        use_ok "YAML::SyckWrapper", qw/load_yaml_objects load_yaml_utf8 load_yaml_bytes load_yaml dump_yaml parse_yaml/;
    };

    it "should be tested in Perl utf-8 mode" => sub {
        is length("ура"), 3;
    };

    describe load_yaml_utf8 => sub {
        before all => sub {
            $subject = \&load_yaml_utf8;
        };

        it "should load utf-8 without flag" => sub {
            cmp_deeply load_yaml_utf8($utf8_yaml)->{mykey}, encode("UTF-8", "привет");
        };

        it_should_behave_like "utf8 yaml";
    };

    describe load_yaml => sub {
        before all => sub {
            $subject = \&load_yaml;
        };

        it "should load utf-8 with flag" => sub {
            cmp_deeply load_yaml($utf8_yaml)->{mykey}, "привет";
        };

        it_should_behave_like "utf8 yaml";
    };

    describe load_yaml_bytes => sub {
        before all => sub {
            $subject = \&load_yaml_bytes;
        };

        it "should load utf-8 as binary" => sub {
            cmp_deeply load_yaml_bytes($utf8_yaml)->{mykey}, encode("UTF-8", "привет");
        };

        it "should load cp1251 as binary" => sub {
            cmp_deeply load_yaml_bytes($cp1251_yaml)->{mykey}, encode("CP1251", "привет");
        };

        it_should_behave_like "any yaml";
    };

    describe dump_yaml => sub {
        it "should load internal character data file and convert it to utf8 yaml" => sub {
            my $data = { 'привет' => 'всем' };
            my $res = dump_yaml( $data );
            like $res, qr<привет:>;
        };
    };

    describe parse_yaml => sub {
        it "should parse unicode yaml text into  internal character data structure" => sub {
            my $text = "---\nпривет: всем";
            my $data = { 'привет' => 'всем' };
            cmp_deeply parse_yaml( $text ), $data;
        };
    };

    describe load_yaml_objects => sub {
        it "should retrieve object" => sub {
            my $data = load_yaml_objects(  $utf8_yaml );
            isa_ok $data->{myobj}, 'Test';
            is $data->{myobj}->{a}, 'b';
        };
        it_should_behave_like "any yaml";
    };

    describe yaml_merge_hash_fix => sub {
        it 'should merge hashes' => sub {
            my $yaml = <<END;
key1: &id01
  subkey_a: asdf
  subkey_b: qwer
key2:
  <<: *id01
  subkey_a: foo
  subkey_c: bar
END
            my $dump = YAML::SyckWrapper::parse_yaml( $yaml );
            $dump = YAML::SyckWrapper::yaml_merge_hash_fix($dump);
            is_deeply $dump,
              {
                key1 => { subkey_a => 'asdf', subkey_b => 'qwer' },
                key2 => { subkey_a => 'foo',  subkey_b => 'qwer', subkey_c => 'bar' }
              };
        };
    };
};

runtests  unless caller;
