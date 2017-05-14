#
# $Id: Segments.pm,v 1.5 2004/08/25 21:49:38 brian.kaney Exp $
#
# XML::ASCX12::Segments
#
# Copyright (c) Vermonster LLC <http://www.vermonster.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# For questions, comments, contributions and/or commercial support
# please contact:
#
#    Vermonster LLC <http://www.vermonster.com>
#    312 Stuart St.  2nd Floor
#    Boston, MA 02116  US
#
# vim: set expandtab tabstop=4 shiftwidth=4
#

=head1 NAME

XML::ASCX12::Segments - Segment *and* Element Definitions for ASCX12 EDI Data

=cut
package XML::ASCX12::Segments;

use Carp qw(croak);
use vars qw(@ISA @EXPORT $VERSION $SEGMENTS $ELEMENTS);

BEGIN
{
    @ISA = ('Exporter');
    @EXPORT = qw($SEGMENTS $ELEMENTS);
    $VERSION = '0.1';
}

=head1 DESCRIPTION

The name is a bit of a misnomer, this file contains both the ASCX12
segments and elements.  Segmentsandelements.pm seemed like too long
of a name.

=head1 PUBLIC STATIC VARIABLES

=over 4

=item $SEGMENTS


This is the segments found in each catalog.  If you add more segments, please
submit your changes to the author so we can keep this project growing.

=cut
$SEGMENTS = {
   # CODE   => [Description, (M)andatory|(O)ptional, MxUse, LoopID, LoopRepeat]
    'ISA'  => ['Interchange Control Header',                'M', 1,  'ISA',  0]
   ,'IEA'  => ['Interchange Control Trailer',               'M', 1,  'ISA',  0]
   ,'GS'   => ['Functional Group Header',                   'M', 1,  'GS',   0]
   ,'GE'   => ['Functional Group Trailer',                  'M', 1,  'GS',   0]
   ,'ST'   => ['Transaction Set Header',                    'M', 1,  'ST',   0]
   ,'SE'   => ['Transaction Set Trailer',                   'M', 1,  'ST',   0]

   #
   # This is Catalog 110 Specific
   #
   ,'B3'   => ['Beg Seg for Carriers Invoice',              'M', 1,  'ST',   0]
   ,'B3A'  => ['Invoice Type',                              'O', 1,  'ST',   0]
   ,'ITD'  => ['Invoice Type Deferred Terms of Sale',       'O', 1,  'ST',   0]
   ,'N1'   => ['Name',                                      'O', 1,  'N1',   3]
   ,'N2'   => ['Additional Name Information',               'O', 1,  'N1',   2]
   ,'N3'   => ['Address Information',                       'O', 2,  'N1',   0]
   ,'N4'   => ['Geographic Information',                    'O', 1,  'N1',   0]
   ,'N5'   => ['Address Information',                       'O', 2,  'N1',   0]
   ,'N9'   => ['Reference Number',                          'O', 10, 'N1',   0]
   ,'LX'   => ['Sequential Number',                         'M', 1,  'LX',   9999]
   ,'P1'   => ['Pickup',                                    'O', 1,  'LX',   0]
   ,'R1'   => ['Route Information (Air)',                   'O', 1,  'LX',   0]
   ,'POD'  => ['Proof of Delivery (POD)',                   'O', 1,  'LX',   0]
   ,'V9'   => ['Event Detail',                              'O', 1,  'LX',   0]
   ,'RMT'  => ['Remittance Advice',                         'O', 10, 'LX',   0]
   ,'NTE'  => ['Note/Special Instruction',                  'O', 10, 'LX',   0]
   ,'L5'   => ['Line Item Description',                     'M', 1,  'L5',   4]
   ,'L0'   => ['Line Item/Qty and Wt',                      'O', 1,  'L5',   0]
   ,'L4'   => ['Measurement',                               'O', 4,  'L5',   0]
   ,'L10'  => ['Weight',                                    'O', 4,  'L5',   0]
   ,'SL1'  => ['Tariff Reference',                          'O', 1,  'L5',   0]
   ,'L1'   => ['Rates and Charges',                         'O', 1,  'L1',   30]
   ,'L3'   => ['Total Weight and Charges',                  'M', 1,  'ST',   0]

   #
   # This is Catalog 997 Specific
   #
   ,'AK1'   => ['Functional Identifier Code',               'M', 1,  'ST',   0]
   ,'AK2'  => ['Transaction Set Response Header',           'O', 1,  'AK2',  9999]
   ,'AK3'  => ['Data Segment Note',                         'O', 1,  'AK3',  9999]
   ,'AK4'  => ['Data Element Notice',                       'O', 99, 'AK3',  9999]
   ,'AK5'  => ['Transaction Set Response Trailer',          'M', 1,  'AK2',  9999]
   ,'AK9'  => ['Functional Group Response Header',          'M', 1,  'ST',   0]

   #
   # This is Catalog 175 Specific
   #
   ,'BGN'   => ['Beginning Segment',                        'M', 1,  'ST',   0]
   ,'CDS'   => ['Case Description',                         'M', 1,  'CDS',   0]
   ,'LS'    => ['Start of CED loops',                       'M', 1,  'CDS',   0]
   ,'CED'  => ['Case Event of Notice Information',          'M', 1,  'CED',  9999]
   ,'DTM'  => ['Date/Time Information',                     'O', 2,  'CED',  9999]
   ,'REF'  => ['Reference Numbers',                         'O', 3,  'CED',  9999]
   ,'MSG'  => ['Free-form Information',                     'O', 9999,  'CED',  9999]
   ,'LM'   => ['Indicates that US Court Codes are to follow','O', 1, 'LM', 9999]
   ,'LQ'   => ['Court code associated with particular event','M', 2, 'LM', 9999]
   ,'NM1'  => ['Name and type of entity',                   'M', 1, 'NM1', 9999]
   ,'N2'   => ['Continuation of NM103 name',                'O', 9999, 'NM1', 9999]
   ,'N3'   => ['Address',                                   'O', 4,'NM1', 9999]
   ,'N4'   => ['City, state and zip code',                  'O', 1,'NM1', 9999]
   ,'REF'  => ['Reference Numbers',                         'O', 3,'NM1', 9999]
   ,'PER'  => ['Telephone Number',                          'O', 1,'NM1', 9999]
   ,'LE'    => ['End of CED loops',                         'M', 1, 'CDS',   0]
};

