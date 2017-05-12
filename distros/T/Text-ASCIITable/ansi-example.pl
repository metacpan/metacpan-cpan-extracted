#!/usr/bin/perl
# Ugly example-usage of Text::ASCIITable with ANSI support
#
# Usage: ./ansi-example.pl <0|1>
#
# Parameter turns "drawRowLine" on and off.

=head1 NAME

ansi-example.pl - An example of how to use ANSI colors with Text::ASCIITable

=head1 SHORT DESCRIPTION

This is a ugly hack to show you how nice a ansi-shaped and -colored table can
look like. It doesn't have to be an ugly hack, but this example is. If anyone
could bother to write a prettier one, code-wise, I would be really glad if you
sent it to me, so I could replace it with this.

=head1 SYNOPSIS

  ./ansi-example.pl
  echo Wow!

=head1 REQUIRES

Text::ASCIITable

=head1 AUTHOR

Håkon Nessjøen, <lunatic@cpan.org> would like to remain anonymous.

=cut

use Text::ASCIITable;

$tt = Text::ASCIITable->new;
$tt->setOptions({allowANSI => 1, drawRowLine => int($ARGV[0]) });
$tt->setCols('eth0','eth1','total');
$tt->alignCol({ 'eth0' => 'center', 'eth1' => 'center' });
$tt->addRow(gc('a'),gc('opqrs'));
$tt->addRow(gc("a\na"),gc("a\naa"));

$t = Text::ASCIITable->new({allowANSI => 1, drawRowLine => int($ARGV[0]) });
$t->setCols( [ ye('One'), ye('Two'), ye('Three') ] );
$t->alignCol({ ye('One') => 'center', ye('Two') => 'right' });
$t->setColWidth(ye('Three'),81);

$t->addRow(g('green'),c('cyan'),ma('magenta'));
$t->addRow(c('ansi'), $tt->draw( ["\e(0\e[31ml\e[m\e(B","\e(0\e[31mk\e[m\e(B","\e(0\e[31mq\e[m\e(B","\e(0\e[31mw\e[m\e(B"],
                     ["\e(0\e[31mx\e[m\e(B","\e(0\e[31mx\e[m\e(B","\e(0\e[31mx\e[m\e(B"],
                     ["\e(0\e[31mt\e[m\e(B","\e(0\e[31mu\e[m\e(B","\e(0\e[31;1mq\e[m\e(B","\e(0\e[31;1mn\e[m\e(B"],
                     ["\e(0\e[31mx\e[m\e(B","\e(0\e[31mx\e[m\e(B","\e(0\e[31mx\e[m\e(B"],
                     ["\e(0\e[31mm\e[m\e(B","\e(0\e[31mj\e[m\e(B","\e(0\e[31mq\e[m\e(B","\e(0\e[31mv\e[m\e(B"],
                     ["\e(0\e[31mt\e[m\e(B","\e(0\e[31mu\e[m\e(B","\e(0\e[31mq\e[m\e(B","\e(0\e[31mn\e[m\e(B"]
                    ), $tt->draw()
);

# Draw table to screen
print $t->draw( ["\e(0\e[32ml\e[m\e(B","\e(0\e[32mk\e[m\e(B","\e(0\e[32mq\e[m\e(B","\e(0\e[32mw\e[m\e(B"],
                     ["\e(0\e[32mx\e[m\e(B","\e(0\e[32mx\e[m\e(B","\e(0\e[32mx\e[m\e(B"],
                     ["\e(0\e[32mt\e[m\e(B","\e(0\e[32mu\e[m\e(B","\e(0\e[32;1mq\e[m\e(B","\e(0\e[32;1mn\e[m\e(B"],
                     ["\e(0\e[32mx\e[m\e(B","\e(0\e[32mx\e[m\e(B","\e(0\e[32mx\e[m\e(B"],
                     ["\e(0\e[32mm\e[m\e(B","\e(0\e[32mj\e[m\e(B","\e(0\e[32mq\e[m\e(B","\e(0\e[32mv\e[m\e(B"],
                     ["\e(0\e[32mt\e[m\e(B","\e(0\e[32mu\e[m\e(B","\e(0\e[32mq\e[m\e(B","\e(0\e[32mn\e[m\e(B"]
                    );

# Subroutines
sub gc { # Write Graphical characters, correctly with newline
  my $out='';
  my @ary = split(/\n/,shift());
  for (0..$#ary) {
	  $out .= "\e(0".$ary[$_]."\e(B";
		$out .= "\n" if ($_ ne $#ary);
  }
	$out;
}

# Green
sub g {return "\e[32;1m".shift()."\e[m";}

# Yellow
sub ye {return "\e[33;1m".shift()."\e[m";}

# Cyan
sub c {return "\e[36;1m".shift()."\e[m";}

# Magenta
sub ma {return "\e[35;1m".shift()."\e[m";}


