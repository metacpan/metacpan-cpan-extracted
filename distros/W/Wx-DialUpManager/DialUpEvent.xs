MODULE=Wx PACKAGE=Wx::DialUpEvent

wxDialUpEvent*
wxDialUpEvent::new(isConnected, isOwnEvent)
    bool isConnected
    bool isOwnEvent
    CODE:
        RETVAL = new wxDialUpEvent(isConnected, isOwnEvent);
    OUTPUT:
        RETVAL

bool
wxDialUpEvent::IsConnectedEvent()

bool
wxDialUpEvent::IsOwnEvent()
