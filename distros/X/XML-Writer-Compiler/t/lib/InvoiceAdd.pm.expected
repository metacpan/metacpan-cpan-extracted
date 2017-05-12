package t::lib::InvoiceAdd;
use Moose;

with qw(XML::Writer::Compiler::AutoPackage);

use Data::Dumper;
use HTML::Element::Library;

use XML::Element;

has 'data' => (
    is      => 'rw',
    trigger => \&maybe_morph
);
has 'writer' => ( is => 'rw', isa => 'XML::Writer' );
has 'string' => ( is => 'rw', isa => 'XML::Writer::String' );

sub _tag_QBXML {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw() );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( QBXML => @$attr );

    $self->_tag_QBXMLMsgsRq;
    $self->writer->endTag;
}

sub _tag_QBXMLMsgsRq {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw() );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( QBXMLMsgsRq => @$attr );

    $self->_tag_InvoiceAddRq;
    $self->writer->endTag;
}

sub _tag_InvoiceAddRq {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw() );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InvoiceAddRq => @$attr );

    $self->_tag_InvoiceAdd;
    $self->_tag_IncludeRetElement;
    $self->writer->endTag;
}

sub _tag_InvoiceAdd {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw() );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InvoiceAdd => @$attr );

    $self->_tag_CustomerRef;
    $self->_tag_ClassRef;
    $self->_tag_ARAccountRef;
    $self->_tag_TemplateRef;
    $self->_tag_TxnDate;
    $self->_tag_RefNumber;
    $self->_tag_BillAddress;
    $self->_tag_ShipAddress;
    $self->_tag_IsPending;
    $self->_tag_IsFinanceCharge;
    $self->_tag_PONumber;
    $self->_tag_TermsRef;
    $self->_tag_DueDate;
    $self->_tag_SalesRepRef;
    $self->_tag_FOB;
    $self->_tag_ShipDate;
    $self->_tag_ShipMethodRef;
    $self->_tag_ItemSalesTaxRef;
    $self->_tag_Memo;
    $self->_tag_CustomerMsgRef;
    $self->_tag_IsToBePrinted;
    $self->_tag_IsToBeEmailed;
    $self->_tag_CustomerSalesTaxCodeRef;
    $self->_tag_Other;
    $self->_tag_ExchangeRate;
    $self->_tag_ExternalGUID;
    $self->_tag_LinkToTxnID;
    $self->_tag_SetCredit;
    $self->_tag_InvoiceLineAdd;
    $self->_tag_InvoiceLineGroupAdd;
    $self->writer->endTag;
}

sub _tag_CustomerRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( CustomerRef => @$attr );

    $self->_tag_CustomerRef_ListID;
    $self->_tag_CustomerRef_FullName;
    $self->writer->endTag;
}

sub _tag_CustomerRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_CustomerRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ClassRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ClassRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ClassRef => @$attr );

    $self->_tag_ClassRef_ListID;
    $self->_tag_ClassRef_FullName;
    $self->writer->endTag;
}

sub _tag_ClassRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ClassRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ClassRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ClassRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ARAccountRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ARAccountRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ARAccountRef => @$attr );

    $self->_tag_ARAccountRef_ListID;
    $self->_tag_ARAccountRef_FullName;
    $self->writer->endTag;
}

sub _tag_ARAccountRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ARAccountRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ARAccountRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ARAccountRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_TemplateRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TemplateRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( TemplateRef => @$attr );

    $self->_tag_TemplateRef_ListID;
    $self->_tag_TemplateRef_FullName;
    $self->writer->endTag;
}

