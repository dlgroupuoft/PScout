package dump;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.ValueBox;
import soot.jimple.ArrayRef;
import soot.jimple.DefinitionStmt;
import soot.jimple.StringConstant;

public class FindPermissionString {
	public final static String FILE = "pstr";
	BufferedWriter out = null;
	
	static String permissions[] = new String[200];
	static int numPerm = 0;

	final static String knownPermissionChecks[] = {
			"<android.content.Context: int checkPermission(java.lang.String,int,int)>",
			"<android.content.Context: int checkCallingPermission(java.lang.String)>",
			"<android.content.Context: int checkCallingOrSelfPermission(java.lang.String)>",
			"<android.content.Context: void enforcePermission(java.lang.String,int,int,java.lang.String)>",
			"<android.content.Context: void enforceCallingPermission(java.lang.String,java.lang.String)>",
			"<android.content.Context: void enforceCallingOrSelfPermission(java.lang.String,java.lang.String)>",
			"<android.content.Context: void sendBroadcast(android.content.Intent,java.lang.String)>",
			"<android.content.Context: void sendOrderedBroadcast(android.content.Intent,java.lang.String)>",
			"<android.content.Context: void sendOrderedBroadcast(android.content.Intent,java.lang.String,android.content.BroadcastReceiver,android.os.Handler,int,java.lang.String,android.os.Bundle)>",
			"<android.content.Context: android.content.Intent registerReceiver(android.content.BroadcastReceiver,android.content.IntentFilter,java.lang.String,android.os.Handler)>"
	};
	
	static boolean isKnownCheck(String stmt) {
		int size = knownPermissionChecks.length;
		for (int i=0; i<size; i++) {
			if (stmt.contains(knownPermissionChecks[i])) {
				return true;
			}
		}
		return false;
	}
	
	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}
	
	void loadPermissions() {
		try {
			BufferedReader in = new BufferedReader(new FileReader("permissions"));
			String str;
			while ((str = in.readLine()) != null) {
				permissions[numPerm] = str;
				numPerm++;
			}
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindPermissionString(SootClass mclass) throws IOException {
		out = new BufferedWriter(new FileWriter(FILE));
    	
    	List<SootMethod> methods = mclass.getMethods();
    	Iterator<SootMethod> iter = methods.iterator();
    	
    	loadPermissions();
   
    	// loop through methods
    	while (iter.hasNext()) {
    		SootMethod m = iter.next();
    		if (! m.isConcrete()) continue;
    		try {
    			Body b = m.retrieveActiveBody();
    			Iterator<Unit>iter_u = b.getUnits().iterator();
    		
    			// keep track of intermediate variables storing permission strings
    			HashMap<ValueBox, String> assigned_perms = new HashMap<ValueBox, String>();
    		    			
    			//loop through statements
    			while (iter_u.hasNext()) {
    				Unit u = iter_u.next();
    				Iterator<ValueBox> iter_vb = u.getUseBoxes().iterator();
    				
    				//loop through value used
    				while (iter_vb.hasNext()) {
    					ValueBox vb = iter_vb.next();
    					Value v = vb.getValue();
    					
    					//direct usage of permission string
        				if(v instanceof StringConstant && v.toString().indexOf("permission") != -1) {
        					int i=0;
        					boolean found = false;
        					while(i<numPerm && !found) {
        						if (v.toString().equals("\""+permissions[i]+"\"")) {
        							found = true;
        							if (u instanceof DefinitionStmt && !isKnownCheck(u.toString())) {
        								DefinitionStmt du = (DefinitionStmt) u;
        								ValueBox varbox = du.getLeftOpBox();
        								Value var = varbox.getValue();
        								if (var instanceof ArrayRef) {
        									ArrayRef avar = (ArrayRef) var;
        									assigned_perms.put(avar.getBaseBox(), permissions[i]);
        								} else {
        									assigned_perms.put(varbox, permissions[i]);
        								}
            							print("PER:"+permissions[i]+"METHOD:"+m.toString()+"STMT:"+u.toString()+"NOTDIRECTUSE");
        							} else {
            							print("PER:"+permissions[i]+"METHOD:"+m.toString()+"STMT:"+u.toString());
        							}
        						}
        						i++;
        					}
        				} else {
        					
        					//look for usage of intermediate variables holding permission strings
        					Iterator<ValueBox> iter_assigned_perms = assigned_perms.keySet().iterator();
        					while (iter_assigned_perms.hasNext()) {
        						ValueBox assigned_perm = iter_assigned_perms.next();
        						if (vb.toString().equals(assigned_perm.toString())) {
        							print("PER:"+assigned_perms.get(assigned_perm)+"METHOD:"+m.toString()+"STMT:"+u.toString()+"NOTDIRECTUSE");
        						}
        					}
        				}
    				}
    			}
    		} catch (RuntimeException e) {
    			System.err.println(m.toString()+" "+e.getMessage());
    		}
    	}
    	out.close();
	}

}

