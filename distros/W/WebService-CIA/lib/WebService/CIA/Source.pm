package WebService::CIA::Source;

require 5.005_62;
use strict;
use warnings;

our $VERSION = '1.4';


# Preloaded methods go here.

sub new {

    my $proto = shift;
    my $source = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;

}

sub value {

    my $self = shift;
    my ($cc, $f) = @_;
    if ($cc eq 'testcountry' and $f eq 'Test') {
        return 'Wombat';
    } else {
        return;
    }

}

sub all {

    my $self = shift;
    my $cc = shift;
    if ($cc eq 'testcountry') {
        return {'Test' => 'Wombat'};
    } else {
        return {};
    }

}


1;
__END__


=head1 NAME

WebService::CIA::Source - A base class for WebService::CIA sources


=head1 SYNOPSIS

  use WebService::CIA::Source;
  my $source = WebService::CIA::Source->new();


=head1 DESCRIPTION

WebService::CIA::Source is a base class for WebService::CIA sources, such as
WebService::CIA::Source::DBM and WebService::CIA::Source::Web.

It could be used as a source in its own right, but it won't get you very far.


=head1 METHODS


=over 4

=item C<new()>

This method creates a new WebService::CIA::Source object. It takes no arguments.

=item C<value($country_code, $field)>

Retrieve a value. Always returns C<undef>.

=item C<all($country_code)>

Retrieve all fields and values. Always returns an empty hashref.


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

WebService::CIA, WebService::CIA::Parser, WebService::CIA::Source::DBM, WebService::CIA::Source::Web

=cut
