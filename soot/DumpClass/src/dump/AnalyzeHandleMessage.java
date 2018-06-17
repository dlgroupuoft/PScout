package dump;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.Local;
import soot.PatchingChain;
import soot.SootClass;
import soot.SootMethod;
import soot.Unit;
import soot.Value;
import soot.jimple.DefinitionStmt;
import soot.jimple.FieldRef;
import soot.jimple.GotoStmt;
import soot.jimple.InvokeExpr;
import soot.jimple.LookupSwitchStmt;
import soot.jimple.ReturnVoidStmt;
import soot.jimple.Stmt;
import soot.jimple.TableSwitchStmt;
import soot.toolkits.graph.ExceptionalUnitGraph;
import soot.toolkits.scalar.SimpleLocalDefs;


public class AnalyzeHandleMessage {
	public final static String FILE = "switch";
	BufferedWriter out = null;
	
	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}

	/**
	 * @param args
	 * @throws IOException 
	 */
	public AnalyzeHandleMessage(SootClass mclass) throws IOException {
		out = new BufferedWriter(new FileWriter(FILE));
		
    	if (! mclass.isConcrete()) {
    		return;
    	}
    	if (! mclass.declaresMethod("void handleMessage(android.os.Message)")) {
    		return;
    	}
    	
    	SootMethod handlemsg = mclass.getMethod("void handleMessage(android.os.Message)");
    	
    	Body b = handlemsg.retrieveActiveBody();
    	PatchingChain<Unit> units = b.getUnits();
		Iterator<Unit>iter_u = units.iterator();
		
		List<String> before_invoke = new ArrayList<String>();
		List<String> after_invoke = new ArrayList<String>();
		
		boolean foundWhat = false;
		int targetCount = 0;
		Unit switchUnit = null;
		while (iter_u.hasNext() && foundWhat == false) {
			Unit u = iter_u.next();
			Value key = null;
			if (u instanceof TableSwitchStmt) {
				TableSwitchStmt tb = (TableSwitchStmt) u;
				targetCount = tb.getTargets().size();
				key = tb.getKey();
			} else if (u instanceof LookupSwitchStmt) {
				LookupSwitchStmt lu = (LookupSwitchStmt) u;
				targetCount = lu.getTargetCount();
				key = lu.getKey();
			} else {						
				try {
					InvokeExpr iv = ((Stmt)u).getInvokeExpr();
					before_invoke.add(iv.getMethod().toString());
				} catch (Exception e) {							
				}
				continue;
			}			
			if (! (key instanceof Local)) {
				print("???"+u.toString());
				continue;
			}

			Local l = (Local) key;
			SimpleLocalDefs sld = new SimpleLocalDefs(new ExceptionalUnitGraph(b));
			Iterator<Unit> defs = sld.getDefsOfAt(l, u).iterator();
			while(defs.hasNext() && foundWhat == false) {
				DefinitionStmt d = (DefinitionStmt) defs.next();
				Value rightOp = d.getRightOp();
				if (! (rightOp instanceof FieldRef)) continue;
				FieldRef f = (FieldRef) rightOp;
				if (f.getField().toString().equals("<android.os.Message: int what>")) {
					//print("Found switch statement on what");
					foundWhat = true;
					switchUnit = u;
				}
			}
		}

		if (!foundWhat) {
			print("Handler<"+mclass.getName()+">");
			Iterator<String> iter_s = before_invoke.iterator();
			print("Common");
			while (iter_s.hasNext()) {
				print(iter_s.next());
			}
			return;
		}

		print("Handler<"+mclass.getName()+">("+targetCount+")");
		//HashMap<Integer, String> targetswitch = new HashMap<Integer, String>();
		if (switchUnit instanceof TableSwitchStmt) {
			TableSwitchStmt tb = (TableSwitchStmt) switchUnit;
			Unit defaultTarget = tb.getDefaultTarget();
			
			Unit d = defaultTarget;
			while (d != null) {
				try {
					InvokeExpr iv = ((Stmt)d).getInvokeExpr();
					after_invoke.add(iv.getMethod().toString());
				} catch (Exception e) {							
				}
				d = units.getSuccOf(d);
			}
			
			int high = tb.getHighIndex();
			int low = tb.getLowIndex();
			//print("TableSwitch from "+low+" to "+high);
			for (int i=0; i<(high-low+1); i++) {
				Unit u = tb.getTarget(i);
				print("Case "+(i+low));
				
				Iterator<String> iter_s = before_invoke.iterator();
				while (iter_s.hasNext()) {
					print(iter_s.next());
				}
				
				boolean finishCurrentCase = false;
				boolean includedefault = true;
				while (!finishCurrentCase) {
					//print("  "+u.toString());
					if (u instanceof GotoStmt) {
						GotoStmt g = (GotoStmt) u;
						Unit go = g.getTarget();
						finishCurrentCase = go.equals(defaultTarget);	
						u = units.getSuccOf(u);					
						finishCurrentCase = finishCurrentCase || u==null || u.equals(defaultTarget);	
					} else {
						try {
							InvokeExpr iv = ((Stmt)u).getInvokeExpr();
							print(iv.getMethod().toString());
						} catch (Exception e) {							
						}
						boolean prevStmtReturn = (u instanceof ReturnVoidStmt);
						u = units.getSuccOf(u);
						finishCurrentCase = u==null || u.equals(defaultTarget);		
						if (finishCurrentCase && prevStmtReturn) includedefault = false;
					}
				}
				
				if (includedefault) {
					Iterator<String> iter_sa = after_invoke.iterator();
					while (iter_sa.hasNext()) {
						print(iter_sa.next());
					}
				}
			}
			
			print("Default");
			Iterator<String> iter_s = before_invoke.iterator();
			while (iter_s.hasNext()) {
				print(iter_s.next());
			}
			Iterator<String> iter_sa = after_invoke.iterator();
			while (iter_sa.hasNext()) {
				print(iter_sa.next());
			}
		} else {
			LookupSwitchStmt lu = (LookupSwitchStmt) switchUnit;
			Unit defaultTarget = lu.getDefaultTarget();
			
			Unit d = defaultTarget;
			while (d != null) {
				try {
					InvokeExpr iv = ((Stmt)d).getInvokeExpr();
					after_invoke.add(iv.getMethod().toString());
				} catch (Exception e) {							
				}
				d = units.getSuccOf(d);
			}
			
			for (int i=0; i<lu.getTargetCount(); i++) {
				Unit u = lu.getTarget(i);
				int casenum = lu.getLookupValue(i);
				print("Case "+casenum);
				
				Iterator<String> iter_s = before_invoke.iterator();
				while (iter_s.hasNext()) {
					print(iter_s.next());
				}
				
				boolean finishCurrentCase = false;
				boolean includedefault = true;
				while (!finishCurrentCase) {
					//print("  "+u.toString());
					if (u instanceof GotoStmt) {
						GotoStmt g = (GotoStmt) u;
						Unit go = g.getTarget();
						finishCurrentCase = go.equals(defaultTarget);	
						u = units.getSuccOf(u);					
						finishCurrentCase = finishCurrentCase || u==null || u.equals(defaultTarget);	
					} else {
						try {
							InvokeExpr iv = ((Stmt)u).getInvokeExpr();
							print(iv.getMethod().toString());
						} catch (Exception e) {							
						}
						boolean prevStmtReturn = (u instanceof ReturnVoidStmt);
						u = units.getSuccOf(u);
						finishCurrentCase = u==null || u.equals(defaultTarget);		
						if (finishCurrentCase && prevStmtReturn) {includedefault = false;}
					}
				}
				
				if (includedefault) {
					Iterator<String> iter_sa = after_invoke.iterator();
					while (iter_sa.hasNext()) {
						print(iter_sa.next());
					}
				}
			}
			
			print("Default");
			Iterator<String> iter_s = before_invoke.iterator();
			while (iter_s.hasNext()) {
				print(iter_s.next());
			}
			Iterator<String> iter_sa = after_invoke.iterator();
			while (iter_sa.hasNext()) {
				print(iter_sa.next());
			}
		}
		out.close();
	}

}
