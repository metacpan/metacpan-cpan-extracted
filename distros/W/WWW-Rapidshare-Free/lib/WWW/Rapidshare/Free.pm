package WWW::Rapidshare::Free;

use strict;

BEGIN {
    $^W = 1;
    $|  = 1;
}

use WWW::Mechanize;
use HTML::Form;
use HTML::Parser;
use Data::Validate::URI qw( is_http_uri );
use Carp qw( croak );
use Exporter;

our $VERSION = '0.01';

our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( links add_links add_links_from_file check_links download
  verbose connection clear_links );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $parser = HTML::Parser->new(
    api_version    => 3,
    start_h        => [ \&_start, 'tagname, attr' ],
    text_h         => [ \&_text, 'text' ],
    end_document_h => [ \&_end_document ],
);
my $mech = WWW::Mechanize->new;
my ( $tagname, $class, $verbose, $counter, $check_links, $error, @links,
    @download_links )
  = ( '', '', 1, 0 );
my $delay = 120;    # An explicit value which will most likely be overwritten

my @text;

# Gets the tagname and also marks the start of the error tag:
# <div class='klappbox'>
sub _start {
    $tagname = shift;
    $class   = 'klappbox'
      if ( exists $_[0]->{'class'} && $_[0]->{'class'} eq 'klappbox' );
}

# Stores contents of <script> tag and also stores the error message
sub _text {
    my $text = shift;
    push @text, $text if $tagname eq 'script';
    if ( $class eq 'klappbox' ) {
        if ( $counter == 1 ) {
            $text =~ s/\s+$//;
            $error = $text;
        }
        elsif ( $counter == 2 ) {
            $class   = '';
            $counter = 0;
        }
        $counter++;
    }
}

# Fetches the `time to wait'
sub _end_document {
    @download_links = ();
    map {
        $delay = $1 if /var c=(\d+)/;
        push @download_links, $1
          if m#
            '<input\ \ type="radio"\ name="mirror"\ 
              onclick="document.dlf.action=\\'(.+)\\'
            #x;
    } map { split /\n/, $_ } @text;
    @text = ();
}

sub links { return @links }

sub clear_links {
    my @temp = @links;
    @links = ();
    return @temp;
}

sub check_links {
    $check_links = 1;
    my @erroneous_links = &download;
    return @erroneous_links;
}

sub download {
    my %callbacks = @_;
    my @erroneous_links;
    my $index = 0;

    for (@links) {
        my $link = $_;
        $mech->get($link);
        my @forms = HTML::Form->parse( $mech->content, $mech->base );

        my ( $dl, $file_name );
        if (@forms) {
            my $response = $mech->request( $forms[0]->click );
            $parser->parse( $response->content );
            $parser->eof;

            $dl = shift @download_links
              or croak
              ' Simultaneous downloads are not available for free users';
            ( $file_name = $dl ) =~ s{.*/}{};
        }
        else {
            ( $counter, $error ) = ( 0, '' );
            $parser->parse( $mech->content );
            $parser->eof;
            push @erroneous_links, [ $link, $error ];
            splice @links, $index, 1;
            next;
        }

        unless ( defined $check_links ) {
            if ( defined $callbacks{'delay'} ) {
                &_delay( $delay, $callbacks{'delay'} );
            }
            else {
                &_delay($delay);
                print "\r";
            }
            open my $fh, '>', $file_name
              or croak "$file_name cannot be opened for output";
            my ( $output, $file_size, $next_so_far ) = ( 0, 0, 0 );
            $mech->get(
                $dl,
                ':content_cb' => sub {
                    my ( $chunk, $response ) = @_;
                    unless ($file_size) {
                        $file_size = $response->content_length;
                        &{ $callbacks{'properties'} }( $file_name, $file_size )
                          if defined( $callbacks{'properties'} );
                    }
                    $output += length $chunk;
                    print {$fh} $chunk;
                    &_progress( $output, $file_size ) if $verbose;
                    &{ $callbacks{'progress'} }($output)
                      if defined( $callbacks{'progress'} );
                }
            );

            &_progress( $file_size, $file_size ) if $verbose;
            if ( -e $file_name && defined( $callbacks{'file_complete'} ) ) {
                &{ $callbacks{'file_complete'} }(1);
            }
        }
        $index++;
    }
    if ( defined $check_links ) {
        undef $check_links;
        return @erroneous_links;
    }
}

my $prev_size = 0;

# Print a fancy progress bar
sub _progress {
    my ( $output, $max ) = @_;
    my $current = ( $output / $max ) * 100;
    printf
      "\rProgress:\t %4.2f%% [ %4.2f MB / %4.2f MB ]",
      $current, $output / ( 1024 * 1024 ), $max / ( 1024 * 1024 );
    $prev_size = $output;
}

