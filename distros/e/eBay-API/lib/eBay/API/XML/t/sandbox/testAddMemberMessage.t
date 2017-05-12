#! /usr/bin/perl -w
use strict;
use warnings;
use Test::More qw (no_plan);
use Data::Dumper;
use HTTP::Response;
use HTTP::Status;
use Encode;
use LWP::Debug qw(+);

use t::FileUtil;

print "Test AddMemberMessage call.\n";
use_ok('eBay::API::XML::Call::AddMemberMessage');
use_ok('eBay::API::XML::DataType::MemberMessageType');

use eBay::API::XML::DataType::Enum::MessageTypeCodeType;
use eBay::API::XML::DataType::Enum::AckCodeType;
use eBay::API::XML::DataType::Enum::QuestionTypeCodeType;

main();

sub main {

    #test_AskSellerQuestion();
    #test_ContactEbayMember();
    #test_ChineseMessage_works();
    test_ChineseMessage_maybe_works();
}

sub test_AskSellerQuestion {

       # 1. instantiate the call
    my $pCall = eBay::API::XML::Call::AddMemberMessage->new();

       # 2. set Item Id
    my $sItemId = 4015192117;

    my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
    $pItemIDType->setValue( $sItemId );
    $pCall->setItemID( $pItemIDType );

       # 3. set message

          # 3.1 instantiate MemberMessageType
    my $pMemberMessage = eBay::API::XML::DataType::MemberMessageType->new();

          # 3.2 set MessageType
    $pMemberMessage->setMessageType(
         eBay::API::XML::DataType::Enum::MessageTypeCodeType::AskSellerQuestion
                                    );
                    
          # 3.3 set Message Text
    my $sMessageText = 'decent question for a seller';
    $pMemberMessage->setBody ( $sMessageText );

          # 3.4 set MemberMessage.RecipientID
    my $raRecipientID = [ 'sol_cn'];
    $pMemberMessage->setRecipientID( $raRecipientID );

          # 3.5 set question type
    $pMemberMessage->setQuestionType( 
                     eBay::API::XML::DataType::Enum::QuestionTypeCodeType::General
                                       );
          # 1.6 do not hide senders email address
    $pMemberMessage->setHideSendersEmailAddress( 0 );

    $pCall->setMemberMessage( $pMemberMessage );



       # 4. execute the call
    $pCall->execute();

       # 5. verify the test
    my $sAck = $pCall->getAck();
    is( $sAck, eBay::API::XML::DataType::Enum::AckCodeType::Success, $sMessageText);

    my $pErrors = $pCall->getErrorsAndWarnings();
    print Dumper ( $pErrors );
    #my $hasUserNotFoundError = $pCall->hasError(904);    
    #ok ( $hasUserNotFoundError, 'User not found - which was expected!');
    print Dumper ( $pCall->getResponseRawXml() );

}

sub test_ContactEbayMember {

       # 1. instantiate the call
    my $pCall = eBay::API::XML::Call::AddMemberMessage->new();

       # 3. set message

          # 3.1 instantiate MemberMessageType
    my $pMemberMessage = eBay::API::XML::DataType::MemberMessageType->new();

          # 3.2 set MessageType
    $pMemberMessage->setMessageType(
         eBay::API::XML::DataType::Enum::MessageTypeCodeType::ContactEbayMember
                                    );
                    
          # 3.3 set Message Text
    my $sMessageText = 'decent question for a memeber';
    $pMemberMessage->setBody ( $sMessageText );

    $pMemberMessage->setSubject ( 'decent subject' );

          # 3.4 set MemberMessage.RecipientID
    my $raRecipientID = [ 'sol_cn'];
    $pMemberMessage->setRecipientID( $raRecipientID );

          # 3.5 this one should not be set 
          #  for messageType ContactEbayMember
    my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
    $pItemIDType->setValue( 0 );
    $pCall->setItemID( $pItemIDType );

    $pCall->setMemberMessage( $pMemberMessage );


       # 4. execute the call
    $pCall->execute();

       # 5. verify the test
    my $sAck = $pCall->getAck();
    my $isOk = ($sAck eq eBay::API::XML::DataType::Enum::AckCodeType::Success);
    ok( $isOk, $sMessageText);

    if ( ! $isOk) {
        my $pErrors = $pCall->getErrorsAndWarnings();
        print Dumper ( $pErrors );
        #print Dumper ( $pCall->getResponseRawXml() );
    }
}

sub test_ChineseMessage_works {

    my $in_newCallFileName = 'AddMemberMessage_chinese.xml';
    my $newGetItemResponseXml = 
          t::FileUtil::readFileIntoString(
		                                    $in_newCallFileName );

    #Encode::_utf8_on($newGetItemResponseXml);
     # read response from a file - rather then from a real call.
    my $pCall = eBay::API::XML::Call::AddMemberMessage->new();
    $pCall->setRequestRawXml( $newGetItemResponseXml);
    $pCall->execute();

    print Dumper($pCall);


       # 5. verify the test
    my $sAck = $pCall->getAck() || 'failure';

    my $isOk = ($sAck eq eBay::API::XML::DataType::Enum::AckCodeType::Success);
    ok( $isOk, "test message with chines characters");

    if ( ! $isOk) {
        my $pErrors = $pCall->getErrorsAndWarnings();
        #print Dumper ( $pErrors );
        #print "rowresponse=|" . Dumper ( $pCall->getResponseRawXml() );
    }
}

sub test_ChineseMessage_maybe_works {

       # 1. instantiate the call
    my $pCall = eBay::API::XML::Call::AddMemberMessage->new();

       # 3. set message

          # 3.1 instantiate MemberMessageType
    my $pMemberMessage = eBay::API::XML::DataType::MemberMessageType->new();

          # 3.2 set MessageType
    $pMemberMessage->setMessageType(
         eBay::API::XML::DataType::Enum::MessageTypeCodeType::ContactEbayMember
                                    );
                    
          # 3.3 set Message Text
    my $in_newCallFileName = 'chinese_utf8.txt';
    my $sMessageText = 
          t::FileUtil::readFileIntoString( $in_newCallFileName );
    #$sMessageText = t::FileUtil::readUtf8FileIntoString( $in_newCallFileName );

    $pMemberMessage->setBody ( $sMessageText );

    $pMemberMessage->setSubject ( 'decent subject' );

          # 3.4 set MemberMessage.RecipientID
    my $raRecipientID = [ 'sol_cn'];
    $pMemberMessage->setRecipientID( $raRecipientID );

          # 3.5 this one should not be set 
          #  for messageType ContactEbayMember
    my $pItemIDType = eBay::API::XML::DataType::ItemIDType->new();
    $pItemIDType->setValue( 0 );
    $pCall->setItemID( $pItemIDType );

    $pCall->setMemberMessage( $pMemberMessage );


       # 4. execute the call
    $pCall->setUserName('sgtest3');
    $pCall->setUserPassword('Password123');
    $pCall->execute();

       # 5. verify the test
    my $sAck = $pCall->getAck();
    my $isOk = ($sAck eq eBay::API::XML::DataType::Enum::AckCodeType::Success);
    ok( $isOk, $sMessageText);

    if ( 1 || ! $isOk) {
        my $pErrors = $pCall->getErrorsAndWarnings();
        print Dumper ( $pErrors );
        print Dumper ( $pCall->getRequestRawXml() );
        print Dumper ( $pCall->getResponseRawXml() );
    }
}
