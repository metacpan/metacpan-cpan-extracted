#!/usr/bin/env perl

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