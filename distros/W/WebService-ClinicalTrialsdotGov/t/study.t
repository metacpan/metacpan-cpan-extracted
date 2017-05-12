

use strict;
use warnings;

use Test::More tests => 2;

use_ok('WebService::ClinicalTrialsdotGov::Study');

my $rh_study = {
          'oversight_info' => {
                              'has_dmc' => 'Yes',
                              'authority' => [
                                             'United States: Institutional Review Board',
                                             'United States: Food and Drug Administration',
                                             'United States: Department of Defence',
                                             'United States: National Cancer Institute'
                                           ]
                            },
          'detailed_description' => {
                                    'textblock' => '
      TUMOR COLLECTION: Tumor cells will be collected from the participant to make the study
      vaccine.  Based on the location of the tumor, a decision will be made as to the best
      approach to obtain these cells.

      DENDRITIC CELL COLLECTION: Participants will undergo a procedure known as leukapheresis to
      obtain their dendritic cells (this procedure may be done before or after the tumor cells
      have been obtained).  This procedure takes about 2-4 hours.  If not enough cells are
      collected, the participant may be asked to return for an additional leukapheresis procedure.
       If sufficient number of cells are obtained, tumor cells and dendritic cells will then be
      fused (combined together to make one larger cell) together in the laboratory and divided
      into the appropriate dose for administration.

      TREATMENT: Treatment will consist of an injection of tumor cells fused with dendritic cells
      under the skin every 3 weeks for a total of 9 weeks.  The dose that the participant receives
      will depend on the total number of fusion cells that are made.

      STUDY COHORTS: The first group of three participants will receive the DC/Tumor Fusion study
      vaccine alone.  The next group of 3 participants will receive the DC/Tumor Fusion study
      vaccine with a low dose of Il-12.  If there are no significant side effects the following
      groups of subjects will be treated with the DC/Tumor Fusion study vaccine and a higher dose
      of Il-12.

      PATIENT MONITORING: Participants will be carefully monitored during the study period and the
      following tests and procedures will be performed: physical exams (weekly); blood collections
      (weekly); DC/Tumor Fusion study vaccine Journal (for the participant to record any side
      effects or other medications they may be taking); tumor cells skin test (before the first
      vaccine and one month following the last vaccine); skin biopsy at the site of the
      vaccination administration, accessible tumor site, or if there is a local reaction site.
    '
                                  },
          'study_type' => 'Interventional',
          'primary_completion_date' => {
                                       'content' => 'December 2012',
                                       'type' => 'Anticipated'
                                     },
          'primary_outcome' => {
                               'time_frame' => '3 years',
                               'measure' => 'To assess the toxicity associated with vaccination of breast cancer patients with dendritic cell(DC)/tumor fusions and rhIl-12.',
                               'safety_issue' => 'Yes'
                             },
          'intervention' => [
                            {
                              'other_name' => 'DC/tumor cell fusion vaccine',
                              'intervention_type' => 'Biological',
                              'arm_group_label' => [
                                                   'Group 1',
                                                   'Group 2',
                                                   'Group 3'
                                                 ],
                              'description' => 'Vaccine is derived from the participants dendritic cells and tumor cells',
                              'intervention_name' => 'Dendritic Cell/Tumor Fusion Vaccine'
                            },
                            {
                              'other_name' => [
                                              'IL-12',
                                              'rhIL-12'
                                            ],
                              'intervention_type' => 'Drug',
                              'arm_group_label' => 'Group 2',
                              'description' => 'Given subcutaneously at dose of 30ng/kg',
                              'intervention_name' => 'Interleukin-12'
                            },
                            {
                              'other_name' => [
                                              'IL-12',
                                              'rhIL-12'
                                            ],
                              'intervention_type' => 'Drug',
                              'arm_group_label' => 'Group 3',
                              'description' => 'Given subcutaneously at dose of 100ng/kg',
                              'intervention_name' => 'Interleukin-12'
                            }
                          ],
          'intervention_browse' => {
                                   'mesh_term' => 'Interleukin-12'
                                 },
          'has_expanded_access' => 'No',
          'arm_group' => [
                         {
                           'arm_group_type' => 'Experimental',
                           'description' => 'Dendritic Cell/Tumor Fusion Vaccine Only',
                           'arm_group_label' => 'Group 1'
                         },
                         {
                           'arm_group_type' => 'Experimental',
                           'description' => 'Dendritic Cell/tumor fusion vaccine and low dose IL-12',
                           'arm_group_label' => 'Group 2'
                         },
                         {
                           'arm_group_type' => 'Experimental',
                           'description' => 'Dendritic Cell/tumor fusion vaccine and higher dose IL-12',
                           'arm_group_label' => 'Group 3'
                         }
                       ],
          'number_of_arms' => '3',
          'overall_official' => {
                                'affiliation' => 'Beth Israel Deaconess Medical Center',
                                'role' => 'Principal Investigator',
                                'last_name' => 'David Avigan, MD'
                              },
          'brief_title' => 'Vaccination of Patients With Breast Cancer With Dendritic Cell/Tumor Fusions and IL-12',
          'study_design' => 'Allocation:  Non-Randomized, Endpoint Classification:  Safety Study, Intervention Model:  Single Group Assignment, Masking:  Open Label, Primary Purpose:  Treatment',
          'location' => {
                        'status' => 'Recruiting',
                        'contact' => {
                                     'email' => 'davigan@bidmc.harvard.edu',
                                     'phone' => '617-667-9920',
                                     'last_name' => 'David Avigan, MD'
                                   },
                        'facility' => {
                                      'name' => 'Beth Israel Deaconess Medical Center',
                                      'address' => {
                                                   'country' => 'United States',
                                                   'zip' => '02215',
                                                   'city' => 'Boston',
                                                   'state' => 'Massachusetts'
                                                 }
                                    }
                      },
          'id_info' => {
                         'secondary_id' => [
                                           'NCI 6040',
                                           'U01CA062490',
                                           'P30CA006516'
                                         ],
                         'nct_id' => 'NCT00622401',
                         'nct_alias' => 'NCT00731406',
                         'org_study_id' => '03-221'
                       },
          'firstreceived_date' => 'February 14, 2008',
          'overall_contact' => {
                               'email' => 'davigan@bidmc.harvard.edu',
                               'phone' => '617-667-9920',
                               'last_name' => 'David Avigan, MD'
                             },
          'overall_status' => 'Recruiting',
          'verification_date' => 'April 2010',
          'source' => 'Dana-Farber Cancer Institute',
          'keyword' => [
                       'stage IV breast cancer',
                       'dendritic cell vaccine',
                       'tumor fusion vaccine',
                       'IL-12'
                     ],
          'sponsors' => {
                        'lead_sponsor' => {
                                          'agency_class' => 'Other',
                                          'agency' => 'Dana-Farber Cancer Institute'
                                        },
                        'collaborator' => [
                                          {
                                            'agency_class' => 'Other',
                                            'agency' => 'Brigham and Women\'s Hospital'
                                          },
                                          {
                                            'agency_class' => 'Other',
                                            'agency' => 'Harvard University'
                                          },
                                          {
                                            'agency_class' => 'U.S. Fed',
                                            'agency' => 'Department of Defense'
                                          },
                                          {
                                            'agency_class' => 'NIH',
                                            'agency' => 'National Cancer Institute (NCI)'
                                          }
                                        ]
                      },
          'official_title' => 'Vaccination of Patients With Breast Cancer With Dendritic Cell/Tumor Fusions and IL-12',
          'enrollment' => {
                          'content' => '41',
                          'type' => 'Anticipated'
                        },
          'condition_browse' => {
                                'mesh_term' => 'Breast Neoplasms'
                              },
          'brief_summary' => {
                             'textblock' => '
      The purpose of this study is to test the safety of an investigational Dendritic Cell/Tumor
      Fusion vaccine given with IL-12 for patients with breast cancer.

      RATIONALE: Vaccines made from a person\'s tumor cells and white blood cells may help the body
      build an effective immune response to kill tumor cells. Interleukin-12 may stimulate the
      white blood cells to kill tumor cells. Giving vaccine therapy together with interleukin-12
      may kill more tumor cells.

      PURPOSE: This phase I/II trial is studying the side effects and best dose of interleukin-12
      when given together with vaccine therapy and to see how well they work in treating women
      with stage IV breast cancer.
    '
                           },
          'location_countries' => {
                                  'country' => 'United States'
                                },
          'is_section_801' => 'Yes',
          'secondary_outcome' => [
                                 {
                                   'time_frame' => '3 years',
                                   'measure' => 'To determine if cellular and humoral immunity is induced by serial vaccination with DC/tumor fusion cells and rhIL-12.',
                                   'safety_issue' => 'No'
                                 },
                                 {
                                   'time_frame' => '3 years',
                                   'measure' => 'To determine if vaccination with DC/tumor fusions and rhIL-12 results in clinically measurable disease responses.',
                                   'safety_issue' => 'No'
                                 }
                               ],
          'responsible_party' => {
                                 'name_title' => 'David Avigan, MD',
                                 'organization' => 'Beth Israel Deaconess Medical Center'
                               },
          'eligibility' => {
                           'healthy_volunteers' => 'No',
                           'minimum_age' => '18 Years',
                           'criteria' => {
                                         'textblock' => '
        Inclusion Criteria:

          -  Stage IV breast cancer with measurable disease and accessible tumor

          -  ECOG Performance Status 0-2 with greater than six week life expectancy

          -  18 years of age or older

          -  Laboratory values as outlined in the protocol

          -  Received a maximum of 2 prior chemotherapy regimens for metastatic disease and may
             have had any number or prior hormonal treatments

        Exclusion Criteria:

          -  Patients must not have received other immunotherapy treatment in the three months
             prior to the initial vaccination

          -  Patients may not be on herceptin therapy during this protocol and may not have
             received it for four weeks prior to initial vaccination

          -  Patients must not have received chemotherapy or hormonal treatment for four weeks
             prior to the initial vaccination

          -  Clinical evidence of CNS disease

          -  Clinically significant autoimmune disease

          -  Patients who are HIV+

          -  Serious intercurrent illness such as infection requiring IV antibiotics, or
             significant cardiac disease characterized by significant arrhythmia, ischemic
             coronary disease or congestive heart failure

          -  Pregnant of lactating women will be excluded, all premenopausal women must undergo
             pregnancy testing'
                                       },
                           'maximum_age' => 'N/A',
                           'gender' => 'Female'
                         },
          'phase' => 'Phase 1/Phase 2',
          'lastchanged_date' => 'April 7, 2010',
          'start_date' => 'December 2009',
          'is_fda_regulated' => 'Yes',
          'required_header' => {
                               'download_date' => 'Information obtained from ClinicalTrials.gov on November 04, 2010',
                               'url' => 'http://clinicaltrials.gov/show/NCT00622401',
                               'link_text' => 'Link to the current ClinicalTrials.gov record.'
                             },
          'overall_contact_backup' => {
                                      'email' => 'yyuan1@bidmc.harvard.edu',
                                      'phone' => '617-667-1998',
                                      'last_name' => 'Emily Yuan'
                                    },
          'condition' => 'Breast Cancer'
        };

my $Study =
  WebService::ClinicalTrialsdotGov::Study->new( $rh_study );

isa_ok( $Study, 'WebService::ClinicalTrialsdotGov::Study' );
