#!/usr/bin/perl

my $calltablefilenorpc = "callgraphnorpc";
my $seedfile = "stringpermissioncheck";
my $contentseedfile = "contentprovidercheck";
my $contentseedfile2 = "contentproviderdynamiccheck";
my $specialmappingfile = "../generatesource/specialmapping";
my $publishedapifile = "current.xml";
my $rpcedgefile = "aidlcallgraphedges";
my $classhierarchyfile = "classhierarchy";
my $perm_file = "permissions";
my $msgedgefile = "sendmessagecallgraphedges";
my $broadcaststickyfile = "broadcaststickycheck";
my $intentpermissionfile = "intentpermissioncheck";
my $reachproviderfile = "permissionreachedprovider";
my $show = 0;

#load 3rd party permissions list
open PERM, "<$perm_file" or die $!;
%thirdperm = ();
while (<PERM>) {
	$line = $_;
	$line =~ s/\n$//;
	$thirdperm{$line} = 1;
}
close(PERM);

#load sinks
%seeds;
$current_permission;
$current_type;
$line;
open FILE, "<".$seedfile or die $!;
while (<FILE>) {
	$line = $_;
	$line =~ s/\n//;
	if ($line =~ /^PERMISSION:(.*)/) {
		$current_permission = $1;
	} elsif ($line =~ /^TYPE:(.*)/) {
		$current_type = $1;
	} else {
		if (!($line =~ /^\s*$/)) {
			push (@{$seeds{$current_permission}{$current_type}}, $line) if ($current_permission ne "android.permission.BROADCAST_STICKY");
		}
	}
	
}
close(FILE);
open FILE, "<".$broadcaststickyfile or die $!;
while (<FILE>) {
	$line = $_;
	$line =~ s/\n//;
	if ($line =~ /^PERMISSION:(.*)/) {
		$current_permission = $1;
	} else {
		if (!($line =~ /^\s*$/)) {
			push (@{$seeds{$current_permission}{$current_type}}, $line);
		}
	}
	
}
close(FILE);
open FILE, "<".$contentseedfile or die $!;
$current_type = 2;
while (<FILE>) {
	$line = $_;
	$line =~ s/\n//;
	if ($line =~ m/^PERMISSION:(.*)/) {
		$current_permission = $1;
	} else {
		if (!($line =~ /^\s*$/)) {
			push (@{$seeds{$current_permission}{$current_type}}, $line);
		}
	}
}
close(FILE);
if (-e $contentseedfile2) {
	open FILE, "<".$contentseedfile2 or die $!;
	$current_type = 2;
	while (<FILE>) {
		$line = $_;
		$line =~ s/\n//;
		if ($line =~ m/^PERMISSION:(.*)/) {
			$current_permission = $1;
		} else {
			if (!($line =~ /^\s*$/)) {
				push (@{$seeds{$current_permission}{$current_type}}, $line);
			}
		}
	}
}
close(FILE);
open FILE, "<".$intentpermissionfile or die $!;
$current_type = 2;
while (<FILE>) {
	$line = $_;
	$line =~ s/\n//;
	if ($line =~ m/^PERMISSION:(.*)/) {
		$current_permission = $1;
	} else {
		if (!($line =~ /^\s*$/)) {
			push (@{$seeds{$current_permission}{$current_type}}, $line);
		}
	}
}
close(FILE);

foreach $p (keys %seeds) {
	next if (! defined $thirdperm{$p});
	$count = 0;
	foreach $t (keys %{$seeds{$p}}) {
		$count += scalar(@{$seeds{$p}{$t}});
	}
	print "$p\t$count\n";
}

