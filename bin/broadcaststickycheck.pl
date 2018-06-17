#!/usr/bin/perl

$inputfile = "stringpermissioncheck";
$callgraph = "callgraph";

open FILE, "<$inputfile" or die $!;
$current_permission = "";
$current_type = "";
@broadcaststicky = ();
while (<FILE>) {
	chomp($_);
	$line = $_;
	if ($line =~ /^PERMISSION:(.*)/) {
		$current_permission = $1;
	} elsif ($line =~ /^TYPE:(.*)/) {
		$current_type = $1;
	} else {
		if (!($line =~ /^\s*$/)) {
			if ($current_permission eq "android.permission.BROADCAST_STICKY") {
				push(@broadcaststicky, $_);
			}
		}
	}
	
}
close FILE;

open FILE, "<$callgraph" or die $!;
%lookup = ();
while (<FILE>) {
	$_ =~ s/\n//;
	if ($_ =~ /^SRC:(.*)TGT:(.*)/) {
		$src = $1;
		$tgt = $2; 
		if (! exists $lookup{$tgt}) {
			push (@{$lookup{$tgt}}, $src);
		} elsif (! ($src ~~ @{$lookup{$tgt}})) {
			push (@{$lookup{$tgt}}, $src);
		}
	}
}
close(FILE);

print "PERMISSION:android.permission.BROADCAST_STICKY\n";
foreach (@broadcaststicky) {
	if ($_ =~ m/broadcastIntentLocked/) {
		@working = ();
		%depth = ();
		foreach (@{$lookup{$_}}) {
			push (@working, $_);
			$depth{$_} = 1;
		}
		foreach $w (@working) {
			next if($depth{$w}==5);
			foreach (@{$lookup{$w}}) {
				push (@working, $_);
				$depth{$_} = $depth{$w}+1;
				print $_."\n" if ($_ =~ m/sticky/i);
			}
		}
	} else {
		print $_."\n";
	}
}
