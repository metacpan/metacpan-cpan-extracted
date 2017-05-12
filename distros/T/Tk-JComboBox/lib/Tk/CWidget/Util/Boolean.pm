package Tk::CWidget::Util::Boolean;

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = "0.01";

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT_OK = qw(IsTrue IsFalse TRUE FALSE);
our %EXPORT_TAGS = 
(
   functions => [qw/IsTrue IsFalse/],
   constants => [qw/TRUE FALSE/],
   all       => [@EXPORT_OK]
);

## Intended for assignment purposes
use constant 
{
    TRUE  => 1,
    FALSE => 0
};

sub IsTrue
{
   my $value = shift;
   return 1 
      if ($value && $value =~ /^\s*(1|t(rue|)|y(es|)|on)\s*$/i);
   return 0;
}

sub IsFalse
{
   my $value = shift;
   return 1 
      if (! defined($value) || $value =~ /^\s*(0|f(alse|)|n(o|)|off)\s*$/i);
   return 0;
}
