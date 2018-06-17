import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.Scene;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.ValueBox;
import soot.jimple.DefinitionStmt;
import soot.jimple.InstanceInvokeExpr;
import soot.jimple.InvokeExpr;
import soot.jimple.NewExpr;
import soot.jimple.Stmt;
import soot.jimple.StringConstant;


public class IntentPermissionCheck {
	static List<String> intents = new ArrayList<String>();
	
	public static void print(String str) {
		System.out.println(str);
	}
	
	private static void loadIntents() {
		try {
			BufferedReader in = new BufferedReader(new FileReader("intentpermission"));
			String str;
			while ((str = in.readLine()) != null) {
				String[] tok = str.split(" ");
				if (tok[0].equals("")) continue;
				intents.add("\""+tok[0]+"\"");
			}
			in.close();
			BufferedReader in2 = new BufferedReader(new FileReader("intentwithdynamicpermission"));
			while ((str = in2.readLine()) != null) {
				String[] tok = str.split(" ");
				if (tok[0].equals("")) continue;
				intents.add("\""+tok[0]+"\"");
			}
			in2.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
        // Resolve dependencies
    	Scene.v().loadBasicClasses();
    	SootClass mclass;
        if (args.length != 1) {
        	//mclass = Scene.v().loadClassAndSupport("com.android.contacts.CallDetailActivity");
        	mclass = Scene.v().loadClassAndSupport("android.content.SyncManager");
        } else {
        	mclass = Scene.v().loadClassAndSupport(args[0]);
        }
    	mclass.setApplicationClass();
    	
    	List<SootMethod> methods = mclass.getMethods();
    	Iterator<SootMethod> iter = methods.iterator();
    	
		loadIntents();
		
		while (iter.hasNext()) {
			SootMethod m = iter.next();
			if (! m.isConcrete()) continue;
    		try {
    			Body b = m.retrieveActiveBody();
    			Iterator<Unit> iter_u = b.getUnits().iterator();
    			HashMap<String, String> intentaction = new HashMap<String,String>();
    			while(iter_u.hasNext()) {
    				Stmt u = (Stmt) iter_u.next();
    				if (u instanceof DefinitionStmt) {
    					DefinitionStmt d = (DefinitionStmt) u;
    					if (d.getRightOp() instanceof NewExpr) {
    						String newbasestr = ((NewExpr)d.getRightOp()).getBaseType().toString();
    						if(newbasestr.equals("android.content.Intent")) {
    							intentaction.put(d.getLeftOp().toString(), "undefined");
    							//print (d.getLeftOp().toString()+":undefined");
    						} else if (newbasestr.equals("android.content.IntentFilter")) {
    							intentaction.put(d.getLeftOp().toString(), "undefined");
    							//print (d.getLeftOp().toString()+":undefined");    							
    						}
    					} else if (intentaction.get(d.getRightOp().toString()) != null) {
    						intentaction.put(d.getLeftOp().toString(), intentaction.get(d.getRightOp().toString()));
    						//print(d.getLeftOp().toString()+":"+intentaction.get(d.getRightOp().toString()));
    					} 
    				}
    				if (!u.containsInvokeExpr()) continue;
    				InvokeExpr i = u.getInvokeExpr();
    				SootMethod invokemethod = i.getMethod();
    				if (i instanceof InstanceInvokeExpr) {
    					InstanceInvokeExpr ii = (InstanceInvokeExpr) i;
    					if (intentaction.get(ii.getBase().toString()) != null) {
    						if(invokemethod.getName().equals("<init>") 
    								&& invokemethod.getParameterCount() > 0
    								&& invokemethod.getParameterType(0).toString().equals("java.lang.String")) {
    							intentaction.put(ii.getBase().toString(), ii.getArg(0).toString());
    							//print (ii.getBase().toString()+":"+ii.getArg(0).toString());
    						} else if (invokemethod.toString().equals("<android.content.IntentFilter: void addAction(java.lang.String)>")) {
    							String newaction = ii.getArg(0).toString();
    							String oldlist = intentaction.get(ii.getBase().toString());
    							intentaction.put(ii.getBase().toString(), oldlist+","+newaction);
    						}
    					} else {
    						Iterator<ValueBox> iter_vb = u.getUseBoxes().iterator();
    						boolean foundintent = false;
    						String intent = "";
    						while(iter_vb.hasNext()) {
    							Value v = iter_vb.next().getValue();
    							
    							//look for usage of stored intents
    							String stored = intentaction.get(v.toString());
    							if (stored != null && intents.contains(stored)) {
        						//if (stored != null) {
    								foundintent = true;
    								intent = intentaction.get(v.toString());
    							}
    							
    						}
    						if (foundintent) {
    							print (m.toString()+";"+intent+";"+invokemethod.toString());
    						}				
    					}
    				}
    			}
    		} catch (RuntimeException e) {
    			System.err.println(m.toString()+" "+e.getMessage());
    		}
		}
	}

}
