import com.sun.jdi.VMDisconnectedException;
import com.sun.jdi.event.Event;
import com.sun.jdi.event.MethodEntryEvent;
import com.sun.jdi.event.MethodExitEvent;
import com.sun.jdi.event.VMStartEvent;
import com.sun.jdi.event.EventIterator;
import com.sun.jdi.event.EventQueue;
import com.sun.jdi.event.EventSet;

/**
 *  This class supports {@link Seq}.  Its constructor spawns a thread to
 *  poll the virtual machine event queue.  When an event is found, it
 *  removes the event from the queue and dispatches it the calling Seq
 *  instance.
 */
public class SeqEventHandler implements Runnable {
    Seq boss;
    boolean connected = true;

    /**
     *  Spawns a thread to tell the supplied {@link Seq} instance when
     *  virtual machine start, method entry, and exit events need to be
     *  handled.
     */
    public SeqEventHandler(Seq boss) {
        this.boss     = boss;
        Thread thread = new Thread(this, "Sequencer Event Thread");
        thread.start();
    }

    /**
     *  Continually polls the virtual machine event queue, removing
     *  and dispatching events to its controlling {@link Seq} instance.
     */
    public void run() {
        EventQueue queue = boss.getVM().eventQueue();
        while (connected) {
            try {
                EventSet      eventSet   = queue.remove();
                EventIterator it         = eventSet.eventIterator();
                while (it.hasNext()) {
                    handleEvent(it.nextEvent());
                }
            }
            catch (InterruptedException ie) { }
            catch (VMDisconnectedException vmde) {
                connected = false;
            }
        }
    }

    // dispatches events of interest to the caller
    private void handleEvent(Event event){
        if      (event instanceof MethodEntryEvent) {
            boss.methodEntryEvent((MethodEntryEvent)event);
        }
        else if (event instanceof MethodExitEvent) {
            boss.methodExitEvent((MethodExitEvent)event);
        }
        else if (event instanceof VMStartEvent) {
            boss.vmStartEvent(event);
        }
    }
}
