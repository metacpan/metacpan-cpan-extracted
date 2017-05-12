package VCI::Util;
use Moose::Util::TypeConstraints;

use Carp qw(confess);
use DateTime;
use DateTime::Format::DateParse;
use Path::Abstract::Underload;
use Scalar::Util qw(blessed);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(taint_fail detaint CLASS_METHODS);

# A list of _class methods from VCI.pm that we delegate to other classes.
use constant CLASS_METHODS => qw(
    commit_class
    diff_class
    directory_class
    file_class
    history_class
    project_class
    repository_class
);
    
###############
# Subroutines #
###############

sub taint_fail {
    my ($msg) = @_;
    
    # Carp just fails utterly to get our messages right, no matter if we
    # try @CARP_NOT, %Carp::CarpInternals, or $Carp::CarpLevel. So I just
    # did this manually myself, to at least give somebody the idea of
    # where their error is.
    my $level = 1;
    while (caller($level) =~ /^VCI::(?:Abstract|VCS)::/
           || caller($level) =~ /^Moose::/ ) { $level++; }
    
    my @info = caller($level);
    $msg .= " at $info[1] line $info[2].\n";
    if (${^TAINT} == 1) {
        die($msg);
    }
    elsif (${^TAINT} == -1) {
        warn($msg);
    }
}

sub detaint {
    return if !defined $_[0];
    $_[0] =~ /^(.*)$/s;
    $_[0] = $1;
}

################
# Object Types #
################

subtype 'VCI::Type::DateTime'
    => as 'Object'
    => where { $_->isa('DateTime') };

coerce 'VCI::Type::DateTime'
    => from 'Num'
        => via { DateTime->from_epoch(epoch => $_) }
    => from 'Str'
        => via {
            my $result = DateTime::Format::DateParse->parse_datetime($_);
            if (!defined $result) {
                confess("Date::Parse failed to parse '$_' into a DateTime");
            }
            return $result;
        };

subtype 'VCI::Type::IntBool'
    => as 'Int';
coerce 'VCI::Type::IntBool'
    => from 'Undef'
        => via { 0 }
    => from 'Str'
        => via { $_ ? 1 : 0 };

subtype 'VCI::Type::Path'
    => as 'Object',
    => where { $_->isa('Path::Abstract::Underload') && $_->stringify !~ m{/\s*$}o };

coerce 'VCI::Type::Path'
    => from 'Str'
        => via {
            $_ =~ s{/\s*$}{}o;
            Path::Abstract::Underload->new($_)->to_branch;
        }
    => from 'ArrayRef'
                # XXX This may not deal with trailing slashes properly.
        => via { Path::Abstract::Underload->new(@$_)->to_branch; }
    => from 'Object'
        => via { $_->to_branch };


1;

__END__

=head1 NAME

VCI::Util - Types and Utility Functions used by VCI

=head1 DESCRIPTION

This contains mostly L<subtypes|Moose::Util::TypeConstraints/subtype> used
by accessors in various VCI modules.

=head1 TYPES

=over

=item C<VCI::Type::DateTime>

A L<DateTime> object.

If you pass in a number for this argument, it will be interpreted as
a Unix epoch (seconds since January 1, 1970) and converted to a DateTime
object using L<DateTime/from_epoch>.

If you pass in a string that's not just an integer, it will be parsed
by L<DateTime::Format::DateParse>. (B<Note>: If you don't specify a time
zone in your string, it will be assumed your time is in the local time zone.)

=item C<VCI::Type::IntBool>

This is basically an Int that accepts C<undef> and turns it into 0, and
converts a string into C<1> if it represents a true value, C<0> if it doesn't.

=item C<VCI::Type::Path>

A L<Path::Abstract::Underload> object. You can convert this into a string
by calling C<stringify> on it, like: C<< $object->stringify >>

If you pass a string for this argument, it will be converted using
L<Path::Abstract::Underload/new>. This means that paths are always Unix
paths--the path separator is always C</>. C<\path\to\file> will not work.

After processing, the path will never start with C</> and never end with
C</>. (In other words, it will always be a relative path and never end
with C</>.)

If you pass the root path (C</>) you will get an empty path.

=back

=head1 SUBROUTINES

=over

=item C<detaint>

Used internally to detaint strings that are only used in safe ways.

Unsafe actions would include:

=over

=item *

C<system> or C<exec> calls

=item *

Putting the string unchecked directly into SQL

=item *

Passing to any external program or module that doesn't properly check
its arguments for security issues, or that might do something unsafe with
a particular file or directory that you're passing. (This is true even if you
use a safe module like C<IPC::Run> to call the command.)

=back

That is not a complete list. All VCI::VCS implementors are strongly
encouraged to read L<perlsec>.

Note that passing a string to L<IPC::Cmd> is safe, because a shell is never
invoked.

=item C<taint_fail>

This handles throwing errors or warnings under taint mode. If we're
in C<-t> mode, this just throws a warning. If we're in C<-T> mode,
this will throw an error using the message you pass.

Messages are thrown from the perspective of the caller, so the error
is shown up as an error in the caller's code, not an error in VCI.

It takes one argument: the message to warn or die with.

=back
