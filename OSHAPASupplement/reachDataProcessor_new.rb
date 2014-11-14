#-----------------------------------------------------------------
# reachDataProcessor
# openSHAPA compatible Ruby script that sifts the trial and reach data
# coded for Victor Santamaria and Jennifer Rachwani's reaching experiments.
# Produces two output files.
#  1 -- A table of all trial data.  Trial data, trial onset, trial offset,
#	    and duration in ms.
#  2 -- A table of all relevant coded data 
#
#  Author -- Wayne Manselle
#  Creation Date -- June 1st, 2012
#  Version Data --
#		0.1 -- Creation
#		0.2 -- Initial Bug-testing Complete and Passed
#		0.3 -- Converting to run under DataVyu
#		0.4 -- Adding relative file paths and checking output dir existence.
#		0.5 -- Patch to remove '/'s from dates and replace with '_'s
#		0.6 -- Exploring differentiations by subject group
#		0.7 -- Converting Descriptive code to new Format
#		0.8 -- Addition of reach coupling identifier
#		0.9 -- Alteration of file names for output to include level of support and organization
#		0.10 -- Fixed up Support Level variables to work with the entered text.
#-----------------------------------------------------------------
#Absolutely necessary.  Currently written to assume the API is in the same directory as the script.
#CSV libraries are needed for output of data
#Are we going to be okay just referencing the old openSHAPA?
if defined?(JRUBY_VERSION)
	if(JRUBY_VERSION=="1.4.0")
		puts "Calling Script from OpenSHAPA"
		#baseDir = File.expand_path("~") + "/Desktop/Folders needed for Study 2/OpenShapaFiles/Rubi Script for processing/"
		baseDir = File.expand_path("~") + "/Victor's Files/Dropbox/RUBY/"
		apiName = 'OpenSHAPA_API.rb'
	else if(JRUBY_VERSION=="1.6.7.2")
			puts "Calling Script from DataVyu"
			baseDir = File.dirname(__FILE__)
			apiName = 'Datavyu_API.rb'
		end
	end
end

puts "BaseDir: " + baseDir
puts "API Needed: " + apiName
require baseDir + apiName
puts "API Loaded"
require 'csv'
puts "CSV Loaded"

begin

puts "Gathering Subject Identity Data"
#Get the subject's ID, Date of Birth, and Date of Visit.
#Every openSHAPA file should only ONE subject.  If they don't?  Something's amiss.
ID = getVariable("ID")
if ID.cells.count>1
	#ERROR.  MORE THAN ONE SUBJECT.
	raise "More than One Subject detected.  Please review dataset."
else
   t_cell = ID.cells.at(0)
   subjnum=t_cell.subjnum
   subjgrp = subjnum[0,2];
   #This is where we can differentiate the subject type.
   #The subject type should be the first two characters of the string.
   DOB=t_cell.birthdate
   DOV=t_cell.testdate
end

