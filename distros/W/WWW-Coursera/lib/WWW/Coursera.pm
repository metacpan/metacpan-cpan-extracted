package WWW::Coursera;

use strict;
use warnings;

use 5.010;
use Moo;
use Mojo::DOM;
use Mojo::UserAgent;
use AnyEvent;
use AnyEvent::Util 'fork_call';
my $cv = AE::cv;
use File::Path qw( make_path );
use Carp qw(croak) ;

$ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824;

=head1 NAME

WWW::Coursera - Downloading parallel material (video, text, pdf ...) from Coursera.org online classes.

=head1 VERSION

version 0.12

=cut

our $VERSION = '0.12';

=head2 username

  set username

=cut

has username => (
    is       => 'ro',
    required => 1,
);

=head2 password

  set password

=cut

has password => (
    is       => 'ro',
    required => 1,
);

=head2 course_id

  set course id

=cut

has course_id => (
    is       => 'ro',
    required => 1,
);

=head2 debug

  debug option

=cut

has debug => (
    is      => 'rw',
    default => 0,
);

=head2 max_parallel_download

  set max parallel http requests

=cut

has max_parallel_download => (
    is      => 'rw',
    default => 2,
);

=head2 override_existing_files

  set option ro override existing files 

=cut

has override_existing_files => (
    is      => 'rw',
    default => 0,
);


=head1 SYNOPSIS

    Scrape video materials from lectures area and download paralell related files.
    The default download directory is set to the course_id.
    
    The only one requirement is to enroll the course online.


    use WWW::Coursera;
    my $init = WWW::Coursera->new(
        username              	=> 'xxxx',	#is required
        password              	=> 'xxxx',	#is required
        course_id             	=> "xxxx",	#is required
        debug                 	=> 1,		#default disabled
        max_parallel_download 	=> 2,		#default 2
        override_existing_files	=> 1,		#default false
      );
      $init->run;

=head1 SUBROUTINES/METHODS

=head2 directory

  Create new directory 

=cut

sub directory {
    my $self = shift;
    unless ( -d $self->{course_id} ) {
        make_path $self->{course_id} or die "Failed to create path: 
  $self->{course_id}";
    }
}

=head2 extentions

  Definition of downoading extentions

=cut

sub extentions {
    my $self = shift;
    my @extention = ( "mp4", "txt", "pdf", "pptx", "srt" );
    return @extention;
}

=head2 UserAgent

  Create UserAgent object

=cut

sub UserAgent {
    my $self = shift;
    my $ua   = Mojo::UserAgent->new;
    $ua = $ua->max_redirects(1);
    $self->{ua} = $ua;
	$ua->transactor->name('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0');
}


=head2 csrf

  Save csrf token for authentication

=cut

sub csrf {
    my $self = shift;
    $self->UserAgent;
    my $tx =
      $self->{ua}
      ->get("https://class.coursera.org/$self->{course_id}/lecture/index");
    my $csrf = $tx->res->cookies->[0]->{value};
    croak "Error: No CSRF key available my be the couse is not available"
      unless $csrf;
    $self->{csrf} = $tx->req->cookies->[0]->{value};
    say "The CSRF key is : $csrf" if $self->debug;
}

=head2 login

  Login with username, password and csrftoken

=cut

sub login {
    my $self = shift;
    $self->csrf;
    my $tx = $self->{ua}->post(
        "https://www.coursera.org/api/login/v3Ssr?csrf3-token=$self->{csrf}" => {
            #'Cookie'      => "CSRF3-Token=$self->{csrf}",
            'csrf3-token' => $self->{csrf},
          } => form =>
          { email => "$self->{username}", password => "$self->{password}" }
    );
    say "The http response code from login page is :" . $tx->res->code
      if $self->debug;
    unless ( $tx->res->code == 200 ) {
        my ( $err1, $code1 ) = $tx->error;
        say $code1 ? "$code1 response: $err1" : "Connection error: $err1";
    }
}

=head2 convert_filename

  Replace all non word chars with underscore

=cut

sub convert_filename {
    my ( $self, $string, $ext ) = @_;
    $string =~ s/\W/_/g;
    $string =~ s/__/_/g;
    $string = "$string" . ".$ext";
    $string =~ s/_\././g;
    say "Convert string $string" if $self->debug;
    return $string;
}

=head2 extract_urls

  Scrape urls from lectures

=cut

sub extract_urls {
    my $self = shift;
    $self->login;
    my %urls;
    my $r =
      $self->{ua}->get("https://class.coursera.org/$self->{course_id}/lecture");
    if ( my $res = $r->success ) {
        my $dom = $r->res->dom;
        $dom->find('div.course-lecture-item-resource')->each(
            sub {
                my ( $e, $count ) = @_;
                my $title = $e->find('a[data-if-linkable=modal-lock]')->each(
                    sub {
                        my ( $b, $cnt ) = @_;
						my $file = $b->find('div.hidden')->[0]->text;
                        my $url  = $b->attr('href');
                        foreach my $ext ( $self->extentions ) {
                            if ( "$url" =~ m/$ext/ ) {
                                my $conv_name =
                                  $self->convert_filename( $file, $ext );
                                $urls{$conv_name} = "$url";
                            }
                        }
                    }
                );
            }
        );
        $self->{urls} = \%urls;
    }
    else {
        my ( $err, $code ) = $res->error;
        say $code ? "$code response: $err" : "Connection error: $err";
    }
}

=head2 download

  Download lectures in the course_id folder

=cut

sub download {
    my ( $self, $file ) = @_;
    say "Start download $file in $self->{course_id}";
    my $url = $self->{urls}->{$file};
    $self->directory;
    my $path = "$self->{course_id}/$file";

    if ( $self->override_existing_files ) {
        my $response = $self->{ua}->get( $url, { Accept => '*/*' } )->res;
        open my $fh, '>', $path or die "Could not open [$file]: $!";
        print $fh $response->body;
    }
    else {
        if ( !-e $path ) {
            my $response = $self->{ua}->get( $url, { Accept => '*/*' } )->res;
            open my $fh, '>', $path or die "Could not open [$file]: $!";
            print $fh $response->body;
        }
    }
}



=head2 run

  Entry point of the package

=cut

sub run {
    my $self = shift;
    $AnyEvent::Util::MAX_FORKS = $self->max_parallel_download;
    $self->extract_urls;
    my @arr = keys %{$self->{urls}};
    foreach my $file (@arr) {
        $cv->begin;
        fork_call {
            $self->download($file);
        }
        sub {
            $cv->end;
          }
    }
    $cv->recv;
}




=head1 AUTHOR

Ovidiu N. Tatar, C<< <ovn.tatar at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-coursera at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Coursera>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 REQUIREMENT

        perl 5.010 or higher
        Enrol course before start downloding
        For more info regarding requires modules (see Build.PL)

=head1 INSTALLATION

To install this module, run the following commands:

	git clone https://github.com/ovntatar/WWW-Coursera.git
	cd WWW-Coursera
        
	perl Build.PL
        ./Build
        ./Build test
        ./Build install

        OR (if you don't have write permissions to create man3) use cpanminus: 

        cpanm WWW-Coursera


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Coursera
    
    or
   
    https://github.com/ovntatar/WWW-Coursera/issues


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Coursera>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Coursera>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Coursera>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Coursera/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ovidiu N. Tatar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Coursera







