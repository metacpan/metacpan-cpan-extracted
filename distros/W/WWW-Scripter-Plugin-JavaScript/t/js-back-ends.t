#!perl

# This script tests the way the JavaScript plugin calls methods of
# back ends.

use lib 't';
use warnings; no warnings<utf8 parenthesis regexp once qw bareword syntax>;

# Variables for collecting information for the tests
our(@method,@args,$obj);

# Dummy back end
{
   package WWW::Scripter::Plugin::JavaScript::BE;
  ++$INC{'WWW/Scripter/Plugin/JavaScript/BE.pm'};
 
   sub new {
    push @method, 'new';
    push @args, \@_;
    $obj = bless [];
   }
   for(<eval bind_classes new_function set>) {
     eval " sub $_ {
       push \@method, '$_';
       push \@args, \\\@_;
      _:
     } ";
   }
}

use WWW::Scripter;

$w = new WWW::Scripter;
$w->use_plugin('JavaScript', engine => 'BE');
$js = $w->plugin("JavaScript");

sub reset { @args = @method =(); }

use tests 6; # new and eval
$js->eval($w,'code','url','78');
is shift @method, 'new', 'eval calls "new"';
is @{$args[0]}, 2, 'new is passed one arg';
is shift @{$args[0]}, WWW'Scripter'Plugin'JavaScript'BE, 'new is passed the pkg';
is shift @{shift @args}, $w, 'new is passed the window';

while(@method and $method[0] ne 'eval') { shift @method, shift @args }
is shift @method, 'eval';
is_deeply shift @args, [$obj,'code','url','78'], 'eval args';

use tests 4; # simple delegated methods
$js->new_function('a',\&reset);
is shift @method, 'new_function', 'new_function';
is_deeply shift @args, [$obj,'a',\&reset], 'new_function arguments';
$js->set($w,'a','b','c',\&reset);
is shift @method, 'set', 'set';
is_deeply shift @args, [$obj,'a','b','c',\&reset], 'set arguments';

use tests 3; # bind_classes
$js->bind_classes(\%::);
&is(shift @method, ('bind_classes')x2);
is @{$args[0]}, 2, 'right number of args to bind_classes';
is pop @{shift @args}, \%::, 'arggh to bind_classes';
