#!perl -T
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use Test::More tests => 15;


use Yahoo::Marketing;

eval { my $ysm_ws = Yahoo::Marketing->new; };
like( $@, qr/^cannot instantiate Yahoo::Marketing directly /, 
             'cannot instantiate Yahoo::Marketing directly'
);


use Yahoo::Marketing::AccountService;
use Yahoo::Marketing::AdGroupService;
use Yahoo::Marketing::AdService;
use Yahoo::Marketing::BasicReportService;
use Yahoo::Marketing::BidInformationService;
use Yahoo::Marketing::BudgetingService;
use Yahoo::Marketing::CampaignService;
use Yahoo::Marketing::ExcludedWordsService;
use Yahoo::Marketing::ForecastService;
use Yahoo::Marketing::KeywordService;
use Yahoo::Marketing::KeywordResearchService;
use Yahoo::Marketing::LocationService;
use Yahoo::Marketing::AccountService;
use Yahoo::Marketing::UserManagementService;


ok( Yahoo::Marketing::AccountService->new );
ok( Yahoo::Marketing::AdGroupService->new );
ok( Yahoo::Marketing::AdService->new );
ok( Yahoo::Marketing::BasicReportService->new );
ok( Yahoo::Marketing::BidInformationService->new );
ok( Yahoo::Marketing::BudgetingService->new );
ok( Yahoo::Marketing::CampaignService->new );
ok( Yahoo::Marketing::ExcludedWordsService->new );
ok( Yahoo::Marketing::ForecastService->new );
ok( Yahoo::Marketing::KeywordService->new );
ok( Yahoo::Marketing::KeywordResearchService->new );
ok( Yahoo::Marketing::LocationService->new );
ok( Yahoo::Marketing::AccountService->new );
ok( Yahoo::Marketing::UserManagementService->new );

