#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;

open MANLIST, "<manifestlist" or die $!;
while (<MANLIST>) {

chomp($_);
$file = $_;

next if (-B "$file");

print "Processing $file -----\n";

$xml = new XML::Simple;

eval{
$data = $xml->XMLin($file);
};
if ($@) {
print "ERROR! Failed to parse $file...\n";
}

$package = $data->{"package"};

if (exists $data->{"application"}->{"android:permission"}) {
	print "Application ".$package." ".$data->{"application"}->{"android:permission"}."\n";
}

@perms;
if (UNIVERSAL::isa($data->{"permission"}, 'ARRAY')) {
	@perms = @{$data->{"permission"}};
} elsif (exists $data->{"permission"}) {
	push (@perms, $data->{"permission"});
}
foreach (@perms) {
	print "Permission ".$package." ".$_->{"android:name"}." ".$_->{"android:protectionLevel"}."\n";
}

@activities;
if (UNIVERSAL::isa($data->{"application"}->{"activity"}, 'ARRAY')) {
	@activities = @{$data->{"application"}->{"activity"}};
} elsif (exists $data->{"application"}->{"activity"}) {
	push (@activities, $data->{"application"}->{"activity"});
}
foreach (@activities) {
	if (exists $_->{"android:permission"}) {
		$activityname = $_->{"android:name"};
		$permname = $_->{"android:permission"};
		if ($activityname =~ m/^\./) {
			print "Activity ".$package.$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		} elsif (index($activityname, ".") == -1) {
			print "Activity ".$package.".".$_->{"android:name"}." ".$_->{"android:permission"}."\n";		
		} else {
			print "Activity ".$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		}
		
		%intents = ();
		if (UNIVERSAL::isa($_->{"intent-filter"}, 'ARRAY')) {
			foreach $if (@{$_->{"intent-filter"}}) {
				if (UNIVERSAL::isa($if->{"action"}, 'ARRAY')) {
					foreach $a (@{$if->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
				} else {
					$intents{$if->{"action"}->{"android:name"}} = 1;
				}
			}
		} elsif (exists $_->{"intent-filter"}) {
			if (UNIVERSAL::isa($_->{"intent-filter"}->{"action"}, 'ARRAY')) {
				foreach $a (@{$_->{"intent-filter"}->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
			} else {
				$intents{$_->{"intent-filter"}->{"action"}->{"android:name"}} = 1;
			}
		}
		print "Intent:$_ $permname S\n" foreach (keys %intents);
	} 
	#print $_->{"android:name"}."\n";
}
@activitiesalias;
if (UNIVERSAL::isa($data->{"application"}->{"activity-alias"}, 'ARRAY')) {
	@activitiesalias = @{$data->{"application"}->{"activity-alias"}};
} elsif (exists $data->{"application"}->{"activity-alias"}) {
	push (@activitiesalias, $data->{"application"}->{"activity-alias"});
}
foreach (@activitiesalias) {
	if (exists $_->{"android:permission"}) {
		$activityname = $_->{"android:name"};
		$permname = $_->{"android:permission"};
		if ($activityname =~ m/^\./) {
			print "Activity ".$package.$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		} elsif (index($activityname, ".") == -1) {
			print "Activity ".$package.".".$_->{"android:name"}." ".$_->{"android:permission"}."\n";		
		} else {
			print "Activity ".$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		}
		
		%intents = ();
		if (UNIVERSAL::isa($_->{"intent-filter"}, 'ARRAY')) {
			foreach $if (@{$_->{"intent-filter"}}) {
				if (UNIVERSAL::isa($if->{"action"}, 'ARRAY')) {
					foreach $a (@{$if->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
				} else {
					$intents{$if->{"action"}->{"android:name"}} = 1;
				}
			}
		} elsif (exists $_->{"intent-filter"}) {
			if (UNIVERSAL::isa($_->{"intent-filter"}->{"action"}, 'ARRAY')) {
				foreach $a (@{$_->{"intent-filter"}->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
			} else {
				$intents{$_->{"intent-filter"}->{"action"}->{"android:name"}} = 1;
			}
		}
		print "Intent:$_ $permname S\n" foreach (keys %intents);
	} 
	#print $_->{"android:name"}."\n";
}

@services;
if (UNIVERSAL::isa($data->{"application"}->{"service"}, 'ARRAY')) {
	@services = @{$data->{"application"}->{"service"}};
} elsif (exists $data->{"application"}->{"service"}) {
	push (@services, $data->{"application"}->{"service"});
}
foreach (@services) {
	if (exists $_->{"android:permission"}) {
		$servicename = $_->{"android:name"};
		$permname = $_->{"android:permission"};
		if ($servicename =~ m/^\./) {
			print "Service ".$package.$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		} elsif (index($servicename, ".") == -1) {
			print "Service ".$package.".".$_->{"android:name"}." ".$_->{"android:permission"}."\n";			
		} else {
			print "Service ".$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		}
		
		%intents = ();
		if (UNIVERSAL::isa($_->{"intent-filter"}, 'ARRAY')) {
			foreach $if (@{$_->{"intent-filter"}}) {
				if (UNIVERSAL::isa($if->{"action"}, 'ARRAY')) {
					foreach $a (@{$if->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
				} else {
					$intents{$if->{"action"}->{"android:name"}} = 1;
				}
			}
		} elsif (exists $_->{"intent-filter"}) {
			if (UNIVERSAL::isa($_->{"intent-filter"}->{"action"}, 'ARRAY')) {
				foreach $a (@{$_->{"intent-filter"}->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
			} else {
				$intents{$_->{"intent-filter"}->{"action"}->{"android:name"}} = 1;
			}
		}
		print "Intent:$_ $permname S\n" foreach (keys %intents);
	} 
	#print $_->{"android:name"}."\n";
}

@receivers;
if (UNIVERSAL::isa($data->{"application"}->{"receiver"}, 'ARRAY')) {
	@receivers = @{$data->{"application"}->{"receiver"}};
} elsif (exists $data->{"application"}->{"receiver"}) {
	push (@receivers, $data->{"application"}->{"receiver"});
}
foreach (@receivers) {
	if (exists $_->{"android:permission"}) {
		$receiverename = $_->{"android:name"};
		$permname = $_->{"android:permission"};
		if ($receiverename =~ m/^\./) {
			print "Receiver ".$package.$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		} elsif (index($receiverename, ".") == -1) {
			print "Receiver ".$package.".".$_->{"android:name"}." ".$_->{"android:permission"}."\n";			
		} else {
			print "Receiver ".$_->{"android:name"}." ".$_->{"android:permission"}."\n";
		}
		
		%intents = ();
		if (UNIVERSAL::isa($_->{"intent-filter"}, 'ARRAY')) {
			foreach $if (@{$_->{"intent-filter"}}) {
				if (UNIVERSAL::isa($if->{"action"}, 'ARRAY')) {
					foreach $a (@{$if->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
				} else {
					$intents{$if->{"action"}->{"android:name"}} = 1;
				}
			}
		} elsif (exists $_->{"intent-filter"}) {
			if (UNIVERSAL::isa($_->{"intent-filter"}->{"action"}, 'ARRAY')) {
				foreach $a (@{$_->{"intent-filter"}->{"action"}}) {$intents{$a->{"android:name"}} = 1;}
			} else {
				$intents{$_->{"intent-filter"}->{"action"}->{"android:name"}} = 1;
			}
		}
		print "Intent:$_ $permname S\n" foreach (keys %intents);
	} 
	#print $_->{"android:name"}."\n";
}

@providers;
if (UNIVERSAL::isa($data->{"application"}->{"provider"}, 'ARRAY')) {
	@providers = @{$data->{"application"}->{"provider"}};
} elsif (exists $data->{"application"}->{"provider"}) {
	push (@providers, $data->{"application"}->{"provider"});
}
foreach (@providers) {	
	$providername = $_->{"android:name"};
	@authorities = split(/;/, $_->{"android:authorities"});
	
	if ($providername =~ m/^\./) {
		$providername = "$package$providername";
	} elsif (index($providername, ".") == -1) {
		$providername = "$package.$providername";	
	}
	foreach (@authorities) {
		print "PROVIDER:$providername;AUTH:$_\n";
	}

	if (exists $_->{"android:readPermission"}) {
		$readperm = $_->{"android:readPermission"};
		foreach (@authorities) {
			print "contents://".$_." R ".$readperm."\n";
		}
	}
	if (exists $_->{"android:writePermission"}) {
		$writeperm = $_->{"android:writePermission"};
		foreach (@authorities) {
			print "contents://".$_." W ".$writeperm."\n";
		}
	}
	if (exists $_->{"android:permission"} && (! exists $_->{"android:readPermission"}) && (! exists $_->{"android:writePermission"})) {
		$perm = $_->{"android:permission"};
		foreach (@authorities) {
			print "contents://".$_." R ".$perm."\n";
			print "contents://".$_." W ".$perm."\n";
		}
	}

	#deals with <path-permission>
	@pathperms = ();
	if (UNIVERSAL::isa($_->{"path-permission"}, 'ARRAY')) {
		@pathperms = @{$_->{"path-permission"}};
	} elsif (exists $_->{"path-permission"}) {
		push (@pathperms, $_->{"path-permission"});
	}	
	foreach (@pathperms) {
		%pathtype = ();
		if (exists $_->{"android:path"}) {
			$key = $_->{"android:path"};
			$pathtype{$key} = "path";
		}
		if (exists $_->{"android:pathPrefix"}) {
			$key = $_->{"android:pathPrefix"};
			$pathtype{$key} = "pathPrefix";
		}
		if (exists $_->{"android:pathPattern"}) {
			$key = $_->{"android:pathPattern"};
			$pathtype{$key} = "pathPattern";
		}
		
		if (exists $_->{"android:readPermission"}) {
			$readperm = $_->{"android:readPermission"};
			foreach (keys %pathtype) {
				$path = $_;
				foreach (@authorities) {
					print "contents://".$_.$path." R ".$readperm." ".$pathtype{$path}."\n";
				}
			}
		}
		if (exists $_->{"android:writePermission"}) {
			$writeperm = $_->{"android:writePermission"};
			foreach (keys %pathtype) {
				$path = $_;
				foreach (@authorities) {
					print "contents://".$_.$path." R ".$writeperm." ".$pathtype{$path}."\n";
				}
			}
		}
		if (exists $_->{"android:permission"} && (! exists $_->{"android:readPermission"}) && (! exists $_->{"android:writePermission"})) {
			$perm = $_->{"android:permission"};
			foreach (keys %pathtype) {
				$path = $_;
				foreach (@authorities) {
					print "contents://".$_.$path." R ".$perm." ".$pathtype{$path}."\n";
					print "contents://".$_.$path." W ".$perm." ".$pathtype{$path}."\n";
				}
			}	
		}
	}

	# deals with <grant-uri-permission>
	if (exists $_->{"android:grantUriPermissions"}) {
		$grant = $_->{"android:grantUriPermissions"};
		foreach (@authorities) {
			print "contents://".$_." grantUriPermissions ".$grant."\n";
		}
	} else {
		foreach (@authorities) {
			print "contents://".$_." grantUriPermissions false\n";
		}
	}
	@grant = ();
	if (UNIVERSAL::isa($_->{"grant-uri-permission"}, 'ARRAY')) {
		@grant = @{$_->{"grant-uri-permission"}};
	} elsif (exists $_->{"grant-uri-permission"}) {
		push (@grant, $_->{"grant-uri-permission"});
	}
	foreach (@grant) {
		if (exists $_->{"android:path"}) {
			$name = $_->{"android:path"};
			foreach (@authorities) {
				print "contents://".$_.$name." grant-uri-permission path\n";
			}
		}
		if (exists $_->{"android:pathPrefix"}) {
			$name = $_->{"android:pathPrefix"};
			foreach (@authorities) {
				print "contents://".$_.$name." grant-uri-permission pathPrefix\n";
			}
		}
		if (exists $_->{"android:pathPattern"}) {
			$name = $_->{"android:pathPattern"};
			foreach (@authorities) {
				print "contents://".$_.$name." grant-uri-permission pathPattern\n";
			}		
		}
	}
}

}

#print Dumper($data);

#$method = "<android.os.PowerManager\$WakeLock: void acquire()>";
#if ($method =~ m/<(.*)\.([^\.]*): (.*) (.*)\(.*>/) {
#	$package = $1;
#	$class = $2;
#	$method = $4;
#	$class =~ s/\$/\./g;
#	print $package."\n".$class."\n".$method."\n";
#}

#if (defined $data->{"package"}->{$package}->{"class"}->{$class}->{"method"}->{$4}) {
#	print "yes\n";
#} else { 
#	print "no\n";
#}
