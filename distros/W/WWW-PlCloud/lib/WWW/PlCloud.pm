package WWW::PlCloud;

use 5.006;
use strict;
use warnings;

=head1 NAME

WWW::PlCloud - The great new WWW::PlCloud!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

use Moo;

use LWP::UserAgent;
use JSON qw/to_json from_json/;
use Data::Dumper;

has sessionid => (
  is => 'rw',
);

has csrftoken => (
  is => 'rw',
);

has ua => (
  is => 'rw',
);

has user => (
  is => 'rw', required => 1,
);

has pass => (
  is => 'rw', required => 1,
);



=head1 SYNOPSIS

宝德云 API SDK,
只提供了一些基本的接口, 例如登陆.
具体的 API 列表参考:
http://docs.plcloud.com/api/list.html

调用方法:

  #!/usr/bin/env perl

  use strict;
  use warnings;
  use Data::Dumper;
  use PlCloud;

  my $pc = PlCloud->new( user => 'user_name', pass => 'password' );
  $pc->login();

  #
  # 无参数API调用方法
  $pc->run_api( 'GetUsageLimits' );

  # 带参数API调用方法
  $pc->run_api( 'GetUsageLimits', obj_id => 789, port_id => 'x' );


目前所有的API返回数据都直接输出至 STDOUT


=head1 SUBROUTINES/METHODS
=cut

sub run_api {
  my ( $self, $api, @o_args ) = @_;
  my $uri = "https://console.plcloud.com/api/";

  # Build
  my %post = @o_args ? @o_args : ();
  $post{ action } = $api;

  my $req = HTTP::Request->new( 'POST', $uri );
  $req->header( 'Content-Type' => 'application/json' );

  # 必须加额外的这个垃圾头
  $req->header( 'x-csrftoken' => $self->csrftoken );
  $req->content( to_json( \%post ) );

  my $res = $self->ua->request( $req );
  if ( $res && $res->is_success ) {
    my $json = from_json( $res->content );
    # 输出数据
    print_result( $json );
  }
}


sub login {
  my $self = shift;
  my $uri = 'https://console.plcloud.com/auth/login/';

  my $post = {
    csrfmiddlewaretoken => $self->csrftoken,
    username => $self->user,
    password => $self->pass,
    region => 'http://58.67.194.89:5001/v2.0',
  };

  my $res = $self->ua->post( $uri, $post );

  return 1 if $res && $res->code == 302;
  return 0;
}


#  init PlCloud Object
sub BUILD {
  my ( $self ) = @_;

  $self->ua( LWP::UserAgent->new( cookie_jar => {} ) );
  $self->ua->max_redirect( 9 );

  # 初始化 csrftoken
  $self->__init_csrftoken();

  return $self;
}

sub __init_csrftoken {
  my $self = shift;

  my $uri = 'https://console.plcloud.com/api/';
  my $res = $self->ua->get( $uri );

  if ( $res->is_success ) {
    my $cookie = $self->ua->cookie_jar;
    $cookie->scan( sub {
        $self->csrftoken( $_[2] ) if $_[1] eq 'csrftoken';
       $self->sessionid( $_[2] ) if $_[1] eq 'sessionid';
      } );

  }else {
    die "Can't get CSRFtoken\n";
  }

  return $self;
}

sub print_result {
  my ( $json, $shift ) = @_;

  foreach my $k ( sort keys %$json ) {
    if ( ref $json->{ $k } eq 'HASH' ) {
      print "$k:\n";
      print_result( $json->{ $k }, 1 );
    } else {
      print "\t"  if $shift;
      print "$k: $json->{ $k }\n";
    }
  }
}

1;

=head1 AUTHOR

MC Cheung, C<< <mc.cheung at aol.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-plcloud at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PlCloud>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PlCloud


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PlCloud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PlCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-PlCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-PlCloud/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 MC Cheung.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::PlCloud
