use strict;
use warnings;
use Test::More;
use utf8;
use DateTime;
use JSON qw(decode_json);
# Test bed for unary operators.
use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new();

my $result = $liquid->render_text({ }, q`<div class="emailSummary" style="mso-hide: all; display: none !important; font-size: 0 !important; max-height: 0 !important; line-height: 0 !important; padding: 0 !important; overflow: hidden !important; float: none !important; width: 0 !important; height: 0 !important;">Confirmation for order {{name}}</div>
<table id="emailBody" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; height: 100%; width: 100%; min-height: 1000px; background-color: #f2f2f2; padding: 0; margin: 0;" border="0" width="100%" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="emailBodyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; height: 100%; width: 100%; min-height: 1000px; background-color: #f2f2f2; padding: 0 0 32px 0; margin: 0;" align="center" valign="top">&nbsp;
<table class="eBox" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; width: 100%; min-width: 576px; padding: 0; margin: 0;" border="0" width="100%" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="eHeader_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
<td class="eHeader" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; width: 512px; background-color: #ffffff; border-bottom: 1px solid #ebebeb; padding: 16px; margin: 0;">
<table style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; padding: 0; margin: 0;" border="0" width="100%" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="eHeaderLogo" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; height: 48px; text-align: left; font-size: 0 !important; font-weight: bold; padding: 0; margin: 0;"><a class="logo" style="display: inline-block; text-decoration: none; color: #d5171d; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; height: 48px; text-align: left; font-size: 18px; font-weight: bold; line-height: 0; padding: 0;" href="{{ shop.url }}"><img class="imageFix" style="height: auto; width: auto; line-height: 100%; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; border: none; display: block; vertical-align: top; padding: 0; margin: 0;" src="{{ 'logo.png' | asset_url }}" alt="{{ shop_name }}" height="48" /></a></td>
<!-- end .eHeaderLogo--></tr>
</tbody>
</table>
</td>
<td class="eHeader_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
</tr>
<tr>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<td class="eBody alignLeft" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; width: 512px; color: #242424; background-color: #ffffff; padding: 16px 16px 0 16px; margin: 0;">
<h1 style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; font-size: 24px; line-height: 36px; font-weight: bold; color: #242424; padding: 0; margin: 0 0 5px 0;">Boa! A sua encomenda est&aacute; pronta para envio.<br /><br /></h1>
<p class="p1"><span class="s1">A sua encomenda j&aacute; est&aacute; pronta para envio :) Pedimos que efectue a transfer&ecirc;ncia nos pr&oacute;ximos momentos para que a mesma chegue a sua casa o mais r&aacute;pido poss&iacute;vel :) Os dados para pagamento est&atilde;o no fundo deste e-mail.</span></p>
<p>&nbsp;Sabia que a Princeless disp&otilde;e de seguro de entrega e de satisfa&ccedil;&atilde;o?</p>
<p class="p1"><span class="s1">Connosco o seu sorriso, &eacute; a nossa prioridade!</span></p>
<p>&nbsp;</p>
</td>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<!-- end .eBody--></tr>
<tr>
<td class="highlight_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
<td class="highlight invoiceHead alignLeft pdBt5" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; width: 512px; font-size: 12px; color: #898989; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 16px 16px 5px 16px; margin: 0;">
<h4 style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; font-size: 14px; font-weight: bold; color: #242424; padding: 0; margin: 0 0 5px 0;">Order {{name}} <span style="font-size: 12px; font-weight: normal; color: #898989;">{{ date | date: "%m/%d/%Y" }}</span></h4>
</td>
<td class="highlight_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
<!-- end .highlight--></tr>
<tr>
<td class="highlight_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
<td class="highlight invoiceHead alignLeft pdTp0" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; width: 512px; font-size: 12px; color: #898989; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 0px 16px 0 16px; margin: 0;">{% if billing_address %}{% endif %} {% if requires_shipping and shipping_address %}{% endif %}
<table style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; padding: 0; margin: 0 auto 0 0;" border="0" width="100%" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="width246 pdRg16" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; vertical-align: top; width: 246px; font-size: 12px; color: #898989; padding: 0 16px 0 0; margin: 0;">
<table class="tag" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; padding: 0; margin: 0 auto 0 0;" border="0" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="btnLfTp" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: top; padding: 0; margin: 0;" align="left" valign="top" width="2" height="2">&nbsp;</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="btnRgTp" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: top; padding: 0; margin: 0;" align="right" valign="top" width="4" height="8">&nbsp;</td>
</tr>
<tr>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="tagName" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 11px; color: #ffffff; background-color: #cbcbcb; text-transform: uppercase; white-space: nowrap; padding: 2px 4px 2px 4px; margin: 0;" align="left" valign="middle">Endere&ccedil;o Fatura&ccedil;&atilde;o</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
</tr>
<tr>
<td class="btnLfBt" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: bottom; padding: 0; margin: 0;" align="left" valign="bottom">&nbsp;</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="btnRgBt" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: bottom; padding: 0; margin: 0;" align="right" valign="bottom">&nbsp;</td>
</tr>
<tr>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
</tr>
</tbody>
</table>
<p style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 19px; text-align: left; color: #898989; padding: 0; margin: 0 0 24px 0;">{{ billing_address.name }}<br /> {{ billing_address.street }}<br /> {{ billing_address.city }}<br /> {{ billing_address.province }} {{ billing_address.zip }}<br /> {{ billing_address.country }}</p>
</td>
<td class="width246" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; vertical-align: top; width: 246px; font-size: 12px; color: #898989; padding: 0; margin: 0;">
<table class="tag" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; padding: 0; margin: 0 auto 0 0;" border="0" cellspacing="0" cellpadding="0">
<tbody>
<tr>
<td class="btnLfTp" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: top; padding: 0; margin: 0;" align="left" valign="top" width="2" height="2">&nbsp;</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="btnRgTp" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: top; padding: 0; margin: 0;" align="right" valign="top" width="4" height="8">&nbsp;</td>
</tr>
<tr>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="tagName" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 11px; color: #ffffff; background-color: #cbcbcb; text-transform: uppercase; white-space: nowrap; padding: 2px 4px 2px 4px; margin: 0;" align="left" valign="middle">Endere&ccedil;o Envio</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
</tr>
<tr>
<td class="btnLfBt" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: bottom; padding: 0; margin: 0;" align="left" valign="bottom">&nbsp;</td>
<td class="emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 0 !important; padding: 0; margin: 0;">&nbsp;</td>
<td class="btnRgBt" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 0 !important; color: #898989; background-color: #cbcbcb; line-height: 100%; width: 2px; height: 2px; vertical-align: bottom; padding: 0; margin: 0;" align="right" valign="bottom">&nbsp;</td>
</tr>
<tr>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
<td class="tag_space emptyCell" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 0 !important; color: #898989; background-color: transparent; line-height: 0 !important; height: 4px; padding: 0; margin: 0;">&nbsp;</td>
</tr>
</tbody>
</table>
<p style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; font-size: 12px; line-height: 19px; text-align: left; color: #898989; padding: 0; margin: 0 0 24px 0;">{{ shipping_address.name }}<br /> {{ shipping_address.street }}<br /> {{ shipping_address.city }}<br /> {{ shipping_address.province }} {{ shipping_address.zip }}<br /> {{ shipping_address.country }}</p>
</td>
</tr>
</tbody>
</table>
</td>
<td class="highlight_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;">&nbsp;</td>
<!-- end .highlight--></tr>
<tr>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<td class="blank" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; width: 544px; padding: 0; margin: 0;">
<table class="invoiceTable2 bottomLine" style="mso-table-lspace: 0pt; mso-table-rspace: 0pt; border-collapse: collapse; border-spacing: 0; background-color: #ffffff; border-bottom: 1px solid #ebebeb; padding: 0; margin: 0;" border="0" width="100%" cellspacing="0" cellpadding="0">
<tbody>
<tr><th class="alignLeft pdLf16" style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 12px; line-height: 16px; font-weight: bold; text-transform: uppercase; color: #898989; background-color: #ffffff; border-bottom: 1px solid #ebebeb; padding: 6px 16px 6px 16px;" colspan="2">Item</th><th class="alignRight" style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 12px; line-height: 16px; font-weight: bold; text-transform: uppercase; color: #898989; background-color: #ffffff; border-bottom: 1px solid #ebebeb; vertical-align: top; padding: 6px 16px 6px 16px;">Subtotal</th></tr>
<tr>
<td class="alignLeft prodImg" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 14px; line-height: 19px; color: #242424; background-color: #ffffff; border-bottom: 1px solid #ebebeb; width: 80px; padding: 14px 0 14px 16px; margin: 0;"><img style="height: auto; width: auto; line-height: 100%; outline: none; text-decoration: none; -ms-interpolation-mode: bicubic; padding: 0; margin: 0 auto 0 0;" src="{{ line.product.featured_image | product_img_url: 'small' }}" alt="{{ line.title }}" width="80" /></td>
<td class="alignLeft prodDesc" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: left; font-size: 12px; line-height: 18px; color: #898989; background-color: #ffffff; border-bottom: 1px solid #ebebeb; width: 280px; vertical-align: top; padding: 14px 0 14px 16px; margin: 0;">
<h4 style="-webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; font-size: 14px; font-weight: bold; color: #242424; padding: 0; margin: 0 0 5px 0;">{{ line.title }}</h4>
Quantity: {{ line.quantity }}<br /> Price: {{ line.price | money }}</td>
<td class="alignRight" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 14px; line-height: 19px; color: #242424; background-color: #ffffff; border-bottom: 1px solid #ebebeb; vertical-align: top; padding: 14px 16px 14px 16px; margin: 0;"><span class="desktopHide" style="display: none; font-size: 0; max-height: 0; width: 0; line-height: 0; overflow: hidden; mso-hide: all;">Subtotal: </span><span class="amount" style="color: #666666;">{{ line.line_price | money }}</span></td>
</tr>
<tr>
<td class="subTotal alignRight mobileHide" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 14px; line-height: 22px; color: #898989; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; vertical-align: top; padding: 16px 0 14px 16px; margin: 0;" colspan="2">{% if discounts %}Discounts<br /> {% endif %} Subtotal<br /> {% for tax_line in tax_lines %}{{ tax_line.title }} {{tax_line.rate_percentage}}%<br /> {% endfor %} {% if requires_shipping %}Shipping{% endif %}</td>
<td class="subTotal alignRight" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; font-size: 14px; line-height: 22px; color: #898989; background-color: #f6f6f7; border-bottom: 1px solid #ebebeb; vertical-align: top; padding: 16px 16px 14px 16px; margin: 0;">{% if discounts %}<span class="desktopHide" style="display: none; font-size: 0; max-height: 0; width: 0; line-height: 0; overflow: hidden; mso-hide: all;">Discounts: </span><span class="amount" style="color: #242424;">{{ discounts_savings | money_with_currency }}</span><br /> {% endif %} <span class="desktopHide" style="display: none; font-size: 0; max-height: 0; width: 0; line-height: 0; overflow: hidden; mso-hide: all;">Subtotal: </span><span class="amount" style="color: #242424;">{{ subtotal_price | money_with_currency }}</span><br /> {% for tax_line in tax_lines %}<span class="desktopHide" style="display: none; font-size: 0; max-height: 0; width: 0; line-height: 0; overflow: hidden; mso-hide: all;">{{ tax_line.title }} {{tax_line.rate_percentage}}%</span> <span class="amount" style="color: #242424;">{{tax_line.price | money_with_currency }}</span><br /> {% endfor %} {% if requires_shipping %}<span class="desktopHide" style="display: none; font-size: 0; max-height: 0; width: 0; line-height: 0; overflow: hidden; mso-hide: all;">Envio: </span> <span class="amount" style="color: #242424;">{{ shipping_price | money_with_currency }}</span> {% endif %}</td>
</tr>
<tr>
<td class="eTotal alignRight" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; border-bottom: 1px solid #ebebeb; font-size: 14px; line-height: 19px; color: #242424; background-color: #ffffff; vertical-align: top; padding: 16px 16px 14px 16px; margin: 0;" colspan="2"><strong>Total</strong></td>
<td class="eTotal alignRight" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: right; border-bottom: 1px solid #ebebeb; font-size: 14px; line-height: 19px; color: #242424; background-color: #ffffff; vertical-align: top; padding: 16px 16px 14px 16px; margin: 0;"><span class="amount" style="color: #666666; font-size: 16px; font-weight: bold;">{{ total_price | money_with_currency }}</span></td>
</tr>
</tbody>
</table>
</td>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<!-- end .eBody--></tr>
<tr>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<td class="bottomCorners" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; height: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;">&nbsp;</td>
</tr>
<tr>
<td class="eBody_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; background-color: #ffffff; padding: 0; margin: 0;" colspan="3" align="center"><!-- Start Lusopay payment code --> {% if gateway == "Refer&ecirc;ncia Multibanco ou Payshop" %} <br /> <img src="https://services.lusopay.com/ShopifyServices/?amount={{total_price}}&amp;order-id={{order_number}}&amp;currency={{shop.currency}}&amp;c=04d849a8-4f96-4474-8a41-bc7fa959f70e&amp;s= 513919538&amp;user=Princeless&amp;l=princeless" alt="" width="400" /> <br /><br /><br /> {% endif %} <!-- End Lusopay payment code --></td>
</tr>
<tr>
<td class="eFooter_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; padding: 0; margin: 0;">&nbsp;</td>
<td class="eFooter" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; text-align: center; font-size: 12px; line-height: 21px; width: 544px; color: #b2b2b2; padding: 14px 0 0 0; margin: 0;">&copy; 2014 {{ shop.name }}. All Rights Reserved.</td>
<td class="eFooter_stretch" style="border-collapse: collapse; border-spacing: 0; -webkit-text-size-adjust: none; font-family: Arial, Helvetica, sans-serif; min-width: 16px; padding: 0; margin: 0;">&nbsp;</td>
</tr>
</tbody>
</table>
<!-- end .eBox --></td>
<!-- end .emailBodyCell --></tr>
</tbody>
</table>
<!-- end #emailBody --><!-- #######  YAY, I AM THE SOURCE EDITOR! #########-->
<h1 style="color: #5e9ca0;">You can edit <span style="color: #2b2301;">this demo</span> text!</h1>
<h2 style="color: #2e6c80;">How to use the editor:</h2>
<p>Paste your documents in the visual editor on the left or your HTML code in the source editor in the right. <br />Edit any of the two areas and see the other changing in real time.&nbsp;</p>
<p>Click the <span style="background-color: #2b2301; color: #fff; display: inline-block; padding: 3px 10px; font-weight: bold; border-radius: 5px;">Clean</span> button to clean your source code.</p>
<h2 style="color: #2e6c80;">Some useful features:</h2>
<ol style="list-style: none; font-size: 14px; line-height: 32px; font-weight: bold;">
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/01-interactive-connection.png" alt="interactive connection" width="45" /> Interactive source editor</li>
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/02-html-clean.png" alt="html cleaner" width="45" /> HTML Cleaning</li>
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/03-docs-to-html.png" alt="Word to html" width="45" /> Word to HTML conversion</li>
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/04-replace.png" alt="replace text" width="45" /> Find and Replace</li>
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/05-gibberish.png" alt="gibberish" width="45" /> Lorem-Ipsum generator</li>
<li style="clear: both;"><img style="float: left;" src="https://html-online.com/img/6-table-div-html.png" alt="html table div" width="45" /> Table to DIV conversion</li>
</ol>
<p>&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</p>
<h2 style="color: #2e6c80;">Cleaning options:</h2>
<table class="editorDemoTable">
<thead>
<tr>
<td>Name of the feature</td>
<td>Example</td>
<td>Default</td>
</tr>
</thead>
<tbody>
<tr>
<td>Remove tag attributes</td>
<td><img style="margin: 1px 15px;" src="images/smiley.png" alt="laughing" width="40" height="16" /> (except <strong>img</strong>-<em>src</em> and <strong>a</strong>-<em>href</em>)</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove inline styles</td>
<td><span style="color: green; font-size: 13px;">You <strong style="color: blue; text-decoration: underline;">should never</strong>&nbsp;use inline styles!</span></td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Remove classes and IDs</td>
<td><span id="demoId">Use classes to <strong class="demoClass">style everything</strong>.</span></td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Remove all tags</td>
<td>This leaves <strong style="color: blue;">only the plain</strong> <em>text</em>. <img style="margin: 1px;" src="images/smiley.png" alt="laughing" width="16" height="16" /></td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove successive &amp;nbsp;s</td>
<td>Never use non-breaking spaces&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;to set margins.</td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Remove empty tags</td>
<td>Empty tags should go!</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove tags with one &amp;nbsp;</td>
<td>This makes&nbsp;no sense!</td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Remove span tags</td>
<td>Span tags with <span style="color: green; font-size: 13px;">all styles</span></td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Remove images</td>
<td>I am an image: <img src="images/smiley.png" alt="laughing" /></td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove links</td>
<td><a href="https://html-online.com">This is</a> a link.</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove tables</td>
<td>Takes everything out of the table.</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Replace table tags with structured divs</td>
<td>This text is inside a table.</td>
<td>&nbsp;</td>
</tr>
<tr>
<td>Remove comments</td>
<td>This is only visible in the source editor <!-- HELLO! --></td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Encode special characters</td>
<td><span style="color: red; font-size: 17px;">&hearts;</span> <strong style="font-size: 20px;">â˜º â˜…</strong> &gt;&lt;</td>
<td><strong style="font-size: 17px; color: #2b2301;">x</strong></td>
</tr>
<tr>
<td>Set new lines and text indents</td>
<td>Organize the tags in a nice tree view.</td>
<td>&nbsp;</td>
</tr>
</tbody>
</table>
<p><strong>&nbsp;</strong></p>
<p><strong>Save this link into your bookmarks and share it with your friends. It is all FREE! </strong><br /><strong>Enjoy!</strong></p>
<p><strong>&nbsp;</strong></p>`);

ok($result);

done_testing();