#
# Outline.pm
#
# Author: Malcolm Beattie, mbeattie@sable.ox.ac.uk
#
# This program may be distributed under the GNU General Public License (GPL)
#
# 1 June 1999  Initial release
#
# Although this module is a standalone module, it is distributed only
# with WING for now, since I haven't properly documented it yet.
#

package Outline;
use strict;

sub new {
    my $class = shift;
    my $tree = [0, "main"];
    my $o = bless {stack => [$tree], ix => 0, tree => $tree}, $class;
    return $o;
}

sub _flip {
    my ($t, $ix, $val) = @_;
    if ($ix >= length($t)) {
	$t .= "0" x ($ix - length($t) + 1);
    }
    substr($t, $ix, 1) = $val;
    return $t;
}

sub _walk {
    my ($l, $level, $template, $callback) = @_;
    my ($ix, $title, @els) = @$l;
    foreach my $e (@els) {
	if (ref($e)) {
	    ($ix, $title) = @$e;
	    if (substr($template, $ix, 1)) {
		&$callback($level, $title, 1, _flip($template, $ix, 0));
		_walk($e, $level + 1, $template, $callback);
		&$callback($level);
	    } else {
		&$callback($level, $title, 0, _flip($template, $ix, 1));
	    }
	} else {
	    &$callback($level, $e);
	}
    }
}

sub walk {
    my ($o, $template, $callback) = @_;
    _walk($o->{tree}, 0, $template, $callback);
}

sub start_sublist {
    my ($o, $title) = @_;
    my $l = $o->{stack}->[-1];
    push(@$l, $l = [$o->{ix}++, $title]);
    push(@{$o->{stack}}, $l);
}

sub end_sublist {
    my $o = shift;
    pop(@{$o->{stack}});
}

sub add_item {
    my ($o, $line) = @_;
    push(@{$o->{stack}->[-1]}, $line);
}

1;
