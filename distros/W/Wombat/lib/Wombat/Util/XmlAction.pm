# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Util::XmlAction;

=pod

=head1 NAME

Wombat::Util::XmlAction - xml parser event handler

=head1 SYNOPSIS

  my $mapper = Wombat::Util::XmlAction->new();

=head1 DESCRIPTION

Represents an action to take when a specific rule is matched by an XmlMapper.

=cut

use fields qw();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over

=cut

sub start {}

sub end {}

sub cleanup {}

sub trim {
    my $self = shift;
    my $str = shift or
        return "";

    $str =~ s/^\s*//;
    $str =~ s/\s*$//;

    return $str;
}

=pod

=back

=cut

1;
__END__

=pod

=head1 SEE ALSO

L<Wombat::Util::XmlAction>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
