package WebService::Kramerius::API4::Rights;

use strict;
use warnings;

use base qw(WebService::Kramerius::API4::Base);

our $VERSION = 0.02;

sub rights {
	my ($self, $opts_hr) = @_;

	$self->_validate_opts($opts_hr, ['actions', 'pid']);

	return $self->_get_data($self->{'library_url'}.'search/api/v5.0/rights'.
		$self->_construct_opts($opts_hr));
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Kramerius::API4::Rights - Class to rights endpoint in Kramerius v4+ API.

=head1 SYNOPSIS

 use WebService::Kramerius::API4::Rights;

 my $obj = WebService::Kramerius::API4::Rights->new(%params);
 my $rights = $obj->rights($opts_hr);

=head1 METHODS

=head2 C<new>

 my $obj = WebService::Kramerius::API4::Rights->new(%params);

Constructor.

=over 8

=item * C<library_url>

Library URL.

This parameter is required.

Default value is undef.

=item * C<output_dispatch>

Output dispatch hash structure.
Key is content-type and value is subroutine, which converts content to what do you want.

Default value is blank hash array.

=back

Returns instance of object.

=head2 C<rights>

 my $rights = $obj->rights($opts_hr);

Get rights info of Kramerius system.

Structure C<$opts_hr> could contain keys:

=over

=item * C<actions>

=item * C<pid>

=back

Returns string with JSON.

=head1 ERRORS

 new():
         Parameter 'library_url' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=kramerius_rights.pl

 use strict;
 use warnings;

 use WebService::Kramerius::API4::Rights;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 library_url\n";
         exit 1;
 }
 my $library_url = $ARGV[0];

 my $obj = WebService::Kramerius::API4::Rights->new(
         'library_url' => $library_url,
 );

 my $rights_json = $obj->rights;

 print $rights_json."\n";

 # Output for 'http://kramerius.mzk.cz/', pretty print.
 # {
 #   "replikator_periodicals": false,
 #   "show_print_menu": false,
 #   "show_client_print_menu": true,
 #   "import": false,
 #   "rightsadmin": false,
 #   "convert": false,
 #   "import_k4_replications": false,
 #   "delete": false,
 #   "aggregate": true,
 #   "display_admin_menu": false,
 #   "show_alternative_info_text": false,
 #   "export_k4_replications": false,
 #   "pdf_resource": true,
 #   "enumerator": false,
 #   "show_client_pdf_menu": true,
 #   "export": false,
 #   "replicationrights": false,
 #   "editor": false,
 #   "read": true,
 #   "reindex": false,
 #   "setprivate": false,
 #   "export_cdk_replications": false,
 #   "virtualcollection_manage": false,
 #   "replikator_k3": false,
 #   "sort": false,
 #   "ndk_mets_import": false,
 #   "setpublic": false,
 #   "dnnt_admin": false,
 #   "rightssubadmin": false,
 #   "show_statictics": false,
 #   "manage_lr_process": false,
 #   "criteria_rights_manage": false,
 #   "replikator_monographs": false,
 #   "administrate": false,
 #   "edit_info_text": false
 # }

=head1 DEPENDENCIES

L<WebService::Kramerius::API4::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-Kramerius-API4>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2023

BSD 2-Clause License

=head1 VERSION

0.02

=cut
