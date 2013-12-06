#!/usr/bin/perl
#######################################################
# File: convert2skos.pl
# Version: 1.0
# Purpose: This Perl script converts ISO-639-3 to SKOS
# Author: Junte Zhang (juntezhang@gmail.com)
#######################################################
use strict;

#####################################################
# store from file into memory to speed things up
#####################################################
my $file_code_set;
my $file_name_index;
my $file_macro_lang;
open($file_code_set, "< ../data/iso-639-3_20120816.tab") or die("Could not open ../data/iso-639-3_20120816.tab", $!);
open($file_name_index, "< ../data/iso-639-3_Name_Index_20120816.tab") or die("Could not open ../data/iso-639-3_Name_Index_20120816.tab", $!);
open($file_macro_lang, "< ../data/iso-639-3-macrolanguages_20120228.tab") or die("Could not open ../data/iso-639-3-macrolanguages_20120228.tab", $!);

my @lines_code_set = <$file_code_set>;
my @lines_name_index = <$file_name_index>;
my @lines_macro_lang = <$file_macro_lang>;

my %code_set = ();
for(my $i = 1 ; $i < @lines_code_set ; $i++) {
	chomp($lines_code_set[$i]);
	$lines_code_set[$i] =~ s/\R//g;
	# Id	Part2B	Part2T	Part1	Scope	Language_Type	Ref_Name	Comment
	# note: skip Part2B, Scope, Language_Type, Comment
	if($lines_code_set[$i] =~ /^(\w+)\t.*\t(.*)\t(.*)\t.*\t.*\t(.*)\t.*/) {
		$code_set{$1}{$2}{$3}{$4}++;
	}
}

my %name_index = ();
for(my $i = 1 ; $i < @lines_name_index ; $i++) {
	chomp($lines_name_index[$i]);
	$lines_name_index[$i] =~ s/\R//g;
	# Id	Print_Name	Inverted_Name
	# Note: skip Print_Name
	if($lines_name_index[$i] =~ /^(\w+)\t(.*)\t(.*)/) {
		$name_index{$1}{$2}{$3}++;
	}
}

my %macro_lang = ();
my %macro_lang_inv = ();
for(my $i = 1 ; $i < @lines_macro_lang ; $i++) {
	chomp($lines_macro_lang[$i]);
	$lines_macro_lang[$i] =~ s/\R//g;
	# M_Id	I_Id
	# Note: broader <-> narrower
	if($lines_macro_lang[$i] =~ /^(\w+)\t(.*)/) {
		$macro_lang{$1}{$2}++;
		$macro_lang_inv{$2}{$1}++;
	}
}

close($file_code_set);
close($file_name_index);
close($file_macro_lang);

#####################################################
# do the SKOS conversion
#####################################################
my $skos = new SKOS();
# header
$skos->create_rdf_start();

# create first RDF triple and insert hasTopConcept links
$skos->create_first_rdf_start();
$skos->has_top_concept();
$skos->create_first_rdf_end();

# insert the RDF triples
$skos->create_rdf_description();

# insert the RDF closing tag
$skos->create_rdf_end();

#####################################################
# SKOS object and methods
#####################################################
package SKOS;
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub create_rdf_start {
	print '<?xml version="1.0"?>
<rdf:RDF xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:mmm="https://maior.memorix.nl/XSI/3.0/">' . "\n";
}

sub has_top_concept {
	foreach my $concept (sort keys %code_set) {
		# omit skos:broader concepts
		if(not exists $macro_lang_inv{$concept}) {
			print "\t" . '<skos:hasTopConcept rdf:resource="http://openskos.meertens.knaw.nl/iso-693-3/' . $concept . '" />' . "\n";
		}
	}

}

sub create_first_rdf_start {
	print '<rdf:Description rdf:about="http://openskos.meertens.knaw.nl/iso-693-3">' . "\n";
  print "\t" . '<rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#ConceptScheme" />' . "\n";
  print "\t" . '<dc:title xml:lang="en">ISO 639-3:2007, Codes for the representation of names of languages — Part 3: Alpha-3 code for comprehensive coverage of languages</dc:title>' . "\n";
  print "\t" . '<dc:description xml:lang="en">ISO 639-3 attempts to provide as complete an enumeration of languages as possible, including living, extinct, ancient, and constructed languages, whether major or minor, written or unwritten.</dc:description>' . "\n";
  print "\t" . '<dc:creator xml:lang="en">SIL International</dc:creator>' . "\n";
}

sub create_first_rdf_end {
	print '</rdf:Description>' . "\n";
}

sub create_rdf_description {
	foreach my $concept (sort keys %code_set) {

		print "\t" . '<rdf:Description rdf:about="http://openskos.meertens.knaw.nl/iso-693-3/' . $concept . '">' . "\n";
		print "\t\t" . '<rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept" />' . "\n";
		print "\t\t" . '<dcterms:source>http://www.sil.org/iso639-3/documentation.asp?id=' . $concept . '</dcterms:source>' . "\n";

		print "\t\t" . '<skos:notation>' . $concept . '</skos:notation>' . "\n";
		print "\t\t" . '<skos:inScheme rdf:resource="http://openskos.meertens.knaw.nl/iso-693-3" />' . "\n";

		my $ref_name_const = "";
		foreach my $part2t (sort keys %{$code_set{$concept}}) {
			foreach my $part1 (sort keys %{$code_set{$concept}{$part2t}}) {

				# skos:exactMatch
				if($part2t ne "") {
					print "\t\t" . '<skos:exactMatch rdf:resource="http://id.loc.gov/vocabulary/iso639-2/' . $part2t . '" />' . "\n";
				}
				if($part1 ne "") {
					print "\t\t" . '<skos:exactMatch rdf:resource="http://id.loc.gov/vocabulary/iso639-1/' . $part1 . '" />' . "\n";
				}

				foreach my $ref_name (sort keys %{$code_set{$concept}{$part2t}{$part1}}) {
					$ref_name_const = $ref_name;
					print "\t\t" . '<skos:prefLabel xml:lang="en">' . $ref_name . '</skos:prefLabel>' . "\n";
				}
			}
		}

		# skos:narrower
		foreach my $narrow_concept (sort keys %{$macro_lang{$concept}}) {
			print "\t\t" . '<skos:narrower rdf:resource="http://openskos.meertens.knaw.nl/iso-693-3/' . $narrow_concept . '" />' . "\n";
		}

		# skos:broader
		foreach my $broader_concept (sort keys %{$macro_lang_inv{$concept}}) {
			print "\t\t" . '<skos:broader rdf:resource="http://openskos.meertens.knaw.nl/iso-693-3/' . $broader_concept . '" />' . "\n";
		}

		foreach my $pref (sort keys %{$name_index{$concept}}) {
			# skos:altLabel
			foreach my $alt (sort keys %{$name_index{$concept}{$pref}}) {
				if($ref_name_const ne $alt) {
					print "\t\t" . '<skos:altLabel xml:lang="en">' . $alt . '</skos:altLabel>' . "\n";
				}
			}
		}

		print "\t" . '</rdf:Description>' . "\n";
	}
}

sub create_rdf_end {
	print '</rdf:RDF>';
}
