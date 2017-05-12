# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use XML::DTDParser;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $DTD = ParseDTD <<'*END*';
<!-- this is an ordinary comment > < -->
<!ELEMENT JOBPOSTINGDOCUMENT (JOB+)>

<!ELEMENT JOB (TITLE,BILLING,FLD,TEXT)>
<!ATTLIST JOB id CDATA #REQUIRED action CDATA #REQUIRED>
<!--#info element='JOB' repeat_set=action repeat_list='add,modify,delete'-->
<!--#info element='JOB' attribute='id' map_to='JDTID_UNIQUE_NUMBER'-->

<!ELEMENT TITLE (#PCDATA)>
<!--#info element='TITLE' map_to='JOB_TITLE'-->

<!ELEMENT BILLING (NAME,PHONE,OFFICE,FOO,FOO*)>
<!ATTLIST BILLING static CDATA #REQUIRED empty CDATA #REQUIRED>
<!--#info element='BILLING' attribute='static' set_to='some value'-->

<!ELEMENT NAME (#PCDATA)>
<!--#info element='NAME' map_to='BILLING_CONTACT_NAME'-->
<!ELEMENT PHONE (#PCDATA)>
<!--#info element='PHONE' map_to='BILLING_CONTACT_PHONE'-->
<!ELEMENT OFFICE (#PCDATA)>
<!--#info element='OFFICE' map_to='BILLING_CONTACT_OFFICE'-->
<!ELEMENT FOO (#PCDATA)>
<!--#info element='FOO' set_to='Bar'-->

<!ELEMENT FLD (#PCDATA)>
<!ELEMENT TEXT (#PCDATA)>

*END*
ok(1);

eval "use Data::Compare;";
if ($@) {
	skip("You don't have Data::Compare\n");
	exit;
}

my $GOOD_DTD = {
          'NAME' => {
                      'parent' => [
                                    'BILLING'
                                  ],
                      'childrenSTR' => '(#PCDATA)',
                      'map_to' => 'BILLING_CONTACT_NAME',
                      'content' => 1,
                      'option' => '!'
                    },
          'TEXT' => {
                      'parent' => [
                                    'JOB'
                                  ],
                      'childrenSTR' => '(#PCDATA)',
                      'content' => 1,
                      'option' => '!'
                    },
          'JOB' => {
                     'repeat_list' => 'add,modify,delete',
                     'childrenARR' => [
                                        'TITLE',
                                        'BILLING',
                                        'FLD',
                                        'TEXT'
                                      ],
                     'parent' => [
                                   'JOBPOSTINGDOCUMENT'
                                 ],
                     'childrenSTR' => '(TITLE,BILLING,FLD,TEXT)',
                     'option' => '+',
                     'children' => {
                                     'TEXT' => '!',
                                     'TITLE' => '!',
                                     'FLD' => '!',
                                     'BILLING' => '!'
                                   },
                     'childrenX' => {
                                     'TEXT' => '1',
                                     'TITLE' => '1',
                                     'FLD' => '1',
                                     'BILLING' => '1'
                                   },
                     'repeat_set' => 'action',
                     'attributes' => {
                                       'action' => [
                                                     'CDATA',
                                                     '#REQUIRED',
                                                     undef,
                                                     undef
                                                   ],
                                       'id' => [
                                                 'CDATA',
                                                 '#REQUIRED',
                                                 undef,
                                                 undef,
                                                 {
                                                   'map_to' => 'JDTID_UNIQUE_NUMBER'
                                                 }
                                               ]
                                     }
                   },
          'TITLE' => {
                       'parent' => [
                                     'JOB'
                                   ],
                       'childrenSTR' => '(#PCDATA)',
                       'map_to' => 'JOB_TITLE',
                       'content' => 1,
                       'option' => '!'
                     },
          'OFFICE' => {
                        'parent' => [
                                      'BILLING'
                                    ],
                        'childrenSTR' => '(#PCDATA)',
                        'map_to' => 'BILLING_CONTACT_OFFICE',
                        'content' => 1,
                        'option' => '!'
                      },
          'JOBPOSTINGDOCUMENT' => {
                                    'childrenARR' => [
                                                       'JOB'
                                                     ],
                                    'childrenSTR' => '(JOB+)',
                                    'children' => {
                                                    'JOB' => '+'
                                                  },
                                    'childrenX' => {
                                                    'JOB' => '1..'
                                                  }
                                  },
          'BILLING' => {
                         'childrenARR' => [
                                            'NAME',
                                            'PHONE',
                                            'OFFICE',
                                            'FOO',
                                            'FOO'
                                          ],
                         'parent' => [
                                       'JOB'
                                     ],
                         'childrenSTR' => '(NAME,PHONE,OFFICE,FOO,FOO*)',
                         'option' => '!',
                         'children' => {
                                         'NAME' => '!',
                                         'OFFICE' => '!',
                                         'FOO' => '+',
                                         'PHONE' => '!'
                                       },
                         'childrenX' => {
                                         'NAME' => '1',
                                         'OFFICE' => '1',
                                         'FOO' => '1..',
                                         'PHONE' => '1'
                                       },
                         'attributes' => {
                                           'empty' => [
                                                        'CDATA',
                                                        '#REQUIRED',
                                                        undef,
                                                        undef
                                                      ],
                                           'static' => [
                                                         'CDATA',
                                                         '#REQUIRED',
                                                         undef,
                                                         undef,
                                                         {
                                                           'set_to' => 'some value'
                                                         }
                                                       ]
                                         }
                       },
          'FOO' => {
                     'parent' => [
                                   'BILLING'
                                 ],
                     'childrenSTR' => '(#PCDATA)',
                     'content' => 1,
                     'option' => '+',
                     'set_to' => 'Bar'
                   },
          'FLD' => {
                     'parent' => [
                                   'JOB'
                                 ],
                     'childrenSTR' => '(#PCDATA)',
                     'content' => 1,
                     'option' => '!'
                   },
          'PHONE' => {
                       'parent' => [
                                     'BILLING'
                                   ],
                       'childrenSTR' => '(#PCDATA)',
                       'map_to' => 'BILLING_CONTACT_PHONE',
                       'content' => 1,
                       'option' => '!'
                     }
        };

ok(Compare($DTD, $GOOD_DTD));

#use Data::Dumper;
#print Dumper($DTD);
