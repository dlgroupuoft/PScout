package dump;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Iterator;
import java.util.List;

import soot.Body;
import soot.Scene;
import soot.SootClass;
import soot.SootField;
import soot.SootMethod;
import soot.Value;
import soot.ValueBox;
import soot.jimple.AnyNewExpr;
import soot.jimple.FieldRef;
import soot.jimple.InvokeExpr;
import soot.jimple.NewArrayExpr;
import soot.jimple.NewExpr;
import soot.jimple.NewMultiArrayExpr;

public class CallGraph {
	
	public final static String FILE = "rcg";
	BufferedWriter out = null;
	
	void print(String msg) throws IOException {
		out.write(msg+"\n");
	}

	boolean hasStaticInitializer(String classname) {
		if (!Scene.v().containsClass(classname))
			return false;
		SootClass c = Scene.v().getSootClass(classname);
		return c.declaresMethod("void <clinit>()");
	}

	/**
	 * @param args
	 * @throws IOException 
	 */
	public CallGraph(SootClass mclass) throws IOException {		
		out = new BufferedWriter(new FileWriter(FILE));

		List<SootMethod> methods = mclass.getMethods();
		Iterator<SootMethod> iter = methods.iterator();

		// loop through methods
		while (iter.hasNext()) {
			SootMethod m = iter.next();
			if (!m.isConcrete()) {
				print("SRC:" + m.toString() + "NOIMPL");
				continue;
			}
			try {
				print("SRC:" + m.toString() + "DECLARATION");
				Body b = m.retrieveActiveBody();
				Iterator<ValueBox> iter_v = b.getUseBoxes().iterator();
				while (iter_v.hasNext()) {
					Value v = iter_v.next().getValue();
					if (v instanceof InvokeExpr) {
						InvokeExpr iv = (InvokeExpr) v;
						String stmt = iv.toString();
						String type;
						if (stmt.startsWith("specialinvoke")) {
							type = "SPECIALINVOKE";
						} else if (stmt.startsWith("staticinvoke")) {
							type = "STATICINVOKE";
							if (hasStaticInitializer(iv.getMethod()
									.getDeclaringClass().toString())) {
								print("SRC:"
										+ m.toString()
										+ "TYPE:CLINIT;CALLING:<"
										+ iv.getMethod().getDeclaringClass()
												.toString()
										+ ": void <clinit>()>");
							}
						} else if (stmt.startsWith("virtualinvoke")) {
							type = "VIRTUALINVOKE";
						} else if (stmt.startsWith("interfaceinvoke")) {
							type = "INTERFACEINVOKE";
						} else {
							type = "XXXXX" + v.toString();
						}
						// print
						// ("---\n"+iv.getClass()+"\n"+iv.getMethod()+"\n"+iv.getMethodRef()+"\n"+iv.getType()+"\n---\n");
						if (iv.getMethod().toString()
								.equals("<java.lang.Thread: void start()>")) {
							print("SRC:"
									+ m.toString()
									+ "TYPE:THREAD;CALLING:<"
									+ iv.getMethodRef().declaringClass()
											.toString() + ": void run()>");
						} else if (iv
								.getMethod()
								.toString()
								.equals("<java.security.AccessController: java.lang.Object doPrivileged(java.security.PrivilegedAction)>")) {
							ValueBox vb = iv.getArgBox(0);
							print("SRC:" + m.toString()
									+ "TYPE:PRIVILEGED;CALLING:<"
									+ vb.getValue().getType().toString()
									+ ": java.lang.Object run()>");
						} else {
							print("SRC:" + m.toString() + "TYPE:" + type
									+ ";CALLING:"
									+ iv.getMethodRef().toString());
						}
					} else if (v instanceof AnyNewExpr) {
						String classname;
						if (v instanceof NewExpr) {
							NewExpr nv = (NewExpr) v;
							classname = nv.getBaseType().toString();
						} else if (v instanceof NewArrayExpr) {
							NewArrayExpr nv = (NewArrayExpr) v;
							classname = nv.getBaseType().toString();
						} else if (v instanceof NewMultiArrayExpr) {
							NewMultiArrayExpr nv = (NewMultiArrayExpr) v;
							classname = nv.getBaseType().toString();
						} else {
							classname = "XXXXX"; // bad!
						}
						if (hasStaticInitializer(classname)) {
							print("SRC:" + m.toString()
									+ "TYPE:CLINIT;CALLING:<" + classname
									+ ": void <clinit>()>");
						}
					} else if (v instanceof FieldRef) {
						FieldRef fv = (FieldRef) v;
						SootField f = fv.getField();
						if (f.isStatic()
								&& hasStaticInitializer(f.getDeclaringClass()
										.toString())) {
							print("SRC:" + m.toString()
									+ "TYPE:CLINIT;CALLING:<"
									+ f.getDeclaringClass().toString()
									+ ": void <clinit>()>");
						}
					}
				}
			} catch (RuntimeException e) {
				System.err.println(m.toString() + " " + e.getMessage());
			}
		}

		if (mclass.declaresMethod("void finalize()")) {
			print("SRC:<" + mclass.toString()
					+ ": void <init>()>TYPE:FINALIZE;CALLING:<"
					+ mclass.toString() + ": void finalize()>");
		}
		out.close();
	}

}
