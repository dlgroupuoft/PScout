package dump;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Iterator;
import java.util.List;

import soot.Scene;
import soot.SootClass;
import soot.SootMethod;


public class FindRPCMethod {
	public final static String FILE = "rpc";

	/**
	 * @param args
	 * @throws IOException 
	 */
	public FindRPCMethod(SootClass mclass) throws IOException {
		BufferedWriter out = new BufferedWriter(new FileWriter(FILE));
		
		String proxyname = mclass.getName();		
		if (!proxyname.contains("$Stub$Proxy")) {
			out.close();
			return;
		}
		
		out.write("----- "+proxyname+"\n");
		
		String interfacename = proxyname.replace("$Stub$Proxy", "");		
       	SootClass interfaceclass = Scene.v().getSootClass(interfacename);
       	
       	// Get source of RPC method
       	List<SootMethod> methods = mclass.getMethods();
       	Iterator<SootMethod> iter = methods.iterator();
       	while (iter.hasNext()) {
       		SootMethod method = iter.next();
       		if (interfaceclass.declaresMethod(method.getSubSignature())) {
	       		out.write(method.toString()+"\n");
       		}
       	}
       	out.close();
	}

}
