package Blosxom::Entry::Twitter;

use strict;
use warnings;

use Exporter();
use Twitter::Daily::Blog::Entry::Base;

our (@ISA, @EXPORT, $VERSION);
@ISA = qw(Exporter Twitter::Daily::Blog::Entry::Base);
@EXPORT = qw(new addLine getEntry getLines setTitle);

use Twitter::Date;

use constant NEWLINE => "\n";

=pod

=head1 NAME

Blosxom::Entry::Twitter - Twitter entry for Blosxom blog

=head1 SYNOPSIS

	my $entry =  Blosxom::Entry::Twitter->new()
	     || die("Not all options were passed");
								
	$entry->addLine("Line 1",'Thu Jan 13 14:26:49 +0000 2011');
    $entry->addLine("Line 2",'Thu Jan 13 13:49:27 +0000 2011');
    $entry->addLine("Line 3",'Thu Jan 13 18:09:00 +0000 2011');

    $entry->setTitle("My First Entry");

    my @entry = $entry->getLines();
    
    ## Now @entry contains the full entry to be published in your Blosxom blog

    My::Module::publishEntry( @entry );
 
=head1 DESCRIPTION 

Creates the Twitter entry to be published in the Blosxom blog

=head2 new

Constructor. Accepts no parameters.

=cut

sub new {
    my $class = shift;
    my $this = $class->SUPER::new();
    my %line;
 
    
    $this->{'lines'} = %line;

    return bless $this, $class;
};


=head2 setTitle

Sets the entry title

=cut

sub setTitle {
    my $this = shift;
    
	return $this->SUPER::setTitle( $_[0]);
}


=head2 addLine

Adds a new line to the entry accepting these parameters :

=over 1

=item * text to be shown

=item * entry creation date used to create the entry oredered by ascengind entry creaton date

=back

=cut

sub addLine {
    my $this = shift;
    ### ToDo add parameter verification
    my $text = shift;
    my $date = shift; 
    
 	no strict "refs";
    $this->{'lines'}{ $date } = $text;
}

sub _orderedByDate {
    my $a1 = Twitter::Date->new($a);
    my $b1 = Twitter::Date->new($b);
    
	return $a1->cmp($b1);
};



=head2 getLines

Retrieves the lines added to the entry

=cut

sub getLines {
    my $this = shift;
    my @line;

 	no strict "refs";
	my @orderedDate = sort _orderedByDate keys %{ $this->{'lines'} };	
	for my $date ( @orderedDate ) {
		push @line, $this->{'lines'}{$date};
	} 
	
	return @line;
}

=head2 getEntry

Retrieves the formatted entry to be published in your Blosxom blog

=cut

sub getEntry {
    my $this = shift;
    my $entry;
    
    $entry = $this->{'title'} . NEWLINE; ## set using Twitter::Daily::Blog::Entry::Base
    $entry .= '<ul>'. NEWLINE;

    foreach my $line ( $this->getLines() ) {
        _addURLtags( $line );
        $entry .= '    <li>' . $line . '</li>'. NEWLINE;
    }

    $entry .= '</ul>';
    return $entry;
}


sub _addURLtags($) {
   $_[0] =~ s/(http\:\/\/[\w\.\/\?\=\&\-]*)/\<a href=\"$1\"\>$1\<\/a\>/g;
   $_[0] =~ s/(https\:\/\/[\w\.\/\?\=\&\-]*)/\<a href=\"$1\"\>$1\<\/a\>/g;
   $_[0] =~ s/\@(\w*)/\<a href=\"http:\/\/twitter.com\/$1\"\>\@$1\<\/a\>/g;
   $_[0] =~ s/ \#(\w*)/\ <a href=\"http:\/\/twitter.com\/search\?q\=\%23$1\"\>\#$1\<\/a\>/g;
};


1;
