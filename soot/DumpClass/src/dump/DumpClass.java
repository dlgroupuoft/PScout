package dump;
import java.io.IOException;

import soot.Scene;
import soot.SootClass;


public class DumpClass {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		// Resolve dependencies
    	Scene.v().loadBasicClasses();
    	SootClass mclass;
        if (args.length != 1) {
        	//Default test classes        	
        	//Default test for FindPermissionString
        	//mclass = Scene.v().loadClassAndSupport("android.accounts.AccountManagerService");
        	
        	//Default test for FindMessage
        	//mclass = Scene.v().loadClassAndSupport("android.webkit.WebSyncManager");
        	
        	//Default test for AnalyzeHandleMessage
        	//mclass = Scene.v().loadClassAndSupport("android.app.ActivityThread$H");
        	
        	//Default test for FindRPCMethod
        	//mclass = Scene.v().loadClassAndSupport("android.view.IWindow$Stub$Proxy");
        	
        	//Default test for FindClearRestoreUid
        	//mclass = Scene.v().loadClassAndSupport("com.android.server.NotificationManagerService");
        	
        	//Default test for FindUriField
        	mclass = Scene.v().loadClassAndSupport("android.provider.ContactsContract$Contacts");
        } else {
        	mclass = Scene.v().loadClassAndSupport(args[0]);
        }
    	mclass.setApplicationClass();
    	
    	try {
			new ClassHierarchy(mclass);
	    	new CallGraph(mclass);
	    	new FindPermissionString(mclass);
	    	new FindPermissionStringWithFlow(mclass);
	    	new FindMessage(mclass);
	    	new AnalyzeHandleMessage(mclass);
	    	new FindRPCMethod(mclass);
	    	new FindClearRestoreUid(mclass);
	    	new FindUriField(mclass);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    	
	}

}
