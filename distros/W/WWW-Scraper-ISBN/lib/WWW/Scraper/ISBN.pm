package WWW::Scraper::ISBN;

use strict;
use warnings;

our $VERSION = '1.05';

#----------------------------------------------------------------------------
# Library Modules

use Carp;
use WWW::Scraper::ISBN::Record;
use WWW::Scraper::ISBN::Driver;

use Module::Pluggable   search_path => ['WWW::Scraper::ISBN'];

eval "use Business::ISBN";
my $business_isbn_loaded = ! $@;

#----------------------------------------------------------------------------
# Public API

# Preloaded methods go here.
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {
        DRIVERS => []
    };

    bless ($self, $class);
    return $self;
}

sub available_drivers {
    my $self = shift;
    my @plugins = $self->plugins();
    my @drivers;
    for my $plugin (@plugins) {
        next unless($plugin =~ /_Driver$/);
        $plugin =~ s/WWW::Scraper::ISBN::(\w+)_Driver/$1/;
        push @drivers, $plugin;
    }
    return @drivers;
}

sub drivers {
    my $self = shift;
    while ($_ = shift) {  push @{$self->{DRIVERS}}, $_; }
    for my $driver ( @{ $self->{DRIVERS} }) {
        require "WWW/Scraper/ISBN/".$driver."_Driver.pm";
    }
    return @{ $self->{DRIVERS} };
}

sub reset_drivers {
    my $self = shift;
    $self->{DRIVERS} = [];
    return @{ $self->{DRIVERS} };
}

sub search {
    my ($self,$isbn) = @_;

    croak("Invalid ISBN specified [].\n") unless($isbn);        

    if($business_isbn_loaded) {
        # Business::ISBN has strong validation algorithms
        my $isbn_object = Business::ISBN->new($isbn);
        croak("Invalid ISBN specified [$isbn].\n") unless($isbn_object && $isbn_object->is_valid);
    } else {
        # our fallback just validates it looks like an ISBN
        my $isbn_object = WWW::Scraper::ISBN::Driver->new();
        croak("Invalid ISBN specified [$isbn].\n") unless($isbn_object && $isbn_object->is_valid($isbn));        
    }

    croak("No search drivers specified.\n")
        if( $self->drivers == 0 );

    my $record = WWW::Scraper::ISBN::Record->new();
    $record->isbn($isbn);
    for my $driver_name (@{ $self->{DRIVERS} }) {
        my $driver = "WWW::Scraper::ISBN::${driver_name}_Driver"->new();
        $driver->search($record->isbn);
        if ($driver->found) {
            $record->found("1");
            $record->found_in("$driver_name");
            $record->book($driver->book);
            last;
        }

        $record->error($record->error.$driver->error)
            if ($driver->error);
    }

    return $record;
}

1;

__END__

=head1 NAME

WWW::Scraper::ISBN - Retrieve information about books from online sources.

=head1 SYNOPSIS

  use WWW::Scraper::ISBN;

  my $scraper = WWW::Scraper::ISBN->new();
  $scraper->drivers("Driver1", "Driver2");
  
  my @drivers = $scraper->available_drivers();
  $scraper->drivers(@drivers);

  my $isbn = "123456789X";
  my $record = $scraper->search($isbn);
  if($record->found) {
    print "Book ".$record->isbn." found by driver ".$record->found_in."\n";
    my $book = $record->book;

    # do stuff with book hash
    
    print $book->{'title'};
    print $book->{'author'};
    
    # etc
  
  } else {
    print $record->error;
  }

=head1 REQUIRES

Requires the following modules be installed:

=over 4

=item L<WWW::Scraper::ISBN::Record>

=item L<Carp>

=back

=head1 DESCRIPTION

The WWW::Scraper::ISBN class was built as a way to retrieve information on 
books from multiple sources easily. It utilizes at least one driver implemented
as a subclass of L<WWW::Scraper::ISBN::Driver>, each of which is designed to 
scrape from a single source.  Because we found that different sources had 
different information available on different books, we designed a basic 
interface that could be implemented in whatever ways necessary to retrieve 
the desired information.

=head1 METHODS

=over 4

=item C<new()>

Class constructor.  Returns a reference to an empty scraper object.  No 
drivers by default

=item C<available_drivers()>

Returns a list of installed drivers, which can be subsequently loaded via the 
drivers() method.

=item C<drivers() or drivers($DRIVER1, $DRIVER2)>

  foreach my $driver ( $scraper->drivers() ) { ... }

  $scraper->drivers("DRIVER1", "DRIVER2");

Accessor/Mutator method which handles the drivers that this instance of the 
WWW::Scraper::ISBN class should utilize.  The appropriate driver module must be
installed (e.g. WWW::Scraper::ISBN::DRIVER1_Driver for "DRIVER1", etc.).  The 
order of arguments determines the order in which the drivers will be searched.

When this method is called, it loads the specified drivers using 'require'.

Must be set before C<search()> method is called.

=item C<reset_drivers>

  $scraper->reset_drivers;

Sets the list of drivers to an empty array.  Will disable search feature until
a new driver is specified.

=item C<search($isbn)>

  my $record = $scraper->search("123456789X");

Searches for information on the given ISBN number.  It goes through the drivers
in the order they are specified, stopping when the book is found or all drivers
are exhausted.  It returns a L<WWW::Scraper::ISBN::Record> object, which will 
have its C<found()> field set according to whether or not the search was 
successful.

If you have L<Business::ISBN> installed, the method will attempt to validate 
the given isbn.

=back

=head1 CODE EXAMPLE

  use WWW::Scraper::ISBN;

  # instantiate the object
  my $scraper = WWW::Scraper::ISBN->new();

  # load the drivers.  requires that 
  # WWW::Scraper::ISBN::LOC_Driver and
  # WWW::Scraper::ISBN::ISBNnu_Driver 
  # be installed
  $scraper->drivers("LOC", "ISBNnu"); 

  @isbns = [ "123456789X", "132457689X", "987654321X" ];

  foreach my $num (@isbns) {
    $scraper->isbn($num);
    $scraper->search($scraper->isbn);
    if ($scraper->found) {
      my $b = $scraper->book;
      print "Title: ".$b->{'title'}."\n";
      print "Author: ".$b->{'author'}."\n\n";
    } else {
      print "Book: ".$scraper->isbn." not found.\n\n";
    }
  }

=head1 SEE ALSO

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<WWW::Scraper::ISBN::Record>

=back

=head1 AUTHOR

  2004-2013 Andy Schamp, E<lt>andy@schamp.netE<gt>
  2013-2019 Barbie, E<lt>barbie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright 2004-2013 by Andy Schamp
  Copyright 2013-2019 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
