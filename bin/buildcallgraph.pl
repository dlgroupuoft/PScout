#!/usr/bin/perl

$callgraphrawfile = "rawcallgraph";
$classhierarchyfile = "classhierarchy";

#load class hierarchy information
#classhierarchy
#	class
#		super
#		interfaces
%classhierarchy = ();	#get parent classes, get interfaces
%parent2child = ();	#get child classes
%interface2impl = ();	#get implementation classes

%parentclasseshash = ();
%childclasseshash = ();
%interfaceclasseshash = ();
%implclasseshash = ();

open FILE, "<$classhierarchyfile" or die $!;
while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ m/^(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*),(.*)$/) {
		$class = $1;
		$interfaceline = $2;
		@interfaces = ();
		$superclassline = $3;
		$superclass = "";
		$outerclassline = $4;
		$outerclass = "";
		$ishandler = $5;
		$isprovider = $6;
		$isabstract = $7;
		$isconcreate = $8;
		$isinterface = $9;

		if ($superclassline ne "") {
			$superclassline =~ m/SUPER:(.*)/;
			$superclass = $1;
			$classhierarchy{$class}{"super"} = $superclass;
			push (@{$parent2child{$superclass}}, $class);
		}

		#if ($outerclassline ne "") {
		#	$outerclassline =~ m/OUTER:(.*)/;
		#	$outerclass = $1;
		#}

		if ($interfaceline ne "") {
			@tokens =  split(/:/, $interfaceline);
			$interfacecount = 0;
			$count = 0;
			foreach (@tokens) {
				if ($_ eq "INTERFACES") {
				} elsif ($_ =~ m/^([\d]*)$/) {
					$interfacecount = $1;
				} else {
					push (@{$classhierarchy{$class}{"interfaces"}}, $_);
					push (@{$interface2impl{$_}}, $class);
					$count++;
				}
			}
			if ($interfacecount != $count) {
				die "ERROR in parsing interfaces";
			}
		}
	}
}
close FILE;

#find all parent classes and store in parentclasseshash
foreach $c (keys %classhierarchy) {
	$currentclass = $c;
	while (exists $classhierarchy{$currentclass}{"super"}) {
		push (@{$parentclasseshash{$c}}, $classhierarchy{$currentclass}{"super"});
		$currentclass = $classhierarchy{$currentclass}{"super"};
	}
}

#find all child classes and store in childclasseshash
foreach $p (keys %parent2child) {
	foreach (@{$parent2child{$p}}) {
		push (@{$childclasseshash{$p}}, $_);
	}
	foreach $x (@{$childclasseshash{$p}}) {
		if (exists $parent2child{$x}) {
			foreach (@{$parent2child{$x}}) {
				push (@{$childclasseshash{$p}}, $_);
			}
		}
	}
}

#find all interface classes and store in interfaceclasseshash
foreach $c (keys %classhierarchy) {
	if (exists $classhierarchy{$c}{"interfaces"}) {
		foreach (@{$classhierarchy{$c}{"interfaces"}}) {
			push (@{$interfaceclasseshash{$c}}, $_);
		}
	}
	foreach $i (@{$interfaceclasseshash{$c}}) {
		if (exists $classhierarchy{$i}{"interfaces"}) {
			foreach (@{$classhierarchy{$i}{"interfaces"}}) {
				push (@{$interfaceclasseshash{$c}}, $_);
			}
		}
	}
}

#find all implementation classes and store in implclasseshash
foreach $i (keys %interface2impl) {
	foreach (@{$interface2impl{$i}}) {
		push (@{$implclasseshash{$i}}, $_);
	}
	foreach $x (@{$implclasseshash{$i}}) {
		if (exists $interface2impl{$x}) {
			foreach (@{$interface2impl{$x}}) {
				push (@{$implclasseshash{$i}}, $_);
			}
		}
	}
}

#save some memory
%classhierarchy = ();
%parent2child = ();
%interface2impl = ();

