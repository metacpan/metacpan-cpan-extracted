// The following classes are from the Java Debugger Platform Architecture jpda
// The ship with SDK 1.3+ in tools.jar
import com.sun.jdi.VirtualMachine;
import com.sun.jdi.Bootstrap;
import com.sun.jdi.Method;
import com.sun.jdi.ObjectReference;
import com.sun.jdi.ReferenceType;
import com.sun.jdi.ThreadReference;
import com.sun.jdi.StackFrame;
import com.sun.jdi.connect.Connector;
import com.sun.jdi.connect.LaunchingConnector;

import com.sun.jdi.event.Event;
import com.sun.jdi.event.MethodEntryEvent;
import com.sun.jdi.event.MethodExitEvent;
import com.sun.jdi.request.EventRequestManager;
import com.sun.jdi.request.MethodEntryRequest;
import com.sun.jdi.request.MethodExitRequest;

// IO classes
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.io.IOException;
import java.io.PrintStream;

// util classes
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 *  This class produces outlines of call sequences for other Java programs
 *  by using debugger hooks.  It is useful for building UML sequence diagrams.
 *  See the documentation for {@link #main} for usage.  See UML::Sequence
 *  on CPAN for Perl scripts to make the diagrams.  In particular, see
 *  genericseq.pl and UML::Sequence::JavaSeq.pm.
 */
public class Seq {
    VirtualMachine      vm;
    Process             process;
    SeqEventHandler     handler;
    EventRequestManager requestManager;
    MethodEntryRequest  initialEntryRequest;
    MethodEntryRequest  regularEntryRequest;
    MethodExitRequest   regularExitRequest;
    static final int    INITIAL_EVENT_STATUS    = 1;
    static final int    REGULAR_EVENT_STATUS    = 2;
    int                 eventStatus             = INITIAL_EVENT_STATUS;
    int                 indent                  = 0;
    boolean             everythingIsInteresting = false;
    HashMap             interestingMethods;
    ArrayList           interestingClasses;
    PrintStream         outputStream;
    String              excludeFilter;

    // objects is keyed by object hash code storing object's number.
    // Numbers are per class and are issued sequentially from 1 during
    // constructor processing.
    HashMap             objects                 = new HashMap();
    // nextObjectNumber is keyed by class name storing the most recently
    // used number.  Preincrement this to use it.
    HashMap             nextObjectNumber        = new HashMap();


    /**
     *  Most callers will use only this method.
     *  Builds a connection to the debugger, launches the supplied program,
     *  directs production outpuer.
     *  @param interestingMethodsFile name of a file listing methods or classes
     *                                you want to see in your output
     *  see <a href="Hello.methods">Hello.methods</a> for an example with
     *  documenation
     *  @param outputFileName name of a file where output will go, standard out
     *                        can't be used, since the program you are tracing
     *                        might be using it
     *  @param args the java class to invoke and any command line arguments
     *              it needs
     */
    public Seq(
        String   interestingMethodsFile,
        String   outputFileName,
        String[] args
    ) throws Exception {
        setupInterestingThings(interestingMethodsFile);
        openOutput(outputFileName);

        LaunchingConnector  conn  = findConnector();
        vm                        = conn.launch(getArgsMap(conn, args));
        process                   = vm.process();
        dumpProcessOutput(process);
        handler                   = new SeqEventHandler(this);
        requestManager            = vm.eventRequestManager();
        initialEntryRequest       = requestManager.createMethodEntryRequest();

        // wait for a method in the starting class
        initialEntryRequest.addClassFilter(args[0]);
        initialEntryRequest.enable();
    }

    private void setupInterestingThings(String file) throws IOException {
        interestingMethods       = new HashMap();
        HashMap        classHash = new HashMap();
        interestingClasses       = new ArrayList();
        FileReader     fr        = new FileReader(file);
        BufferedReader reader    = new BufferedReader(fr);

        Integer dummyInt         = new Integer(1);
        String line;
        while ((line = reader.readLine()) != null) {
            // skip comments and blanks
            if (line.startsWith("#") || line.trim().length() == 0) {
                continue;
            }
            // turn off method name checking if file has an 'ALL' line
            else if (line.equals("ALL")) {
                everythingIsInteresting = true;
            }
            // assume everything else is a method/class name
            // There is no harm in putting extraneous things into the
            // interestingMethods hash.  If everythingIsInteresting,
            // the hash will be completely ignored.  In other cases,
            // actual methods are looked up in the hash, if they are there
            // they print, otherwise not.  No one cares if extra entries
            // are there.
            else {
                interestingMethods.put(line,                dummyInt);
                classHash         .put(grabClassName(line), dummyInt);
            }
        }
        reader.close();
        fr.close();

        // turn classHash into a List, this could be folded into 
        // switchToRegularStatus
        Set      classKeys = classHash.keySet();
        Iterator iter      = classKeys.iterator();
        while (iter.hasNext()) {
            interestingClasses.add(iter.next());
        }
    }

    private String grabClassName(String line) {
        // look for opening (
        int parenPos = line.indexOf('(');
        // there is one, this is a signature
        if (parenPos >= 0) {
            // remove arg list
            String methodName = line.substring(0, parenPos);
            // look for last dot
            int lastDot = methodName.lastIndexOf('.');
            // there is one, there is a package name
            if (lastDot >= 0) {
                // remove the method name, leaving all packages and the class
                String className = methodName.substring(0, lastDot);
                return className;
            }
            else {
                return methodName;  // unlikely
            }
        }
        // no opening paren, the whole line is a class name
        else {
            return line;
        }
    }

    private void openOutput(String file) throws IOException {
        FileOutputStream fos = new FileOutputStream(file);
        outputStream         = new PrintStream(fos);
    }

    public VirtualMachine getVM() { return vm; }

    // sets the main attribute of the connection argument hash to the
    // name of the program to trace, concatenated with its arguments,
    // the list is delimited by spaces
    private Map getArgsMap(Connector conn, String[] args) {
        Map                argsMap = conn.defaultArguments();
        Connector.Argument mainArg = (Connector.Argument)argsMap.get("main");

        StringBuffer       sb      = new StringBuffer();

        int argCount = args.length;
        int maxArg   = argCount - 1;
        for (int i = 0; i < argCount; i++) {
            sb.append(args[i]);
            if (i < maxArg) {
                sb.append(" ");
            }
        }

        mainArg.setValue(sb.toString());
        return argsMap;
    }

    // gains a valid LaunchingConnector reference by a name lookup
    public LaunchingConnector findConnector() {
        List     connectors = Bootstrap.virtualMachineManager().allConnectors();
        Iterator iter       = connectors.iterator();
        while (iter.hasNext()) {
            Connector conn = (Connector)iter.next();
            if (conn.name().equals("com.sun.jdi.CommandLineLaunch")) {
                return (LaunchingConnector)conn;
            }
        }
        return null;
    }

    // when a method exits, adjusts the depth of the call sequence
    // and restarts the virtual machine
    public void methodExitEvent(MethodExitEvent event) {
        indent--;
        vm.resume();
    }

    // the virtual machine is up, ask it to start
    public void vmStartEvent(Event event) {
        vm.resume();
    }

    // If this is the first entry event, swithToRegularStatus.
    // In all cases, print the method signature, if the
    // user is interested in it.  Then increment the call sequence depth
    // and restart the virtual machine.
    public void methodEntryEvent(MethodEntryEvent event) {
        if (eventStatus == INITIAL_EVENT_STATUS) {
            switchToRegularStatus();
        }

        Method method     = event.method();
        String signature  = grabSignature(method);
        String objectName = grabInstanceName(event, method);

        Object includeIt  = interestingMethods.get(signature);

        if (everythingIsInteresting || includeIt != null) {
            outputStream.println(formIndentString() + objectName + signature);
        }

        indent++;
        vm.resume();
    }

    // Returns the manufactured name of the instance which is operative
    // in the current method (the one called this in that method).
    // Maintains the list of objects by number using two hashes:
    // objects and nextObjectNumber.  For example the second Roller object
    // used in a program will yield roller2.
    private String grabInstanceName(MethodEntryEvent event, Method method) {
        ObjectReference thisRef    = grabStackTopReference(event);

        if (thisRef == null) { // the top method is static => no this instance
            return "";
        }

        String          type       = thisRef.referenceType().name();
        Integer         thisCode   = new Integer(thisRef.hashCode());
        Integer         countI     = null;

        if (method.isConstructor()) {  // store the hash code
            countI     = (Integer)nextObjectNumber.get(type);
            int count  = 0;
            if (countI == null) { count = 1;                     }
            else                { count = countI.intValue() + 1; }

            countI     = new Integer(count);
            nextObjectNumber.put(type, countI);

            objects.put(thisCode, countI);
        }
        else {  // regular instance method (not constructor, not static)
            countI = (Integer)objects.get(thisCode);
        }
        return lcfirst(type) + countI.toString() + ":";
    }

    // Examines the current stack frame returning the ObjectReference
    // of the instance operative in the method on top of the stack.
    // Caller can fish in the returned reference for the type name of
    // the operative instance
    private ObjectReference grabStackTopReference(MethodEntryEvent event) {
        ThreadReference thread     = event.thread();
        StackFrame      frame      = null;
        try {
            frame  = thread.frame(0);
        } catch (Exception e) { }
        // com.sun.jdi.IncompatibleThreadStateException

        return frame.thisObject();
    }

    // This should be part of java.lang.String.  It takes a String and
    // returns it with the first character in lower case Roller becomes roller.
    private static String lcfirst(String in) {
        String first = in.substring(0, 1);
        String rest  = in.substring(1);
        return first.toLowerCase() + rest;
    }

    // turn off initial entry request
    // make new entry and exit requests for each class the user want to see
    private void switchToRegularStatus() {
        eventStatus          = REGULAR_EVENT_STATUS;
        initialEntryRequest.disable();

        Iterator       iter  = interestingClasses.iterator();
        if (iter.hasNext()) {
            while (iter.hasNext()) {  // make one filter for each class
                String className = (String)iter.next();

                MethodEntryRequest  entryRequest;
                MethodExitRequest   exitRequest;

                entryRequest     = requestManager.createMethodEntryRequest();
                exitRequest      = requestManager.createMethodExitRequest();

                entryRequest.addClassFilter(className);
                exitRequest .addClassFilter(className);

                entryRequest.enable();
                exitRequest .enable();

            }
        }
        else { // no classes were named, here comes the flood
            MethodEntryRequest  entryRequest;
            MethodExitRequest   exitRequest;

            entryRequest     = requestManager.createMethodEntryRequest();
            exitRequest      = requestManager.createMethodExitRequest();

            entryRequest.enable();
            exitRequest .enable();
        }
    }

    // builds an official signature like
    // com.company.package.ClassName.method(java.lang.String[], float)
    // uses assembleArgs to make the argument list
    private String grabSignature(Method method) {
        return method.declaringType().name()
               + "." + method.name() + "("
               + assembleArgs(method) + ")";
    }

    // gives a string which can be printed before the signature to
    // show the current call sequence depth visually
    private String formIndentString() {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < indent; i++) {
            sb.append("  ");
        }
        return sb.toString();
    }

    // asks the method for its types, then assembles them for proper printing
    private String assembleArgs(Method method) {
        List         argTypes = method.argumentTypeNames();
        Iterator     iter     = argTypes.iterator();
        StringBuffer sb       = new StringBuffer();
        while (iter.hasNext()) {
            sb.append(iter.next());
            if (iter.hasNext()) {
                sb.append(", ");
            }
        }
        return sb.toString();
    }

    // the debugger must have a way to expell error message, lest it die
    // from full buffers, this method arranges that
    private void dumpProcessOutput(Process proc) {
        dumpOutput(proc.getErrorStream());
        dumpOutput(proc.getInputStream());
    }

    // spawns a thread so dumpStream can run concurrently with other threads
    private void dumpOutput(final InputStream stream) {
        Thread thread = new Thread() {
            public void run() {
                try {
                    dumpStream(stream);
                }
                catch (Exception e) {
                    System.err.println("dump failed for " + stream);
                }
            }
        };
        thread.setPriority(Thread.MAX_PRIORITY - 1);
        thread.start();
    }

    // continually issues blocking reads stdin, or stderr from the virtual
    // machines process
    // prints the result to standard err.
    private void dumpStream(InputStream stream) throws IOException {
        BufferedReader in = new BufferedReader(new InputStreamReader(stream));
        String line;
        while ((line = in.readLine()) != null) {
            System.err.println(line);
        }
    }

    public static void printUsage() {
        System.err.println("usage: java Seq methods_file output_file"
            + " class [args...]");
    }

    /**
     *  This is meant to be used, as shown in {@link #printUsage} above.
     *  @param args <br>method_file<br>output_file<br>class
     *  <br>[args_for_class...]
     */
    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            printUsage();
            System.exit(1);
        }
        String[] passThroughArgs = new String[args.length - 2];
        for (int i = 2; i < args.length; i++) {
            passThroughArgs[i - 2] = args[i];
        }
        Seq s = new Seq(args[0], args[1], passThroughArgs);
    }
}
