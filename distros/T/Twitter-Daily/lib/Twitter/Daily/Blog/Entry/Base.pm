package Twitter::Daily::Blog::Entry::Base;

use strict;
use warnings;

=pod

=head1 NAME

Twitter::Daily::Blog::Entry::Base - Generic blog entry  

=head1 SYNOPSIS
 
 use Twitter::Daily::Blog::Entry::Base;

 my $entry = Twitter::Daily::Blog::Entry::Base->new();

 $entry->setTitle("My first blog entry");
 $entry->setBody('Some simple text<br/>\n' .
                 'Nonsense only');
 
 saveEntryToFile( $entry->getEntry() );

=head1 DESCRIPTION 

It represents a generic entry for a Blosxom blog

=head1 INTERFACE

=head2 new

Creates a new Twitter::Daily::Blog::Entry::Base object.

=cut


sub new {
    my $class = shift;
    my $this;
    
    $this->{'title'} = "";
 	$this->{'body'} = "";
 
    return bless $this, $class;
};

=pod

=head2 setTitle

Sets the entry title

=cut


sub setTitle {
	my $this = shift;
	
	$this->{'title'} = shift;
};


=pod

=head2 setBody

Sets the entry body contents

=cut


sub setBody {
	my $this = shift;
	
	$this->{'body'} = shift;
}


=pod

=head2 getEntry

Returns the entry content

=cut

sub getEntry {
	my $this = shift;
	
	return  $this->{'title'} . "\n" . $this->{'body'};
}

=pod

=head1 AUTHOR

Victor A. Rodriguez (Bit-Man)

=cut


1;