#load ctraw data into hash structure
#ctraw
#	class
#		method
#			method
#				type
%ctraw = ();
open FILE, "<$callgraphrawfile" or die $!;
while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ m/^SRC:<(.*): (.* .*)>TYPE:(.*);CALLING:(.*)$/) {
		$srcclass = $1;
		$srcmethod = $2;
		$invoketype = $3;
		$invokemethod = $4;
		#$ctraw{$srcclass}{$srcmethod}{"type"} = $invoketype;
		#$ctraw{$srcclass}{$srcmethod}{"method"} = $invokemethod;

		$ctraw{$srcclass}{$srcmethod}{$invokemethod} = $invoketype;
	} elsif ($_ =~ m/^SRC:<(.*): (.* .*)>DECLARATION$/) {
		$ctraw{$1}{$2}{"declaration"} = 1;
	} elsif ($_ =~ m/^SRC:<(.*): (.* .*)>NOIMPL$/) {
		$ctraw{$1}{$2}{"noimpl"} = 1;
	}
}
close FILE;

#virtual invoke
foreach $c (keys %childclasseshash) {
	foreach $m (keys %{$ctraw{$c}}) {
		foreach (@{$childclasseshash{$c}}) {
			print "SRC:<$c: $m>TGT:<$_: $m>\n";

			#traverse up the hierarchy tree to look for implementation of method
			if (!(exists $ctraw{$_}{$m})) {
				$currclass = $_;
				$found = 0;
				foreach (@{$parentclasseshash{$currclass}}) {
					if (exists $ctraw{$_}{$m}{"declaration"}) {
						print "SRC:<$currclass: $m>TGT:<$_: $m>\n";
						$found = 1;
						last;
					}
				}
				#if ($found == 0) { print "Failed to resolve call to $invokemethod\n"; }
			}
		}
	}
}

#interface invoke
foreach $c (keys %implclasseshash) {
	foreach $m (keys %{$ctraw{$c}}) {
		if (! exists $ctraw{$c}{$m}{"noimpl"}) { next; }
		foreach $impl (@{$implclasseshash{$c}}) {	
			print "SRC:<$c: $m>TGT:<$impl: $m>\n";
		}
	}
}

%resolvedmethods = ();
foreach $c (keys %ctraw) {
	foreach $m (keys %{$ctraw{$c}}) {
		foreach $invokemethod (keys %{$ctraw{$c}{$m}}) {
			$invoketype = $ctraw{$c}{$m}{$invokemethod};
			$invokeclass;
			$invokemethodsub;

			if ($invokemethod eq "declaration" || $invokemethod eq "noimpl") { next; }
			if ($invokemethod =~ m/^<(.*): (.* .*)>$/) {
				$invokeclass = $1;
				$invokemethodsub = $2;
			} else { die "Invalid invoke method?!"; }	 

			if ($invoketype eq "FINALIZE") { next; }
			print "SRC:<$c: $m>TGT:$invokemethod\n";

			#if (exists $resolvedmethods{$invokemethod}) { next; }
			if ($invoketype eq "VIRTUALINVOKE") {					
				#all child classes are potential targets to virtual calls
				foreach (@{$childclasseshash{$invokeclass}}) {
					if (exists $ctraw{$_}{$invokemethodsub}) {
						print "SRC:$invokemethod"."TGT:<$_: $invokemethodsub>\n";
					}
				}

				#traverse up the hierarchy tree to look for implementation of method
				if (!(exists $ctraw{$invokeclass}{$invokemethodsub})) {
					$found = 0;
					foreach (@{$parentclasseshash{$invokeclass}}) {
						if (exists $ctraw{$_}{$invokemethodsub}{"declaration"}) {
							print "SRC:$invokemethod"."TGT:<$_: $invokemethodsub>\n";
							$found = 1;
							last;
						}
					}
					#if ($found == 0) { print "Failed to resolve call to $invokemethod\n"; }
				}
			} elsif ($invoketype eq "INTERFACEINVOKE") {
				#all impl classes are potential targets to interface calls
				foreach (@{$implclasseshash{$invokeclass}}) {
					if (exists $ctraw{$_}{$invokemethodsub}) {
						print "SRC:$invokemethod"."TGT:<$_: $invokemethodsub>\n";
					}
				}
			}
			$resolvedmethods{$invokemethod} = 1;
		}
	}
}

