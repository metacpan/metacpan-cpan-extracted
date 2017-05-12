package WWW::Arbeitsagentur::Arbeitnehmer;
our $VERSION="0.0.1";

=head1 CONSTRUCTOR AND OTHER METHODS

=head2 new

Creates a new Arbeitgeber instance.

=cut

sub new {
    my ($class) = @_;
    my $self = {
        type => 'Arbeitnehmer',
        mech => '',
    };
    return bless \$self, ref($class) || $class;
}

=head2 $ag->choose_my_side(Z<>)

Switches to the pages concerning employees on http://www.arbeitsagentur.de

=cut

sub choose_my_side {
    my ($self) = @_;
#    warn "Versuche, auf Arbeitnehmer-Seite zu wechseln.\n";
    $self->mech->follow_link('text_regex' => qr!^Arbeits?- und Ausbildungssuchende$! );
    $self->mech->success() or die "Konnte nicht auf Arbeitnehmer-Seite wechseln.\n";
}


1;

__END__
=head1 NAME

Dewarim::Arbeit::Arbeitnehmer - Base class for classes searching for work


=head1 SYNOPSIS

Its only use is as a base class for classes searching for work.


=head1 DESCRIPTION

=head2 Overview

This class is the base class for classes searching for work on
http://www.arbeitsagentur.de.
It provides a constructor and a method for switching to the pages concerning
applicants on http://www.arbeitsagentur.de.

=cut




=head1 SEE ALSO

L<Dewarim::Arbeit::FastSearchForWork> - A class for the fast search for
jobs at http://www.arbeitsagentur.de

L<Dewarim::Arbeit::ProfileSearchForWork> - A class for a search for jobs using
your profile at http://www.arbeitsagentur.de

http://arbeitssuche.sourceforge.net


=head1 AUTHORS

Ingo Wiarda
dewarim@users.sourceforce.net

Stefan Rother
bendana@users.sourceforce.net


=head1        COPYRIGHT

Copyright (c) 2004,2005, I. Wiarda, S. Rother. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
