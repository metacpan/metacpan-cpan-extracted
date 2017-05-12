package use;
use strict;
use warnings;
use 5.008;
our $VERSION = '0.05';
use base 'use::perl5';
use version 0.86 'is_lax';

sub use {
    unshift @_, __PACKAGE__;
    goto &{__PACKAGE__->can('import')};
}

sub import {
    return unless @_;
    my $class = shift(@_);
    if (@_ and is_lax($_[0])) {
        my $perl_version = version->parse(shift(@_))->numify;
        eval "use $perl_version; 1" or die $@;
        if ($perl_version >= 5.009003 and $perl_version < 6) {
            my $sub_version = int(($perl_version - 5) * 1000);
            push @_, (
                strict =>
                feature => [":5.$sub_version"],
            );
        }
    }
    unshift @_, $class;
    goto &{use::perl5->can('importer')};
}

1;

__END__

=encoding utf8

=head1 NAME

use - Import several modules with a single use statement

=head1 SYNOPSIS

    # Use several modules in command line:
    % perl -Muse=CGI,DBI,PPI -e '...'

    # Import several modules at once
    use use qw[ strict warnings methods invoker ];

    # Pass options as array refs
    use use 'strict', 'warnings', 'HTTP::Status' => [':constants'];

    # Pass required versions after module names
    use use '5.12.0', 'HTTP::Status' => '6.00' => [':constants'];

    # ...or in your own module, importing on behalf of its caller:
    package MY::Macro;
    sub import {
        use use;
        local @_ = qw[ Module1 Module2 ];
        goto &use::use;
    }

=head1 DESCRIPTION

This module lets you import several modules at once.

This is almost the same as L<modules>, except that C<caller> is
properly set up so syntax-altering modules based on L<Devel::Declare>,
L<Filter::Simple> or L<Module::Compile> work correctly.

If a Perl version number larger than C<5.9.3> appears as the first argument,
then it's automatically expanded just like a regular C<use VERSION> statement.
For example, C<use use '5.12.0'> expands to C<use strict; use feature ':5.12'>.

=head1 ACKNOWLEDGEMENTS

Thanks to ingy∵net for refactoring most of this module into the L<perl5>
module, and making this module a simple subclass of it.

=head1 SEE ALSO

L<perl5>, L<modules>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<use>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
