package WWW::Scraper::ISBN::Record;

use strict;
use warnings;

our $VERSION = '1.03';

#----------------------------------------------------------------------------
# Public API

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
        ISBN        => undef,
        FOUND       => 0,
        FOUND_IN    => undef,
        BOOK        => undef,
        ERROR       => '',
    };

	bless ($self, $class);
	return $self;
}

sub isbn        { my $self = shift; return $self->_accessor('ISBN',@_)     }
sub found       { my $self = shift; return $self->_accessor('FOUND',@_)    }
sub found_in    { my $self = shift; return $self->_accessor('FOUND_IN',@_) }
sub book        { my $self = shift; return $self->_accessor('BOOK',@_)     }
sub error       { my $self = shift; return $self->_accessor('ERROR',@_)    }

sub _accessor {
	my $self     = shift;
	my $accessor = shift;
	if (@_) { $self->{$accessor} = shift };
	return $self->{$accessor};
}

1;

__END__

# Documentation

=head1 NAME

WWW::Scraper::ISBN::Record - Book Record class for L<WWW::Scraper::ISBN> module.

=head1 SYNOPSIS

used from within WWW::Scraper::ISBN.  No need to invoke directly.  But if you want to:

    use WWW::Scraper::ISBN::Record;
    $record = WWW::Scraper::ISBN::Record->new();

It is usually best to let an instantiation of WWW::Scraper::ISBN create it and
search for it. This class does not know how to search on its own.

    print $record->isbn;

    if ($record->found) {
	    print $record->found_in;
    } else {
	    print "not found";
    }

    $book = $record->book;
    print $book->{'title'};
    print $book->{'author'};
    # etc.

    if ($record->error) { print $record->error(); }

=head1 DESCRIPTION

The WWW::Scraper::ISBN::Record module defines a class that can be used to deal 
with book information.  It was primarily created as a return type for the 
L<WWW::Scraper::ISBN> module, though it could be used for other purposes.  It 
knows minimal information about itself, whether the book was found, where it 
was found, its ISBN number, and whether any errors occurred.  It is usually up 
to the L<WWW::Scraper::ISBN::Driver> and its subclasses to make sure that the 
fields get set correctly.

=head1 METHODS

=over 4

=item C<new()>

Class Constructor.  Usually invoked by C<< WWW::Scraper::ISBN->search() >>.  
Takes no parameters, creates an object with the default values:

    isbn = undef;
    found = 0;
    found_in = undef;
    book = undef;
    error = "";

=item C<isbn() or isbn($isbn_number)>

    print $record->isbn; # returns the ISBN number string
    $record->isbn("123456789X"); # set the ISBN 

Accessor/Mutator method for handling the ISBN associated with this record.  

=item C<found() or found($bool)>

    if ($record->found) { # ... }
    $record->found(1);

Accessor/Mutator method for handling the search status of this record.  This is
0 by default, and should only be set to true if the Record object contains the
desired information, as retrieved by C<< WWW::Scraper::ISBN::Record->book() >>.

=item C<found_in() or found_in($DRIVER_NAME)>

    print $record->found_in;
    $record->found_in("Driver_name");

Accessor/Mutator method for handling the L<WWW::Scraper::ISBN::Driver> subclass
that first successfully retrieved the desired record.  Please note that this 
may depend upon the order in which the drivers are invoked, as set by 
C<< WWW::Scraper::ISBN->drivers() >>.  Returns the driver name of the successful 
driver, e.g. "LOC" if found by C<< WWW::Scraper::ISBN::LOC_Driver->search() >>.

=item C<book() or book($hashref)>

    my $book = $record->book;
    print $book->{'title'};
    print $book->{'author'};
    $another_book = { 
       'title'  => "Some book title",
       'author' => "Author of some book"
    }; 
    $record->book( $another_book );

Accessor/Mutator method for handling the book information retrieved by the driver.  Set to a hashref by the driver, returns 
a hashref when invoked alone.  The resulting hash should contain the standard fields as specified by 
L<WWW::Scraper::ISBN::Driver>, and possibly additional fields based on the driver used.

=item C<error() or error($error_string)>

    print $record->error;
    $record->error("Invalid ISBN number, or some similar error.");

Accessor/Mutator method for handling any errors which occur during the search.  The search drivers may add errors to record 
fields, which may be useful in gleaning information about failed searches.

=back

=head1 SEE ALSO

=over 4

=item L<WWW::Scraper::ISBN>

=item L<WWW::Scraper::ISBN::Driver>

=back

=head1 AUTHOR

  2004-2013 Andy Schamp, E<lt>andy@schamp.netE<gt>
  2013-2014 Barbie, E<lt>barbie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright 2004-2013 by Andy Schamp
  Copyright 2013-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
