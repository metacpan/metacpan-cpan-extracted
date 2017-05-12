#!/usr/bin/env perl

use Test::More tests => 5;

use lib 't/lib';
use lib 'lib';
use lib '../lib';
use Test::Wiretap;

my @call_order;
{
  package SomePackage;

  sub method {
    my ($class, @args) = @_;
    push @call_order, 'original';
    return 'orig rv';
  }
}

# call ordering
{
  {
    my $full_featured_tap = Test::Wiretap->new({
      name => 'SomePackage::method',
      before => sub {
        push @call_order, 'before';
      },
      after => sub {
        push @call_order, 'after';
      },
    });

    SomePackage->method;

    is_deeply( \@call_order, [qw(before original after)],
      "Tap functions get called in the right order",
    );
  }
  # When the tap handle goes out of scope, the function is restored
  @call_order = ();
  SomePackage->method;
  is_deeply( \@call_order, ['original'], "Tap destruction restores original function" );

  # you can have just a before, just an after, or neither
  {
    @call_order = ();
    my $just_before_tap = Test::Wiretap->new({
      name => 'SomePackage::method',
      before => sub {
        push @call_order, 'before';
      },
    });

    SomePackage->method;

    is_deeply( \@call_order, [qw(before original)], "can omit 'after'" );
  }

  {
    @call_order = ();
    my $just_after_tap = Test::Wiretap->new({
      name => 'SomePackage::method',
      after => sub {
        push @call_order, 'after';
      },
    });

    SomePackage->method;

    is_deeply( \@call_order, [qw(original after)], "can omit 'before'" );
  }

  {
    @call_order = ();
    my $bare_tap = Test::Wiretap->new({
      name => 'SomePackage::method',
    });

    SomePackage->method;

    is_deeply( \@call_order, [qw(original)], "can omit both" );
  }
}

