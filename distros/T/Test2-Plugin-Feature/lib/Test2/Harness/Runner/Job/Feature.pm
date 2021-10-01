package Test2::Harness::Runner::Job::Feature;

use strict;
use warnings;

our $VERSION = '0.001111';

use Test2::Harness::Util::HashBase;
use parent 'Test2::Harness::Runner::Job';
use Test2::Harness::Util qw/open_file/;

sub spawn_params {
    my $self = shift;

    my $command = [$self->{task}->{command}, $self->args];

    my $out_fh = open_file($self->out_file, '>');
    my $err_fh = open_file($self->err_file, '>');
    my $in_fh  = open_file($self->in_file,  '<');

    return {
        command => $command,
        stdin   => $in_fh,
        stdout  => $out_fh,
        stderr  => $err_fh,
        chdir   => $self->ch_dir(),
        env     => $self->env_vars(),
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Harness::Runner::Job::feature - Job runner.

=head1 VERSION

version 0.001111

=head1 DESCRIPTION

B<PLEASE NOTE:> Test2::Harness is still experimental, it can all change at any
time. Documentation and tests have not been written yet!

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Yves Lavoie E<lt>ylavoie@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2019 ....

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