=item $ELEMENTS


These are the elements found within each segment.  If you add more elements, please
submit your changes to the author so we can keep this project growing.

=cut
$ELEMENTS = {
    # CODE   => [Description, (M)andatory|(O)ptional, Type, Min, Max]
     'ISA01' => ['Authorization Information Qualifier', 'M', 'ID', 2,  2]
    ,'ISA02' => ['Authorization Information',           'M', 'AN', 10, 10]
    ,'ISA03' => ['Security Information Qualifier',      'M', 'ID', 2,  2]
    ,'ISA04' => ['Security Information',                'M', 'AN', 10, 10,]
    ,'ISA05' => ['Interchange ID Qualifier',            'M', 'ID', 2,  2]
    ,'ISA06' => ['Interchange Sender ID',               'M', 'AN', 15, 15]
    ,'ISA07' => ['Interchange ID Qualifier',            'M', 'ID', 2,  2]
    ,'ISA08' => ['Interchange Receiver ID',             'M', 'AN', 15, 15]
    ,'ISA09' => ['Interchange Date',                    'M', 'DT', 6,  6]
    ,'ISA10' => ['Interchange Time',                    'M', 'TM', 4,  4]
    ,'ISA11' => ['Interchange Cntrl Standards ID',      'M', 'ID', 1,  1]
    ,'ISA12' => ['ISA Control Version Number',          'M', 'ID', 5,  5]
    ,'ISA13' => ['Interchange Control Number',          'M', 'NO', 9,  9]
    ,'ISA14' => ['ACK Requested',                       'M', 'ID', 1,  1]
    ,'ISA15' => ['Usage Indicator',                     'M', 'ID', 1,  1]
    ,'ISA16' => ['Component Element Separator',         'M', 'ID', 1,  1]
    ,'GS01'  => ['Functional ID Code',           ,      'M', 'ID', 2,  2]
    ,'GS02'  => ['Application Sender Code',             'M', 'AN', 2,  15]
    ,'GS03'  => ['Application Receiver Code',           'M', 'AN', 2,  15]
    ,'GS04'  => ['Date',                                'M', 'DT', 8,  8]
    ,'GS05'  => ['Time',                                'M', 'TM', 4,  8]
    ,'GS06'  => ['Group Control Number',                'M', 'NO', 1,  9]
    ,'GS07'  => ['Responsible Agency Code',             'M', 'ID', 1,  2]
    ,'GS08'  => ['Version/Release ID Code',             'M', 'AN', 1,  12]
    ,'ST01'  => ['Transaction Set Identifier Code',     'M', 'ID', 3,  3]
    ,'ST02'  => ['Transaction Set Control Number',      'M', 'AN', 4,  9]
    ,'B302'  => ['Invoice Number',                      'M', 'AN', 1,  22]
    ,'B304'  => ['Shipment Method of Payment',          'M', 'ID', 2,  2]
    ,'B306'  => ['Billing Date',                        'M', 'DT', 8,  8]
    ,'B307'  => ['Net Amount Due',                      'M', 'N2', 1,  12]
    ,'B308'  => ['Invoice Type',                        'O', 'ID', 2,  2]
    ,'B311'  => ['SCAC',                                'M', 'ID', 2,  4]
    ,'B312'  => ['Billing Date',                        'O', 'DT', 8, 8]
    ,'B313'  => ['Settlement Option',                   'O', 'ID', 2, 2]
    ,'B3A01' => ['Transaction Type Codes',              'M', 'ID', 2, 2]
    ,'B3A02' => ['Number of Transactions',              'O', 'N0', 1, 5]
    ,'ITD01' => ['Terms Type Code',                     'O', 'ID', 2, 2]
    ,'ITD02' => ['Terms Basis Date Code',               'O', 'ID', 1, 2]
    ,'ITD07' => ['Terms Net Days',                      'O', 'N0', 1, 3]
    ,'N101'  => ['Entity Identifier Code',              'M', 'ID', 2, 3]
    ,'N102'  => ['Name',                                'X', 'AN', 1, 60]
    ,'N201'  => ['Name',                                'M', 'AN', 1, 60]
    ,'N301'  => ['Address',                             'M', 'AN', 1, 55]
    ,'N302'  => ['Address',                             'O', 'AN', 1, 55]
    ,'N401'  => ['City Name',                           'O', 'AN', 2, 30]
    ,'N402'  => ['State/Province Code',                 'O', 'ID', 2, 2]
    ,'N403'  => ['Postal Code',                         'O', 'ID', 3, 15]
    ,'N404'  => ['Country Code',                        'O', 'ID', 2, 3]
    ,'N901'  => ['Reference Identification Qualifier',  'M', 'ID', 2, 3]
    ,'N902'  => ['Reference Identification',            'X', 'AN', 1, 30]
    ,'N903'  => ['Free-Form Description',               'X', 'AN', 1, 45]
    ,'LX01'  => ['Assigned Number',                     'M', 'N0', 1, 6]
    ,'P101'  => ['Pickup or Delivery Code',             'O', 'ID', 1, 2]
    ,'P102'  => ['Pickup Date',                         'M', 'DT', 8, 8]
    ,'P103'  => ['Date/Time Qualifier',                 'M', 'ID', 3, 3]
    ,'R101'  => ['SCAC',                                'O', 'ID', 2, 4]
    ,'R103'  => ['Airport Code',                        'M', 'ID', 3, 5]
    ,'R104'  => ['Air Carrier Code',                    'M', 'ID', 3, 3]
    ,'R105'  => ['Airport Code',                        'M', 'ID', 3, 5]
    ,'POD01' => ['Date',                                'M', 'DT', 8, 8]
    ,'POD02' => ['Time',                                'O', 'TM', 4, 8]
    ,'POD03' => ['Name',                                'M', 'AN', 1, 60]
    ,'V901'  => ['Event Code',                          'M', 'ID', 3, 3]
    ,'V902'  => ['Event',                               'O', 'AN', 1, 25]
    ,'V903'  => ['Event Date (Used to validate on-time delivery)', 'O', 'DT', 8, 8]
    ,'V904'  => ['Event Time (Used to validate on-time delivery)', 'X/Z', 'TM', 4, 8]
    ,'V908'  => ['Status Reason Code (Used to validate on-time delivery)', 'O', 'ID', 3, 3]
    ,'V912'  => ['Free-Form Message',                   'O', 'AN', 1, 30]
    ,'RMT01' => ['Reference Identification Qualifier',  'M', 'ID', 2, 3]
    ,'RMT02' => ['Reference Identification',            'M', 'AN', 1, 30]
    ,'RMT03' => ['Monetary Amount',                     'O', 'R', 1, 18]
    ,'RMT06' => ['Monetary Amount',                     'O', 'R', 1, 18]
    ,'RMT08' => ['Monetary Amount',                     'O', 'R', 1, 18]
    ,'RMT01' => ['Reference Identification Qualifier',  'M', 'ID', 2, 3]
    ,'RMT02' => ['Reference Identification',            'M', 'AN', 1, 30]
    ,'NTE01' => ['Note Reference Code',                 'O', 'ID', 3, 3]
    ,'NTE02' => ['Free-Form Message',                   'M', 'AN', 1, 80]
    ,'L501'  => ['Lading Line Item Number',             'O', 'N0', 1, 3]
    ,'L502'  => ['Lading Description',                  'O', 'AN', 1, 50]
    ,'L503'  => ['Commodity Code',                      'X', 'AN', 1, 30]
    ,'L504'  => ['Commodity Code Qualifier',            'X', 'ID', 1, 1]
    ,'L505'  => ['Packaging Code',                      'O', 'AN', 3, 5]
    ,'L001'  => ['Lading Line Item Number',             'O', 'N0', 1, 3]
    ,'L004'  => ['Weight',                              'X', 'R', 1, 10]
    ,'L005'  => ['Weight Qualifier',                    'X', 'ID', 1, 2]
    ,'L008'  => ['Lading Quantity',                     'X/Z', 'N0', 1, 7]
    ,'L009'  => ['Packaging Form Code',                 'X', 'ID', 3, 3]
    ,'L011'  => ['Weight Unit Code',                    'O', 'ID', 1, 1]
    ,'L013'  => ['Charge Count',                        'X/Z', 'R', 1, 15]
    ,'L015'  => ['Charge Count Qualifier',              'X', 'ID', 1, 1]
    ,'L1001' => ['Weight',                              'M', 'R', 1, 10]
    ,'L1002' => ['Weight Qualifier',                    'M', 'ID', 1, 2]
    ,'L1003' => ['Weight Unit Qualifier',               'O', 'ID', 1, 1]
    ,'SL101' => ['Service Base Code',                   'M', 'ID', 2, 2]
    ,'SL102' => ['Tariff Number',                       'O', 'AN', 1, 7]
    ,'SL103' => ['Commodity Code',                      'X', 'AN', 1, 30]
    ,'SL104' => ['Scale',                               'X', 'AN', 1, 10]
    ,'SL106' => ['Service Level Code',                  'O', 'ID', 2, 2]
    ,'SL107' => ['Shipment Method of Payment',          'O', 'ID', 2, 2]
    ,'SL108' => ['Data Source Code',                    'O', 'ID', 2, 2]
    ,'SL109' => ['International/Intra-U.S. Code',       'O', 'ID', 1, 1]
    ,'L104'  => ['Charge',                              'X', 'N2', 1, 12]
    ,'L108'  => ['Special Charge Code',                 'O', 'ID', 3, 3]
    ,'L109'  => ['Rate Class Code',                     'O', 'ID', 1, 3]
    ,'L112'  => ['Special Charge Description',          'O', 'AN', 2, 25]
    ,'L114'  => ['Declared Value',                      'X', 'N2', 2, 12]
    ,'L115'  => ['Rate/Value Qualifier',                'X', 'ID', 2, 2]
    ,'L119'  => ['Percent',                             'O', 'R', 1, 10]
    ,'L120'  => ['Currency Code',                       'O', 'ID', 3, 3]
    ,'L121'  => ['Amount',                              'O', 'N2', 1, 15]
    ,'L305'  => ['Charge',                              'O', 'N2', 1, 12]
    ,'L308'  => ['Special Charge or Allowance Code',    'O', 'ID', 3, 3]
    ,'SE01'  => ['Number of Included Segments',         'M', 'N0', 1, 10]
    ,'SE02'  => ['Transaction Set Control Number',      'M', 'AN', 4, 9]
    ,'GE01'  => ['Number of Transaction Sets Included', 'M', 'NO', 1, 6]
    ,'GE02'  => ['Group Control Number',                'M', 'NO', 1, 9]
    ,'IEA01' => ['Number of Included functional Group', 'M', 'NO', 1, 5]
    ,'IEA02' => ['Interchange Control Number',          'M', 'NO', 9, 9]

   #
   # This is Catalog 175 Specific
   #
    ,'BGN01'  => ['Transaction Set Purpose Code',        'M', 'ID', 2, 2]
    ,'BGN02'  => ['Reference Number',                    'M', 'AN', 1, 30]
    ,'BGN03'  => ['Date',                                'M', 'DT', 6, 6]
    ,'CDS01'  => ['Case Type Code',                      'M', 'ID', 1, 2]
    ,'CDS02'  => ['Court Type Code',                     'M', 'ID', 1, 2]
    ,'CDS03'  => ['Reference Number Qualifier',          'O', 'ID', 2, 2]
    ,'CDS04'  => ['Reference Number',                    'M', 'AN', 1, 30]
    ,'CDS05'  => ['Description',                         'O', 'AN', 1, 80]
    ,'CDS06'  => ['Identification Code Qualifier',       'M', 'ID', 1, 2]
    ,'CDS07'  => ['Identification Code',                 'M', 'ID', 2, 20]
    ,'CDS08'  => ['Identification Code Qualifier',       'M', 'ID', 1, 2]
    ,'CDS09'  => ['Identification Code',                 'M', 'ID', 2, 20]
    ,'LS01'   => ['Loop Identifier Code',                'M', 'ID', 1, 4]
    ,'CED01'  => ['Court Event Type Code',               'M', 'ID', 1, 3]
    ,'CED02'  => ['Action Code',                         'O', 'ID', 1, 2]
    ,'CED03'  => ['Notice Type Code',                    'O', 'ID', 1, 3]
    ,'CED04'  => ['Case Type Code',                      'O', 'ID', 1, 2]
    ,'DTM01'  => ['Date/Time Qualifier',                 'M', 'ID', 3, 3]
    ,'DTM02'  => ['Date',                                'M', 'DT', 6, 6]
    ,'DTM03'  => ['Time',                                'O', 'TM', 4, 6]
    ,'CDS01'  => ['Case Type Code',                      'M', 'ID', 1, 2]
    ,'CDS02'  => ['Court Type Code',                     'M', 'ID', 1, 2]
    ,'CDS03'  => ['Reference Number Qualifier',          'O', 'ID', 2, 2]
    ,'CDS04'  => ['Reference Number',                    'M', 'AN', 1, 30]
    ,'CDS05'  => ['Description',                         'O', 'AN', 1, 80]
    ,'MSG01'  => ['Free-Form Message Text',              'M', 'AN', 1, 264]
    ,'LM01'   => ['Agency Qualifier Code',               'M', 'ID', 2, 2]
    ,'LQ01'   => ['Code List Qualifier Code',            'M', 'ID', 1, 3]
    ,'LQ02'   => ['Industry Code',                       'M', 'AN', 1, 20]
    ,'NM101'  => ['Entity Identifier Code',              'M', 'ID', 2, 2]
    ,'NM102'  => ['Entity Type Qualifier',               'M', 'ID', 1, 1]
    ,'NM103'  => ['Last Name or Organization Name',      'O', 'AN', 1, 35]
    ,'NM104'  => ['First Name',                          'O', 'AN', 1, 25]
    ,'NM105'  => ['Middle Name',          ,              'O', 'AN', 1, 25]
    ,'NM106'  => ['Name Prefix',                         'O', 'AN', 1, 10]
    ,'NM107'  => ['Name Suffix',                         'O', 'AN', 1, 10]
    ,'NM108'  => ['Identification Code Qualifier',       'O', 'ID', 1, 2]
    ,'NM109'  => ['Identification Code',                 'C', 'AN', 1, 20]
    ,'NM110'  => ['Entity Relationship Code',            'C', 'ID', 2, 2]
    ,'NM111'  => ['Entity Identifier Code',              'O', 'ID', 2, 2]
    ,'N201'   => ['Name',                                'M', 'AN', 1, 35]
    ,'N202'   => ['Name',                                'O', 'AN', 1, 35]
    ,'N301'   => ['Address Information',                 'M', 'AN', 1, 35]
    ,'N302'   => ['Address Information',                 'O', 'AN', 1, 35]
    ,'N401'   => ['City Name',                           'O', 'AN', 2, 30]
    ,'N402'   => ['State or Province Code',              'O', 'ID', 2, 2]
    ,'N403'   => ['Postal Code',                         'O', 'ID', 3, 11]
    ,'N404'   => ['Country Code',                        'O', 'ID', 2, 3]
    ,'REF01'  => ['Reference Number Qualifier',          'M', 'ID', 2, 35]
    ,'REF02'  => ['Reference Number',                    'M', 'AN', 1, 30]
    ,'PER01'  => ['Contact Function Code',               'M', 'ID', 2, 2]
    ,'PER02'  => ['Name',                                'NU', 'AN', 1, 35]
    ,'PER03'  => ['Communications Number Qualifier',     'M', 'ID', 2, 2]
    ,'PER04'  => ['Communications Number',               'M', 'ID', 1, 80]
    ,'LE01'   => ['Loop Identifier Code',                'M', 'ID', 1, 4]
    ,'SE01'   => ['Transaction Set Identifier Code',     'M', 'N0', 1, 10]
    ,'SE02'   => ['Transaction Set Control Number',      'M', 'AN', 4, 9]
};

=back

=head1 AUTHORS

Brian Kaney <F<brian@vermonster.com>>, Jay Powers <F<jpowers@cpan.org>>

L<http://www.vermonster.com/>

Copyright (c) 2004 Vermonster LLC.  All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2 of the
License, or (at your option) any later version.

Basically you may use this library in commercial or non-commercial applications.
However, If you make any changes directly to any files in this library, you are
obligated to submit your modifications back to the authors and/or copyright holder.
If the modification is suitable, it will be added to the library and released to
the back to public.  This way we can all benefit from each other's hard work!

If you have any questions, comments or suggestions please contact the author.

=head1 SEE ALSO

L<XML::ASCX12> and L<XML::ASCX12::Catalogs>

=cut
1;
