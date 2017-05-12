package WebService::CIA::Source::DBM;

require 5.005_62;
use strict;
use warnings;
use Fcntl;
use MLDBM qw(DB_File Storable);
use Carp;
use WebService::CIA::Source;

@WebService::CIA::Source::DBM::ISA = ("WebService::CIA::Source");

our $VERSION = '1.4';

sub new {

    my $proto = shift;
    my $opts = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    unless (exists $opts->{DBM}) {
        croak("WebService::CIA::Source::DBM: No DBM file specified");
    }

    my $mode;
    if (exists $opts->{Mode} && $opts->{Mode} eq "readwrite") {
        tie %{$self->{DBM}}, "MLDBM", $opts->{DBM}, O_CREAT|O_RDWR, 0640 or croak "WebService::CIA::Source::DBM: Can't open DBM: $!"; ## no critic (ProhibitLeadingZeros)
    } elsif (-e $opts->{DBM}) {
        tie %{$self->{DBM}}, "MLDBM", $opts->{DBM}, O_RDONLY, 0440 or croak "WebService::CIA::Source::DBM: Can't open DBM: $!"; ## no critic (ProhibitLeadingZeros)
    } else {
        croak "WebService::CIA::Source::DBM: $opts->{DBM}: $!";
    }

    bless ($self, $class);
    return $self;

}

sub value {

    my $self = shift;
    my ($country, $field) = @_;
    if (exists $self->dbm->{$country} and exists $self->dbm->{$country}->{$field}) {
        return $self->dbm->{$country}->{$field};
    } else {
        return;
    }

}

sub all {

    my $self = shift;
    my $cc = shift;
    if (exists $self->dbm->{$cc}) {
        return $self->dbm->{$cc};
    } else {
        return {};
    }

}

sub set {

    my $self = shift;
    my ($cc, $data) = @_;
    $self->dbm->{$cc} = $data;

}

sub dbm {

    my $self = shift;
    return $self->{DBM};

}


1;

__END__


=head1 NAME

WebService::CIA::Source::DBM - An interface to a DBM copy of the CIA World Factbook


=head1 SYNOPSIS

  use WebService::CIA::Source::DBM;
  my $source = WebService::CIA::Source::DBM->new({
                                                   DBM  => 'factbook.dbm',
                                                   Mode => 'read'
                                                 });


=head1 DESCRIPTION

WebService::CIA::Source::DBM is an interface to a pre-compiled DBM copy of the CIA
World Factbook.

The module can also be used to make the DBM file, taking data from
WebService::CIA::Parser (or WebService::CIA::Source::Web) and inserting it into a DBM.

A script to do this - webservice-cia-makedbm.pl - should be included in this
module's distribution.

=head1 METHODS

Apart from C<new>, these methods are normally accessed via a WebService::CIA object.

=over 4

=item C<new(\%opts)>

This method creates a new WebService::CIA::Source::DBM object. It takes a hashref of
options. Valid keys are "DBM" and "Mode".

DBM is mandatory and should be the location of the DBM file to be used.

Mode is optional and can be either "read" or "readwrite". It defaults to
"read".

=item C<value($country_code, $field)>

Retrieve a value from the DBM.

C<$country_code> should be the FIPS 10-4 country code as defined in
L<https://www.cia.gov/library/publications/the-world-factbook/appendix/appendix-d.html>.

C<$field> should be the name of the field whose value you want to
retrieve, as defined in
L<https://www.cia.gov/library/publications/the-world-factbook/docs/notesanddefs.html>.
(WebService::CIA::Parser also creates four extra fields: "URL", "URL - Print",
"URL - Flag", and "URL - Map" which are the URLs of the country's Factbook
page, the printable version of that page, a GIF map of the country, and a
GIF flag of the country respectively.)

=item C<all($country_code)>

Returns a hashref of field-value pairs for C<$country_code> or an empty
hashref if C<$country_code> isn't in the DBM.

=item C<set($country_code, $data)>

Insert or update data in the DBM.

C<$country_code> should be as described above.

C<$data> is a hashref of the data to store (as Field =E<gt> Value).

C<set> B<overwrites> any data already in the DBM under C<$country_code>.

=item C<dbm()>

Returns a reference to the DBM file in use.

=back


=head1 AUTHOR

Ian Malpass (ian-cpan@indecorous.com)


=head1 COPYRIGHT

Copyright 2003-2007, Ian Malpass

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The CIA World Factbook's copyright information page
(L<https://www.cia.gov/library/publications/the-world-factbook/docs/contributor_copyright.html>)
states:

  The Factbook is in the public domain. Accordingly, it may be copied
  freely without permission of the Central Intelligence Agency (CIA).


=head1 SEE ALSO

WebService::CIA, WebService::CIA::Parser, WebService::CIA::Source::Web


=cut
