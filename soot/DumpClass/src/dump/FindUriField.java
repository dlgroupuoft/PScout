package dump;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.Scene;
import soot.SootClass;
import soot.SootField;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.ValueBox;
import soot.jimple.DefinitionStmt;
import soot.jimple.FieldRef;
import soot.jimple.InstanceInvokeExpr;
import soot.jimple.InvokeExpr;
import soot.jimple.Stmt;


public class FindUriField {
	public final static String FILE = "uri";
	BufferedWriter out = null;
	
	String intents[] = new String[200];
	int numIntent = 0;

	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}
		
	public boolean isUriBuilder(String c, String m) {
		if (c.equals("android.net.Uri$Builder")) {
			return true;
		} else if (c.equals("android.net.Uri")
				&& m.contains("buildUpon")) {
			return true;
		} else {
			return false;
		}
	}
	
	public boolean isBuildingUri(String c, String m) {
		if (c.equals("android.content.ContentUris")
				&& m.contains("withAppendedId")) {
			return true;
		} else if (c.equals("android.net.Uri")
				&& m.contains("withAppendedPath")) {
			return true;
		} else {
			return false;
		}
	}
	
	//0 = no access; 1 = read; 2 = write;
	public int isContentProviderAccess(String c, String m) {
		if (c.equals("android.content.ContentResolver")) {
			if (m.contains("query")) {
				return 1;
			} else if (m.contains("insert")
					|| m.contains("delete") 
					|| m.contains("update") 
					|| m.contains("bulkInsert")) {
				return 2;
			} else {
				return 0;
			}
		} else if (c.equals("android.app.Activity")) {
			if (m.contains("managedQuery")) {
				return 1;
			} else {
				return 0;
			}
		} else {
			return 0;
		}
	}
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindUriField(SootClass mclass) throws IOException {   	
		out = new BufferedWriter(new FileWriter(FILE));
    	
    	// Get list of final android.net.Uri fields
		List<String> finalUriFields = new ArrayList<String>();
		Iterator<SootField> iter_fields = mclass.getFields().iterator();
		while (iter_fields.hasNext()) {
			SootField field = iter_fields.next();
			if (field.getType().toString().equals("android.net.Uri") && field.isFinal()) {
				finalUriFields.add(field.toString());
			}
		}
    	
    	// Get uri string from final android.net.Uri field initialization
		List<String> foundUriFields = new ArrayList<String>();
    	if(mclass.declaresMethod("void <clinit>()")) {
    		SootMethod init = mclass.getMethod("void <clinit>()");
    		try {
    			Body b = init.retrieveActiveBody();
    			Iterator<Unit> iter_u = b.getUnits().iterator();
    			HashMap<String,String> uris = new HashMap<String,String>();    			
    			
    			while(iter_u.hasNext()) {
    				Stmt u = (Stmt) iter_u.next();
    				
    				if (u.containsInvokeExpr()) {
    					InvokeExpr i = u.getInvokeExpr();
    					String invokeClass = i.getMethod().getDeclaringClass().toString();
    					String invokeMethod = i.getMethod().getSubSignature();
    					if (i.getMethod().toString().equals("<android.net.Uri: android.net.Uri parse(java.lang.String)>")) {
    						uris.put(((DefinitionStmt)u).getLeftOp().toString(),i.getArg(0).toString());
    					} else if (isBuildingUri(invokeClass, invokeMethod)) {
    						uris.put(((DefinitionStmt)u).getLeftOp().toString(),uris.get(i.getArg(0).toString()));
						} else if (isUriBuilder(invokeClass, invokeMethod)) {
							InstanceInvokeExpr ii = (InstanceInvokeExpr) i;
							uris.put(((DefinitionStmt)u).getLeftOp().toString(),uris.get(ii.getBase().toString()));
						} else if (i.getMethod().getReturnType().toString().equals("android.net.Uri")) {
							uris.put(((DefinitionStmt)u).getLeftOp().toString(),i.getMethod().toString());
						}
    				}
    				if (u instanceof DefinitionStmt) {
    					DefinitionStmt d = (DefinitionStmt) u;
    					if (uris.get(d.getRightOp().toString()) != null && d.getLeftOp() instanceof FieldRef) {
    						print("Field:"+d.getLeftOp().toString()+uris.get(d.getRightOp().toString()));
    						foundUriFields.add(d.getLeftOp().toString());
    					} else {
    						Value rightOp = d.getRightOp();
    						if (rightOp instanceof FieldRef) {
    							FieldRef rightOpField = (FieldRef) rightOp;
    							if(rightOpField.getType().toString().equals("android.net.Uri")) {
    								uris.put(d.getLeftOp().toString(), rightOpField.toString());
    							}
    						}
    					}
    				}
    			}
    		} catch (RuntimeException e) {
    			System.err.println(init.toString()+" "+e.getMessage());    			
    		}
    	}
    	// check that all final uri fields are found
    	if (!foundUriFields.containsAll(finalUriFields)) {
    		finalUriFields.removeAll(foundUriFields);
    		Iterator<String> iter_finalUriFields = finalUriFields.iterator();
    		while (iter_finalUriFields.hasNext()) {
    			print("!!WARNING!! "+iter_finalUriFields.next()+" NOT FOUND");
    		}
    	}    	
    	    	
    	// begin analyze class methods
    	List<SootMethod> methods = mclass.getMethods();
    	Iterator<SootMethod> iter = methods.iterator();
    	while (iter.hasNext()) {
    		SootMethod m = iter.next();
    		if (m.getSubSignature().equals("void <clinit>()")) continue;
    		if (! m.isConcrete()) continue;
    		try {
    			Body b = m.retrieveActiveBody();			

    			// method returning URI with known base content uri string that are not content provider access
	        	if (m.getReturnType().toString().equals("android.net.Uri")) {
	        		boolean usedUriField = false;
	        		Iterator<ValueBox> iter_vbs = b.getUseBoxes().iterator();
	        		List<String> urimethods = new ArrayList<String>();
	        		while (iter_vbs.hasNext()) {
	        			Value v = iter_vbs.next().getValue();
	        			if (v instanceof FieldRef) {
	        				FieldRef f = (FieldRef) v;
	        				if (f.getType().toString().equals("android.net.Uri") && f.getField().isFinal()) {
	        					urimethods.add("URIMETHOD:"+m.toString()+f.toString());
	        					usedUriField = true;
	        				}
	        			}
	        		}
	        		if (usedUriField) {
	        			boolean isProviderAccess = false;
	    				Iterator<Unit>iter_u = b.getUnits().iterator(); 	
	    				while (iter_u.hasNext() && isProviderAccess == false) {
	    					Stmt u = (Stmt) iter_u.next();
	        				if (!u.containsInvokeExpr()) continue;
	    					InvokeExpr i = u.getInvokeExpr();
	    					String invokeClass = i.getMethod().getDeclaringClass().toString();
	    					String invokeMethod = i.getMethod().getSubSignature();
	    					isProviderAccess = isContentProviderAccess(invokeClass, invokeMethod)!=0;
	    				}
	    				if (!isProviderAccess) {
	    					Iterator<String> iter_str = urimethods.iterator();
	    					while (iter_str.hasNext()) {
	    						print(iter_str.next());
	    					}
	    					continue;
	    				}
	        		}
	        	}

	        	// generic methods, find usage of uri field
	        	// - directly passed to provider access
	        	// - unknown uri field usage
				Iterator<Unit>iter_u = b.getUnits().iterator(); 	
	        	HashMap<String, String> vars = new HashMap<String, String>();
	        	boolean foundUriAccess = false;	        	
	        	List<String> reads = new ArrayList<String>();
	        	List<String> writes = new ArrayList<String>();
	        	while (iter_u.hasNext()) {
	        		Stmt u = (Stmt) iter_u.next();
    				if (u instanceof DefinitionStmt) {
    					DefinitionStmt d = (DefinitionStmt) u;
						Value rightOp = d.getRightOp();
						if (rightOp instanceof FieldRef) {
							FieldRef rightOpField = (FieldRef) rightOp;
							if(rightOpField.getType().toString().equals("android.net.Uri") && rightOpField.getField().isFinal()) {
								vars.put(d.getLeftOp().toString(), rightOpField.toString());
							}
						}
    				}
    				if (!u.containsInvokeExpr()) continue;
					InvokeExpr i = u.getInvokeExpr();
    				Iterator<Value> iter_args = i.getArgs().iterator();
					String invokeClass = i.getMethod().getDeclaringClass().toString();
					String invokeMethod = i.getMethod().getSubSignature();
					if (i.getMethod().toString().equals("<android.net.Uri: android.net.Uri parse(java.lang.String)>")) {
						vars.put(((DefinitionStmt)u).getLeftOp().toString(),i.getArg(0).toString());
					} else if (isBuildingUri(invokeClass, invokeMethod)) {
						vars.put(((DefinitionStmt)u).getLeftOp().toString(),vars.get(i.getArg(0).toString()));
					} else if (isUriBuilder(invokeClass, invokeMethod)) {
						if (u instanceof DefinitionStmt) {
							InstanceInvokeExpr ii = (InstanceInvokeExpr) i;
							vars.put(((DefinitionStmt)u).getLeftOp().toString(),vars.get(ii.getBase().toString()));
						}
					} else if (i.getMethod().getReturnType().toString().equals("android.net.Uri")
							&& isContentProviderAccess(invokeClass, invokeMethod) == 0) {
						vars.put(((DefinitionStmt)u).getLeftOp().toString(), i.getMethod().toString());
					} else {
	    				int access = isContentProviderAccess(invokeClass, invokeMethod);
	    				boolean resolved = false;
	    				List<String> uriused = new ArrayList<String>();
	    				while(iter_args.hasNext()) {
	    					Value arg = iter_args.next();
	    					String assignedUriUsed = vars.get(arg.toString());
	    					if (assignedUriUsed != null) {
	    						if (access == 1) {
	    							if (!reads.contains(assignedUriUsed)) 
	    								reads.add(assignedUriUsed);
	        						resolved = true;
	        						foundUriAccess = true;
	    						} else if (access == 2) {
	    							if (!writes.contains(assignedUriUsed))
	    								writes.add(assignedUriUsed);
	        						resolved = true;
	        						foundUriAccess = true;
	    						}
	    						uriused.add(assignedUriUsed);
	    					}
	    				}
	    				if (resolved == false) {
	    					if (access == 0 && !invokeClass.equals("android.content.ContentUris")) {
	    						Iterator<String> is = uriused.iterator();
	    						while (is.hasNext())
	    							print("UNKNOWNUSAGE:"+m.toString()+"STMT:"+u.toString()+"FIELD:"+is.next());
	    					} else {
	        					print("!!!Unresolved content provider access "+m.toString()+" at "+u.toString());    						
	    					}
	    				}
					}
	        	}
	        	
    			if (foundUriAccess) {
    				print("METHOD:"+m.toString());
    				if (!reads.isEmpty()) {
    					Iterator<String> r = reads.iterator();
    					while (r.hasNext()) {
    						String [] result = r.next().split(";");
    						for (int i=0; i<result.length; i++) {
    							print("R "+result[i]);
    						}
    					}
    				}
    				if (!writes.isEmpty()) {
    					Iterator<String> w = writes.iterator();
    					while (w.hasNext()) {
    						String [] result = w.next().split(";");
    						for (int i=0; i<result.length; i++) {
    							print("W "+result[i]);
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
