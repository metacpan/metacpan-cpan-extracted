package Text::Thread;
use strict;
use warnings;

our $VERSION = '0.2';

no warnings  'closure';

=head1 NAME

Text::Thread - format threaded items to ascii tree

=head1 SYNOPSIS

    use Text::Thread;

    my @tree = (
     { title => 'test1',
       child => [{ title => 'test2',
		   child => [{ title => 'test5' },
			     { title => 'test3'}]}]},
     { title => 'test4' } );

    my @list = Text::Thread::formatthread
        ('child', 'threadtitle', 'title', \@tree);

    print "$_->{threadtitle}\n" foreach @list;

=head1 DESCRIPTION

B<Text::Thread> formats a tree structure into a ascii tree, which is
often used in threaded mail and netnews reader.

=over 4

=item formatthread CHILD THREADTITLE TITLE TREE

format the given TREE. CHILD is the hash key for child nodes in the
items in TREE. it could be either arrayref or hashref. THREADTITLE is
the key for the output ascii tree in each node. TITLE is the thing to
be put at the leaves of the tree.

=back

=cut

# warning: this is lisp
sub formatthread {
    my ($c, $t, $ot, $tree) = @_;
    no warnings 'uninitialized';
    sub flat {
	my @child = ref($_[0]->{$c}) eq 'HASH' ?
	    values %{$_[0]->{$c}} : @{$_[0]->{$c}} if $_[0]->{$c};
	$_[1] |= (my $bit = 1 << $_[0]->{level});
	($_[0], map { my $last = $_ eq $child[-1];
		      $_->{$t} = (join('',map {
			  ($_[1] & 1 << $_) ? '| ' : '  '
		      }(0..$_[0]->{level}-1))).
			  ($last ? '`' : '|').'->'.
			      ($_->{$ot} eq $_[0]->{$ot}
			       ? '' : $_->{$ot});
		      $_->{level} = $_[0]->{level} + 1;
		      $_[1] ^= $bit if $last;
		      flat($_, $_[1]);
		  } @child)
    };
    map {$_->{$t} = $_->{$ot}; flat $_} @$tree;
}

1;

=head1 BUGS

It doesn't work if the depth of the tree is more than 32.

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.org>

=head1 COPYRIGHT

Copyright 2001,2006 by Chia-liang kao E<lt>clkao@clkao.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