sub _tag_TemplateRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TemplateRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_TemplateRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TemplateRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_TxnDate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TxnDate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( TxnDate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_RefNumber {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(RefNumber) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( RefNumber => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( BillAddress => @$attr );

    $self->_tag_BillAddress_Addr1;
    $self->_tag_BillAddress_Addr2;
    $self->_tag_BillAddress_Addr3;
    $self->_tag_BillAddress_Addr4;
    $self->_tag_BillAddress_Addr5;
    $self->_tag_BillAddress_City;
    $self->_tag_BillAddress_State;
    $self->_tag_BillAddress_PostalCode;
    $self->_tag_BillAddress_Country;
    $self->_tag_BillAddress_Note;
    $self->writer->endTag;
}

sub _tag_BillAddress_Addr1 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Addr1) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr1 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Addr2 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Addr2) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr2 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Addr3 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Addr3) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr3 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Addr4 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Addr4) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr4 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Addr5 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Addr5) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr5 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_City {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress City) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( City => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_State {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress State) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( State => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_PostalCode {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress PostalCode) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( PostalCode => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Country {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Country) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Country => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_BillAddress_Note {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(BillAddress Note) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Note => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ShipAddress => @$attr );

    $self->_tag_ShipAddress_Addr1;
    $self->_tag_ShipAddress_Addr2;
    $self->_tag_ShipAddress_Addr3;
    $self->_tag_ShipAddress_Addr4;
    $self->_tag_ShipAddress_Addr5;
    $self->_tag_ShipAddress_City;
    $self->_tag_ShipAddress_State;
    $self->_tag_ShipAddress_PostalCode;
    $self->_tag_ShipAddress_Country;
    $self->_tag_ShipAddress_Note;
    $self->writer->endTag;
}

sub _tag_ShipAddress_Addr1 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Addr1) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr1 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Addr2 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Addr2) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr2 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Addr3 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Addr3) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr3 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Addr4 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Addr4) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr4 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Addr5 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Addr5) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Addr5 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_City {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress City) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( City => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_State {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress State) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( State => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_PostalCode {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress PostalCode) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( PostalCode => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Country {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Country) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Country => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipAddress_Note {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipAddress Note) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Note => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_IsPending {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(IsPending) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( IsPending => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_IsFinanceCharge {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(IsFinanceCharge) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( IsFinanceCharge => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_PONumber {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(PONumber) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( PONumber => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_TermsRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TermsRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( TermsRef => @$attr );

    $self->_tag_TermsRef_ListID;
    $self->_tag_TermsRef_FullName;
    $self->writer->endTag;
}

sub _tag_TermsRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TermsRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_TermsRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(TermsRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_DueDate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(DueDate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DueDate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_SalesRepRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SalesRepRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( SalesRepRef => @$attr );

    $self->_tag_SalesRepRef_ListID;
    $self->_tag_SalesRepRef_FullName;
    $self->writer->endTag;
}

sub _tag_SalesRepRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SalesRepRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_SalesRepRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SalesRepRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_FOB {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(FOB) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FOB => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipDate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipDate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ShipDate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipMethodRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipMethodRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ShipMethodRef => @$attr );

    $self->_tag_ShipMethodRef_ListID;
    $self->_tag_ShipMethodRef_FullName;
    $self->writer->endTag;
}

sub _tag_ShipMethodRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipMethodRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ShipMethodRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ShipMethodRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ItemSalesTaxRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ItemSalesTaxRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ItemSalesTaxRef => @$attr );

    $self->_tag_ItemSalesTaxRef_ListID;
    $self->_tag_ItemSalesTaxRef_FullName;
    $self->writer->endTag;
}

sub _tag_ItemSalesTaxRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ItemSalesTaxRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ItemSalesTaxRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ItemSalesTaxRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_Memo {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(Memo) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Memo => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_CustomerMsgRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerMsgRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( CustomerMsgRef => @$attr );

    $self->_tag_CustomerMsgRef_ListID;
    $self->_tag_CustomerMsgRef_FullName;
    $self->writer->endTag;
}

sub _tag_CustomerMsgRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerMsgRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_CustomerMsgRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerMsgRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_IsToBePrinted {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(IsToBePrinted) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( IsToBePrinted => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_IsToBeEmailed {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(IsToBeEmailed) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( IsToBeEmailed => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_CustomerSalesTaxCodeRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerSalesTaxCodeRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( CustomerSalesTaxCodeRef => @$attr );

    $self->_tag_CustomerSalesTaxCodeRef_ListID;
    $self->_tag_CustomerSalesTaxCodeRef_FullName;
    $self->writer->endTag;
}

sub _tag_CustomerSalesTaxCodeRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(CustomerSalesTaxCodeRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_CustomerSalesTaxCodeRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(CustomerSalesTaxCodeRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_Other {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(Other) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Other => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ExchangeRate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ExchangeRate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ExchangeRate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_ExternalGUID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(ExternalGUID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ExternalGUID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_LinkToTxnID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(LinkToTxnID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( LinkToTxnID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_SetCredit {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SetCredit) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( SetCredit => @$attr );

    $self->_tag_SetCredit_CreditTxnID;
    $self->_tag_SetCredit_AppliedAmount;
    $self->_tag_SetCredit_Override;
    $self->writer->endTag;
}

sub _tag_SetCredit_CreditTxnID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SetCredit CreditTxnID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( CreditTxnID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_SetCredit_AppliedAmount {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SetCredit AppliedAmount) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( AppliedAmount => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_SetCredit_Override {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(SetCredit Override) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Override => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InvoiceLineAdd => @$attr );

    $self->_tag_InvoiceLineAdd_ItemRef;
    $self->_tag_InvoiceLineAdd_Desc;
    $self->_tag_InvoiceLineAdd_Quantity;
    $self->_tag_InvoiceLineAdd_UnitOfMeasure;
    $self->_tag_InvoiceLineAdd_Rate;
    $self->_tag_InvoiceLineAdd_RatePercent;
    $self->_tag_InvoiceLineAdd_PriceLevelRef;
    $self->_tag_InvoiceLineAdd_ClassRef;
    $self->_tag_InvoiceLineAdd_Amount;
    $self->_tag_InvoiceLineAdd_InventorySiteRef;
    $self->_tag_InvoiceLineAdd_ServiceDate;
    $self->_tag_InvoiceLineAdd_SalesTaxCodeRef;
    $self->_tag_InvoiceLineAdd_OverrideItemAccountRef;
    $self->_tag_InvoiceLineAdd_Other1;
    $self->_tag_InvoiceLineAdd_Other2;
    $self->_tag_InvoiceLineAdd_LinkToTxn;
    $self->_tag_InvoiceLineAdd_DataExt;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ItemRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ItemRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ItemRef => @$attr );

    $self->_tag_InvoiceLineAdd_ItemRef_ListID;
    $self->_tag_InvoiceLineAdd_ItemRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ItemRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ItemRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ItemRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ItemRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Desc {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Desc) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Desc => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Quantity {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Quantity) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Quantity => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_UnitOfMeasure {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd UnitOfMeasure) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( UnitOfMeasure => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Rate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Rate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Rate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_RatePercent {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd RatePercent) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( RatePercent => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_PriceLevelRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd PriceLevelRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( PriceLevelRef => @$attr );

    $self->_tag_InvoiceLineAdd_PriceLevelRef_ListID;
    $self->_tag_InvoiceLineAdd_PriceLevelRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_PriceLevelRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd PriceLevelRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_PriceLevelRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd PriceLevelRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ClassRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ClassRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ClassRef => @$attr );

    $self->_tag_InvoiceLineAdd_ClassRef_ListID;
    $self->_tag_InvoiceLineAdd_ClassRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ClassRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ClassRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ClassRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd ClassRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Amount {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Amount) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Amount => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_InventorySiteRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd InventorySiteRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InventorySiteRef => @$attr );

    $self->_tag_InvoiceLineAdd_InventorySiteRef_ListID;
    $self->_tag_InvoiceLineAdd_InventorySiteRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_InventorySiteRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd InventorySiteRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_InventorySiteRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd InventorySiteRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_ServiceDate {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd ServiceDate) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ServiceDate => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_SalesTaxCodeRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd SalesTaxCodeRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( SalesTaxCodeRef => @$attr );

    $self->_tag_InvoiceLineAdd_SalesTaxCodeRef_ListID;
    $self->_tag_InvoiceLineAdd_SalesTaxCodeRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_SalesTaxCodeRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd SalesTaxCodeRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_SalesTaxCodeRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd SalesTaxCodeRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_OverrideItemAccountRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd OverrideItemAccountRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( OverrideItemAccountRef => @$attr );

    $self->_tag_InvoiceLineAdd_OverrideItemAccountRef_ListID;
    $self->_tag_InvoiceLineAdd_OverrideItemAccountRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_OverrideItemAccountRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd OverrideItemAccountRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_OverrideItemAccountRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd OverrideItemAccountRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Other1 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Other1) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Other1 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_Other2 {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd Other2) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Other2 => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_LinkToTxn {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd LinkToTxn) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( LinkToTxn => @$attr );

    $self->_tag_InvoiceLineAdd_LinkToTxn_TxnID;
    $self->_tag_InvoiceLineAdd_LinkToTxn_TxnLineID;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_LinkToTxn_TxnID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd LinkToTxn TxnID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( TxnID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_LinkToTxn_TxnLineID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd LinkToTxn TxnLineID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( TxnLineID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_DataExt {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd DataExt) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExt => @$attr );

    $self->_tag_InvoiceLineAdd_DataExt_OwnerID;
    $self->_tag_InvoiceLineAdd_DataExt_DataExtName;
    $self->_tag_InvoiceLineAdd_DataExt_DataExtValue;
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_DataExt_OwnerID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineAdd DataExt OwnerID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( OwnerID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_DataExt_DataExtName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd DataExt DataExtName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExtName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineAdd_DataExt_DataExtValue {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineAdd DataExt DataExtValue) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExtValue => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineGroupAdd) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InvoiceLineGroupAdd => @$attr );

    $self->_tag_InvoiceLineGroupAdd_ItemGroupRef;
    $self->_tag_InvoiceLineGroupAdd_Quantity;
    $self->_tag_InvoiceLineGroupAdd_UnitOfMeasure;
    $self->_tag_InvoiceLineGroupAdd_InventorySiteRef;
    $self->_tag_InvoiceLineGroupAdd_DataExt;
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_ItemGroupRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd ItemGroupRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ItemGroupRef => @$attr );

    $self->_tag_InvoiceLineGroupAdd_ItemGroupRef_ListID;
    $self->_tag_InvoiceLineGroupAdd_ItemGroupRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_ItemGroupRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd ItemGroupRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_ItemGroupRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd ItemGroupRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_Quantity {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineGroupAdd Quantity) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( Quantity => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_UnitOfMeasure {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd UnitOfMeasure) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( UnitOfMeasure => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_InventorySiteRef {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd InventorySiteRef) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( InventorySiteRef => @$attr );

    $self->_tag_InvoiceLineGroupAdd_InventorySiteRef_ListID;
    $self->_tag_InvoiceLineGroupAdd_InventorySiteRef_FullName;
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_InventorySiteRef_ListID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd InventorySiteRef ListID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( ListID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_InventorySiteRef_FullName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd InventorySiteRef FullName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( FullName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_DataExt {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw(InvoiceLineGroupAdd DataExt) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExt => @$attr );

    $self->_tag_InvoiceLineGroupAdd_DataExt_OwnerID;
    $self->_tag_InvoiceLineGroupAdd_DataExt_DataExtName;
    $self->_tag_InvoiceLineGroupAdd_DataExt_DataExtValue;
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_DataExt_OwnerID {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd DataExt OwnerID) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( OwnerID => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_DataExt_DataExtName {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd DataExt DataExtName) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExtName => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_InvoiceLineGroupAdd_DataExt_DataExtValue {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata =
      $self->DIVE( $root, qw(InvoiceLineGroupAdd DataExt DataExtValue) );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( DataExtValue => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub _tag_IncludeRetElement {
    my ($self) = @_;

    my $root = $self->data;

    my $elementdata = $self->DIVE( $root, qw() );

    my ( $attr, $data ) = $self->EXTRACT($elementdata);
    $self->writer->startTag( IncludeRetElement => @$attr );

    $self->writer->characters($data);
    $self->writer->endTag;
}

sub xml {
    my ($self) = @_;
    my $method = '_tag_QBXML';
    $self->$method;
    $self->writer->end;
    $self;
}

1;
