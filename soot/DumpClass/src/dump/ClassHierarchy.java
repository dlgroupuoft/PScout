package dump;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Iterator;

import soot.Scene;
import soot.SootClass;
import soot.util.Chain;


public class ClassHierarchy {
	
	public final static String FILE = "ch";

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
	
	boolean isProviderClass(String sig) {
		if (!Scene.v().containsClass(sig)) return false;		
		SootClass c = Scene.v().getSootClass(sig);
		boolean isproviderclass = c.getName().equals("android.content.ContentProvider");
		while (isproviderclass == false && ! c.getName().equals("java.lang.Object")) {
			c = c.getSuperclass();
			if (c.getName().equals("android.content.ContentProvider")) {
				isproviderclass = true;
			}
		}
		return isproviderclass;
	}
		
	/**
	 * @param args
	 * @throws IOException 
	 */
	public ClassHierarchy(SootClass mclass) throws IOException {	
		BufferedWriter out = new BufferedWriter(new FileWriter(FILE));
    
        out.write(mclass.getName()+",");
        
        int interCount = mclass.getInterfaceCount(); 
        if (interCount > 0) {
        	Chain<SootClass> interfaces = mclass.getInterfaces();
        	Iterator<SootClass> iter = interfaces.iterator();
        	out.write("INTERFACES:"+interCount+":");
        	while (iter.hasNext()) {
        		SootClass sc = iter.next();
        		out.write(sc.getName()+":");
        	}
        }
        out.write(",");
        
        if (mclass.hasSuperclass()) {
        	SootClass sc = mclass.getSuperclass();
        	if (!sc.getName().equals("java.lang.Object")) {
        		out.write("SUPER:"+mclass.getSuperclass().getName());
        	}
        }
        out.write(",");
        
        if (mclass.hasOuterClass()) {
            out.write("OUTER:"+mclass.getOuterClass().getName()); 
        }
        out.write(",");
        
        if (isHandlerClass(mclass.getName())) {
        	out.write("ISHANDLER");
        }
        out.write(",");
        
        if (isProviderClass(mclass.getName())) {
        	out.write("ISPROVIDER");
        }
        out.write(",");
        
        if (mclass.isAbstract()) {
            out.write("ISABSTRACT");        	
        }
        out.write(",");
        
        if (mclass.isConcrete()) {
        	out.write("ISCONCRETE");
        }
        out.write(",");
        
        if (mclass.isInterface()) {
        	out.write("ISINTERFACE");
        }
        out.write("\n");
        out.close();
	}

}
