use Test::More;
use strict;
use warnings;

BEGIN{use_ok('WWW::betfair::TypeCheck'); }
ok(my $tc = WWW::betfair::TypeCheck->new, 'new');

# Check parameter
ok($tc->checkParameter('username', 'sillymoos'), 'checkParameter - username');
ok($tc->checkParameter('password', 'itsasecret'), 'checkParameter - password');
ok($tc->checkParameter('int', -1), 'checkParameter - int');
ok($tc->checkParameter('decimal', 2.76), 'checkParameter - decimal');
ok($tc->checkParameter('date', '2013-12-01T05:30:56Z'), 'checkParameter - date');
ok(!$tc->checkParameter('username', 'silly$moos'), 'checkParameter - username');
ok(!$tc->checkParameter('password', 'itsa'), 'checkParameter - password');
ok(!$tc->checkParameter('int', '2.1'), 'checkParameter - int');
ok(!$tc->checkParameter('decimal', '900.Y'), 'checkParameter - decimal');
ok(!$tc->checkParameter('date', '2013-12-01T05:30:5'), 'checkParameter - date');

# Enums
ok($tc->checkAccountStatementEnum('RESULT_ERR'), 'checkAccountStatementEnum');
ok(!$tc->checkAccountStatementEnum('OKI'), 'checkAccountStatementEnum');
ok($tc->checkAccountStatementIncludeEnum('DEPOSITS_WITHDRAWALS'), 'checkAccountStatementIncludeEnum');
ok(!$tc->checkAccountStatementIncludeEnum('EXCHNGE'), 'checkAccountStatementIncludeEnum');
ok($tc->checkAccountStatusEnum('Z'), 'checkAccountStatusEnum');
ok(!$tc->checkAccountStatusEnum('B'), 'checkAccountStatusEnum');
ok($tc->checkAccountTypeEnum('TRADING'), 'checkAccountTypeEnum');
ok(!$tc->checkAccountTypeEnum, 'checkAccountTypeEnum');
ok($tc->checkBetCategoryTypeEnum('NONE'), 'checkBetCategoryEnum');
ok(!$tc->checkBetCategoryTypeEnum('P'), 'checkBetCategoryEnum');
ok($tc->checkBetPersistenceTypeEnum('IP'), 'checkBetPersistenceTypeEnum');
ok(!$tc->checkBetPersistenceTypeEnum('PP'), 'checkBetPersistenceTypeEnum');
ok($tc->checkBetsOrderByEnum('BET_ID'), 'checkBetsOrderByEnum');
ok(!$tc->checkBetsOrderByEnum('DATE'), 'checkBetsOrderByEnum');
ok($tc->checkBetStatusEnum('MU'), 'checkBetStatusEnum');
ok(!$tc->checkBetStatusEnum('C C'), 'checkBetStatusEnum');
ok($tc->checkBetTypeEnum('B'), 'checkBetTypeEnum');
ok($tc->checkBetTypeEnum('L'), 'checkBetTypeEnum');
ok(!$tc->checkBetTypeEnum, 'checkBetTypeEnum');
ok($tc->checkBillingPeriodEnum('ANNUALLY'), 'checkBillingPeriodEnum');
ok(!$tc->checkBillingPeriodEnum('DAILY'), 'checkBillingPeriodEnum');
ok($tc->checkCardTypeEnum('VISA'), 'checkCardTypeEnum');
ok(!$tc->checkCardTypeEnum('MASTERCAD'), 'checkCardTypeEnum');
ok($tc->checkGamcareLimitFreqEnum('WEEKLY'), 'checkGamcareLimitFreqEnum');
ok(!$tc->checkGamcareLimitFreqEnum('FORTNIGHTLY'), 'checkGamcareLimitFreqEnum');
ok($tc->checkMarketStatusEnum('SUSPENDED'), 'checkMarketStatusEnum');
ok($tc->checkMarketStatusEnum('ACTIVE'), 'checkMarketStatusEnum');
ok($tc->checkMarketTypeEnum('O'), 'checkMarketTypeEnum');
ok(!$tc->checkMarketTypeEnum, 'checkMarketTypeEnum');
ok($tc->checkArrayMarketTypeEnum(['O', 'NOT_APPLICABLE','L', 'A', 'R']), 'checkArrayMarketTypeEnum');
ok(!$tc->checkArrayMarketTypeEnum([]), 'checkMarketTypeEnum null array');
ok(!$tc->checkArrayMarketTypeEnum(['G']), 'checkMarketTypeEnum - G');
ok($tc->checkMarketTypeVariantEnum('D'), 'checkMarketTypeVariantEnum');
ok(!$tc->checkMarketTypeVariantEnum('AFL'), 'checkMarketTypeVariantEnum');
ok($tc->checkPaymentCardStatusEnum('UNLOCKED'), 'checkPaymentCardStatusEnum');
ok(!$tc->checkPaymentCardStatusEnum('ACTV'), 'checkPaymentCardStatusEnum');
ok($tc->checkRegionEnum('NORD'), 'checkRegionEnum');
ok(!$tc->checkRegionEnum, 'checkRegionEnum');
ok($tc->checkSecurityQuestion1Enum('SQ1A'), 'checkSecurityQuestion1Enum');
ok(!$tc->checkSecurityQuestion1Enum('SQ1F'), 'checkSecurityQuestion1Enum');
ok($tc->checkSecurityQuestion2Enum('SQ2S'), 'checkSecurityQuestion2Enum');
ok(!$tc->checkSecurityQuestion2Enum('SQ2F'), 'checkSecurityQuestion2Enum');
ok($tc->checkServiceEnum('GET_BET'), 'checkServiceEnum');
ok(!$tc->checkServiceEnum('LAOD_BET_HISTORY'), 'checkServiceEnum');
ok($tc->checkSortOrderEnum('ASC'), 'checkSortOrderEnum');
ok($tc->checkSortOrderEnum('DESC'), 'checkSortOrderEnum');
ok($tc->checkSubscriptionStatusEnum('INACTIVE'), 'checkSubscriptionStatusEnum');
ok(!$tc->checkSubscriptionStatusEnum('SUSPEND'), 'checkSubscriptionStatusEnum');
ok($tc->checkTitleEnum('Miss'), 'checkTitleEnum');
ok(!$tc->checkTitleEnum, 'checkTitleEnum');
ok(!$tc->checkValidationErrorsEnum(2), 'checkValidationErrorsEnum');
ok($tc->checkValidationErrorsEnum('INVALID_ANSWER2'), 'checkValidationErrorsEnum');
ok($tc->checkValidationErrorsEnum('INVALID_CURRENCY'), 'checkValidationErrorsEnum');
ok($tc->checkValidationErrorsEnum('INVALID_SUPERPARTNER_ID'), 'checkValidationErrorsEnum');
ok(!$tc->checkValidationErrorsEnum('VALID*'), 'checkValidationErrorsEnum');

