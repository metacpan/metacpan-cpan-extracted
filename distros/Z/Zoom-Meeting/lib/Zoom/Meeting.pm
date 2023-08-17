# ABSTRACT: Launch Zoom meetings via Perl


use v5.37.12;
use experimental qw( class try builtin );
use builtin qw( true false blessed );

package Zoom::Meeting; # quirk
class Zoom::Meeting {

  use overload q("") => sub { $_[0] -> _url; };

  use URI;
  use Path::Tiny;
  use System::Command;

  # @formatter:off
  field $id :param;
  field $password :param = undef;
  # @formatter:on


  method id ( $new_id = undef ) {
    if ( defined $new_id ) {
      $id = $new_id;
    }
    else {
      return $id;
    }
  }



  method password ( $new_password = undef ) {
    if ( defined $new_password ) {
      $password = $new_password;
    }
    else {
      return $password;
    }
  }


  method _url ( ) {
    my $uri = URI -> new( 'zoommtg://zoom.us' ); # scheme is '_foreign' class, so no 'host' method
    $uri -> path( 'join' );
    $uri -> query_form_hash( {
      'confno' => $id ,
      'pwd'    => $password
    } );
    return $uri;
  }



  method launch ( ) {

    my $zoom;

    if ( $^O eq 'linux' and -f '/proc/sys/fs/binfmt_misc/WSLInterop' ) {
      $zoom = path '/mnt/c/Program Files/Zoom/bin/zoom.exe';
    }

    System::Command -> new(
      $zoom ,
      "--url=@{ [ $self -> _url ] }" ,
      # { trace => 3 }
    );

  }


}

__END__

=pod

=encoding UTF-8

=head1 NAME

Zoom::Meeting - Launch Zoom meetings via Perl

=head1 VERSION

version 0.231740

=head1 SYNOPSIS

  use Zoom::Meeting;
  # Load the module

  my $zoom = Zoom::Meeting -> new (id => '0' x 11);
  # Create object with the required meeting ID field set

  $zoom -> password('NEW_PASS');
  # Set meeting's password via a method call

  say $zoom;
  # Show the URL string (the Zoom object being overloaded as string)

  $zoom -> launch;
  # Join the meeting by launching Zoom

=head1 METHODS

=head2 new

Constructor method used to create a C<Zoom::Meeting> object

Accepts C<id> and C<password> parameters to initialize its fields

=head2 id([$new_id])

Return or set meeting ID

=head2 password([$new_password])

Return or set meeting password

=head2 _url

Private method constructing Zoom URL containing C<confno> and C<pwd> fields
standing for meeting ID and password respectively

=head2 launch()

Launch the Zoom meeting object in a Zoom application

Supports only WSL currently, Linux and native Windows support to be added

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
