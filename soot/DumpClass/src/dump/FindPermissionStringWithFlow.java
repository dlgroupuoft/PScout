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
import soot.Local;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.ValueBox;
import soot.jimple.DefinitionStmt;
import soot.jimple.StringConstant;
import soot.toolkits.graph.ExceptionalUnitGraph;
import soot.toolkits.scalar.SimpleLocalDefs;

public class FindPermissionStringWithFlow {
	public final static String FILE = "pstrf";
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
	
	void getStringConstantsFromLocal(SimpleLocalDefs sld, Local l, Unit u, HashMap<String,String> perms) throws IOException {
		Iterator<Unit> iter = sld.getDefsOfAt(l, u).iterator();
		while (iter.hasNext()) {
			Unit def = iter.next();
			if (! (def instanceof DefinitionStmt)) continue;
			DefinitionStmt assign = (DefinitionStmt) def;
			Value rightOp = assign.getRightOp();
			if (rightOp instanceof StringConstant) {
				int i=0;
				boolean found = false;
				while(i<numPerm && !found) {
					if (rightOp.toString().equals("\""+permissions[i]+"\"")) {
						found = true;
						if (u instanceof DefinitionStmt && !isKnownCheck(u.toString())) {
							perms.put(permissions[i], "NOTDIRECTUSE");
						} else {
							perms.put(permissions[i], "");
						}
					}
					i++;
				}
			} else if (rightOp instanceof Local) {
				getStringConstantsFromLocal(sld, (Local)rightOp, def, perms);
			} else {
				//irrelevant types
			}
		}
	}

	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindPermissionStringWithFlow(SootClass mclass) throws IOException {
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
    			Iterator<Unit> iter_u = b.getUnits().iterator();
    			SimpleLocalDefs sld = new SimpleLocalDefs(new ExceptionalUnitGraph(b));
    		
    			while (iter_u.hasNext()) {
    				Unit u = iter_u.next();
    				Iterator<ValueBox> iter_vb = u.getUseBoxes().iterator();
    				
    				while (iter_vb.hasNext()) {
    					Value v = iter_vb.next().getValue();
    					
    					if (v instanceof StringConstant) {
        					int i=0;
        					boolean found = false;
        					while(i<numPerm && !found) {
        						if (v.toString().equals("\""+permissions[i]+"\"")) {
        							found = true;
        							if (u instanceof DefinitionStmt && !isKnownCheck(u.toString())) {
            							print("PER:"+permissions[i]+"METHOD:"+m.toString()+"STMT:"+u.toString()+"NOTDIRECTUSE");
        							} else {
            							print("PER:"+permissions[i]+"METHOD:"+m.toString()+"STMT:"+u.toString());
        							}
        						}
        						i++;
        					}
    					} else if (v instanceof Local) {
    						HashMap<String,String> localperms = new HashMap<String,String>();
    						getStringConstantsFromLocal(sld, (Local) v, u, localperms);
    						Iterator<String> iter_perms = localperms.keySet().iterator();
    						while (iter_perms.hasNext()) {
    							String perm = iter_perms.next();
    							print("PER:"+perm+"METHOD:"+m.toString()+"STMT:"+u.toString()+localperms.get(perm));
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

