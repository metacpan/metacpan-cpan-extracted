package USCIS::Case;

use strict;
use warnings;

our @EXPORT_OK = qw(check_case_status);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
use base qw(Exporter);

our $VERSION = '0.02';

use LWP::Protocol::https;
use LWP::UserAgent;
use XML::LibXML;


sub check_case_status {
    my $case_number = shift @_;
    my $case_status_ref = {
        'validity' => 'no',
        'case_number' => $case_number,
        'case_status' => undef,
        'case_detail' => undef,
        'uscis_web_rc' => '',
    };

    # USCSI case status query vars
    my $uscis_case_status_endpoint = 'https://egov.uscis.gov/casestatus/mycasestatus.do';
    my $query_form = [
        'appReceiptNum' => $case_number,
        'initCaseSearch' => 'CHECK STATUS',
        'changeLocale' => '',
    ];

    # construct UA to call USCIS case status endpoint
    my $call = LWP::UserAgent->new();
    my $res = $call->post($uscis_case_status_endpoint, Content => $query_form);

    # update USCIS web access response code / messages
    $case_status_ref->{uscis_web_rc} = $res->status_line;

    if ($res->is_success) {
        my $case_status_html = $res->content;

        my $dom = XML::LibXML->load_html(
            string => $case_status_html,
            recover => 1,
            suppress_errors => 1,
        );

        # XPath search
        my $case_status = ($dom->findnodes('//div[@class=\'rows text-center\']/h1')->to_literal_list)[0];
        my $case_detail = ($dom->findnodes('//div[@class=\'rows text-center\']/p')->to_literal_list)[0];

        if (defined($case_status)) {
            $case_status_ref->{validity} = 'yes';
            $case_status_ref->{case_status} = $case_status;
            $case_status_ref->{case_detail} = $case_detail;
        } else {
            $case_status_ref->{validity} = 'no';
        }
    }

    return $case_status_ref;
}

1;

__END__

=head1 NAME

USCIS::Case - Perl extensions to check USCIS (United States Citizenship and Immigration Services) case status. More features would be added in the future.

=head1 SYNOPSIS

  use Data::Dumper;
  use USCIS::Case qw(check_case_status);

  my $case = 'LIN0000000000';

  # a hash reference is returned
  my $case_status = check_case_status($case);

  print Dumper($case_status);

=head1 DESCRIPTION

USCIS::Case is a wrapper to access USCIS (United States Citizenship and Immigration Services) website to get information about USCIS case. It has only one function now which is to check the case status. But more features would be added in the future.

Each function will return a hash reference.

=head1 EXPORT

Nothing is exported by default. You can ask for specific subroutines (described below) or ask for all subroutines at once:

    use USCIS::Case qw(check_case_status);
    # or
    use USCIS::Case qw(:all);

=head1 SUBROUTINES

=head2 check_case_status

Return a hash reference about the USCIS case information. This hash reference includes 5 entries: C<validity>, C<case_number>, C<case_status>, C<case_detail> and C<uscis_web_rc>.

C<validity>: Default value is C<no>. It contains value "yes" or "no". This indicates if the case number can be queried in USCIS website or not.

C<case_number>: The USCIS case number passed to check status.

C<case_status>: Default value is C<undef>. USCIS case status acquired from USCIS website.

C<case_detail>: Default value is C<undef>. Some extra details about the USCIS case.

C<uscis_web_rc>: Default value is an empty string. This entry records USCIS response code / messages. HTTP 200 response code does not mean the USCIS case can be queried. User must use C<validity> to determine if the USCIS case is valid to query or not.

=head1 SEE ALSO

You can find documentation for this module with the perldoc command.

    perldoc USCIS::Case

Source Code: L<https://github.com/meow-watermelon/USCIS-Case>

=head1 AUTHOR

Hui Li, E<lt>herdingcat@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
