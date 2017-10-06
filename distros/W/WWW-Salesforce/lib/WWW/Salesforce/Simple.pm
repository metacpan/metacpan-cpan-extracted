package WWW::Salesforce::Simple;

use strict;
use warnings;

use base 'WWW::Salesforce';

#handle versioning and exporting
our $VERSION = '0.302';
$VERSION = eval $VERSION;

# alias these methods to the base class

1;

__END__

=pod

=head1 NAME

WWW::Salesforce::Simple.pm - this class provides a simpler abstraction layer between WWW::Salesforce and Salesforce.com.

=head1 DESCRIPTION

Because the Salesforce API is somewhat cumbersome to deal with, this class
was created to make it a little simpler to get information.

=head1 METHODS

This class inherits all the methods from L<WWW::Salesforce> and adds the following new ones.

=head2 new( %parameters )

Handles creating new Salesforce objects as well as the login process
to use the salesforce objects.

=head2 do_query( $sql_query_string )

Executes a query against the information in Salesforce.  Returns a reference
to an array of hash references keyed by the column names. Strict attention
should be paid to the case of the field names.

=head2 do_queryAll( $sql_query_string )

Executes a query against the information in Salesforce.  Returns a reference
to an array of hash references keyed by the column names that includes deleted
and archived objects. Strict attention should be paid to the case of the field
names.

=head2 get_field_list( $table_name )

Gathers a list of fields contained in a given table.  Returns a reference
to an array of hash references.  The hash references have several keys
which provide information about the field's type, etc.  The key 'name'
will provide the name of the field itself.

=head2 get_tables( )

Gathers a list of tables available for use from salesforce.  Returns a
reference to an array of strings representing each table name.


=head1 EXAMPLES

=head2 new()

    use WWW::Salesforce::Simple;

    my $sforce = WWW::Salesforce::Simple->new(
        'username' => $user,
        'password' => $pass
    );

=head2 do_query( $query )

    my $query = 'select Id from Account';

    my $res = $sforce->do_query( $query );

    foreach my $field ( @{ $res } ) {
        print $field->{'Id'} . "\n";
    }
    print "Found " . scalar @{$res} . " results\n";

=head2 do_queryAll( $query )

    my $query = 'select Id from Account';

    my $res = $sforce->do_queryAll( $query );

    foreach my $field ( @{ $res } ) {
        print $field->{'Id'} . "\n";
    }
    print "Found " . scalar @{$res} . " results\n";

=head2 get_field_list( $table_name )

    my $fields_ref = $sforce->get_field_list( 'Account' );

    foreach my $field( @{$fields_ref} ) {
        print $field->{'name'} . "\n";
        foreach my $key ( keys %{$field} ) {
            print "\t $key --> ";
            print $field->{$key} if ( $field->{$key} );
            print "\n";
        }
        print "\n";
    }

=head2 get_tables()

    my $tables_ref = $sforce->get_tables();

    foreach my $table ( @{$tables_ref} ) {
        print "$table\n";
    }
    print "\n";

=head1 SUPPORT

Please visit Salesforce.com's user/developer forums online for assistance with
this module. You are free to contact the author directly if you are unable to
resolve your issue online.

=head1 AUTHORS

Chase Whitener <F<capoeirab@cpan.org>>

Fred Moyer <fred at redhotpenguin dot com>

=head1 COPYRIGHT & LICENSE

Copyright 2003-2004 Byrne Reese, Chase Whitener, Fred Moyer. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
