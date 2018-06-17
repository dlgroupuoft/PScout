package dump;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.Local;
import soot.PatchingChain;
import soot.Scene;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.ValueBox;
import soot.jimple.Constant;
import soot.jimple.DefinitionStmt;
import soot.jimple.FieldRef;
import soot.jimple.InstanceFieldRef;
import soot.jimple.InstanceInvokeExpr;
import soot.jimple.IntConstant;
import soot.jimple.InvokeExpr;
import soot.jimple.NewExpr;
import soot.jimple.ParameterRef;
import soot.toolkits.graph.ExceptionalUnitGraph;
import soot.toolkits.scalar.SimpleLocalDefs;

public class FindMessage {
	
	public final static String FILE = "msg";
	BufferedWriter out = null;
		
	static final String sendMethods[] = {
		"<android.os.Messenger: void send(android.os.Message)>",
		"<android.os.Handler: boolean sendEmptyMessage(int)>",
		"<android.os.Handler: boolean sendEmptyMessageAtTime(int, long)>",
		"<android.os.Handler: boolean sendEmptyMessageDelayed(int,long)>",
		"<android.os.Handler: boolean sendMessage(android.os.Message)>",
		"<android.os.Handler: boolean sendMessageAtFrontOfQueue(android.os.Message)>",
		"<android.os.Handler: boolean sendMessageAtTime(android.os.Message,long)>",
		"<android.os.Handler: boolean sendMessageDelayed(android.os.Message,long)>"
	};
	
	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}
	
	int isSendMethod(String sig) {
		int size = sendMethods.length;
		for (int i=0; i<size; i++) {
			if (sig.equals(sendMethods[i])) {
				return i;
			}	
		}
		return -1;
	}
	
	boolean isHandlerClass(String sig) {
		if (!Scene.v().containsClass(sig)) return false;		
		SootClass c = Scene.v().getSootClass(sig);
		boolean ishandlerclass = c.getName().equals("android.os.Handler");
		while (ishandlerclass == false && ! c.getName().equals("java.lang.Object")) {
			c = c.getSuperclass();
			if (c.getName().equals("android.os.Handler")) {
				ishandlerclass = true;
			}
		}
		return ishandlerclass;
	}
	
	void getIntConstantsFromLocal(SimpleLocalDefs sld, Local l, Unit u, List<String> whats) throws IOException {
		Iterator<Unit> iter = sld.getDefsOfAt(l, u).iterator();
		while (iter.hasNext()) {
			Unit def = iter.next();
			if (! (def instanceof DefinitionStmt)) continue;
			DefinitionStmt assign = (DefinitionStmt) def;
			Value rightOp = assign.getRightOp();
			if (rightOp instanceof IntConstant) {
				whats.add(rightOp.toString());
			} else if (rightOp instanceof ParameterRef){
				whats.add(rightOp.toString());
			} else if (rightOp instanceof Local) {
				getIntConstantsFromLocal(sld, (Local)rightOp, def, whats);
				print("getIntConstantsFromLocal -> local");
			} else {
				print("???"+def.toString());
			}
		}
	}
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindMessage(SootClass mclass) throws IOException {

		out = new BufferedWriter(new FileWriter(FILE));
    	    	
    	List<SootMethod> methods = mclass.getMethods();
    	Iterator<SootMethod> iter_m = methods.iterator();    	
    	    	
    	// loop through and analyze concrete methods
    	while (iter_m.hasNext()) {
    		SootMethod m = iter_m.next();   
    		if (m.isConcrete() == false) continue;    		
    		try {
    			//print("method: "+m.toString());
    			Body b = m.retrieveActiveBody();
    			SimpleLocalDefs sld = new SimpleLocalDefs(new ExceptionalUnitGraph(b));
    			PatchingChain<Unit> units = b.getUnits();
    			Iterator<Unit>iter_u = units.iterator();
    			HashMap<String, ArrayList<String>> local_fields_assignment = new HashMap<String, ArrayList<String>>();
    			
    			// loop through statements
    			while (iter_u.hasNext()) {
    				Unit u = iter_u.next();
    				
    				// look for assignment of fields
    				if (u instanceof DefinitionStmt) {
    					DefinitionStmt asu = (DefinitionStmt) u;
    					Value lov = asu.getLeftOp();
    					if (! (lov instanceof InstanceFieldRef)) continue;
						InstanceFieldRef lo = (InstanceFieldRef) lov;
						
						// Store assignment of the what field of Local Message variable
						if (! lo.getBase().equals(b.getThisLocal())) {
							if (lo.getField().toString().equals("<android.os.Message: int what>")) {
								String base = lo.getBase().toString();
    							//print("Found what assigned to "+base);
        						Value rov = asu.getRightOp();    						
								if (!local_fields_assignment.containsKey(base)) 
									local_fields_assignment.put(base, new ArrayList<String>());
								if (rov instanceof IntConstant) {
									local_fields_assignment.get(base).add(rov.toString());
								} else if (rov instanceof Local) {
									//Local l = (Local) rov;
									getIntConstantsFromLocal(sld, (Local) rov, u, local_fields_assignment.get(base));
									//getIntConstantsFromLocal(sld.getDefsOfAt(l, u).iterator(), local_fields_assignment.get(base));
								} else {
									print("???NOT CONSTANT/LOCAL???");
								}
							}
							continue;
						}
						
						// Check if field is subclass of android.os.Handler and only record handler classes
						String fieldtype = lo.getField().getType().toString();
						if (isHandlerClass(fieldtype) == false) continue;					
						
						if (! fieldtype.equals("android.os.Handler")) {
							print("FIELD:"+lo.getField().toString()+"ASSIGNEDVALUE:"+fieldtype+"INMETHOD:"+m.toString());
							continue;
						}
						
						// Get assignment this android.os.Handler field in this
						Value rov = asu.getRightOp();    						
						if (rov instanceof Local) {
							Local l = (Local) rov;
							List<Unit> defs = sld.getDefsOfAt(l, u);
							Iterator<Unit> itr = defs.iterator();
							while (itr.hasNext()) {
								Unit def = itr.next();
								DefinitionStmt assign = (DefinitionStmt) def;
								Value rov2 = assign.getRightOp();
								if (rov2 instanceof NewExpr) {
									NewExpr ron = (NewExpr) rov2;
									print("FIELD:"+lo.getField().toString()+"ASSIGNEDVALUE:"+ron.getType().toString()+"INMETHOD:"+m.toString());
								} else if (rov2 instanceof ParameterRef) {
									print("FIELD:"+lo.getField().toString()+"ASSIGNEDPARAM:"+rov2.toString()+"INMETHOD:"+m.toString());
								} else if (rov2 instanceof Constant) {
									//in case handler assigned to null
								} else {
									print("???Unexpected value assigned to handler field???"+asu.toString());
								}
							} 
						} 
    					
    				} else {    			
    					
        				// look for send method invocation
        				List<ValueBox> valueboxes = u.getUseBoxes();
        				Iterator<ValueBox> iter_vb = valueboxes.iterator();
	    				while (iter_vb.hasNext()) {
	    					Value v = iter_vb.next().getValue();
	    					if (v instanceof InstanceInvokeExpr) {
	    						InstanceInvokeExpr i = (InstanceInvokeExpr) v;
	    						String mSig = i.getMethod().getSignature();
	    						int sendMethodIdx = isSendMethod(mSig);
	    						if (sendMethodIdx == -1) continue;
	    						
    							// get message content
	    						List<String> whats = new ArrayList<String>();
    							switch (sendMethodIdx) {
    							case 1:
    							case 2:
    							case 3:
    								Value arg0 = i.getArg(0);
    								if (arg0 instanceof IntConstant) {
										whats.add(arg0.toString());
    								} else if (arg0 instanceof Local) {
    									//Local l = (Local) arg0;
    									//getIntConstantsFromLocal(sld.getDefsOfAt(l, u).iterator(), whats);
    									getIntConstantsFromLocal(sld, (Local) arg0, u, whats);
    								}
    								break;
    							case 0:
    							case 4:
    							case 5:
    							case 6:
    							case 7:
    								Value msgv = i.getArg(0);
    								if (msgv instanceof Local && msgv.getType().toString().equals("android.os.Message")) {
    									Local l = (Local) msgv;
    									Iterator<Unit> iter_defs = sld.getDefsOfAt(l, u).iterator();
    									while (iter_defs.hasNext()) {
    										Unit def = iter_defs.next();
    										if (! (def instanceof DefinitionStmt)) continue;
    										DefinitionStmt assign = (DefinitionStmt) def;
    										Value rightOp = assign.getRightOp();
    										
    										// deals with different flavors of obtainMessage
    										if (rightOp instanceof InvokeExpr) {
    											InvokeExpr o = (InvokeExpr) rightOp;
    											if (o.getMethod().getDeclaringClass().getName().equals("android.os.Handler") 
    													&& o.getMethod().getParameterCount() > 0 
    													&& o.getMethod().getName().indexOf("obtainMessage") != -1) {
    												Value p = o.getArg(0);
    			    								if (p instanceof IntConstant) {
    													whats.add(p.toString());
    			    								} else if (p instanceof Local) {
    			    									//Local l2 = (Local) p;
    			    									//getIntConstantsFromLocal(sld.getDefsOfAt(l2, u).iterator(), whats);
    			    									getIntConstantsFromLocal(sld, (Local) p, u, whats);
    			    								}
    											} else if (o.getMethod().getDeclaringClass().getName().equals("android.os.Message") 
    													&& o.getMethod().getParameterCount() > 1
    													&& o.getMethod().getName().indexOf("obtain") != -1) {
    												Value p = o.getArg(1);
    			    								if (p instanceof IntConstant) {
    													whats.add(p.toString());
    			    								} else if (p instanceof Local) {
    			    									//Local l2 = (Local) p;
    			    									//getIntConstantsFromLocal(sld.getDefsOfAt(l2, u).iterator(), whats);
    			    									getIntConstantsFromLocal(sld, (Local) p, u, whats);
    			    								}
    											}
    										} else if (rightOp instanceof Local) {
    											//Local l3 = (Local) rightOp;
    											//getIntConstantsFromLocal(sld.getDefsOfAt(l3, u).iterator(), whats);
    											getIntConstantsFromLocal(sld, (Local) rightOp, u, whats);
    										} else if (rightOp instanceof ParameterRef) {
    											whats.add(rightOp.toString());
    										}
    									}
    									
    									// add stored stored assignment of what field
    									List<String> local_whats = local_fields_assignment.get(msgv.toString());
    									if (local_whats != null) {
    										Iterator<String> itr = local_whats.iterator();
    										while(itr.hasNext()) {
    											whats.add(itr.next());
    										}
    									}
    								} 
    								break;
    							default:
    								print("!!!!!Unhandled send method!!!!!");
    							}
    							
    							// Backward analysis to get service handler
        						Value base = i.getBase();
    							if (base instanceof Local) {
    								Local l = (Local) base;
    								Iterator<Unit> iter_defs = sld.getDefsOfAt(l, u).iterator();
    								while (iter_defs.hasNext()) {
    									Unit def = iter_defs.next();
    									//print(def.toString());
    									if (def instanceof DefinitionStmt) {
    										DefinitionStmt assign = (DefinitionStmt) def;
    										Value rightOp = assign.getRightOp();
    										//print(rightOp.toString());
    										if (whats.size() == 0) {
    											print("!!!!!Failed to get msg content!!!!!"+m.toString());
    										}
    										if (rightOp instanceof FieldRef) {
    											FieldRef rightfield = (FieldRef) rightOp;
    											for (int j=0; j<whats.size();j++)
    												print("METHOD:"+m.toString()
    														+"HANDLERFIELD:"+rightfield.getField().toString()
    														+"WHAT:"+whats.get(j));
    										} else {
    											//Assume assignment type is what we want...
    											for (int j=0; j<whats.size();j++)
    												print("METHOD:"+m.toString()
    														+"HANDLERNOTFIELD:"+rightOp.getType().toString()
    														+"WHAT:"+whats.get(j));
    										}
    									} else {
    										print("!!!!!?????!!!!!");
    									}
    								}
    							} else {
    								print("!!!!!NOT LOCAL INVOKE??!!!!!");
    							}
	    					} else if (v instanceof InvokeExpr) {
	    						InvokeExpr i = (InvokeExpr) v;
	    						if (isSendMethod(i.getMethod().getSignature().toString()) != -1) {
	    							print("!!!!!MISSED SEND METHOD!!!!!");
	    						}
	    					}	// end if method invocation
	    				}	// end loop for method invocation
    				}	// end if assignment statement
    			}	// end loop for statements
    			
    		} catch (RuntimeException e) {
    			System.err.println(m.toString()+" "+e.getMessage());
    		}
    	}	// end loop for method
    	out.close();
	}
}
