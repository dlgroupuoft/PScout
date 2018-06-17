#!/usr/bin/perl

$inputfile = "urifield";
$content_provider_perm_file = "contentproviderpermission";
$reached_content_provider_perm_file = "reachedcontentproviderpermission";
$calltablefile = "callgraph";
$classfile = "classhierarchy";

%contentprovidermapping = ();

%knownaccess = (
"<android.app.Activity: android.database.Cursor managedQuery(android.net.Uri,java.lang.String[],java.lang.String,java.lang.String)>",1,
"<android.content.ContentResolver: android.database.Cursor query(android.net.Uri,java.lang.String[],java.lang.String,java.lang.String[],java.lang.String)>",1,
"<android.content.ContentResolver: int update(android.net.Uri,android.content.ContentValues,java.lang.String,java.lang.String[])>",1,
"<android.content.ContentResolver: android.net.Uri insert(android.net.Uri,android.content.ContentValues)>",1,
"<android.content.ContentResolver: int bulkInsert(android.net.Uri,android.content.ContentValues[])>",1,
"<android.content.ContentResolver: int delete(android.net.Uri,java.lang.String,java.lang.String[])>",1,
"<android.content.ContentProviderOperation: android.content.ContentProviderOperation\$Builder newInsert(android.net.Uri)>",1,
"<android.content.ContentProviderOperation: android.content.ContentProviderOperation\$Builder newUpdate(android.net.Uri)>",1,
"<android.content.ContentProviderOperation: android.content.ContentProviderOperation\$Builder newDelete(android.net.Uri)>",1,
"<android.content.ContentProviderOperation: android.content.ContentProviderOperation\$Builder newAssertQuery(android.net.Uri)>",1,
);

open CLASS, "<$classfile" or die $!;
%providerclass = ();
while (<CLASS>) {
	chomp($_);
	if ($_ =~ m/^([^,]*),(.*)$/) {
		$c = $1;
		$info = $2;
		if ($info =~ m/ISPROVIDER/) {
			$providerclass{$c} = 1;
		}
	}
}
$providerclass{"com.android.providers.contacts.LegacyApiSupport"} = 1;
close CLASS;

open CONTENT, "<$content_provider_perm_file" or die $!;
%content_provider_perm = ();
while (<CONTENT>) {
	$line = $_;
	$line =~ s/\n$//;
	@tok = split(/ /, $line);
	$uri = $tok[0];
	$mode = $tok[1];
	$perm = $tok[2];
	$content_provider_perm{$uri}{$mode}{$perm} = 1;
}
close(CONTENT);
if (-e $reached_content_provider_perm_file) {
	open CONTENT, "<$reached_content_provider_perm_file" or die $!;
	while (<CONTENT>) {
		$line = $_;
		$line =~ s/\n$//;
		@tok = split(/ /, $line);
		$uri = $tok[0];
		$mode = $tok[1];
		$perm = $tok[2];
		$content_provider_perm{$uri}{$mode}{$perm} = 1;
	}
	close(CONTENT);
}

#create final uri field to permission mapping
%fieldmapping = ();
$currentmethod = "";
%unresolved = ();
%parsedurimethod = ();
open FILE, "<$inputfile" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^Field:(.*)"(.*)"/) {
		$field = $1;
		$content = $2;
		foreach (keys %content_provider_perm) {
			$f = $_;
			if ($content =~ m/$f/) {
				if (exists $content_provider_perm{$f}{"R"}) {
					foreach $p (keys %{$content_provider_perm{$f}{"R"}}) {
						$fieldmapping{$field}{"R"}{$p} = 1;
					#print "CONTENT:$content"."\nPERM:".$content_provider_perm{$_}{"R"}."\n"
					}
				}
				if (exists $content_provider_perm{$f}{"W"}) {
					foreach $p (keys %{$content_provider_perm{$f}{"W"}}) {
						$fieldmapping{$field}{"W"}{$p} = 1;
					#print "CONTENT:$content"."\nPERM:".$content_provider_perm{$_}{"W"}."\n"
					}
				}
			}
		}
		$currentmethod = "";
	} elsif ($_ =~ m/^Field:<(.*)><(.*)>/) {
		$field = "<$1>";
		$contentfield = "<$2>";
		$unresolved{$field} = $contentfield;
	} elsif ($_ =~ m/^URIMETHOD:<(.*)><(.*)>/) {
		$method = "<$1>";
		$contentfield = "<$2>";
		$parsedurimethod{$method} = $contentfield;
	}
}
close FILE;
#multiple passes to take care transitivity
$count = 0;
while ($count < 5) {
	foreach $field (keys %unresolved) {
		$contentfield = $unresolved{$field};
		if (defined $fieldmapping{$contentfield}) {
			if (defined $fieldmapping{$contentfield}{"R"}) {
				foreach $p (keys %{$fieldmapping{$contentfield}{"R"}}) {
					$fieldmapping{$field}{"R"}{$p} = 1;
				}
			}
			if (defined $fieldmapping{$contentfield}{"W"}) {
				foreach $p (keys %{$fieldmapping{$contentfield}{"W"}}) {
					$fieldmapping{$field}{"W"}{$p} = 1;
				}
			}
		} 
	}
	$count++;
}

