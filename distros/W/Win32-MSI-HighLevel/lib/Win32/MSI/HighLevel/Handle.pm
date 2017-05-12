use strict;
use warnings;

=head1 NAME

Win32::MSI::HighLevel::Handle - Helper module for Win32::MSI::HighLevel.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


package Win32::MSI::HighLevel::Handle;

use Win32::API;
use Win32::MSI::HighLevel::Common;
use Carp;
#use Devel::StackTrace;

use constant kDebug => 0;

my $MsiCloseHandle = Win32::MSI::HighLevel::Common::_def(MsiCloseHandle => "I");
my %handleCheck;

sub new {
    my ($type, $hdl, %params) = @_;
    my $class = ref $type || $type;

    croak "Internal error: handle required as first parameter to Handle->new"
        unless defined $hdl;

    if (exists $handleCheck{$hdl}) {
        croak "Reusing handle";
    }

    $params{class} = $class;
    $params{handle} = $hdl =~ /^\d+$/ ? $hdl : unpack ("l", $hdl);
    $handleCheck{$params{handle}} = [
        #Devel::StackTrace->new ()->as_string (),
        {%params}
        ];
    return bless \%params, $class;
}


sub DESTROY {
    my $self = shift;

    croak "Destroying null handle" unless $self->{handle};
    unless (exists $handleCheck{$self->{handle}}) {
        croak "handleCheck entry $self->{handle} missing";
    }

    $self->{result} = $MsiCloseHandle->Call ($self->{handle});
    croak "Failed with error code $self->{result}" if $self->{result};
    $handleCheck{$self->{handle}} = undef;
    delete $handleCheck{$self->{handle}};
    $self->{handle} = undef;
}


sub null {
    return pack ("l",0);
}

END {
    for my $leaked (values %handleCheck) {
        my $warning = "\nLeaked $leaked->[1]{class} object";

        #$warning .= " created at: \n$leaked->[0]";
        warn "$warning\n\n";
    }
}

1;
