
class wxPliTreeListCtrl:public wxTreeListCtrl
{
    WXPLI_DECLARE_DYNAMIC_CLASS( wxPliTreeListCtrl );
    WXPLI_DECLARE_V_CBACK();
public:
    WXPLI_DEFAULT_CONSTRUCTOR( wxPliTreeListCtrl, "Wx::TreeListCtrl", true );
    WXPLI_CONSTRUCTOR_7( wxPliTreeListCtrl, "Wx::TreeListCtrl", true,
                         wxWindow*, wxWindowID, const wxPoint&,
                         const wxSize&, long, const wxValidator&,
                         const wxString& );

    virtual wxString OnGetItemText( wxTreeItemData* item, long column ) const;
    int OnCompareItems( const wxTreeItemId& item1, const wxTreeItemId& item2 );
    int OnCompareItems( const wxTreeItemId& item1, const wxTreeItemId& item2, int col );
    
};

wxString wxPliTreeListCtrl::OnGetItemText( wxTreeItemData* item, long column ) const
{
    dTHX;
    if( wxPliVirtualCallback_FindCallback( aTHX_ &m_callback, "OnGetItemText" ) )
    {
        SV* t1 = wxPli_non_object_2_sv( aTHX_ newSViv( 0 ), (void*)&item, "Wx::TreeItemData" );
        
        SV* ret = wxPliVirtualCallback_CallCallback( aTHX_ &m_callback, G_SCALAR,
                                                     "Sl", t1, column );
        
        sv_setiv( SvRV( t1 ), 0 );
        wxString val;
        WXSTRING_INPUT( val, char*, ret );
        SvREFCNT_dec( ret );
        SvREFCNT_dec( t1 );
        
        return val;
    }

    return wxTreeListCtrl::OnGetItemText( item, column );
}

int wxPliTreeListCtrl::OnCompareItems( const wxTreeItemId& item1,
                                       const wxTreeItemId& item2 )
{
    dTHX;
    if( wxPliVirtualCallback_FindCallback( aTHX_ &m_callback, "OnCompareItems" ) )
    {
        SV* t1 = wxPli_non_object_2_sv( aTHX_ newSViv( 0 ),
                                        (void*)&item1, "Wx::TreeItemId" );
        SV* t2 = wxPli_non_object_2_sv( aTHX_ newSViv( 0 ),
                                        (void*)&item2, "Wx::TreeItemId" );
        SV* ret = wxPliVirtualCallback_CallCallback
            ( aTHX_ &m_callback, G_SCALAR, "SS", t1, t2 );

        sv_setiv( SvRV( t1 ), 0 );
        sv_setiv( SvRV( t2 ), 0 );
        int val = SvIV( ret );
        SvREFCNT_dec( ret );
        SvREFCNT_dec( t1 );
        SvREFCNT_dec( t2 );

        return val;
    }
    else
        return wxTreeListCtrl::OnCompareItems( item1, item2 );
}

int wxPliTreeListCtrl::OnCompareItems( const wxTreeItemId& item1,
                                       const wxTreeItemId& item2,
                                       int column)
{
    dTHX;
    if( wxPliVirtualCallback_FindCallback( aTHX_ &m_callback, "OnCompareItems" ) )
    {
        SV* t1 = wxPli_non_object_2_sv( aTHX_ newSViv( 0 ),
                                        (void*)&item1, "Wx::TreeItemId" );
        SV* t2 = wxPli_non_object_2_sv( aTHX_ newSViv( 0 ),
                                        (void*)&item2, "Wx::TreeItemId" );
        SV* ret = wxPliVirtualCallback_CallCallback
            ( aTHX_ &m_callback, G_SCALAR, "SSi", t1, t2, column );

        sv_setiv( SvRV( t1 ), 0 );
        sv_setiv( SvRV( t2 ), 0 );
        int val = SvIV( ret );
        SvREFCNT_dec( ret );
        SvREFCNT_dec( t1 );
        SvREFCNT_dec( t2 );

        return val;
    }
    else
        return wxTreeListCtrl::OnCompareItems( item1, item2, column );
}

WXPLI_IMPLEMENT_DYNAMIC_CLASS( wxPliTreeListCtrl, wxTreeListCtrl );
