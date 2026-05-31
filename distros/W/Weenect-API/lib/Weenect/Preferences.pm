#! perl

use v5.36;
use Object::Pad;
use Class::JSON_Object;
use utf8;

=head1 NAME

Weenect::Preferences - Preferences data

=head1 DESCRIPTION

These are data classes for the preferences. Read the source for details.

=cut

class Weenect::Preferences :does(Class::JSON_Object) {
    field @account_option_offers      	:Class(Weenect::Preferences_account_option_offers);	# 
    field @account_options            	:Class(Weenect::Preferences_account_options);	# 
    field $address;                   	# 
    field $city;                      	# 
    field $connection_date;           	# 
    field $contact_mail;              	# 
    field $country;                   	# 
    field $creation_date;             	# 
    field $default_payment_mean;      	# 
    field $disable_history;           	# 
    field $emailpref;                 	# 
    field $firstname;                 	# 
    field $id;                        	# 
    field $is_admin;                  	# 
    field $is_b2b;                    	# 
    field $is_premium;                	# 
    field $is_security;               	# 
    field $language;                  	# 
    field $last_connection_date;      	# 
    field $lastname;                  	# 
    field $mail;                      	# 
    field $mail_pref;                 	# 
    field $need_subscription;         	# 
    field $optin;                     	# 
    field $phone;                     	# 
    field $postal_code;               	# 
    field $preferred_metric_system;   	# 
    field $review_link;               	# 
    field $role_retailer_id;          	# 
    field $role_site;                 	# 
    field $short_code;                	# 
    field $site;                      	# 
    field $sms;                       	# 
    field $user_notation;             	# 
    field $valid;                     	# 
    field $white_label;               	# 
}

class Weenect::Preferences_account_option_offers :does(Class::JSON_Object) {
    field $code;                      	# 
    field $created_at;                	# 
    field $id;                        	# 
    field $price_offer;               	# 
    field $site;                      	# 
    field $sms;                       	# 
    field $updated_at;                	# 
}

class Weenect::Preferences_account_option_offers_price_offer :does(Class::JSON_Object) {
    field $code;                      	# 
    field $de;                        	# 
    field $en;                        	# 
    field $es;                        	# 
    field $fr;                        	# 
    field $id;                        	# 
    field $it;                        	# 
    field $nl;                        	# 
}

class Weenect::Preferences_account_option_offers_price_offer_de :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_option_offers_price_offer_en :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_option_offers_price_offer_es :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_option_offers_price_offer_fr :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_option_offers_price_offer_it :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_option_offers_price_offer_nl :does(Class::JSON_Object) {
    field $amount;                    	# 
    field $currency;                  	# 
}

class Weenect::Preferences_account_options :does(Class::JSON_Object) {
    field $activated;                 	# 
    field $activation_date;           	# 
    field $amount;                    	# 
    field $cancel_date;               	# 
    field $cancel_reason;             	# 
    field $code;                      	# 
    field $created_at;                	# 
    field $currency;                  	# 
    field $id;                        	# 
    field $is_running;                	# 
    field $next_charge_at;            	# 
    field $sms;                       	# 
    field $subscription_id;           	# 
    field $updated_at;                	# 
    field $user_id;                   	# 
}

class Weenect::Preferences_default_payment_mean :does(Class::JSON_Object) {
    field $bank_account;                    	# 
    field $card_expiry;                     	# 
    field $card_pan;                        	# 
    field $count_option_payment_error;      	# 
    field $count_subscription_payment_error;	# 
    field $country;                         	# 
    field $created_at;                      	# 
    field $customer_id;                     	# 
    field $has_card_expired;                	# 
    field $has_insufficient_funds;          	# 
    field $id;                              	# 
    field $ipaddress;                       	# 
    field $is_activated;                    	# 
    field $payment_additional_id;           	# 
    field $payment_id;                      	# 
    field $payment_mean;                    	# 
    field $payment_product;                 	# 
    field $updated_at;                      	# 
    field $user_id;                         	# 
}

class Weenect::Preferences_mail_pref :does(Class::JSON_Object) {
    field $company_news;              	# 
    field $new_features;              	# 
    field $offers;                    	# 
    field $surveys_and_tests;         	# 
}

class Weenect::Preferences_user_notation :does(Class::JSON_Object) {
    field $amazon_review_link;            	# 
    field $created_at;                    	# 
    field $id;                            	# 
    field $notation_in_app;               	# 
    field $trustpilot_product_review_link;	# 
    field $trustpilot_service_review_link;	# 
    field $updated_at;                    	# 
    field $user_id;                       	# 
}

class Weenect::Preferences_white_label :does(Class::JSON_Object) {
    field $code;                      	# 
    field $display_header;            	# 
    field $display_logo;              	# 
    field $display_splashscreen;      	# 
    field $logo;                      	# 
    field $logo_header;               	# 
    field $logo_splashscreen;         	# 
    field $name;                      	# 
}

1;
