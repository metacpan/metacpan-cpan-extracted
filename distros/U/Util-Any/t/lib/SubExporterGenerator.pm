package SubExporterGenerator;

use strict;
use Util::Any -Base;

our $Utils =
  {
   -test => [
             [
              'List::MoreUtils', '',
              {
               foo => sub {sub () {"foo"} },
               -select => ['uniq'],
              }
             ],
             [
             'List::Util', '',
             {
              -select => ['shuffle'],
              min => \&build_min_reformatter,
              max => \&build_max_reformatter,
              hoge => sub { sub () {"hogehoge"}},
              check_default => \&check_default,
             }
            ],
            ]
  };

sub build_min_reformatter {
  my ($pkg, $class, $name, @option) = @_;
  no strict 'refs';
  my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
  sub {
    my @args = @_;
    $code->(@args, ($option[0]->{under} || ()));
  }
}

sub build_max_reformatter {
  my ($pkg, $class, $name, @option) = @_;
  my $code = do { no strict 'refs'; \&{$class . '::' . $name}};
  sub {
    my @args = @_;
    $code->(@args, ($option[0]->{upper} || ()));
  }
}

sub check_default {
  my ($pkg, $class, $name, $args, $default_args) = @_;
  sub {
    return $default_args;
  }
}

1;