# string
ok($tc->checkString(0), 'checkString 0');
ok($tc->checkString('Sillymoose'), 'checkString Sillymoose');
ok(!$tc->checkString(''), 'checkString zero length');
ok(!$tc->checkString, 'checkString null');

# string9
ok($tc->checkString9(0), 'checkString9 0');
ok($tc->checkString9('Sillymoos'), 'checkString9 Sillymoos');
ok(!$tc->checkString9('Sillymoose'), 'checkString9 Sillymoose');
ok(!$tc->checkString9(''), 'checkString9 zero length');
ok(!$tc->checkString9, 'checkString9 null');

# cardDate
ok($tc->checkCardDate(1234), 'checkCardDate 1234');
ok($tc->checkCardDate('0123'), 'checkCardDate "0123"');
ok(!$tc->checkCardDate('1.14'), 'checkCardDate 1.14');
ok(!$tc->checkCardDate('90578'), 'checkCardDate 90578');
ok(!$tc->checkCardDate, 'checkCardDate null');
ok(!$tc->checkCardDate('1b'), 'checkCardDate string');
ok(!$tc->checkCardDate('1'), 'checkCardDate string');

# decimal
ok($tc->checkDecimal(0), 'checkDecimal 0');
ok($tc->checkDecimal('0.7'), 'checkDecimal 0.7');
ok($tc->checkDecimal('-0.01'), 'checkDecimal minus 0.01');
ok($tc->checkDecimal('-50'), 'checkDecimal minus 50');
ok($tc->checkDecimal('1.14'), 'checkDecimal 1.14');
ok($tc->checkDecimal('90578'), 'checkDecimal 90578');
ok(!$tc->checkDecimal, 'checkDecimal null');
ok($tc->checkDecimal('015.2'), 'checkDecimal leading zero 015.2');
ok(!$tc->checkDecimal('1b'), 'checkDecimal string');

# int
ok($tc->checkInt(0), 'checkInt 0');
ok($tc->checkInt('7'), 'checkInt 7');
ok($tc->checkInt('-0'), 'checkInt minus 0');
ok($tc->checkInt('-50'), 'checkInt minus 50');
ok($tc->checkInt('123'), 'checkInt 123');
ok($tc->checkInt('90578'), 'checkInt 90578');
ok(!$tc->checkInt, 'checkInt null');
ok(!$tc->checkInt(1.1), 'checkInt decimal');
ok(!$tc->checkInt('A 1 hey'), 'checkInt string');
ok($tc->checkArrayInt([1, -3, 4, 193000]), 'checkArrayInt');
ok(!$tc->checkArrayInt([]), 'checkArrayInt null');
ok(!$tc->checkArrayInt(['a', 'ab', 1]), 'checkArrayInt string');

# datetime
ok($tc->checkDate('2013-01-18T12:30:58Z'), 'checkDate standard');
ok($tc->checkDate('2013-01-18T12:30:58Z'), 'checkDate Z');
ok($tc->checkDate('2013-01-18T12:30:58-05:00'), 'checkDate -05:00');
ok($tc->checkDate('2013-01-18T12:30:58+06:00'), 'checkDate +06:00');
ok(!$tc->checkDate('201-01-18T12:30:58'), 'checkDate 3 digit year');
ok(!$tc->checkDate('13-01-18T12:30:58'), 'checkDate 2 digit year');
ok(!$tc->checkDate('2013-01-18'), 'checkDate - date only');
ok(!$tc->checkDate, 'checkDate null');
    
# credentials
ok(!$tc->checkUsername('maeu89D'),'checkUsername 7');
ok($tc->checkUsername('tEst12hb'),'checkUsername 8');
ok($tc->checkUsername('umaeu89D123849506lIp'),'checkUsername 20');
ok(!$tc->checkUsername('umaeu89D123849506lIpa'),'checkUsername 21');
ok(!$tc->checkUsername('umae~89D123849506lIpa'),'checkUsername 21 illegal char');
ok(!$tc->checkUsername('umaeu89i*49506lIpa'),'checkUsername illegal char');
ok(!$tc->checkUsername,'checkUsername null');
ok(!$tc->checkPassword('maeu89D'),'checkPassword 7');
ok($tc->checkPassword('tEst2hba'),'checkPassword 8');
ok($tc->checkPassword('umaeu89D{23849506lIp'),'checkPassword 20');
ok(!$tc->checkPassword('umaeu89D123849506lIpa'),'checkPassword 21');
ok(!$tc->checkPassword, 'checkPassword null');
done_testing();
