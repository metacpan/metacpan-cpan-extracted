package YA::CLI::PodRole;
our $VERSION = '0.006';
use Moo::Role;
use namespace::autoclean;

# ABSTRACT: Pod handler role

use YA::CLI::Usage;

sub usage_pod { 0 }

sub as_help {
    my $self = shift;
    my $rc = shift;
    my $message = shift;

    return YA::CLI::Usage->new(
      rc => ($rc // 0),
      $message ? (message => $message) : (),
      $self->_get_podfile_for_usage,
    );
}

sub as_manpage {
    my $self = shift;

    return YA::CLI::Usage->new(
        rc      => 0,
        verbose => 2,
        $self->_get_podfile_for_usage,
    );
}

sub _get_podfile_for_usage {
    my $self = shift;

    my $podfile;
    my $pod = $self->usage_pod;
    return unless $pod;
    return if $pod eq 'pl';
    return (pod_file => $pod) unless $pod == 1;
    return (pod_file => ref $self || $self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

YA::CLI::PodRole - Pod handler role

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This role is to make as_help and as_manual easier for consumers.

=head1 METHODS

=head2 as_help

Show POD as help page

=head2 as_manual

Show POD as a man page

=head2 usage_pod

If the handler provides its own usage POD. If this is 0/undef, the POD of the
script it used. If this function returns 1, it it taken from the file itself.
Otherwise it is assumed the return value is the path to the POD itself.
Use YA_CLI_USAGE_LIB=1 to see how we get the POD.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
