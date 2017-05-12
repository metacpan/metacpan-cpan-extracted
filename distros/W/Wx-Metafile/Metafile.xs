#include <cpp/wxapi.h>
#include <wx/metafile.h>

MODULE=Wx__Metafile PACKAGE=Wx::Metafile

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

wxMetafile*
wxMetafile::new( name )
    wxString name
    CODE:
    	RETVAL = new wxMetafile( name );
        // workaround for wxWindows bug
        if( !RETVAL->GetHENHMETAFILE() )
        {
            WXHANDLE mf = (WXHANDLE)GetEnhMetaFile( name.c_str() );
            RETVAL->SetHENHMETAFILE( mf );
        }       
    OUTPUT:
    	RETVAL

bool
wxMetafile::Ok()
	CODE:
		RETVAL = THIS->Ok();
	OUTPUT:
		RETVAL

bool
wxMetafile::Play( dc, rectBound = (wxRect *)NULL)
    wxDC* dc
    wxRect* rectBound
	CODE:
		RETVAL = THIS->Play( dc, rectBound );
	OUTPUT:
		RETVAL
		
wxSize*
wxMetafile::GetSize()
  CODE:
    RETVAL = new wxSize( THIS->GetSize() );
  OUTPUT:
    RETVAL

int
wxMetafile::GetWidth()

int
wxMetafile::GetHeight()

