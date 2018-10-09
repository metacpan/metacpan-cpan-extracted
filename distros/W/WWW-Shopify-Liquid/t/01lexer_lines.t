use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text("{% for i in (1..2) %}\n{{ i }}\n{% endfor %}");
is(int(@tokens), 5);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Tag');
is($tokens[0]->{line}->[0], 1);
isa_ok($tokens[1], 'WWW::Shopify::Liquid::Token::Text');
is($tokens[1]->{line}->[0], 1);
isa_ok($tokens[2], 'WWW::Shopify::Liquid::Token::Output');
is($tokens[2]->{line}->[0], 2);
isa_ok($tokens[3], 'WWW::Shopify::Liquid::Token::Text');
is($tokens[3]->{line}->[0], 2);
isa_ok($tokens[4], 'WWW::Shopify::Liquid::Token::Tag');
is($tokens[4]->{line}->[0], 3);

@tokens = $lexer->parse_text("{% assign a = 1 | pluralize: 'asd', 'sadfsdf' %}");
is(int(@tokens), 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Tag');
is(int(@{$tokens[0]->{arguments}}), 9);
isa_ok($tokens[0]->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($tokens[0]->{arguments}->[1], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{arguments}->[2], 'WWW::Shopify::Liquid::Token::Number');
isa_ok($tokens[0]->{arguments}->[3], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{arguments}->[4], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($tokens[0]->{arguments}->[5], 'WWW::Shopify::Liquid::Token::Separator');
isa_ok($tokens[0]->{arguments}->[6], 'WWW::Shopify::Liquid::Token::String');
isa_ok($tokens[0]->{arguments}->[7], 'WWW::Shopify::Liquid::Token::Separator');
isa_ok($tokens[0]->{arguments}->[8], 'WWW::Shopify::Liquid::Token::String');

my $text = q(<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<html lang="en">
  <head>
    <!--[if gte mso 15]>
      <xml>
        <o:OfficeDocumentSettings>
          <o:AllowPNG />
            <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml>
    <![endif]-->
    <meta name="viewport" content="width=device-width">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="x-apple-disable-message-reformatting">
    <meta http-equiv="Content-Type" content="text/html; charset=US-ASCII">
    <!-- Customer account welcome email template for Shopify -->
    <style type="text/css" data-premailer="ignore">
      /* What it does: Remove spaces around the email design added by some email clients. */
          /* Beware: It can remove the padding / Margin and add a background color to the compose a reply window. */
          html, body {
            Margin: 0 auto !important;
            padding: 0 !important;
            width: 100% !important;
              height: 100% !important;
          }
          /* What it does: Stops email clients resizing small text. */
          * {
            -ms-text-size-adjust: 100%;
            -webkit-text-size-adjust: 100%;
            text-rendering: optimizeLegibility;
              -webkit-font-smoothing: antialiased;
              -moz-osx-font-smoothing: grayscale;
          }
          /* What it does: Forces Outlook.com to display emails full width. */
          .ExternalClass {
            width: 100%;
          }
          /* What is does: Centers email on Android 4.4 */
          div[style*="Margin: 16px 0"] {
              Margin:0 !important;
          }
          /* What it does: Stops Outlook from adding extra spacing to tables. */
          table,
          th {
            mso-table-lspace: 0pt;
            mso-table-rspace: 0pt;
          }
          /* What it does: Fixes Outlook.com line height. */
          .ExternalClass,
          .ExternalClass * {
            line-height: 100% !important;
          }
          /* What it does: Fixes webkit padding issue. Fix for Yahoo mail table alignment bug. Applies table-layout to the first 2 tables then removes for anything nested deeper. */
          table {
            border-spacing: 0 !important;
            border-collapse: collapse !important;
            border: none;
            Margin: 0 auto;
          }
          div[style*="Margin: 16px 0"] {
              Margin:0 !important;
          }
          /* What it does: Uses a better rendering method when resizing images in IE. */
          img {
            -ms-interpolation-mode:bicubic;
          }
          /* What it does: Overrides styles added when Yahoo's auto-senses a link. */
          .yshortcuts a {
            border-bottom: none !important;
          }
          /* What it does: Overrides blue, underlined link auto-detected by iOS Mail. */
          /* Create a class for every link style needed; this template needs only one for the link in the footer. */
          /* What it does: A work-around for email clients meddling in triggered links. */
          *[x-apple-data-detectors],  /* iOS */
          .x-gmail-data-detectors,    /* Gmail */
          .x-gmail-data-detectors *,
          .aBn {
              border-bottom: none !important;
              cursor: default !important;
              color: inherit !important;
              text-decoration: none !important;
              font-size: inherit !important;
              font-family: inherit !important;
              font-weight: inherit !important;
              line-height: inherit !important;
          }
      
          /* What it does: Prevents Gmail from displaying an download button on large, non-linked images. */
          .a6S {
              display: none !important;
              opacity: 0.01 !important;
          }
          /* If the above doesn't work, add a .g-img class to any image in question. */
          img.g-img + div {
              display:none !important;
          }
          /* What it does: Prevents underlining the button text in Windows 10 */
          a,
          a:link,
          a:visited {
              color: #616161;
              text-decoration: none !important;
          }
          .header a {
              color: #c5c5c5;
              text-decoration: none;
              text-underline: none;
          }
          .main a {
              color: #616161;
              text-decoration: none;
              text-underline: none;
              word-wrap: break-word;
          }
          .main .section.customer_and_shipping_address a,
          .main .section.shipping_address_and_fulfillment_details a {
              color: #616161;
              text-decoration: none;
              text-underline: none;
              word-wrap: break-word;
          }
          .footer a {
              color: #87c646;
              text-decoration: none;
              text-underline: none;
          }
      
          /* What it does: Overrides styles added images. */
          img {
            border: none !important;
            outline: none !important;
            text-decoration:none !important;
          }
          /* What it does: Fixes fonts for Google WebFonts; */
          [style*="Muli"] {
              font-family: 'Muli',-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif !important;
          }
          [style*="Muli"] {
              font-family: 'Muli',-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif !important;
          }
          [style*="Muli"] {
              font-family: 'Muli',-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif !important;
          }
          [style*="Muli"] {
              font-family: 'Muli',-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif !important;
          }
          td.menu_bar_1 a:hover,
          td.menu_bar_6 a:hover {
            color: #616161 !important;
          }
          th.related_product_wrapper.first {
            border-right: 10px solid #ffffff;
            padding-right: 5px;
          }
          th.related_product_wrapper.last {
            border-left: 10px solid #ffffff;
            padding-left: 5px;
          }
    </style>
    <!--[if (mso)|(mso 16)]>
      <style type="text/css" data-premailer="ignore">
        a {text-decoration: none;}
      </style>
    <![endif]-->
    <!--[if !mso]><!-->
  <link href="https://fonts.googleapis.com/css?family=Muli:300,400,700|Muli:300,400,700|Muli:400,700|Muli:400,400,700" rel="stylesheet" type="text/css" data-premailer="ignore">
  <!--<![endif]-->
      <style type="text/css" data-premailer="ignore">
        /* Media Queries */
            /* What it does: Removes right gutter in Gmail iOS app */
            @media only screen and (min-device-width: 375px) and (max-device-width: 413px) { /* iPhone 6 and 6+ */
                .container {
                    min-width: 375px !important;
                }
            }
            /* Main media query for responsive styles */
            @media only screen and (max-width:480px) {
              /* What it does: Overrides email-container's desktop width and forces it into a 100% fluid width. */
              .email-container {
                width: 100% !important;
                min-width: 100% !important;
              }
              .section > th {
                padding: 10px 20px 10px 20px !important;
              }
              .section.divider > th {
                padding: 20px 20px !important;
              }
              .main .section:first-child > th,
              .main .section:first-child > td {
                  padding-top: 20px !important;
              }
                .main .section:last-child > th,
                .main .section:last-child > td {
                    padding-bottom: 30px !important;
                }
              .section.recommended_products > th,
              .section.discount > th {
                  padding: 20px 20px !important;
              }
              /* What it does: Forces images to resize to the width of their container. */
              img.fluid,
              img.fluid-centered {
                width: 100% !important;
                min-width: 100% !important;
                max-width: 100% !important;
                height: auto !important;
                Margin: auto !important;
                box-sizing: border-box;
              }
              /* and center justify these ones. */
              img.fluid-centered {
                Margin: auto !important;
              }
        
              /* What it does: Forces table cells into full-width rows. */
              th.stack-column,
              th.stack-column-left,
              th.stack-column-center,
              th.related_product_wrapper,
              .column_1_of_2,
              .column_2_of_2 {
                display: block !important;
                width: 100% !important;
                min-width: 100% !important;
                direction: ltr !important;
                box-sizing: border-box;
              }
              /* and left justify these ones. */
              th.stack-column-left {
                text-align: left !important;
              }
              /* and center justify these ones. */
              th.stack-column-center,
              th.related_product_wrapper {
                text-align: center !important;
                border-right: none !important;
                border-left: none !important;
              }
              .column_button,
              .column_button > table,
              .column_button > table th {
                width: 100% !important;
                text-align: center !important;
                Margin: 0 !important;
              }
              .column_1_of_2 {
                padding-bottom: 20px !important;
              }
              .column_1_of_2 th {
                  padding-right: 0 !important;
              }
              .column_2_of_2 th {
                  padding-left:  0 !important;
              }
              .column_text_after_button {
                padding: 0 10px !important;
              }
              /* Adjust product images */
              th.table-stack {
                padding: 0 !important;
              }
              th.product-image-wrapper {
                  padding: 20px 0 10px 0 !important;
              }
              img.product-image {
                    width: 240px !important;
                    max-width: 240px !important;
              }
              tr.row-border-bottom th.product-image-wrapper {
                border-bottom: none !important;
              }
              th.related_product_wrapper.first,
              th.related_product_wrapper.last {
                padding-right: 0 !important;
                padding-left: 0 !important;
              }
              .text_banner th.banner_container {
                padding: 10px !important;
              }
              .mobile_app_download .column_1_of_2 .image_container {
                padding-bottom: 0 !important;
              }
              .mobile_app_download .column_2_of_2 .image_container {
                padding-top: 0 !important;
              }
            }
      </style>
      <style type="text/css" data-premailer="ignore">
        /* Custom Media Queries */
          @media only screen and (max-width:480px) {
            .section_th {
                padding: 40px 20px !important;
            }
            .header .section_th {
                padding: 0 20px 0 20px !important;
            }
            .header .section_wrapper_th {
                padding: 0 20px 0 20px !important;
            }
            .footer .section_wrapper_th {
              padding: 20px 20px 20px 20px !important;
            }
            .footer .column_2_of_2,
            .footer .column_2_of_2 th,
            .footer .column_2_of_2 th p {
                text-align: left !important;
            }
          }
      </style>
    </head>
    <body class="body" id="body" leftMargin="0" topMargin="0" Marginwidth="0" Marginheight="0" bgcolor="#ffffff" style="-webkit-text-size-adjust: none; -ms-text-size-adjust: none; Margin: 0; padding: 0;">
      <!--[if !mso 9]><!-->
        <div style="display: none; overflow: hidden; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; mso-hide: all;">
          Welcome, your registry account is now active! The next time you shop with us, you can save time at checkout by logging into your account here:
        </div>
      <!--<![endif]-->
        <!-- BEGIN: CONTAINER -->
        <table class="container container_header" cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse: collapse; min-width: 100%;" role="presentation" bgcolor="#f3f9ed">
          <tbody>
            <tr>
              <th valign="top" style="mso-line-height-rule: exactly;">
                <center style="width: 100%;">
                  <table border="0" width="600" cellpadding="0" cellspacing="0" align="center" style="width: 600px; min-width: 600px; max-width: 600px; Margin: auto;" class="email-container" role="presentation">
                    <tr>
                      <th valign="top" style="mso-line-height-rule: exactly;">
                        <!-- BEGIN : SECTION : HEADER -->
                        <table class="section_wrapper header" data-id="header" id="section-header" border="0" width="100%" cellpadding="0" cellspacing="0" align="center" style="min-width: 100%;" role="presentation" bgcolor="#f3f9ed">
                          <tr>
                            <td class="section_wrapper_th" style="mso-line-height-rule: exactly; padding: 0 40px;" bgcolor="#f3f9ed">
                              <table border="0" width="100%" cellpadding="0" cellspacing="0" align="center" style="min-width: 100%;" role="presentation">
                                <tr>
                                  <th class="column_logo" style="mso-line-height-rule: exactly; padding-top: 0px; padding-bottom: 0px; Margin: 0;" align="left" bgcolor="#f3f9ed">
                                    <!-- Logo : BEGIN -->
                                   <!–– JARROD removed strip filter––>
                                      <img src="https://d1oo2t5460ftwl.cloudfront.net/api/file/W2NgMZ5bSueTSSqcOL6F/convert?fit=max&amp;w=900" class="logo logo_banner " width="100%" border="0" style="width: 100%; height: auto !important; display: block; max-width: 600px; text-align: left; padding-top: 0; padding-bottom: 0; Margin: auto;">
                                    </a>
                                    <!-- Logo : END -->
                                  </th>
                                </tr>
                              </table>
                            </td>
                          </tr>
                        </table>
                        <!-- END : SECTION : HEADER -->
                      </th>
                    </tr>
                  </table>
                </center>
              </th>
            </tr>
          </tbody>
        </table>
        <!-- END : CONTAINER -->
        <!-- BEGIN: CONTAINER -->
        <table class="container container_main" cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse: collapse; min-width: 100%;" role="presentation" bgcolor="#ffffff">
          <tbody>
            <tr>
              <th valign="top" style="mso-line-height-rule: exactly;">
                <center style="width: 100%;">
                  <table border="0" width="600" cellpadding="0" cellspacing="0" align="center" style="width: 600px; min-width: 600px; max-width: 600px; Margin: auto;" class="email-container" role="presentation">
                    <tr>
                      <th valign="top" style="mso-line-height-rule: exactly;">
                        <!-- BEGIN : SECTION : MAIN -->
                        <table class="section_wrapper main" data-id="main" id="section-main" border="0" width="100%" cellpadding="0" cellspacing="0" align="center" style="min-width: 100%; text-align: left;" role="presentation" bgcolor="#ffffff">
                          <tr>
                            <td class="section_wrapper_th" style="mso-line-height-rule: exactly; padding-top: 20px;" align="left" bgcolor="#ffffff">
                              <table border="0" width="100%" cellpadding="0" cellspacing="0" align="center" style="min-width: 100%;" id="mixContainer" role="presentation">
                                <tr data-id="link-list">
                                  <td class="menu_bar menu_bar_1" style="mso-line-height-rule: exactly; padding: 10px 0 20px;" align="left" bgcolor="#ffffff">
                                    <table class="table_menu_bar" border="0" width="100%" cellpadding="0" cellspacing="0" role="presentation">
                                      <tr>
                                        <th class="menu_bar_item first" style="width: 25%; mso-line-height-rule: exactly; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; font-weight: 300; line-height: 20px; text-transform: uppercase; color: #949292; border-right-width: 1px; border-right-color: #87c646; border-right-style: solid; border-left-width: 1px; border-left-color: #87c646; border-left-style: none;" align="center" bgcolor="#ffffff">
                                         <!–– JARROD removed strip filer ––>
                                            Shop
                                          </a>
                                        </th>
                                        <th class="menu_bar_item" style="width: 25%; mso-line-height-rule: exactly; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; font-weight: 300; line-height: 20px; text-transform: uppercase; color: #949292; border-right-width: 1px; border-right-color: #87c646; border-right-style: solid; border-left-width: 1px; border-left-color: #87c646; border-left-style: solid;" align="center" bgcolor="#ffffff">
                                          <!–– JARROD removed strip filter ––>
                                            About
                                          </a>
                                        </th>
                                        <th class="menu_bar_item" style="width: 25%; mso-line-height-rule: exactly; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; font-weight: 300; line-height: 20px; text-transform: uppercase; color: #949292; border-right-width: 1px; border-right-color: #87c646; border-right-style: solid; border-left-width: 1px; border-left-color: #87c646; border-left-style: solid;" align="center" bgcolor="#ffffff">
                                          <!–– JARROD removed strip filter ––>
                                            Contact
                                          </a>
                                        </th>
                                        <th class="menu_bar_item last" style="width: 25%; mso-line-height-rule: exactly; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; font-weight: 300; line-height: 20px; text-transform: uppercase; color: #949292; border-right-width: 1px; border-right-color: #87c646; border-right-style: none; border-left-width: 1px; border-left-color: #87c646; border-left-style: solid;" align="center" bgcolor="#ffffff">
                                          <!–– JARROD Removed strip filter ––>
                                            Contactez-nous
                                          </a>
                                        </th>
                                      </tr>
                                    </table>
                                  </td>
                                </tr>
                                <!-- BEGIN SECTION: Heading -->
                                <tr id="section-1465703" class="section heading">
                                  <th style="mso-line-height-rule: exactly; padding: 10px 40px;" align="left" bgcolor="#ffffff">
                                    <table cellspacing="0" cellpadding="0" border="0" width="100%" role="presentation">
                                      <tr>
                                        <th style="mso-line-height-rule: exactly;" align="left" bgcolor="#ffffff" valign="top">
                                          <h1 data-key="1465703_heading" style="font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 26px; line-height: 36px; font-weight: 300; color: #87c646; text-transform: none; Margin: 0;">Registry Confirmation</h1>
                                        </th>
                                      </tr>
                                    </table>
                                  </th>
                                </tr>
                                <!-- END SECTION: Heading -->
                                <!-- BEGIN SECTION: Introduction -->
                                <tr id="section-1465704" class="section introduction">
                                  <th style="mso-line-height-rule: exactly; padding: 10px 40px;" align="left" bgcolor="#ffffff">
                                    {% if customer.first_name != blank or billing_address.first_name != blank %}
                                      <p style="mso-line-height-rule: exactly; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; line-height: 20px; font-weight: 300; color: #616161; Margin: 0 0 10px;" align="left">
                                        <span data-key="1465704_greeting_text" style="text-align: left; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,'Muli'; font-size: 14px; line-height: 20px; font-weight: 300; color: #616161;">
                                          Hello
                                        </span>
                                        {{ registry.registrant.first_name }} ,
                                      </p>
                                    {% endif %});                 
@tokens = $lexer->parse_text($text);
is($tokens[1]->{line}->[0], 413);

done_testing();