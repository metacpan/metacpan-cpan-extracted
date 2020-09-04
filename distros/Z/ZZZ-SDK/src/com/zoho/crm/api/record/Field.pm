require 'src/com/zoho/crm/api/layouts/Layout.pm';
require 'src/com/zoho/crm/api/record/InventoryLineItems.pm';
require 'src/com/zoho/crm/api/record/Participants.pm';
require 'src/com/zoho/crm/api/record/PricingDetails.pm';
require 'src/com/zoho/crm/api/record/Record.pm';
require 'src/com/zoho/crm/api/record/RecurringActivity.pm';
require 'src/com/zoho/crm/api/record/RemindAt.pm';
require 'src/com/zoho/crm/api/tags/Tag.pm';
require 'src/com/zoho/crm/api/users/User.pm';
require 'src/com/zoho/crm/api/util/Choice.pm';
require 'src/com/zoho/crm/api/util/Constants.pm';
require 'src/com/zoho/api/exception/SDKException.pm';

package record::Field;
use Moose;
sub new
{
	my ($class,$api_name) = @_;
	my $self = 
	{
		api_name => $api_name,
	};
	bless $self,$class;
	return $self;
}

sub get_api_name
{
	my ($self) = shift;
	return $self->{api_name}; 
}

package record::Field::Products;
our @ISA = qw(record::Field);
 sub product_category
{
	return record::Field->new("Product_Category"); 

}

 sub qty_in_demand
{
	return record::Field->new("Qty_in_Demand"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub vendor_name
{
	return record::Field->new("Vendor_Name"); 

}

 sub tax
{
	return record::Field->new("Tax"); 

}

 sub sales_start_date
{
	return record::Field->new("Sales_Start_Date"); 

}

 sub product_active
{
	return record::Field->new("Product_Active"); 

}

 sub record_image
{
	return record::Field->new("Record_Image"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub product_code
{
	return record::Field->new("Product_Code"); 

}

 sub manufacturer
{
	return record::Field->new("Manufacturer"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub support_expiry_date
{
	return record::Field->new("Support_Expiry_Date"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub commission_rate
{
	return record::Field->new("Commission_Rate"); 

}

 sub product_name
{
	return record::Field->new("Product_Name"); 

}

 sub handler
{
	return record::Field->new("Handler"); 

}

 sub support_start_date
{
	return record::Field->new("Support_Start_Date"); 

}

 sub usage_unit
{
	return record::Field->new("Usage_Unit"); 

}

 sub qty_ordered
{
	return record::Field->new("Qty_Ordered"); 

}

 sub qty_in_stock
{
	return record::Field->new("Qty_in_Stock"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub sales_end_date
{
	return record::Field->new("Sales_End_Date"); 

}

 sub unit_price
{
	return record::Field->new("Unit_Price"); 

}

 sub taxable
{
	return record::Field->new("Taxable"); 

}

 sub reorder_level
{
	return record::Field->new("Reorder_Level"); 

}






package record::Field::Tasks;
our @ISA = qw(record::Field);
 sub status
{
	return record::Field->new("Status"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub due_date
{
	return record::Field->new("Due_Date"); 

}

 sub priority
{
	return record::Field->new("Priority"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub closed_time
{
	return record::Field->new("Closed_Time"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub send_notification_email
{
	return record::Field->new("Send_Notification_Email"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub recurring_activity
{
	return record::Field->new("Recurring_Activity"); 

}

 sub what_id
{
	return record::Field->new("What_Id"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub remind_at
{
	return record::Field->new("Remind_At"); 

}

 sub who_id
{
	return record::Field->new("Who_Id"); 

}






package record::Field::Vendors;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub email
{
	return record::Field->new("Email"); 

}

 sub category
{
	return record::Field->new("Category"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub vendor_name
{
	return record::Field->new("Vendor_Name"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub website
{
	return record::Field->new("Website"); 

}

 sub city
{
	return record::Field->new("City"); 

}

 sub record_image
{
	return record::Field->new("Record_Image"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub phone
{
	return record::Field->new("Phone"); 

}

 sub state
{
	return record::Field->new("State"); 

}

 sub gl_account
{
	return record::Field->new("GL_Account"); 

}

 sub street
{
	return record::Field->new("Street"); 

}

 sub country
{
	return record::Field->new("Country"); 

}

 sub zip_code
{
	return record::Field->new("Zip_Code"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}






package record::Field::Calls;
our @ISA = qw(record::Field);
 sub call_duration
{
	return record::Field->new("Call_Duration"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub reminder
{
	return record::Field->new("Reminder"); 

}

 sub caller_id
{
	return record::Field->new("Caller_ID"); 

}

 sub cti_entry
{
	return record::Field->new("CTI_Entry"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub call_start_time
{
	return record::Field->new("Call_Start_Time"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub call_agenda
{
	return record::Field->new("Call_Agenda"); 

}

 sub call_result
{
	return record::Field->new("Call_Result"); 

}

 sub call_type
{
	return record::Field->new("Call_Type"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub what_id
{
	return record::Field->new("What_Id"); 

}

 sub call_duration_in_seconds
{
	return record::Field->new("Call_Duration_in_seconds"); 

}

 sub call_purpose
{
	return record::Field->new("Call_Purpose"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub dialled_number
{
	return record::Field->new("Dialled_Number"); 

}

 sub call_status
{
	return record::Field->new("Call_Status"); 

}

 sub who_id
{
	return record::Field->new("Who_Id"); 

}






package record::Field::Leads;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub company
{
	return record::Field->new("Company"); 

}

 sub email
{
	return record::Field->new("Email"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub rating
{
	return record::Field->new("Rating"); 

}

 sub website
{
	return record::Field->new("Website"); 

}

 sub twitter
{
	return record::Field->new("Twitter"); 

}

 sub salutation
{
	return record::Field->new("Salutation"); 

}

 sub last_activity_time
{
	return record::Field->new("Last_Activity_Time"); 

}

 sub first_name
{
	return record::Field->new("First_Name"); 

}

 sub full_name
{
	return record::Field->new("Full_Name"); 

}

 sub lead_status
{
	return record::Field->new("Lead_Status"); 

}

 sub industry
{
	return record::Field->new("Industry"); 

}

 sub record_image
{
	return record::Field->new("Record_Image"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub skype_id
{
	return record::Field->new("Skype_ID"); 

}

 sub phone
{
	return record::Field->new("Phone"); 

}

 sub street
{
	return record::Field->new("Street"); 

}

 sub zip_code
{
	return record::Field->new("Zip_Code"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub email_opt_out
{
	return record::Field->new("Email_Opt_Out"); 

}

 sub designation
{
	return record::Field->new("Designation"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub city
{
	return record::Field->new("City"); 

}

 sub no_of_employees
{
	return record::Field->new("No_of_Employees"); 

}

 sub mobile
{
	return record::Field->new("Mobile"); 

}

 sub converted_date_time
{
	return record::Field->new("Converted_Date_Time"); 

}

 sub last_name
{
	return record::Field->new("Last_Name"); 

}

 sub layout
{
	return record::Field->new("Layout"); 

}

 sub state
{
	return record::Field->new("State"); 

}

 sub lead_source
{
	return record::Field->new("Lead_Source"); 

}

 sub is_record_duplicate
{
	return record::Field->new("Is_Record_Duplicate"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub fax
{
	return record::Field->new("Fax"); 

}

 sub annual_revenue
{
	return record::Field->new("Annual_Revenue"); 

}

 sub secondary_email
{
	return record::Field->new("Secondary_Email"); 

}






package record::Field::Deals;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub campaign_source
{
	return record::Field->new("Campaign_Source"); 

}

 sub closing_date
{
	return record::Field->new("Closing_Date"); 

}

 sub last_activity_time
{
	return record::Field->new("Last_Activity_Time"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub lead_conversion_time
{
	return record::Field->new("Lead_Conversion_Time"); 

}

 sub deal_name
{
	return record::Field->new("Deal_Name"); 

}

 sub expected_revenue
{
	return record::Field->new("Expected_Revenue"); 

}

 sub overall_sales_duration
{
	return record::Field->new("Overall_Sales_Duration"); 

}

 sub stage
{
	return record::Field->new("Stage"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub territory
{
	return record::Field->new("Territory"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub amount
{
	return record::Field->new("Amount"); 

}

 sub probability
{
	return record::Field->new("Probability"); 

}

 sub next_step
{
	return record::Field->new("Next_Step"); 

}

 sub contact_name
{
	return record::Field->new("Contact_Name"); 

}

 sub sales_cycle_duration
{
	return record::Field->new("Sales_Cycle_Duration"); 

}

 sub type
{
	return record::Field->new("Type"); 

}

 sub deal_category_status
{
	return record::Field->new("Deal_Category_Status"); 

}

 sub lead_source
{
	return record::Field->new("Lead_Source"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}






package record::Field::Campaigns;
our @ISA = qw(record::Field);
 sub status
{
	return record::Field->new("Status"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub campaign_name
{
	return record::Field->new("Campaign_Name"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub end_date
{
	return record::Field->new("End_Date"); 

}

 sub type
{
	return record::Field->new("Type"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub num_sent
{
	return record::Field->new("Num_sent"); 

}

 sub expected_revenue
{
	return record::Field->new("Expected_Revenue"); 

}

 sub actual_cost
{
	return record::Field->new("Actual_Cost"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub expected_response
{
	return record::Field->new("Expected_Response"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub parent_campaign
{
	return record::Field->new("Parent_Campaign"); 

}

 sub start_date
{
	return record::Field->new("Start_Date"); 

}

 sub budgeted_cost
{
	return record::Field->new("Budgeted_Cost"); 

}






package record::Field::Quotes;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub discount
{
	return record::Field->new("Discount"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub shipping_state
{
	return record::Field->new("Shipping_State"); 

}

 sub tax
{
	return record::Field->new("Tax"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub deal_name
{
	return record::Field->new("Deal_Name"); 

}

 sub valid_till
{
	return record::Field->new("Valid_Till"); 

}

 sub billing_country
{
	return record::Field->new("Billing_Country"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub team
{
	return record::Field->new("Team"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub carrier
{
	return record::Field->new("Carrier"); 

}

 sub quote_stage
{
	return record::Field->new("Quote_Stage"); 

}

 sub grand_total
{
	return record::Field->new("Grand_Total"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub billing_street
{
	return record::Field->new("Billing_Street"); 

}

 sub adjustment
{
	return record::Field->new("Adjustment"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub terms_and_conditions
{
	return record::Field->new("Terms_and_Conditions"); 

}

 sub sub_total
{
	return record::Field->new("Sub_Total"); 

}

 sub billing_code
{
	return record::Field->new("Billing_Code"); 

}

 sub product_details
{
	return record::Field->new("Product_Details"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub contact_name
{
	return record::Field->new("Contact_Name"); 

}

 sub shipping_city
{
	return record::Field->new("Shipping_City"); 

}

 sub shipping_country
{
	return record::Field->new("Shipping_Country"); 

}

 sub shipping_code
{
	return record::Field->new("Shipping_Code"); 

}

 sub billing_city
{
	return record::Field->new("Billing_City"); 

}

 sub quote_number
{
	return record::Field->new("Quote_Number"); 

}

 sub billing_state
{
	return record::Field->new("Billing_State"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub shipping_street
{
	return record::Field->new("Shipping_Street"); 

}






package record::Field::Invoices;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub discount
{
	return record::Field->new("Discount"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub shipping_state
{
	return record::Field->new("Shipping_State"); 

}

 sub tax
{
	return record::Field->new("Tax"); 

}

 sub invoice_date
{
	return record::Field->new("Invoice_Date"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub billing_country
{
	return record::Field->new("Billing_Country"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub sales_order
{
	return record::Field->new("Sales_Order"); 

}

 sub status
{
	return record::Field->new("Status"); 

}

 sub grand_total
{
	return record::Field->new("Grand_Total"); 

}

 sub sales_commission
{
	return record::Field->new("Sales_Commission"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub due_date
{
	return record::Field->new("Due_Date"); 

}

 sub billing_street
{
	return record::Field->new("Billing_Street"); 

}

 sub adjustment
{
	return record::Field->new("Adjustment"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub terms_and_conditions
{
	return record::Field->new("Terms_and_Conditions"); 

}

 sub sub_total
{
	return record::Field->new("Sub_Total"); 

}

 sub invoice_number
{
	return record::Field->new("Invoice_Number"); 

}

 sub billing_code
{
	return record::Field->new("Billing_Code"); 

}

 sub product_details
{
	return record::Field->new("Product_Details"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub contact_name
{
	return record::Field->new("Contact_Name"); 

}

 sub excise_duty
{
	return record::Field->new("Excise_Duty"); 

}

 sub shipping_city
{
	return record::Field->new("Shipping_City"); 

}

 sub shipping_country
{
	return record::Field->new("Shipping_Country"); 

}

 sub shipping_code
{
	return record::Field->new("Shipping_Code"); 

}

 sub billing_city
{
	return record::Field->new("Billing_City"); 

}

 sub purchase_order
{
	return record::Field->new("Purchase_Order"); 

}

 sub billing_state
{
	return record::Field->new("Billing_State"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub shipping_street
{
	return record::Field->new("Shipping_Street"); 

}






package record::Field::Attachments;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub file_name
{
	return record::Field->new("File_Name"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub size
{
	return record::Field->new("Size"); 

}

 sub parent_id
{
	return record::Field->new("Parent_Id"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}






package record::Field::Price_Books;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub active
{
	return record::Field->new("Active"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub pricing_details
{
	return record::Field->new("Pricing_Details"); 

}

 sub pricing_model
{
	return record::Field->new("Pricing_Model"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub price_book_name
{
	return record::Field->new("Price_Book_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}






package record::Field::Sales_Orders;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub discount
{
	return record::Field->new("Discount"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub customer_no
{
	return record::Field->new("Customer_No"); 

}

 sub shipping_state
{
	return record::Field->new("Shipping_State"); 

}

 sub tax
{
	return record::Field->new("Tax"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub deal_name
{
	return record::Field->new("Deal_Name"); 

}

 sub billing_country
{
	return record::Field->new("Billing_Country"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub carrier
{
	return record::Field->new("Carrier"); 

}

 sub quote_name
{
	return record::Field->new("Quote_Name"); 

}

 sub status
{
	return record::Field->new("Status"); 

}

 sub sales_commission
{
	return record::Field->new("Sales_Commission"); 

}

 sub grand_total
{
	return record::Field->new("Grand_Total"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub due_date
{
	return record::Field->new("Due_Date"); 

}

 sub billing_street
{
	return record::Field->new("Billing_Street"); 

}

 sub adjustment
{
	return record::Field->new("Adjustment"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub terms_and_conditions
{
	return record::Field->new("Terms_and_Conditions"); 

}

 sub sub_total
{
	return record::Field->new("Sub_Total"); 

}

 sub billing_code
{
	return record::Field->new("Billing_Code"); 

}

 sub product_details
{
	return record::Field->new("Product_Details"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub contact_name
{
	return record::Field->new("Contact_Name"); 

}

 sub excise_duty
{
	return record::Field->new("Excise_Duty"); 

}

 sub shipping_city
{
	return record::Field->new("Shipping_City"); 

}

 sub shipping_country
{
	return record::Field->new("Shipping_Country"); 

}

 sub shipping_code
{
	return record::Field->new("Shipping_Code"); 

}

 sub billing_city
{
	return record::Field->new("Billing_City"); 

}

 sub so_number
{
	return record::Field->new("SO_Number"); 

}

 sub purchase_order
{
	return record::Field->new("Purchase_Order"); 

}

 sub billing_state
{
	return record::Field->new("Billing_State"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub pending
{
	return record::Field->new("Pending"); 

}

 sub shipping_street
{
	return record::Field->new("Shipping_Street"); 

}






package record::Field::Contacts;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub email
{
	return record::Field->new("Email"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub vendor_name
{
	return record::Field->new("Vendor_Name"); 

}

 sub mailing_zip
{
	return record::Field->new("Mailing_Zip"); 

}

 sub reports_to
{
	return record::Field->new("Reports_To"); 

}

 sub other_phone
{
	return record::Field->new("Other_Phone"); 

}

 sub mailing_state
{
	return record::Field->new("Mailing_State"); 

}

 sub twitter
{
	return record::Field->new("Twitter"); 

}

 sub other_zip
{
	return record::Field->new("Other_Zip"); 

}

 sub mailing_street
{
	return record::Field->new("Mailing_Street"); 

}

 sub other_state
{
	return record::Field->new("Other_State"); 

}

 sub salutation
{
	return record::Field->new("Salutation"); 

}

 sub other_country
{
	return record::Field->new("Other_Country"); 

}

 sub last_activity_time
{
	return record::Field->new("Last_Activity_Time"); 

}

 sub first_name
{
	return record::Field->new("First_Name"); 

}

 sub full_name
{
	return record::Field->new("Full_Name"); 

}

 sub asst_phone
{
	return record::Field->new("Asst_Phone"); 

}

 sub record_image
{
	return record::Field->new("Record_Image"); 

}

 sub department
{
	return record::Field->new("Department"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub skype_id
{
	return record::Field->new("Skype_ID"); 

}

 sub assistant
{
	return record::Field->new("Assistant"); 

}

 sub phone
{
	return record::Field->new("Phone"); 

}

 sub mailing_country
{
	return record::Field->new("Mailing_Country"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub email_opt_out
{
	return record::Field->new("Email_Opt_Out"); 

}

 sub reporting_to
{
	return record::Field->new("Reporting_To"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub date_of_birth
{
	return record::Field->new("Date_of_Birth"); 

}

 sub mailing_city
{
	return record::Field->new("Mailing_City"); 

}

 sub other_city
{
	return record::Field->new("Other_City"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub title
{
	return record::Field->new("Title"); 

}

 sub other_street
{
	return record::Field->new("Other_Street"); 

}

 sub mobile
{
	return record::Field->new("Mobile"); 

}

 sub territories
{
	return record::Field->new("Territories"); 

}

 sub home_phone
{
	return record::Field->new("Home_Phone"); 

}

 sub last_name
{
	return record::Field->new("Last_Name"); 

}

 sub lead_source
{
	return record::Field->new("Lead_Source"); 

}

 sub is_record_duplicate
{
	return record::Field->new("Is_Record_Duplicate"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub fax
{
	return record::Field->new("Fax"); 

}

 sub secondary_email
{
	return record::Field->new("Secondary_Email"); 

}






package record::Field::Solutions;
our @ISA = qw(record::Field);
 sub status
{
	return record::Field->new("Status"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub comments
{
	return record::Field->new("Comments"); 

}

 sub no_of_comments
{
	return record::Field->new("No_of_comments"); 

}

 sub product_name
{
	return record::Field->new("Product_Name"); 

}

 sub add_comment
{
	return record::Field->new("Add_Comment"); 

}

 sub solution_number
{
	return record::Field->new("Solution_Number"); 

}

 sub answer
{
	return record::Field->new("Answer"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub solution_title
{
	return record::Field->new("Solution_Title"); 

}

 sub published
{
	return record::Field->new("Published"); 

}

 sub question
{
	return record::Field->new("Question"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}






package record::Field::Events;
our @ISA = qw(record::Field);
 sub all_day
{
	return record::Field->new("All_day"); 

}

 sub owner
{
	return record::Field->new("Owner"); 

}

 sub check_in_state
{
	return record::Field->new("Check_In_State"); 

}

 sub check_in_address
{
	return record::Field->new("Check_In_Address"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub start_datetime
{
	return record::Field->new("Start_DateTime"); 

}

 sub latitude
{
	return record::Field->new("Latitude"); 

}

 sub participants
{
	return record::Field->new("Participants"); 

}

 sub event_title
{
	return record::Field->new("Event_Title"); 

}

 sub end_datetime
{
	return record::Field->new("End_DateTime"); 

}

 sub check_in_by
{
	return record::Field->new("Check_In_By"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub check_in_city
{
	return record::Field->new("Check_In_City"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub check_in_comment
{
	return record::Field->new("Check_In_Comment"); 

}

 sub remind_at
{
	return record::Field->new("Remind_At"); 

}

 sub who_id
{
	return record::Field->new("Who_Id"); 

}

 sub check_in_status
{
	return record::Field->new("Check_In_Status"); 

}

 sub check_in_country
{
	return record::Field->new("Check_In_Country"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub venue
{
	return record::Field->new("Venue"); 

}

 sub zip_code
{
	return record::Field->new("ZIP_Code"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub longitude
{
	return record::Field->new("Longitude"); 

}

 sub check_in_time
{
	return record::Field->new("Check_In_Time"); 

}

 sub recurring_activity
{
	return record::Field->new("Recurring_Activity"); 

}

 sub what_id
{
	return record::Field->new("What_Id"); 

}

 sub check_in_sub_locality
{
	return record::Field->new("Check_In_Sub_Locality"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}






package record::Field::Purchase_Orders;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub discount
{
	return record::Field->new("Discount"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub vendor_name
{
	return record::Field->new("Vendor_Name"); 

}

 sub shipping_state
{
	return record::Field->new("Shipping_State"); 

}

 sub tax
{
	return record::Field->new("Tax"); 

}

 sub po_date
{
	return record::Field->new("PO_Date"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub billing_country
{
	return record::Field->new("Billing_Country"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub carrier
{
	return record::Field->new("Carrier"); 

}

 sub status
{
	return record::Field->new("Status"); 

}

 sub grand_total
{
	return record::Field->new("Grand_Total"); 

}

 sub sales_commission
{
	return record::Field->new("Sales_Commission"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub po_number
{
	return record::Field->new("PO_Number"); 

}

 sub due_date
{
	return record::Field->new("Due_Date"); 

}

 sub billing_street
{
	return record::Field->new("Billing_Street"); 

}

 sub adjustment
{
	return record::Field->new("Adjustment"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub terms_and_conditions
{
	return record::Field->new("Terms_and_Conditions"); 

}

 sub sub_total
{
	return record::Field->new("Sub_Total"); 

}

 sub billing_code
{
	return record::Field->new("Billing_Code"); 

}

 sub product_details
{
	return record::Field->new("Product_Details"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub tracking_number
{
	return record::Field->new("Tracking_Number"); 

}

 sub contact_name
{
	return record::Field->new("Contact_Name"); 

}

 sub excise_duty
{
	return record::Field->new("Excise_Duty"); 

}

 sub shipping_city
{
	return record::Field->new("Shipping_City"); 

}

 sub shipping_country
{
	return record::Field->new("Shipping_Country"); 

}

 sub shipping_code
{
	return record::Field->new("Shipping_Code"); 

}

 sub billing_city
{
	return record::Field->new("Billing_City"); 

}

 sub requisition_no
{
	return record::Field->new("Requisition_No"); 

}

 sub billing_state
{
	return record::Field->new("Billing_State"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub shipping_street
{
	return record::Field->new("Shipping_Street"); 

}






package record::Field::Accounts;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub ownership
{
	return record::Field->new("Ownership"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub account_type
{
	return record::Field->new("Account_Type"); 

}

 sub rating
{
	return record::Field->new("Rating"); 

}

 sub sic_code
{
	return record::Field->new("SIC_Code"); 

}

 sub shipping_state
{
	return record::Field->new("Shipping_State"); 

}

 sub website
{
	return record::Field->new("Website"); 

}

 sub employees
{
	return record::Field->new("Employees"); 

}

 sub last_activity_time
{
	return record::Field->new("Last_Activity_Time"); 

}

 sub industry
{
	return record::Field->new("Industry"); 

}

 sub record_image
{
	return record::Field->new("Record_Image"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub account_site
{
	return record::Field->new("Account_Site"); 

}

 sub phone
{
	return record::Field->new("Phone"); 

}

 sub billing_country
{
	return record::Field->new("Billing_Country"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub account_number
{
	return record::Field->new("Account_Number"); 

}

 sub ticker_symbol
{
	return record::Field->new("Ticker_Symbol"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub billing_street
{
	return record::Field->new("Billing_Street"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub billing_code
{
	return record::Field->new("Billing_Code"); 

}

 sub territories
{
	return record::Field->new("Territories"); 

}

 sub parent_account
{
	return record::Field->new("Parent_Account"); 

}

 sub shipping_city
{
	return record::Field->new("Shipping_City"); 

}

 sub shipping_country
{
	return record::Field->new("Shipping_Country"); 

}

 sub shipping_code
{
	return record::Field->new("Shipping_Code"); 

}

 sub billing_city
{
	return record::Field->new("Billing_City"); 

}

 sub billing_state
{
	return record::Field->new("Billing_State"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub fax
{
	return record::Field->new("Fax"); 

}

 sub annual_revenue
{
	return record::Field->new("Annual_Revenue"); 

}

 sub shipping_street
{
	return record::Field->new("Shipping_Street"); 

}






package record::Field::Cases;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub email
{
	return record::Field->new("Email"); 

}

 sub description
{
	return record::Field->new("Description"); 

}

 sub internal_comments
{
	return record::Field->new("Internal_Comments"); 

}

 sub no_of_comments
{
	return record::Field->new("No_of_comments"); 

}

 sub reported_by
{
	return record::Field->new("Reported_By"); 

}

 sub case_number
{
	return record::Field->new("Case_Number"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub deal_name
{
	return record::Field->new("Deal_Name"); 

}

 sub phone
{
	return record::Field->new("Phone"); 

}

 sub account_name
{
	return record::Field->new("Account_Name"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub solution
{
	return record::Field->new("Solution"); 

}

 sub status
{
	return record::Field->new("Status"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub priority
{
	return record::Field->new("Priority"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub comments
{
	return record::Field->new("Comments"); 

}

 sub product_name
{
	return record::Field->new("Product_Name"); 

}

 sub add_comment
{
	return record::Field->new("Add_Comment"); 

}

 sub case_origin
{
	return record::Field->new("Case_Origin"); 

}

 sub subject
{
	return record::Field->new("Subject"); 

}

 sub case_reason
{
	return record::Field->new("Case_Reason"); 

}

 sub type
{
	return record::Field->new("Type"); 

}

 sub is_record_duplicate
{
	return record::Field->new("Is_Record_Duplicate"); 

}

 sub tag
{
	return record::Field->new("Tag"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub related_to
{
	return record::Field->new("Related_To"); 

}






package record::Field::Notes;
our @ISA = qw(record::Field);
 sub owner
{
	return record::Field->new("Owner"); 

}

 sub modified_by
{
	return record::Field->new("Modified_By"); 

}

 sub modified_time
{
	return record::Field->new("Modified_Time"); 

}

 sub created_time
{
	return record::Field->new("Created_Time"); 

}

 sub parent_id
{
	return record::Field->new("Parent_Id"); 

}

 sub id
{
	return record::Field->new("id"); 

}

 sub created_by
{
	return record::Field->new("Created_By"); 

}

 sub note_title
{
	return record::Field->new("Note_Title"); 

}

 sub note_content
{
	return record::Field->new("Note_Content"); 

}




1;