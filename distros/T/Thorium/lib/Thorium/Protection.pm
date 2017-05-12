package Thorium::Protection;
{
  $Thorium::Protection::VERSION = '0.510';
}
BEGIN {
  $Thorium::Protection::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Use protection when dealing with radioactive elements

use strict;
use warnings;

sub import {
    strict->import();
    warnings->import();

    require utf8;
    utf8->import();

    require feature;
    feature->import(':5.10');

    require mro;
    mro->import();
    mro::set_mro(scalar(caller()), 'c3');

    no indirect;
    indirect->unimport(':FATAL');

    return;
}

1;



=pod

=head1 NAME

Thorium::Protection - Use protection when dealing with radioactive elements

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    use Thorium::Protection;

=head1 DESCRIPTION

This pragma[1] does:

=over

=item * Turns on strict

=item * Turns on all warnings

=item * Enable 5.10+ features via L<feature>

=item * Sets the method order resolution (mro) to C3. See L<mro> for more info

=item * Turns indirect method calling into a fatal action. This is done through
L<indirect>

=back

Inspiration derived from L<Modern::Perl> and cron.

[1] Technically not a pragma, but a lower case package name. But since we are
changing pragma-y things, make it look like one

=head1 WARNINGS

=over

=item * The C<use> should be as close to the first thing executed as possible,
otherwise you may think you have strict turned on, but won't.

=item * Use of this in modules isn't encouraged as you don't really gain
anything other than a shaving off a few keystrokes. Modules are generally not
invoked as if executables from the command line. Additionally there would be a
slight (not timed/tested) overhead of doing this a large amount of
times. Therefore, stick to use in non-modules.

=item * Not tested under mod_perl. While I don't suspect any problems, mod_perl
does weird things.

=item * This doesn't enabled strict, warnings, etc for all modules/other perl
associated with that script -- only to the end of the file.

=back

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