# Filter links
sub _store_links {
    my $link = shift;
    unless ( /^\s*#/
        || !is_http_uri($link)
        || !m#^http://(?:www.)?rapidshare.com/# )
    {    # Ignore comments
        push @links, $link;
        return 1;
    }
    else {
        return 0;
    }
}

sub add_links {
    my @added_links;
    map { push @added_links, $_ if &_store_links($_) } @_;
    return @added_links;
}

sub add_links_from_file {
    my $file_name = shift;
    my @added_links;
    open my ($fh), '<', $file_name
      or croak "$file_name cannot be opened for input";
    if ( -f $file_name ) {
        while (<$fh>) {
            chomp;
            push @added_links, $_ if &_store_links($_);
        }
    }
    else { croak " $file_name does not exist or is not a file" }
    return @added_links;
}

sub verbose { $verbose = shift }

sub connection {
    my %connection = @_;
    if ( exists $connection{'reconnect'} ) {
        system $connection{'reconnect'};
    }
    elsif ( keys %connection != 2 ) {
        croak ' Incorrect number of parametres';
    }
    else {
        system $connection{'disconnect'};
        system $connection{'connect'};
    }
}

# Fancy delay
sub _delay {
    my ( $delay, $callback ) = @_;
    for ( my $i = $delay ; $i >= 0 ; $i-- ) {
        sleep 1;
        if ($verbose) {
            printf "\rTime Left:\t %3d", $i;
        }
        else {
            &$callback($i);
        }
    }
}

1;    # End of WWW::Rapidshare::Free

__END__


=head1 NAME

WWW::Rapidshare::Free - Automates downloading from Rapidshare.com and checking links for free users

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::Rapidshare::Free qw( verbose add_links check_links 
      download connection );

    # We are going to let the module be verbose and display a delay metre and 
    # progress bar.
    verbose(1);

    my @links = add_links(
        qw{
          http://rapidshare.com/files/175658683/perl-51.zip
          http://rapidshare.com/files/175662062/perl-52.zip
          }
    );

    print "Added links:\n";
    map print("\t$_\n"), @links;

    my @erroneous_links = check_links;
    map {
        my ( $uri, $error ) = @{$_};
        print "URI: $uri\nError: $error\n";
    } @erroneous_links;

    download(
        properties    => \&properties,
        file_complete => \&file_complete,
    );

    sub properties {
        my ( $file_name, $file_size ) = @_;
        print "Filename: $file_name\nFile size: $file_size bytes\n";
    }

    sub file_complete {
        # Let us restart the modem. I have updated my /etc/sudoers file to allow me
        # to execute sudo pppoe-start and sudo pppoe-stop without a password.
        connection(
            connect    => 'sudo pppoe-start',
            disconnect => 'sudo pppoe-stop',
        );
    }

=head1 FUNCTIONS

By default, the module does not export any function. An export tag C<all> has 
been defined to export all functions. The following functions can be exported:

=over 4

=item * add_links

Adds links to be downloaded and returns the added links as an array. Accepts an 
array of values as argument. Ignores commented links (links that start with a 
C<#>) and invalid links.

=item * add_links_from_file

Adds links from a file which is given as an argument and returns the added 
links as an array. Ignores commented links (links that start with a C<#>) and 
invalid links.

=item * links

Returns current links which have been added by C<add_links> or 
C<add_links_from_file>.

=item * clear_links

Clears current links and returns them as an array.

=item * check_links

Checks if the links are alive or not. Returns an array of array references if 
there are dead links. The latter arrays are of the form 
C<[ link, error message ]>. If all links are alive, returns false. Additionally
it also removes the dead links.

    my @erroneous_links = check_links;
    map {
        my ( $uri, $error ) = @{$_};
        print "URI: $uri\nError: $error\n";
    } @erroneous_links;
 

=item * download

Downloads files off valid links. Accepts a hash with a maximum of four keys 
having callbacks as their values. The hash should be of the form:

    (
        delay          => \&delay_callback,
        properties     => \&properties_callback,
        progress       => \&progress_callback,
        file_complete  => \&file_complete
    )


Callbacks are passed values as follows:

=over 4

=item * C<delay>

C<delay> callback is passed the number of seconds until download begins. It is 
called every second until the delay is zero. Delay is decremented each time the 
callback is executed.

=item * C<properties>

C<properties> is passed the file name and file size as two arguments.

=item * C<progress>

Sole argument is the number of bytes of the current file downloaded so far. This
callback is executed every instant in which data is written to the file which is
being downloaded.

=item * C<file_complete>

This callback passes control after each file is downloaded. 
Disconnection/connection establishment or reconnection is possible by invoking 
C<connection>.

=back

=item * verbose

Controls the output verbosity. Pass it a false value such as 0 or '' (empty 
string) to turn off the delay metre and progress bar. Everything else turns on 
verbosity. Verbosity is true by default.

=item * connection

Most useful within the callback of C<download> pertaining to the hash key 
C<file_complete>. Accepts a hash:

    connection(
        connect    => '',  # Command to start a connection
        disconnect => '',  # Command to disconnect
        reconnect  => ''   # Command to reconnect
    );

Either both C<connect> and C<disconnect> have to be specified, or C<reconnect> 
has to be specified. If a single command can reconnect, then a value for 
C<reconnect> will be apt, else C<connect> and C<disconnect> should be assigned 
the respective commands to connect and disconnect. The commands should be your 
operating system's commands to connect/disconnect/reconnect the internet 
connection.

Windows users can use the rasdial utility to connect/disconnect: 
L<http://technet.microsoft.com/en-us/library/bb490979.aspx>.

=back

Check C<download.pl> file inside C<example> directory for usage example of the 
module.

=head1 AUTHOR

Alan Haggai Alavi, C<< <alanhaggai at alanhaggai.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-www-rapidshare-free at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Rapidshare-Free>. I will 
be notified, and then you will automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Rapidshare::Free


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Rapidshare-Free>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Rapidshare-Free>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Rapidshare-Free>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Rapidshare-Free/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Alan Haggai Alavi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

