package UtilExporter;

use strict;
use Clone qw/clone/;

use Util::Any -Exporter;

our @EXPORT = qw/hello/;
our @EXPORT_OK = qw/askme hello hi/;
our %EXPORT_TAGS = (
                    'greet' => [qw/hello hi/],
                    'uk'    => [qw/hello/],
                    'us'    => [qw/hi/],
                    'hello' => [qw/hello_name hello_where/],
                    'all'   => [qw/hello hi askme/],
                   );

our $Utils = clone $Util::Any::Utils;
$Utils->{l2s} = [
                 ['List::Util', '', [qw(first min minstr max maxstr sum)]],
                ];
$Utils->{-hello} = [
                    ['exampleHello' => '', {'hey'   => \&hey_generator}],
                   ];

sub hello { "hello there" }
sub askme { "what you will" }
sub hi    { "hi there" }
sub hello_where { "hello where" }

sub hey_generator {
  my ($self, $class, $func, $given) = @_;
  my $at = $given->{at};
  my $in = $given->{in};
  return sub {
    no strict 'refs';
    my ($_at, $_in) = @_;
    &{$class . '::' . $func}($_at || $at, $_in || $in);
  }
}

1;
