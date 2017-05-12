package Ubic::SingletonLock;
$Ubic::SingletonLock::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: lock which can be safely created several times from the same process without deadlocking


use Params::Validate;
use Scalar::Util qw(weaken);

use Ubic::Lockf;

our %LOCKS;

sub new {
    my ($class, $file, $options) = validate_pos(@_, 1, 1, 0);

    if ($LOCKS{$file}) {
        return $LOCKS{$file};
    }
    my $lock = lockf($file, $options);
    my $self = bless { file => $file, lock => $lock } => $class;

    $LOCKS{$file} = $self;
    weaken $LOCKS{$file};
    return $self;
}

sub DESTROY {
    my $self = shift;
    local $@;
    delete $LOCKS{ $self->{file} };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::SingletonLock - lock which can be safely created several times from the same process without deadlocking

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::SingletonLock;

    $lock = Ubic::SingletonLock->new($file);
    $lock_again = Ubic::SingletonLock->new($file); # this works, unlike Ubic::Lockf which would deadlock at this moment
    undef $lock;

=head1 METHODS

=over

=item B<< Ubic::SingletonLock->new($filename) >>

=item B<< Ubic::SingletonLock->new($filename, $options) >>

Construct new singleton lock.

Consequent invocations with the same C<$filename> will return the same object if previous object still exists somewhere in process memory.

Any options will be passed directly to L<Ubic::Lockf>.

=back

=head1 BUGS AND CAVEATS

This module is a part of ubic implementation and shouldn't be used in non-core code.

It passes options blindly to Ubic::Lockf, so following code will not work correctly:

    $lock = Ubic::SingletonLock->new("file", { shared => 1 });
    $lock = Ubic::SingletonLock->new("file"); # this call will just return cached shared lock again

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
