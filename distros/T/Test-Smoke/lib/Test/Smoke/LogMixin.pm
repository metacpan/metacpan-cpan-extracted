package Test::Smoke::LogMixin;
use warnings;
use strict;
use Data::Dumper;
BEGIN { $|++ }

our $VERSION = '0.002';

use Exporter 'import';
our @EXPORT = qw/verbosity log_warn log_info log_debug/;

our $USE_TIMESTAMP = 1;

require POSIX;

=head1 NAME

Test::Smoke::LogMixin - "Role" that adds logging methods to "traditional" objects.

=head1 SYNOPSIS

    package MyPackage;
    use warnings;
    use strict;
    use Test::Smoke::LogMixin;

    sub new {
        my $class = shift;
        my %selfish = @_;
        $selfish{_verbose} ||= 0;
        return bless \%selfish, $class;
    }
    1;

    package main;
    use MyPackage;
    my $o = MyPackage->new(_verbose => 2);
    $o->log_debug("This will end up in the log");

=head1 DESCRIPTION

This package with these mixin-methods acts like a role to extend your traditional (created with
C<bless()>) object with 4 new methods. It has some extra
L<Test::Smoke::App::Base> logic to determine the log-level (by looking at C<<
$app->option('verbose') >>).  For other object types it tries to fiend if there
are methods by the name C<verbose> or C<v>, or maybe the keys C<_verbose> or
C<_v> (See also L<Test::Smoke::ObjectBase>).

The three log methods use the C<sprintf()> way of composing strings whenever
more than 1 argument is passed!

=head2 $app->verbosity

Return the verbosity of this app.

=head3 Arguments

None.

=head3 Returns

The value of either C<_verbose> or C<_v>

=cut

sub verbosity {
    my $self = shift;
    if ($self->isa('Test::Smoke::App::Base')) {
        return $self->option('verbose');
    }
    for my $vfield (qw/verbose v/) {
        return $self->$vfield if $self->can($vfield) or exists $self->{"_$vfield"};
    }
    my $struct = Data::Dumper->new([$self])->Terse(1)->Sortkeys(1)->Indent(1)->Dump;
    die "Could not find a verbosity option: $struct\n";
}

=head2 $app->log_warn($fmt, @values)

C<< prinf $fmt, @values >> to the currently selected filehandle.

=head3 Arguments

Positional.

=over

=item $fmt => a (s)printf format

The format gets an extra new line if one wasn't present.

=item @values => optional vaules for the template.

=back

=head3 Returns

use in void context.

=head3 Exceptions

None.

=cut

sub log_warn {
    my $self = shift;

    print _log_message(@_);
}

=head2 $app->log_info($fmt, @values)

C<< prinf $fmt, @values >> to the currently selected filehandle if the 'verbose'
option is set.

=head3 Arguments

Positional.

=over

=item $fmt => a (s)printf format

The format gets an extra new line if one wasn't present.

=item @values => optional vaules for the template.

=back

=head3 Returns

use in void context.

=head3 Exceptions

None.

=cut

sub log_info {
    my $self = shift;
    return if !$self->verbosity;

    print _log_message(@_);
}

=head2 $app->log_debug($fmt, @values)

C<< prinf $fmt, @values >> to the currently selected filehandle if the 'verbose'
option is set to a value > 1.

=head3 Arguments

Positional.

=over

=item $fmt => a (s)printf format

The format gets an extra new line if one wasn't present.

=item @values => optional vaules for the template.

=back

=head3 Returns

use in void context.

=head3 Exceptions

None.

=cut

sub log_debug {
    my $self = shift;
    return if $self->verbosity < 2;

    print _log_message(@_);
}

# Compose the message to be logged.
sub _log_message {
    (my $fmt = shift) =~ s/\n*\z//;

    my $stamp = $USE_TIMESTAMP
        ? $^O eq 'MSWin32'
            ? POSIX::strftime("[%Y-%m-%d %H:%M:%SZ] ", gmtime)
            : POSIX::strftime("[%Y-%m-%d %H:%M:%S%z] ", localtime)
        : "";

    # use the $stamp for every line.
    # sprintf iff @_;
    my @message = split(/\n/, @_ ? sprintf("$fmt", @_) : ($fmt));
    return join("\n", map "$stamp$_", @message) . "\n";
}

=head1 NAME

Test::Smoke::Logger - Helper object for logging.

=head1 SYNOPSIS

    use Test::Smoke::LogMixin;
    my $logger = Test::Smoke::Logger->new(v => 1);
    $logger->log_warn("Minimal log level"); # v >= 0
    $logger->log_info("Medium log level");  # v <= 1
    $logger->log_debug("High log level");   # v >  1

=head1 DESCRIPTION

=head2 Test::Smoke::Logger->new(%arguments)

Return a logger instance.

=head3 Arguments

Named, hash:

=over

=item v => <0|1|2>

=back

=head3 Returns

The L<Test::Smoke::Logger> instance.

=cut

package Test::Smoke::Logger;
use warnings;
use strict;
use base 'Test::Smoke::ObjectBase';
use Test::Smoke::LogMixin;
Test::Smoke::LogMixin->import();

sub new {
    my $class = shift;
    my %raw = @_;
    my $self = { _verbose => $raw{v} || 0 };
    return bless $self, $class;
}

1;

=head1 COPYRIGHT

(c) 2020, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