foreach $method (keys %parsedurimethod) {
	if (defined $fieldmapping{$parsedurimethod{$method}}{"R"}) {
		foreach $p (keys %{$fieldmapping{$parsedurimethod{$method}}{"R"}}) {
			$contentprovidermapping{$p}{$method} = 1;
		}
	}
	if (defined $fieldmapping{$parsedurimethod{$method}}{"W"}) {
		foreach $p (keys %{$fieldmapping{$parsedurimethod{$method}}{"W"}}) {
			$contentprovidermapping{$p}{$method} = 1;
		}
	}
}

#find content provider access with indirect calls to query/insert/delete/update with call graph
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
	}
}
close(FILE);

open FILE, "<$inputfile" or die $!;
while (<FILE>) {
	if ($_ =~ m/^UNKNOWNUSAGE:(.*)STMT:(.*)FIELD:(.*)$/) {
		$line = $_;
		$m = $1;
		$s = $2;
		$f = $3;
#staticinvoke <android.provider.Settings$System: android.net.Uri getUriFor(java.lang.String)>("show_web_suggestions")
		if ($f =~ m/^(.*\(.*\)>)\(.*\)$/) {
			$f = $1;
		}
		if (! exists $fieldmapping{$f}) {next;}
		if ($s =~ m/query\(/ || $s =~ m/Query\(/) {
			if (exists $fieldmapping{$f}{"R"}) {
				foreach $p (keys %{$fieldmapping{$f}{"R"}}) {
					$contentprovidermapping{$p}{$m} = 1;
				#print "R $m ".$fieldmapping{$f}{"R"}."\n";
				}
			}
		} elsif ($s =~ m/insert\(/i || $s =~ m/delete\(/i || $s =~ m/update\(/i || $s =~ m/bulkInsert\(/i) {
			if (exists $fieldmapping{$f}{"W"}) {
				foreach $p (keys %{$fieldmapping{$f}{"W"}}) {
					$contentprovidermapping{$p}{$m} = 1;
				#print "W $m ".$fieldmapping{$f}{"W"}."\n";
				}
			}
		} else {
			#is this a provider class?
			$m =~ m/^<(.*): ([^ ]* [^ ]*)>/;
			$thisclass = $1;
			$thismethod = $2;
			if (exists $providerclass{$thisclass}) {

#$r = "android.database.Cursor query(android.net.Uri,java.lang.String[],java.lang.String,java.lang.String[],java.lang.String)";
#$w = "int update(android.net.Uri,android.content.ContentValues,java.lang.String,java.lang.String[])";
#$w2 = "android.net.Uri insert(android.net.Uri,android.content.ContentValues)";
#$w3 = "int bulkInsert(android.net.Uri,android.content.ContentValues[])";
#$w4 = "int delete(android.net.Uri,java.lang.String,java.lang.String[])";

				if ($thismethod =~ m/query\(/ || $thismethod =~ m/Query\(/) {
					if (exists $fieldmapping{$f}{"R"}) {
						foreach $p (keys %{$fieldmapping{$f}{"R"}}) {
							$contentprovidermapping{$p}{$m} = 1;
						#print "R $m ".$fieldmapping{$f}{"R"}."\n";
						}
					}
					next;
				} elsif ($thismethod =~ m/insert\(/i || $thismethod =~ m/delete\(/i || $thismethod =~ m/update\(/i || $thismethod =~ m/bulkInsert\(/i) {
					if (exists $fieldmapping{$f}{"W"}) {
						foreach $p (keys %{$fieldmapping{$f}{"W"}}) {
							$contentprovidermapping{$p}{$m} = 1;
						#print "W $m ".$fieldmapping{$f}{"W"}."\n";
						}
					}
					next;
				}
			}

			#look for indirect call to content provider access
			if ($s =~ m/invoke[^<]*<(.*)>\(.*\)$/) {
				$invokemethod = "<".$1.">";
			} else {
				#print "!!FLAG STMT NOT INVOKE NOT KNOWN!! $_\n";
				next;
			}
			if ($invokemethod =~ m/^<java\./) {
				#print "SKIPPING $line\n";
				next;
			}
			@workingset = ();
			$found = 0;
			$count = 0;
			$foundread = 0;
			$foundwrite = 0;
			push (@workingset, $invokemethod);
			foreach (@workingset) {
				$workingmethod = $_;
				#print "$_\n";

				#is this a provider class?
				$workingmethod =~ m/^<(.*): ([^ ]* [^ ]*)>/;
				$thisclass = $1;
				$thismethod = $2;
				$con = 1;
				if (exists $providerclass{$thisclass}) {
					if ($thismethod =~ m/query\(/ || $thismethod =~ m/Query\(/) {
						if (exists $fieldmapping{$f}{"R"}) {
							foreach $p (keys %{$fieldmapping{$f}{"R"}}) {
								$contentprovidermapping{$p}{$m} = 1;
								#print "R $m ".$fieldmapping{$f}{"R"}."\n";
							}
						}
						$foundread = 1;
						if($foundread == 1 && $foundwrite == 1) {@workingset = ();}
						$con = 0;
					} elsif ($thismethod =~ m/insert\(/i || $thismethod =~ m/delete\(/i || $thismethod =~ m/update\(/i || $thismethod =~ m/bulkInsert\(/i) {
						if (exists $fieldmapping{$f}{"W"}) {
							foreach $p (keys %{$fieldmapping{$f}{"W"}}) {
								$contentprovidermapping{$p}{$m} = 1;
							#print "W $m ".$fieldmapping{$f}{"W"}."\n";
							}
						}
						$foundwrite = 1;
						if($foundread == 1 && $foundwrite == 1) {@workingset = ();}
						$con = 0;
					}
				}
				if ($con == 0) {next;}

				if (exists $knownaccess{$workingmethod}) {
					if ($workingmethod =~ m/query/ || $workingmethod =~ m/Query/) {
						if (exists $fieldmapping{$f}{"R"}) {
							foreach $p (keys %{$fieldmapping{$f}{"R"}}) {
								$contentprovidermapping{$p}{$m} = 1;
							#print "R $m ".$fieldmapping{$f}{"R"}."\n";
							}
						}
						$foundread = 1;
					} else {
						if (exists $fieldmapping{$f}{"W"}) {
							foreach $p (keys %{$fieldmapping{$f}{"W"}}) {
								$contentprovidermapping{$p}{$m} = 1;
							#print "W $m ".$fieldmapping{$f}{"W"}."\n";
							}
						}
						$foundwrite = 1;
					}
					if($foundread == 1 && $foundwrite == 1) {@workingset = ();}
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
				if ($count % 500 == 0) {
					#print "ATTENTION $count $line\n";
					@workingset = ();
				}
			}
			if ($foundread == 0 and $foundwrite == 0) {
				#print "!!FLAG INVOKE NOT SINK!! $_\n";
			}

		}
		$currentmethod = "";
	} elsif ($_ =~ m/^METHOD:(.*)$/) {
		$currentmethod = $1;
	} elsif ($_ =~ m/^R (.*)$/) {
		$f = $1;
		if ($f =~ m/^(.*\(.*\)>)\(.*\)$/) {
			$f = $1;
		}
		if (! exists $fieldmapping{$f}) {next;}
		if (exists $fieldmapping{$f}{"R"}) {
			foreach $p (keys %{$fieldmapping{$f}{"R"}}) {
				$contentprovidermapping{$p}{$currentmethod} = 1;
			#print "R $currentmethod ".$fieldmapping{$f}{"R"}."\n";
			}
		}
	} elsif ($_ =~ m/^W (.*)$/) {
		$f = $1;
		if ($f =~ m/^(.*\(.*\)>)\(.*\)$/) {
			$f = $1;
		}
		if (! exists $fieldmapping{$f}) {next;}
		if (exists $fieldmapping{$f}{"W"}) {
			foreach $p (keys %{$fieldmapping{$f}{"W"}}) {
				$contentprovidermapping{$p}{$currentmethod} = 1;
			#print "W $currentmethod ".$fieldmapping{$f}{"W"}."\n";
			}
		}
	}
}
close FILE;

foreach $p (keys %contentprovidermapping) {
	print "PERMISSION:$p\n";
	if (exists $contentprovidermapping{$p}) {
		foreach $m (keys %{$contentprovidermapping{$p}}) {
			print "$m\n";
		}
	}
}

open FIELDMAP, ">contentproviderfieldpermission" or die $!;
$permrequirement = ();
foreach $f (keys %fieldmapping) {
	foreach $t (keys %{$fieldmapping{$f}}) {
		foreach $p (keys %{$fieldmapping{$f}{$t}}) {
			push (@{$permrequirement{$p}},$f);
		}
	}
}
foreach $p (keys %permrequirement) {
	print FIELDMAP "PERMISSION:$p\n";
	foreach (@{$permrequirement{$p}}) {
		print FIELDMAP "$_\n";
	}
}
close FIELDMAP;
