use strict;
use warnings;
use Test::More;

use Win32::Unicode::InternetShortcut;

BEGIN {
    no warnings 'once';
    $Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 1;
    Win32::Unicode::InternetShortcut->CoInitialize();
}

my $self = Win32::Unicode::InternetShortcut->new;
my $url  = 'http://www.example.com/';
my $path = 'test.url';

my @tests = (
  sub {
    ok(ref $self eq 'Win32::Unicode::InternetShortcut');
  },
  sub {
    $self->save($path, $url);
    ok(-f $path);
  },
  sub {
    $self->load($path);
    ok($self->{path} eq $path);
  },
  sub {
    ok($self->{url} eq $url);
  },
  sub {
    SKIP: {
      skip 'This test seems unreliable: '.
           'set $ENV{TEST_MODIFIED} to test', 1
        unless $ENV{TEST_MODIFIED};

      ok($self->{modified});
    }
  },
  sub {
    $self->load_properties($path);
    ok(ref $self->{properties} eq 'HASH');
  },
  (defined $self->{properties}->{url} ?
    sub {
      ok($self->{properties}->{url} eq $url);
    }
    :
    ()
  ),
  sub {
    ok(ref $self->{site_properties} eq 'HASH');
  },
  (defined $ENV{TEST_INVOKE} ?
    sub {
      ok($self->invoke($path));
    }
    :
    ()
  ),
);

plan tests => scalar @tests;
foreach my $test (@tests) { $test->() }

unlink $path;

END {
    Win32::Unicode::InternetShortcut->CoUninitialize();
}

