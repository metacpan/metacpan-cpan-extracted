package Test::Smoke::LogMixin;
use warnings;
use strict;
BEGIN { $|++ }

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/verbosity log_warn log_info log_debug/;

our $USE_TIMESTAMP = 1;

require POSIX;

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
    use Data::Dumper;
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
    my @message = split(/\n/, sprintf("$fmt", @_));
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
