package dump;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.jimple.Stmt;
import soot.toolkits.graph.BriefUnitGraph;
import soot.toolkits.graph.UnitGraph;


public class FindClearRestoreUid {

	public final static String FILE = "uid";
	BufferedWriter out = null;

	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}
	
	List<Unit> seen = new ArrayList<Unit>();
		
	void findAllUnitsBeforeRestore(List<Unit> restores, Unit from, UnitGraph ug, String mname) throws IOException {
		seen.add(from);
		Iterator<Unit> succ = ug.getSuccsOf(from).iterator();
		while(succ.hasNext()) {
			Stmt s = (Stmt) succ.next();
			if (restores.contains(s)) {
				//done
			} else {
				if (s.containsInvokeExpr()) {
					print (mname+";"+s.getInvokeExpr().getMethod().toString());
				}
				if (!seen.contains(s))
					findAllUnitsBeforeRestore(restores, s, ug, mname);
			}
		}
	}
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindClearRestoreUid(SootClass mclass) throws IOException {
		out = new BufferedWriter(new FileWriter(FILE));

    	List<SootMethod> methods = mclass.getMethods();
    	Iterator<SootMethod> iter = methods.iterator();
    	
    	while (iter.hasNext()) {
    		SootMethod m = iter.next();
    		if (! m.isConcrete()) continue;
    		try {
    			Body b = m.retrieveActiveBody();
    			boolean foundclear = false;
    			boolean foundrestore = false;
    			Iterator<Unit> units = b.getUnits().iterator();
    			List<Unit> clears = new ArrayList<Unit>();
    			List<Unit> restores = new ArrayList<Unit>();
    			while (units.hasNext()) {
    				Stmt s = (Stmt) units.next();
    				if (s.containsInvokeExpr()) {
    					String mstring = s.getInvokeExpr().getMethod().toString();
    					//if (m.toString().equals("<com.android.server.NotificationManagerService: void enqueueToast(java.lang.String,android.app.ITransientNotification,int)>")) {print (mstring);}
    					if (mstring.equals("<android.os.Binder: long clearCallingIdentity()>")) {
    						foundclear = true;
    						clears.add(s);
    					} else if (mstring.equals("<android.os.Binder: void restoreCallingIdentity(long)>")) {
    						foundrestore = true;
    						restores.add(s);
    					} 
    				}
    			}
    			
    			if (!foundclear || !foundrestore) continue;

    			BriefUnitGraph ug = new BriefUnitGraph(b);
    			Iterator<Unit> iter_c = clears.iterator();
    			while (iter_c.hasNext()) {
    				Unit from = iter_c.next();
    				Iterator<Unit> iter_r = restores.iterator();
    				while (iter_r.hasNext()) {
    					Unit to = iter_r.next();	    					
    					List<Unit> resultslist = ug.getExtendedBasicBlockPathBetween(from, to);
    					if (resultslist != null) {
    						Iterator<Unit> results = resultslist.iterator();
	    					while (results.hasNext()) {
	    						Stmt rs = (Stmt) results.next();
	    						if (rs.containsInvokeExpr()) {
	    							print (m.toString()+";"+rs.getInvokeExpr().getMethod().toString());
	    						}
	    					}
    					} else {
    						seen.clear();
    						findAllUnitsBeforeRestore(restores, from, ug, m.toString());
    					}
    					/*List<Unit> beforeto = ug.getPredsOf(to);
    					
    					Iterator<Unit> results = afterfrom.iterator();
    					while (results.hasNext()) {
    						Stmt rs = (Stmt) results.next();
    						print (rs.toString());
    						if (!beforeto.contains(rs)) continue;
    						if (rs.containsInvokeExpr()) {
    							print (m.toString()+";"+rs.toString());
    						}
    					}*/
    				}
    			}
    			
    		} catch (RuntimeException e) {	   
    			System.err.println("ERROR:"+m.toString()+" "+e.getMessage()); 			
    		}
    	}
    	out.close();
	}

}
