package Text::ECSV;

use warnings;
use strict;

our $VERSION = '0.02';

use base 'Text::CSV_XS', 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
        fields_hash
        dup_keys_strategy
        }
);

sub field_named {
    my $self = shift;
    my $name = shift;

    return $self->fields_hash->{$name};
}

sub parse {
    my $self = shift;

    # reset fields hash
    $self->fields_hash({});

    # run Text::CSV_XS parse
    my $status = $self->SUPER::parse(@_);

    # if the CSV parsing failed then just return
    return $status
        if not $status;

    # decode the fileds
    foreach my $field ($self->fields) {

        # if we have key value pair
        if ($field =~ m/^([^=]+)=(.*)$/) {
            my $name  = $1;
            my $value = $2;

            # if it the second occurence of the same key and we have a strategy use it
            #    to construct the new value
            if (    exists $self->{'fields_hash'}->{$name}
                and exists $self->{'dup_keys_strategy'}) {
                $value = $self->{'dup_keys_strategy'}
                    ->($name, $self->{'fields_hash'}->{$name}, $value);
            }

            # store value
            $self->{'fields_hash'}->{$name} = $value;
        }

        # else fail
        else {
            $status = 0;

            # TODO fill error messages

            last;
        }
    }

    return $status;
}

sub combine {
    my $self       = shift;
    my @key_values = @_;
    my @fields;

    while (@key_values) {
        push @fields, (shift(@key_values) . '=' . shift(@key_values));
    }

    return $self->SUPER::combine(@fields);
}

1;

__END__

=head1 NAME

Text::ECSV - Extended CSV manipulation routines

=head1 SYNOPSIS

    use Text::ECSV;
    $ecsv    = Text::ECSV->new ();         # create a new object
    $line    = 'id=3,name=Text::ECSV,shot_desc=Extended CSV manipulation routines';
    $status  = $ecsv->parse ($line);       # parse a CSV string into fields
                                           #    and name value pairs
    %columns = $ecsv->fields_hash ();      # get the parsed field hash
    $column  = $ecsv->field_named('id');   # get field value for given name

    $ecsv->combine('b' => 2, 'a' => 1, 'c' => 3, );
    # ok($ecsv->string eq 'b=2,a=1,c=3');

=head1 DESCRIPTION

C< use base 'Text::CSV_XS'; > => see L<Text::CSV_XS>.

Roland Giersig had a presentation at YAPC 2007 called 'Techniques for Remote
System-Monitoring'. He was explaining his search after a good logging
format or how to store continuous flow of data in a most usable form.
XML? YAML? CSV? XML is nice but for a machines not for humans,
YAML is nice for both but it's hard to grep. CSV is readable and grep-able
but not too flexible. So what is the conclusion? ECSV is like a CSV but
in each comma separated field the name of the column is set. This gives a
flexibility to skip, reorder, add the fields. All the information is stored
per line so it's easy to grep. Also it's easy to compare two records by
md5ing the lines or doing string eq.

=head1 PROPERTIES

=head2 fields_hash

Holds hash reference to the resulting hash constructed by C<parse()>.

=head2 dup_keys_strategy

If set and a duplicate key names occur in a parsed line, this strategy
is called with C<< ->($name, $old_value, $value) >>.

Can be used for duplicate keys to join values to one string, or push them
to an array or to treat them how ever is desired. By default values overwrite
each other.

=head1 METHODS

=head2 field_named($name)

Return field with $name.

=head2 parse()

In additional to the C<SUPER::parse()> functionality it decodes
name value pairs to fill in C<fields_hash>.

=head2 combine($key => $value, ...)

The function joins all $key.'='.$value and then calls C<SUPER::combine>
constructing a CSV from the arguments, returning success or failure.

=head1 AUTHOR

Jozef Kutej, C<< <jkutej@cpan.org> >>,
thanks to Roland Giersig C<< <RGiersig@cpan.org> >> for the idea.

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-ecsv at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-ECSV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::ECSV


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-ECSV>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-ECSV>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-ECSV>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-ECSV>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
