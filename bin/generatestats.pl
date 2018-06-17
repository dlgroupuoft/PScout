#!/usr/bin/perl

$num_all_mapping = `grep ^\\< API | wc -l`;
print "Number of API mappings: $num_all_mapping";
$num_published_mapping = `grep ^\\< publishedapimapping | wc -l`;
print "Number of published API mappings: $num_published_mapping";

%sysperm = ();
open SYSPERM, "<systempermission" or die $!;
while (<SYSPERM>) {
	chomp($_);
	$sysperm{$_} = 1;
}
close SYSPERM;
%thirdperm = ();
open PERM, "<permissions" or die $!;
while (<PERM>) {
	chomp($_);
	if (! defined $sysperm{$_}) {
		$thirdperm{$_} = 1;
	}
}
$num_permissions = keys %thirdperm;
print "Number of third party permissions: $num_permissions\n";

$published_mapping_perms = `grep Permission: publishedapimapping`;
%published_perms = ();
$num_published_perm = 0;
foreach (split(/\n/, $published_mapping_perms)) {
	$_ =~ m/^Permission:(.*)$/;
	$published_perms{$1} = 1;
	if (defined $thirdperm{$1}) {
		$num_published_perm++;
	}
}
$contentprovider = `cat contentproviderpermission`;
%contentproviderperm = ();
foreach (split(/\n/, $contentprovider)) {
	@tok = split(/ /, $_);
	$contentproviderperm{$tok[2]} = 1;
}
$intent = `cat intentpermission`;
%intentperm = ();
foreach (split(/\n/, $intent)) {
	@tok = split(/ /, $_);
	$intentperm{$tok[1]} = 1;
}
$intent = `cat intentwithdynamicpermission`;
foreach (split(/\n/, $intent)) {
	@tok = split(/ /, $_);
	$intentperm{$tok[1]} = 1;
}
$all_mapping_perms = `grep Permission: API`;
$num_all_perm = 0;
%only_in_all_perm = ();
foreach (split(/\n/, $all_mapping_perms)) {
	$_ =~ m/^Permission:(.*)$/;
	if (defined $thirdperm{$1} && ! defined $published_perms{$1} && ! defined $contentproviderperm{$1} && ! defined $intentperm{$1}) {
		$only_in_all_perm{$1} = 1;
	}
	if (defined $thirdperm{$1}) {
		$num_all_perm++;
	}
}
$num_only_in_all_perm = keys %only_in_all_perm;
print "Number of permissions in all mappings: $num_all_perm\n";
print "Number of permissions in published mappings: $num_published_perm\n";
print "\nNumber of permissions only in all mappings: $num_only_in_all_perm\n- excluding content provider and intent permissions\n";
print "  $_\n" foreach (sort keys %only_in_all_perm);

