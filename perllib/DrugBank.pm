#!/usr/bin/perl

package DrugBank;
use DrugTargetBase;
use PUGREST;
use IDMAP;
use Data::Dumper;
use strict;
use warnings;
#----------------------------------------------------------TEST AREA-----------------------------
#my $input = shift @ARGV;
#my $drugbank = new DrugBank();
#my $ikey = "WGWPRVFKDLAUQJ-UHFFFAOYSA-N";
#my $ikey2 = "WGWPRVFKDLAUQJ-MITYVQBRSA-N";
#print $drugbank->get_DrugBank_drugname_by_InChIKey($ikey);
#print Dumper($drugbank->get_DrugBank_targets_by_InChIKey($ikey));
#print $drugbank->get_DrugBank_drugname_by_InChIKey($ikey2);
#print Dumper($drugbank->get_DrugBank_targets_by_InChIKey($ikey2));
#----------------------------------------------------------TEST AREA-----------------------------
my $is_demo_on = 0;	# read demo data (shorter list) if 1
my $is_ikey_needed = 1;	# 1 if need PUGREST step
sub new
{
        my $class = shift;
        my $range = shift;
	my $self;
	if ($is_ikey_needed == 1){
        	$self = DrugBankData();	#does perform PUGREST; will contain InChIKeys
	} else {
		$self = DrugBankSimple();	#does not perform PUGREST; will NOT have InChIKeys
	}
        bless $self, $class;
        return $self;
}
sub get_DrugBank_drugname_by_InChIKey
{
        #input InChIKey then output the drugname
        my( $self, $ikey ) = @_;
        my $drugname = $self->{$ikey}->{drugname};
        return $drugname;
}
sub get_DrugBank_targets_by_InChIKey
{
        #input InChIKey then output a reference to targets in a hash
        my( $self, $ikey ) = @_;
        my $targetref = $self->{$ikey}->{targets};
        return $targetref;
}
sub DrugBankSimple
{
	#target IDs are in genename format, NOT UniProtKB.
	my $file = "./static/DrugBank/DrugBank_name_target_action.tsv";
	$file = "./static/DrugBank/DrugBank_name_target_action_demo.tsv" if $is_demo_on;
	
	my %DrugBankData;
	open my $DrugBank, '<', $file or die "Could not open DrugBank file, $file: $!\n";
	while (my $line = <$DrugBank>){
		my @words = split(/\t/, $line);
		my $drugname = shift @words;
		chomp($drugname);
		my @targets;
		while(@words){
			my $target = shift @words;
			chomp($target);
			$target = manual_get_genename_by_UniProtKB($target) if manual_get_genename_by_UniProtKB($target);	#target IDs are converted to genename
			chomp($target);
			push (@targets, $target);
			my $action = shift @words;
		}
		$DrugBankData{$drugname} = [@targets];
	}
	close $DrugBank;
	return \%DrugBankData;
}
sub DrugBankData
{
	#target IDs are in genename format, NOT UniProtKB.
	my $file = "./static/DrugBank/DrugBank_name_target_action.tsv";
	$file = "./static/DrugBank/DrugBank_name_target_action_demo.tsv" if $is_demo_on;
	
	my %DrugBankData;
	open my $DrugBank, '<', $file or die "Could not open DrugBank file, $file: $!\n";
	while (my $line = <$DrugBank>){
		my @words = split(/\t/, $line);
		my $drugname = shift @words;
		chomp($drugname);
		my %target_action;
		while(@words){
			my $target = shift @words;
			chomp($target);
			$target = manual_get_genename_by_UniProtKB($target) if manual_get_genename_by_UniProtKB($target);	#target IDs are converted to genename
			my $action = shift @words;
			chomp($action);
			$target_action{$target} = $action;
		}
		my @ikeys = get_InChIKey_by_name($drugname);
		foreach my $ikey (@ikeys){
			chomp($ikey);
			$DrugBankData{$ikey}{drugname} = $drugname;
			foreach my $target (keys %target_action){
				$DrugBankData{$ikey}{targets}{$target} = $target_action{$target};
			}
		}
	
	}
	close $DrugBank;
	return \%DrugBankData;
}

1;
