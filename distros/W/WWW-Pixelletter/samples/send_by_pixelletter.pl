#!/usr/bin/perl
use strict;
use warnings;
use WWW::Pixelletter;

my $username  = 'your_email';
my $password  = 'your_password';
my $test_mode = 'false';  # Set to 'true' for testing without costs!

eval
{
    # Create the object
    my $pl = WWW::Pixelletter->new( 'username' => $username, 'password' => $password, 'test_mode' => $test_mode );

    # Add any files passed as arguments
    foreach( @ARGV )
    {
        $pl->addFile( $_ );
    }
    
    # Don't continue if there's nothing to send...
    if( $pl->filecount() < 1 )
    {
        die( "No files given to send...\n" );
    }
    
    # Send by post or fax
    my $method = undef;
    while( ! $method )
    {
        print "Fax or Post (f/p)? ";
        $method = <STDIN>;
        chomp( $method );
        $method = ( $method =~ m/^(f|p)$/ ? $method : undef );
    }
    
    if( $method eq 'f' )
    {
        # Send by fax
        print "Fax number? ";
        my $fax_number = <STDIN>;
        chomp( $fax_number );
        my( $code, $msg ) = $pl->sendFax( $fax_number );
        print "Fax sent successfully\n";
    }
    else
    {
        # Send by post
        print "Which country are you sending to (DE, AT, ...): ";
        my $dest_country = <STDIN>;
        chomp( $dest_country );
        
        print "Which post center do you want to use (1=Munich, 2=Wien, 3=Hamburg): ";
        my $post_center = <STDIN>;
        chomp( $post_center );
        my( $code, $msg ) = $pl->sendPost( $post_center, $dest_country );
        print "Post sent successfully\n";
    }
};
if( $@ )
{
    print $@ . "\n";
    my $finished = <STDIN>;
    exit;
}

my $finished = <STDIN>;
exit;

__END__

=pod

=head1 NAME

  send_by_pixelletter.pl

=head1 SYNOPSIS

  send_by_pixelletter.pl file1.pdf file2.pdf

=head1 DESCRIPTION

A sample interactive script to use the WWW::Pixelletter script to send files by fax or post.
It will ask you to enter the necessary details.

= cut
