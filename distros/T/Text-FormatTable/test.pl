use Test;
BEGIN { plan tests => 5 };
use Text::FormatTable;
ok(1); # If we made it this far, we're ok.

use strict;
use warnings;

{
    my $table = Text::FormatTable->new('r| l l');
$table->head('a', 'b', 'c');
    $table->rule('=');
    $table->row('this a test, a nice test', 'oh, cool, a test!', 'yep');
    $table->rule;
    $table->row('you mean it\'s really a test?', 'yes, it is.', 'z');
    $table->rule('=');
    my $is = $table->render(15);

    my $shouldbe = <<'END';
     a| b     c  
=================
this a| oh,   yep
 test,| cool,    
a nice| a        
  test| test!    
------+----------
   you| yes,  z  
  mean| it       
  it's| is.      
really|          
     a|          
 test?|          
=================
END

    ok($is, $shouldbe);
}

# Test behavior with ANSI-colored header
{
    my $colortable = Text::FormatTable->new('l l l');
    my $RED = "\e[31m";
    my $RESET = "\e[0m";
    $colortable->head('foo', $RED . 'bar' . $RESET, 'bat');
    $colortable->rule('=');
    $colortable->row(qw(a b c));
    my $output = $colortable->render();
    my ($rule) = ($output =~ /(=+)/);
    ok(length($rule), length("foo bar bat"));
}

# Test behavior with ANSI-colored row data
{
    my $colortable = Text::FormatTable->new('l l l');
    my $RED = "\e[31m";
    my $RESET = "\e[0m";
    $colortable->head('foo', 'bar', 'bat');
    $colortable->rule('=');
    $colortable->row('a', $RED . 'b' . $RESET, 'c');
    my $output = $colortable->render();
    my ($rule) = ($output =~ /(=+)/);
    ok(length($rule), length("foo bar bat"));
}

# rt34546, warnings when column has zero length
{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    
    my $table = Text::FormatTable->new('l l');
    $table->head('foo', q{});
    my $output = $table->render();
    ok(not defined $warning);
}
