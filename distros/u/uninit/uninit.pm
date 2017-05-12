package uninit;

$uninit::VERSION="1.00";

CHECK {
   use B qw(main_start);
   my %globs;
   my ($prog, $line);
   for (my $op = main_start; $$op; $op = $op->next) {
    if ($op->name =~ /gvsv/) {
        my $var = '$'.$op->sv->SAFENAME;
        my $top = $op;
        $top = $top->sibling while $top->can("sibling") and ${$top->sibling};
        if ($top->next->name =~ /assign/) {
            $assigned{$var}++;
        } elsif (not exists $assigned{$var}) {
            warn "$var may be used uninitialized at $prog line $line.\n";
        }
    } elsif ($op->name eq "nextstate") {
        $prog = $op->file; $line = $op->line; 
    }
   }
}

=pod

=head1 NAME

uninit - Warn about uninitialized variables

=head1 SYNOPSIS

    perl -Muninit myprogram

=head1 DESCRIPTION

It's all very well being warned about the use of C<undef> if you
don't know what variable it is that contains C<undef>, especially
if you've got more than one variable in a line. 

C<uninit> attempts to do compile-time static checking of your
program to see if any variables are used before they have any
values assigned to them; it also reports B<which> variable actually
caused the problem.

It isn't guaranteed to catch all cases, and you can probably trick
it with judicious use of C<eval>, but I can't do anything about that.
It's only a guideline.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<optimize>, L<B>

=cut

1;