#Quick patch to replace slashes in dates of visit/birth with underscores.
stringsubID=subjnum.to_s.gsub(/\//,'_')
stringDOV=DOV.to_s.gsub(/\//,'_')

puts "Preparing the Data Tables"
#Create Hashtables to store assembled data for all outputs
trialDataHash = Hash.new
#Left Hand Reaches and Descriptives
leftReachActivityHash = Hash.new
leftReachDescHash = Hash.new
#Right Hand Reaches and Descriptives
rightReachActivityHash = Hash.new
rightReachDescHash = Hash.new
#Merged Output Hashes
reachDataHash = Hash.new
descDataHash = Hash.new

puts "Grabbing Variables"
#Assemble the Trial Data Hashtable for CSV Output
Trial = getVariable("Trial")

supportLevel = getVariable("Support")
s_cell = supportLevel.cells.at(0)
stringSupportLevel = s_cell.level

#Recode level of support for descriptives
#1 = Axillae
#2 = Lumbar
#3 = Thoracic
reCodedLOS = 0

if(stringSupportLevel=="Axillae")
	reCodedLOS="1"
else if(stringSupportLevel=="Thoracic")
		reCodedLOS="2"
	else
		reCodedLOS="3"
	end
end

rightHand = getVariable("RightHand")
leftHand = getVariable("LeftHand")

puts "Gathering Trial Data"
#Iterate over all trial cells, gathering what data is available
rowCounter = 0
for t_cell in Trial.cells
	#Trial Variables -- Ordinal, Trial Onset, Trial Offset, Trial Duration, Number
	curTrialArray = Array.new(5,0)
	curTrialArray[0] = t_cell.ordinal
	curTrialArray[1] = t_cell.onset
	curTrialArray[2] = t_cell.offset
	curTrialArray[3] = t_cell.offset - t_cell.onset
	curTrialArray[4] = t_cell.number
	trialDataHash[rowCounter.to_s()] = curTrialArray
	rowCounter=rowCounter+1
end
#Iterate over all Hand Cells, gathering Activity Data
puts "Gathering Reach Data"
for hand in 1..2
	if hand==1
		handData = getVariable("RightHand")
	else
		handData = getVariable("LeftHand")
	end
	#Iterate over all rightHand trials
	rowCounter = 0
	for t_cell in handData.cells
		#Hand Event Array Variables --
		#Reach Number, Reach Onset, Reach Offset, Reach Duration, Reach Activity
		curHandArray = Array.new(5,0)
		curHandArray[0] = t_cell.ordinal
		curHandArray[1] = t_cell.onset
		curHandArray[2] = t_cell.offset
		curHandArray[3] = t_cell.offset - t_cell.onset
		curHandArray[4] = t_cell.activity
		if hand==1
			rightReachActivityHash[rowCounter.to_s()] = curHandArray
		else
			leftReachActivityHash[rowCounter.to_s()] = curHandArray
		end
		rowCounter=rowCounter+1
	end
end
#Around here we should likely iterate over both Hash Tables in order to
#determine if a CP subject has coupled reaches.
puts "Check for CP Subject related to Coupled Reaches"
if(subjgrp=="CP")
	puts "Checking for Coupled reaches"
	coupledReaches=0
	iterateSet = []
	compareSet = []
	#Determine the largest set of activities
	#There's probably a much more efficient way to do this, what might it be?
	if(rightReachActivityHash.length >= leftReachActivityHash.length)
		puts "More Right Reaches than Left"
		iterateSet = rightReachActivityHash;
		compareSet = leftReachActivityHash;
	else
		puts "More Left Reaches than Right"
		iterateSet = leftReachActivityHash;
		compareSet = rightReachActivityHash;
	end
	#Set our iterate based on that size
	altInd=0
	for index in 0..iterateSet.length-1
		explore=true
		while (explore && (altInd < compareSet.length))
			leftSide = iterateSet[index.to_s()]
			rightSide = compareSet[altInd.to_s()]
			if(leftSide[0] == rightSide[0])
				if((leftSide[4] == 'BDSR' && rightSide[4] == 'BNDSR' ) || (leftSide[4] == 'BNDSR' && rightSide[4] == 'BDSR' ) || (leftSide[4] == 'BDUR' && rightSide[4] == 'BNDUR' ) || (leftSide[4] == 'BNDUR' && rightSide[4] == 'BDUR' ))
					coupledReaches+=1
					altInd+=1
					leftSide[4] = 'C' + leftSide[4]
					rightSide[4] = 'C' + rightSide[4]
				else
					altInd+=1
				end
			else
				explore = false
			end
		end
	end
	#Update the Activity Hash Tables
	if(rightReachActivityHash.length >= leftReachActivityHash.length)
		rightReachActivityHash = iterateSet
		leftReachActivityHash = compareSet
	else
		leftReachActivityHash = iterateSet
		rightReachActivityHash = compareSet
	end
end

#Cross Compare the Trial Data to the Activity Data to Gather Descriptives
#Counters for placement into the output hash 
#Design of Descriptive tables --
#Row by Row
#<SubjID><Level of Support><Handedness of Reach><EventCode>
#Caveats
#Recode reach handedness
#1 - Right Reach
#2 - Left Reach
puts "Gathering Descriptive Data"
outputCounter=0
for hand in 1..2
	#Create the Hash for the Table
	rHand="0"
	puts "Determining Handedness"
	if hand==1
		dataTable = rightReachActivityHash
		rHand = "1"
	else
		dataTable = leftReachActivityHash
		rHand = "2"
	end
	#For all reaching trials
	puts "Looking over the data"
	dataTable.each_value{|reachDataRow|
		descRow = Array.new(5,0)
		#Set Hand and Trial Number
		descRow[0] = subjnum
		descRow[1] = reCodedLOS
		descRow[2] = reachDataRow[0]
		descRow[3] = rHand
		descRow[4] = reachDataRow[4]
		descDataHash[outputCounter.to_s()] = descRow
		outputCounter = outputCounter+1
	}
end
puts "Merging Reach Data for Output"
#Quick and dirty, put the reach data gathered for each hand together
#so that in the subsequent output, there's one table.  Right handed
#reaches on the left, and left on the right.  Because that makes sense.
dataTable=0
if rightReachActivityHash.size > leftReachActivityHash.size
	dataTable = rightReachActivityHash
else
	dataTable = leftReachActivityHash
end
rowCount=0
dataTable.each_key{ |key|
	#Grab the reach data for the relevant key given, as we know our key scheme
	#is identical between hashes.  If there is no array at the given key, we've set 
	#the system to return an array of blanks to keep the output file rounded out.
	rightReachArray = rightReachActivityHash.fetch(key,Array.new(5,''))
	leftReachArray = leftReachActivityHash.fetch(key,Array.new(5,''))
	#Built-in Array Concatenation.  Nice.
	mergedArray = rightReachArray+leftReachArray
	reachDataHash[rowCount.to_s()] = mergedArray
	rowCount = rowCount+1
}

#Test first for Master Output Containing Folder
outDirBase=File.expand_path("~") + "/Desktop/SUBJECTS/OpenSHAPAOutput/"
if !File.directory?(outDirBase)
	puts "Base Output" + outDirBase
	Dir.mkdir(outDirBase)
end

#Test for output directory
outDir=outDirBase + stringsubID + '/'
if !File.directory?(outDir)
	puts outDir
	Dir.mkdir(outDir)
end

puts "Output piped to: " + outDir
puts stringSupportLevel
#CSV Output Lines, eventually move these.  Filename based on subject number, date of visit, and type of file.
#Addition, Level of Support
#Trial Data File
trialFileName= outDir + "Output" + "_" + stringsubID + "_" + stringSupportLevel + "_" + stringDOV + ".csv"
puts trialFileName
trialFile = File.new(trialFileName,'w')
#Reach Output File
reachFileName= outDir + "HandOutput" + "_" + stringsubID + "_" + stringSupportLevel + "_" + stringDOV + ".csv"
reachFile = File.new(reachFileName,'a')	
#Summary Output File
descFileName= outDir + "DescOutput" + "_" + stringsubID + "_" + stringSupportLevel + "_" + stringDOV + ".csv"
descFile = File.new(descFileName,'a')

puts "Outputting All Data to CSV"
#Data Assembled, begin printing Files.
#Trial Onset, Offset, and Duration Data
writer = CSV.open(trialFileName,"wb")
writer << ['Trial','Onset','Offset','Duration(ms)','Number']
trialDataHash.each_value {|value| writer << value} 
writer.close
#Individual reach data for both hands output
writer = CSV.open(reachFileName,"wb")
writer << ['RReachNum','ROnset','ROffset','RDuration(ms)','RActivity','LReachNum','LOnset','LOffset','LDuration(ms)','LActivity']
reachDataHash.each_value {|value| writer << value}
writer.close
#Descriptive Data
writer = CSV.open(descFileName,"wb")
writer << ['Subj','Support','Trial','R.Hand','Event']
descDataHash.each_value {|value| writer << value}
writer.close
#Processing Complete
puts "Finished."
end