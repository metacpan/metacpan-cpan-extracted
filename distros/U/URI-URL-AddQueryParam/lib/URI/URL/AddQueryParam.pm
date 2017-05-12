package URI::URL::AddQueryParam;

use 5.008008;
use strict;
use warnings;
use URI;
use URI::URL;
use URI::QueryParam;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(http_add_query_param);
our $VERSION = '0.03';

sub http_add_query_param
{
	my $base_url = shift;
	my $hashref_add_query_param = shift;

	my $obj_url = URI::URL->new($base_url);
	foreach (sort keys %$hashref_add_query_param)
	{
		$obj_url->query_param_append($_, $$hashref_add_query_param{$_});
	}
	return $obj_url->abs;
}

1;
__END__

=head1 NAME

URI::URL::AddQueryParam - Add Query Param after HTTP URL

=head1 SYNOPSIS

  use strict;
  use warnings;
  use URI::URL::AddQueryParam qw(http_add_query_param);

  my %http_param = ('ta' => 'ok', 'foobar' => 1, 'hoge' => 0);
  my $base_url = 'http://example.com/';
  print http_add_query_param($base_url, \%http_param);
  # got 'http://example.com/?ta=ok&hoge=0&foobar=1'

  %http_param = ('ta' => 'ok', 'foobar' => 1, 'hoge' => 0);
  $base_url = 'http://example.com?soso=gogo';
  print http_add_query_param($base_url, \%http_param);
  # got 'http://example.com/tt3.php?soso=gogo&ta=ok&hoge=0&foobar=1'

=head1 DESCRIPTION

avoid '&/?' things.

=head2 EXPORT

None by default.


=head1 SEE ALSO

L<URI::QueryParam>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
