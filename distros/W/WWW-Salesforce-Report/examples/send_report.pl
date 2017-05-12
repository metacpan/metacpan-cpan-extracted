# Copyright 2010 Pedro Paixao
use lib "../lib";
use WWW::Salesforce::Report;
use Net::SMTP::TLS;
use Mime::Lite;

$sfr = WWW::Salesforce::Report->new(
    id=> "000000068AxXd",
    user=> "myuser",
    password => "mypassword" );
    
$sfr->login();
my $xls_data = $sfr->get_report(format => "xls");
my $name = $sfr->write(file=> "report.xls");

# using TLS to send the e-mail
my $mailer = new Net::SMTP::TLS(
    "mail.domain.com",
    Hello   => "mail.domain.com",
    Port    =>  25,
    User    => "my_user_name",
    Password=> "my_password");

# email of the sender
$mailer->mail("reports@domain.com");

# email of the recipient
$mailer->to("user@domain.com");

$mailer->data;

my $message = MIME::Lite->new(
        From    => "reports@domain.com",
        To      => "user@domain.com",
        Subject => "REPORT: Quarter Forecast by Region",
        Type    =>'multipart/mixed'
);

# Message body
$message->attach(
        Type => "TEXT",
        Data => "Here are the latest forecast numbers.",
);

# Attach the zip file
$message->attach(
        Type => "application/zip",
        Filename => $name,
        Path => $name,
        Encoding => "base64",
        Disposition => 'attachment',
);  

$mailer->datasend($message->as_string);

$mailer->dataend;
$mailer->quit;