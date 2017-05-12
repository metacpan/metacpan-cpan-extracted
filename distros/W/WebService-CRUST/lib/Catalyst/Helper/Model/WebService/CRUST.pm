package Catalyst::Helper::Model::WebService::CRUST;


use strict;


=head1 NAME

Catalyst::Helper::Model::WebService::CRUST - Helper for Catalyst WebService::CRUST
based models

=head1 SYNOPSIS

  script/create.pl model MyService WebService::CRUST [base_uri]
  
  Where:
      MyService is the short name for the Model class being generated
      base_url is an optional base URI (see L<WebService::CRUST>)

=cut

sub mk_compclass {
    my ($self, $helper, $base) = @_;
    
    $helper->{base} = $base;

    $helper->render_file( 'compclass', $helper->{file} );
}

=head1 SEE ALSO

L<WebService::CRUST>, L<Catalyst::Model::WebService::CRUST>

=head1 AUTHOR

Chris Heschong E<lt>chris@wiw.orgE<gt>

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::WebService::CRUST';

[% IF base %]
__PACKAGE__->config(
    base => '[%  base %]'
);
[% END %]

=head1 NAME

[% class %] - Catalyst WebService::CRUST Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::WebService::CRUST> Model for making REST queries

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
