package Test2::Bundle::SpecDeclare;
use strict;
use warnings;

use Test2::IPC;

require Test2::Bundle::Extended;
require Test2::Tools::Spec;
require Test2::Plugin::SpecDeclare;

sub import {
    my $class = shift;
    my @args  = @_;

    my @caller = caller;
    my $target = {
        package => $caller[0],
        file    => $caller[1],
        line    => $caller[2],
    };

    my @imports = qw{
        describe
        tests it
        case
        before_all  around_all  after_all
        before_case around_case after_case
        before_each around_each after_each
        mini
        iso   miso
        async masync
    };

    eval <<"    EOT" || die $@;
package $caller[0];
#line $caller[2] "$caller[1]"
Test2::Bundle::Extended->import(\@args); Test2::Tools::Spec->import(\@imports); Test2::Plugin::SpecDeclare->import;
1;
    EOT
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Bundle::Spec - Extended Bundle + IPC + Spec + SpecDeclare

=head1 DESCRIPTION

This loads the L<Test2::IPC> module, as well as L<Test2::Bundle::Extended>,
L<Test2::Tools::Spec>, and L<Test2::Tools::SpecDeclare>.

=head1 SYNOPSIS

    use Test2::Bundle::SpecDeclare;

Is the same as:

    use Test2::IPC;
    use Test2::Bundle::Extended;
    use Test2::Tools::Spec;
    use Test2::Plugin::SpecDeclare;

=head1 SOURCE

The source code repository for Test2-Workflow can be found at
F<http://github.com/Test-More/Test2-Workflow/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
