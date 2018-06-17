#!/usr/bin/perl

#permission check files
$check1 = "stringpermissioncheck";
#$check2 = "broadcaststickycheck";
$check3 = "contentprovidercheck";
$check4 = "contentproviderdynamiccheck";
$check5 = "intentpermissioncheck";
$callgraph = "callgraph";
$permissions = "permissions";
$classhierarchy = "classhierarchy";

%checks = ();
%target = ();
%src = ();

#load 3rd party permissions
open FILE, "<$permissions" or die $!;
%thirdperm = ();
while (<FILE>) {
	$line = $_;
	$line =~ s/\n$//;
	$thirdperm{$line} = 1;
}
close(FILE);

#load checks
$currentperm = "";
open FILE, "<$check1" or die $1;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^PERMISSION:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(<.*>)$/) {
		$checks{$currentperm}{$1} = 1;
	}
}
close FILE;
open FILE, "<$check3" or die $1;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^PERMISSION:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(<.*>)$/) {
		$checks{$currentperm}{$1} = 1;
	}
}
close FILE;
open FILE, "<$check4" or die $1;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^PERMISSION:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(<.*>)$/) {
		$checks{$currentperm}{$1} = 1;
	}
}
close FILE;
open FILE, "<$check5" or die $1;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^PERMISSION:(.*)$/) {
		$currentperm = $1;
	} elsif ($_ =~ m/^(<.*>)$/) {
		$checks{$currentperm}{$1} = 1;
	}
}
close FILE;

#load class information
open CLASS, "<$classhierarchy" or die $!;
%child = ();
while (<CLASS>) {
	$_ =~ s/\n//;
	if ($_ =~ m/^([^,]*),.*SUPER:([^,]*),/) {
		$child{$2}{$1} = 1;
	}
}
close CLASS;
sub parenthaschild {
	my($p, $c) = @_;
	@workingchildset = ();
	foreach (keys %{$child{$p}}) {
		return 1 if ($_ eq $c);
		push (@workingchildset, $_);
	}
	foreach (@workingchildset) {
		return 1 if ($_ eq $c);
		push (@workingchildset, $_) foreach (keys %{$child{$_}});
	}
	return 0;
}

#load call graph
open FILE, "<$callgraph" or die $!;
while (<FILE>) {
	chomp($_);
	$_ =~ s/\n//;
	if ($_ =~ m/^SRC:(.*)TGT:(.*)$/) {
		$source = $1;
		$targ = $2;
		$target{$source}{$targ} = 1;
		$src{$targ}{$source} = 1;
	}
}
close FILE;

#compute coverage for each permission
foreach $p (keys %checks) {
	next if (!defined $thirdperm{$p});
	@workingset = ();
	%worked = ();
	%protected = ();
	foreach $m (keys %{$checks{$p}}) {
		$protected{$m} = 1;
		push(@workingset, $m);
		
		if ($m =~ m/ enforce/ || $m =~ m/ check/) {
			foreach(keys %{$src{$m}}) {
				$protected{$_} = 1;
				push(@workingset, $_) 
			}
		}
	}
	
	$count = 0;
	foreach $m (@workingset) {
		next if (defined $worked{$m});
		if ($count > 3000) {
			print "MAXED OUT!!!\n" if ($count == 3001);
			$count++;
			next;
		}
		#print $m."\n";
		
		$m =~ m/^<(.*): .* (.*)\(/;
		$mclass = $1;
		$mmethod = $2;
	
		@sources = keys %{$src{$m}};
		@targets = keys %{$target{$m}};
		
		$isprotected = 1;
		foreach (@sources) {
			#print "S  $_\n";
			$isprotected = 0 if (!defined $protected{$_});
		}
		next if ($isprotected == 0 && $protected{$m} != 1);

		$protected{$m} = 1;
		foreach (@targets) {
			$_ =~ m/^<(.*): .* (.*)\(/;
			$targetclass = $1;
			$targetmethod = $2;
			next if (parenthaschild($mclass, $targetclass) == 1 && $mmethod eq $targetmethod);
			push (@workingset, $_);
			#print "T  $_\n";
		}
		$count++;	
		$worked{$m} = 1;
	}
	
	print "Permission:$p\n";
	@keys = keys %protected;
	@checks = keys %{$checks{$p}};
	print scalar(@checks)." checks protect ".scalar(@keys)." methods\n";
	foreach $m (keys %protected) {
		print "$m\n";
	}
}

