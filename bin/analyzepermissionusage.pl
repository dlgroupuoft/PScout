#!/usr/bin/perl

$foundseedfile = "permissionstringusage";
$calltablefile = "callgraph";

%knownPermissionClass = (
	"android.content.Context", 1,
	"android.content.ContextWrapper", 1,
	"com.android.server.am.ActivityManagerService", 1,
	"android.content.pm.PackageManager", 1,
	"com.android.server.pm.PackageManagerService", 1,
	"android.app.PendingIntent", 1,
);

# 1 = check permission
# 2 = check calling
# 3 = perm required to receive
# 4 = perm required to send
%knownPermissionCheck = (
	"checkPermission", 1,
	"checkCallingPermission", 2,
	"checkCallingOrSelfPermission", 2,
	"enforcePermission", 1,
	"enforceCallingPermission", 2,
	"enforceCallingOrSelfPermission", 2,
	"sendBroadcast", 3,
	"sendOrderedBroadcast", 3,
	"registerReceiver", 4,
	"checkComponentPermission", 2,
	"broadcastIntentLocked", 3,
	"isPermissionEnforced", 2, 
	"isPermissionEnforcedLocked", 2,
	"send", 3,
);

%sinks;
%sinktype;

# find sinks with direct calls to knownPermissionCheck
$perm;
$method;
$stmt;
$invokeclass;
$invokemethod;
$directuse;
open FILE, "<$foundseedfile" or die $!;
@file = <FILE>;
close FILE;
foreach (@file) {
	$_ =~ s/\n//;
	if ($_ =~ m/^PER:(.*)METHOD:(.*)STMT:(.*)NOTDIRECTUSE$/) {
		$perm = $1;
		$method = $2;
		$stmt = $3;
		$directuse = 0;
	} elsif ($_ =~ m/^PER:(.*)METHOD:(.*)STMT:(.*)$/) {
		$perm = $1;
		$method = $2;
		$stmt = $3;
		$directuse = 1;
	}
#	<android.webkit.WebIconDatabase: void releaseIconForPageUrl(java.lang.String)>
	if ($stmt =~ m/invoke.*<(.*)>\(.*\)$/) {
		$tmp = "<".$1.">";
		$tmp =~ m/^<(.*): .* (.*)\(/;
		$invokeclass = $1;
		$invokemethod = $2;
	} else {
		next;
	}
	if (defined $knownPermissionClass{$invokeclass} && defined $knownPermissionCheck{$invokemethod}) {
		$sinktype{$perm.$method} = $knownPermissionCheck{$invokemethod};
		if (! exists $sinks{$perm}) {
			push (@{$sinks{$perm}}, $method);
		} elsif (! ($method ~~ @{$sinks{$perm}})) {
			push (@{$sinks{$perm}}, $method);
		}
	}
}

#find sinks with indirect calls to knownPermissionCheck
open FILE, "<".$calltablefile or die $!;
%lookup;
while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ /^SRC:(.*)TGT:(.*)/) {
		$src = $1;
		$tgt = $2; 
		if (! exists $lookup{$src}) {
			push (@{$lookup{$src}}, $tgt);
		} elsif (! ($tgt ~~ @{$lookup{$src}})) {
			push (@{$lookup{$src}}, $tgt);
		}
#		if ($_ =~ /virtualinvoke.*\.<(.*)>\(/) {
#			$virtualsrc = "<".$1.">";
#			if (! exists $lookup{$virtualsrc}) {
#				push (@{$lookup{$virtualsrc}}, $tgt);
#			} elsif (! ($tgt ~~ @{$lookup{$virtualsrc}})) {
#				push (@{$lookup{$virtualsrc}}, $tgt);
#			}			
#		}
	}
}
close(FILE);

foreach (@file) {
	$_ =~ s/\n//;
	$line = $_;
	if ($_ =~ m/^PER:(.*)METHOD:(.*)STMT:(.*)NOTDIRECTUSE$/) {
		$perm = $1;
		$method = $2;
		$stmt = $3;
		$directuse = 0;
	} elsif ($_ =~ m/^PER:(.*)METHOD:(.*)STMT:(.*)$/) {
		$perm = $1;
		$method = $2;
		$stmt = $3;
		$directuse = 1;
	}
	#skip if it's already known that method is checking for the permission
	if (exists $sinks{$perm}) {
		if ($method ~~ @{$sinks{$perm}}) {
			next;
		}
	}
	if ($stmt =~ m/invoke.*<(.*)>\(.*\)$/) {
		$invokemethod = "<".$1.">";
	} else {
		print "!!FLAG STMT NOT INVOKE NOT KNOWN!! $_\n";
		next;
	}

	if ($invokemethod =~ m/^<java\./) {
		print "SKIPPING $line\n";
		next;
	}

	@workingset = ();
	$found = 0;
	$count = 0;
	push (@workingset, $invokemethod);
	foreach (@workingset) {
		$workingmethod = $_;
		$workingmethod =~ m/^<(.*): .* (.*)\(/;
		$wclass = $1;
		$wmethod = $2;
		if (defined $knownPermissionClass{$wclass} && defined $knownPermissionCheck{$wmethod}) {
			$found = 1;
			$sinktype{$perm.$method} = $knownPermissionCheck{$wmethod};
			if (! exists $sinks{$perm}) {
				push (@{$sinks{$perm}}, $method);
			} elsif (! ($method ~~ @{$sinks{$perm}})) {
				push (@{$sinks{$perm}}, $method);
			}
			@workingset = ();
		} elsif (exists $lookup{$workingmethod}) {
			foreach (@{$lookup{$workingmethod}}) {
				if ($_ =~ m/^<java\./) { 
					#print "SKIPPING $_\n";
				} elsif (! ($_ ~~ @workingset)) {
					push (@workingset, $_)
				}
			}
		}
		$count++;
		if ($count % 100 == 0) {
			print "ATTENTION $count $line\n";
		}
	}
	if ($found == 0) {
		print "!!FLAG INVOKE NOT SINK!! $_\n";
	}
}

#print results
foreach (keys %sinks) {
	$p = $_;
	foreach (@{$sinks{$_}}) {
		print "PER:$p"."TYPE:".$sinktype{$p.$_}."METHOD:$_\n";
	}
}

