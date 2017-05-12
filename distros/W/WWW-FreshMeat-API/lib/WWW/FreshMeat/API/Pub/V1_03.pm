package WWW::FreshMeat::API::Pub::V1_03;
use base 'Exporter';
our @EXPORT_OK = qw/get_api_info/;
our $VERSION = '0.01';

# pulled by testing API....
our $api = {

    fetch_available_licenses => {
        desc    => 'Fetch all available licenses',
        params  => [],
        returns => [
                  'Academic Free License (AFL)',
                  'Adaptive Public License (APL)',
                  'Affero General Public License',
                  'Aladdin Free Public License (AFPL)',
                  'Apple Public Source License (APSL)',
                  'Artistic License',
                  'Boost Software License',
                  'BSD License (original)',
                  'BSD License (revised)',
                  'Common Development and Distribution License (CDDL)',
                  'Common Public License',
                  'Copyback License',
                  'DFSG approved',
                  'Eclipse Public License',
                  'Educational Community License',
                  'Eiffel Forum License (EFL)',
                  'Free For Educational Use',
                  'Free For Home Use',
                  'Free for non-commercial use',
                  'Free To Use But Restricted',
                  'Freely Distributable',
                  'Freeware',
                  'GNAT Modified GPL (GMGPL)',
                  'GNU Free Documentation License (FDL)',
                  'GNU General Public License (GPL)',
                  'GNU General Public License v2',
                  'GNU General Public License v3',
                  'GNU Lesser General Public License (LGPL)',
                  'Guile license',
                  'IBM Public License',
                  'MIT/X Consortium License',
                  'MITRE Collaborative Virtual Workspace License (CVW)',
                  'Mozilla Public License (MPL)',
                  'Netscape Public License (NPL)',
                  'Nokia Open Source License (NOKOS)',
                  'Open Software License',
                  'OSI Approved',
                  'Other/Proprietary License',
                  'Other/Proprietary License with Free Trial',
                  'Other/Proprietary License with Source',
                  'Perl License',
                  'Public Domain',
                  'Python License',
                  'Q Public License (QPL)',
                  'Ricoh Source Code Public License',
                  'Shareware',
                  'SUN Binary Code License',
                  'SUN Community Source License',
                  'SUN Public License',
                  'The Apache License',
                  'The Apache License 2.0',
                  'The CeCILL License',
                  'The Clarified Artistic License',
                  'The Latex Project Public License (LPPL)',
                  'The Open Content License',
                  'The PHP License',
                  'Voxel Public License (VPL)',
                  'W3C License',
                  'WTFPL',
                  'zlib/libpng License',
                  'Zope Public License (ZPL)',
            ],
    },
        
    fetch_available_release_foci => {
        desc    => 'Fetch all available release focus types',
        params  => [],
        returns => {
                  'N/A' => '0',
                  'Major security fixes' => '9',
                  'Documentation' => '2',
                  'Minor security fixes' => '8',
                  'Initial freshmeat announcement' => '1',
                  'Minor bugfixes' => '6',
                  'Code cleanup' => '3',
                  'Major bugfixes' => '7',
                  'Minor feature enhancements' => '4',
                  'Major feature enhancements' => '5'
        },
    },
    
    fetch_branch_list => {
        desc    => 'Fetch all branch names and IDs for a given project', 
        params  => [ qw/SID project_name/ ],
        returns => [],  # returns list of branches, for eg. 'Default'
    },
        
    fetch_project_list => {
        desc    => 'Fetch all projects assigned to logged in user',
        params  => [ qw/SID/ ],
        returns => [ { projectname_full => 1, projectname_short => 1, project_status => 1, project_version => 1 } ],
    },
        
    fetch_release => {
        desc    => 'Fetch data from a pending release submission',
        params  => [ qw/SID project_name branch_name version/ ],
        returns => { version => 1, changes => 1, release_focus => 1, hide_from_frontpage => 1 },
    },
    
    login => {
        desc    => 'Start an XML-RPC session',
        params  => [ qw/username password/ ],
        returns => { 'SID' => 1, 'Lifetime' => 1, 'API Version' => 1 },
    },
    
    logout => {
        desc    => 'End an XML-RPC session',
        params  => [ qw/SID/ ],
        returns => { OK => "Logout successful." },  #  if logout was successful
    },
    
    publish_release	=> {
        desc    => 'Publish a new release',
        params  => [ qw/
            SID project_name branch_name version changes release_focus hide_from_frontpage
            license url_homepage url_tgz url_bz2 url_zip url_changelog url_rpm url_deb 
            url_osx url_bsdport url_purchase url_cvs url_list url_mirror url_demo	   
        / ],
        returns => { OK => "submission successful" },  # if successful!
    },
    
    withdraw_release => {
        desc    => 'Take back a release submission',
        params  => [ qw/SID project_name branch_name version/ ],
        returns => { OK => "Withdraw successful." },  # if successfully withdrawn!
    },
};


# Below is only bit of info I actually used from freshmeat-submit
# [ Appendix A: Release focus IDs ]
# 0 - N/A
# 1 - Initial freshmeat announcement
# 2 - Documentation
# 3 - Code cleanup
# 4 - Minor feature enhancements
# 5 - Major feature enhancements
# 6 - Minor bugfixes
# 7 - Major bugfixes
# 8 - Minor security fixes
# 9 - Major security fixes
# 
# 
# [ Appendix B: Error codes ]
#  10 - Login incorrect
#  20 - Session inconsistency
#  21 - Session invalid
#  30 - Branch ID incorrect
#  40 - Permission to publish release denied
#  50 - Version string missing
#  51 - Duplicate version string
#  60 - Changes field empty
#  61 - Changes field too long
#  62 - Changes field contains HTML
#  70 - No valid email address set
#  80 - Release not found
#  81 - Project not found
#  90 - Release focus missing
#  91 - Release focus invalid
# 100 - License invalid
# 999 - Unknown error

sub get_api_info { $api }

1;
    
__END__

=head1 NAME

package WWW::FreshMeat::API::Pub::V1_03 - Metadata for FreshMeat API v1.03

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

    use package WWW::FreshMeat::API::Pub::V1_03 qw/get_api_info/;
    

=head1 DESCRIPTION

Exports on request get_api_info() which is simply a sub around hashref metadata.

Used by WWW::FreshMeat::API::Pub to build the published API as methods.

=head1 EXPORT

=head2 get_api_info()

On request


=head1 FUNCTIONS

=head2 get_api_info()


=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freshmeat-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreshMeat-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FreshMeat::API::Pub::V1_03


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreshMeat-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreshMeat-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreshMeat-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreshMeat-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 SEE ALSO

=head2 Freshmeat API FAQ

http://freshmeat.net/faq/view/49/

=head2 Freshmeat XML-RPC API announcement

http://freshmeat.net/articles/view/1048/

=head2 Other WWW::FreshMeat::API modules

L<WWW::FreshMeat::API>



=head1 COPYRIGHT & LICENSE

Copyright 2009 Barry Walsh (Draegtun Systems Ltd), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.





