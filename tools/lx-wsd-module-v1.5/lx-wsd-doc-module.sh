#! /bin/bash

#read test


UKBDir=$1
outputDir=$2
language=$3
document=$4

sentences=()

i=0

while read line
do
	sentences[$i]=$line
	i=$[$i +1]
done < $document

# Context Conversion

echo -e "*** Converting from input to UKB context file:\n"

contextString=""
finalWordString=""
emptyLine=0

for sentenceIndex in "${!sentences[@]}"
do
	sentence="${sentences[sentenceIndex]}"

	if [ $sentenceIndex -gt 0 ]
	then
		if [ $emptyLine == 0 ]
		then
			contextString="$contextString\n\n"
		fi	
	else
		:
	fi

	IFS=" " read -a lineSplit <<< $sentence

	#echo -e "Sentence $sentenceIndex"

	#echo -e "Line contains ${#lineSplit[@]} elements"	

	wordString=""
	contextLine=""
	wordId=0

	for index in "${!lineSplit[@]}"
	do
		#split="${lineSplit[index]}"
		#lemma="${split%%/*}"	
		#echo "$lemma"

		if [ $language == "en" ]
		then
			#echo -e "$index Language is English"
			word=""
			split="${lineSplit[index]}"		
		
			if [ "${split:(-3)}" == "/NN" ] || [ "${split:(-4)}" == "/NNS" ] || [ "${split:(-4)}" == "/NNP" ] || [ "${split:(-5)}" == "/NNPS" ] || [ "${split:(-3)}" == "/VB" ] || [ "${split:(-4)}" == "/VBD" ] || [ "${split:(-4)}" == "/VBG" ] || [ "${split:(-4)}" == "/VBN" ] || [ "${split:(-4)}" == "/VBP" ] || [ "${split:(-4)}" == "/VBZ" ] || [ "${split:(-3)}" == "/JJ" ] || [ "${split:(-4)}" == "/JJR" ] || [ "${split:(-4)}" == "/JJS" ] || [ "${split:(-3)}" == "/RB" ] || [ "${split:(-4)}" == "/RBR" ] || [ "${split:(-4)}" == "/RBS" ]
			then
				
				lemma=""
			
				if [ "${split:(-3)}" == "/RB" ] || [ "${split:(-4)}" == "/RBR" ] || [ "${split:(-4)}" == "/RBS" ]
				then
					lemma="${split%%/*}"
					lemma="${lemma,,}"
				else	
					lemma="${split#*/}"
					lemma="${lemma%%/*}"
					lemma="${lemma,,}"
				fi

				if [ "x$lemma" == "x" ]
				then
					:
				else
					wordId=$[$wordId +1]
					partOfSpeech=""
				
					if [ "${split:(-3)}" == "/NN" ] || [ "${split:(-4)}" == "/NNS" ] || [ "${split:(-4)}" == "/NNP" ] || [ "${split:(-5)}" == "/NNPS" ]
					then
						partOfSpeech="n"
					fi
					if [ "${split:(-3)}" == "/VB" ] || [ "${split:(-4)}" == "/VBD" ] || [ "${split:(-4)}" == "/VBG" ] || [ "${split:(-4)}" == "/VBN" ] || [ "${split:(-4)}" == "/VBP" ] || [ "${split:(-4)}" == "/VBZ" ]
					then
						partOfSpeech="v"
					fi
					if [ "${split:(-3)}" == "/JJ" ] || [ "${split:(-4)}" == "/JJR" ] || [ "${split:(-4)}" == "/JJS" ]
					then
						partOfSpeech="a"
					fi
					if [ "${split:(-3)}" == "/RB" ] || [ "${split:(-4)}" == "/RBR" ] || [ "${split:(-4)}" == "/RBS" ]
					then
						partOfSpeech="r"
					fi
				
					if [ $wordId -gt 1 ]
					then
						contextLine="$contextLine "
					fi	

					contextLine="$contextLine$lemma#$partOfSpeech#w$wordId#1"
				
					word="${split%%/*}/<$lemma#$partOfSpeech#w$wordId#1>"
				fi
			else
				word="${split%%/*}/_"
			fi

			if [ $index -gt 0 ]
			then
				word=" $word"
			fi

			wordString="$wordString$word"

		elif [ $language == "pt" ]
		then
			word=""
			split="${lineSplit[index]}"		

			if [ "${split:(-3)}" == "/CN" ] || [ "${split:(-4)}" == "/ADJ" ] || [ "${split:(-4)}" == "/ADV" ] || [ "${split:(-4)}" == "/PPA" ] || [ "${split:(-2)}" == "/V" ] || [ "${split:(-4)}" == "/INF" ] || [ "${split:(-5)}" == "/VAUX" ] || [ "${split:(-8)}" == "/VAUXINF" ] || [ "${split:(-8)}" == "/VAUXGER" ] || [ "${split:(-4)}" == "/GER" ] || [ "${split:(-4)}" == "/PPT" ]
			then
				lemma=""
			
				if [ "${split:(-4)}" == "/ADV" ]
				then
					lemma="${split%%/*}"
					lemma="${lemma,,}"
				else	
					lemma="${split#*/}"
					lemma="${lemma%%/*}"
					lemma="${lemma,,}"
				fi

				if [ $lemma == "" ]
				then
					:
				else
					wordId=$[$wordId +1]
					partOfSpeech=""
				
					if [ "${split:(-3)}" == "/CN" ]
					then
						partOfSpeech="n"
					fi
					if [ "${split:(-2)}" == "/V" ] || [ "${split:(-4)}" == "/INF" ] || [ "${split:(-5)}" == "/VAUX" ] || [ "${split:(-8)}" == "/VAUXINF" ] || [ "${split:(-8)}" == "/VAUXGER" ] || [ "${split:(-4)}" == "/GER" ] || [ "${split:(-4)}" == "/PPT" ]
					then
						partOfSpeech="v"
					fi
					if [ "${split:(-4)}" == "/ADJ" ]
					then
						partOfSpeech="a"
					fi
					if [ "${split:(-4)}" == "/ADV" ]
					then
						partOfSpeech="r"
					fi
					if [ "${split:(-4)}" == "/PPA" ]
					then
						partOfSpeech="p"
					fi
				
					if [ $wordId -gt 1 ]
					then
						contextLine="$contextLine "
					fi	

					contextLine="$contextLine$lemma#$partOfSpeech#w$wordId#1"
				
					word="${split%%/*}/<$lemma#$partOfSpeech#w$wordId#1>"
				fi
			else
				word="${split%%/*}/_"
			fi

			if [ $index -gt "0" ]
			then
				word=" $word"
			fi

			wordString="$wordString$word"
		else
			:	
		fi
	done

	if [ "$contextLine" == "" ]
	then		
		emptyLine=1
	else
		trueIndex=$[$sentenceIndex +1]
		newContextString="ctx_0$trueIndex\n$contextLine"
		contextString="$contextString$newContextString"		

		outputString=$wordString

		emptyLine=0
	fi

	finalWordString="$finalWordString$wordString"
	if [ $sentenceIndex -lt "${#sentences[@]}" ]
	then
		finalWordString="$finalWordString\n"
	fi
done

echo -e $contextString > $outputDir"/UKBContext.txt"
#UKBContext=$contextString
#echo -e $finalWordString > $outputDir"/unmappedOutput.txt"

# Run UKB

echo -e "*** Running UKB:\n"

if [ $language == "pt" ]
then
	time $UKBDir/ukb_wsd --ppr -K $UKBDir/mwnpt30verified-true.bin -D $UKBDir/mwnpt30verified-true_dict.txt $outputDir/UKBContext.txt > $outputDir/UKBOutput.txt 2>&1
fi

if [ $language == "en" ]
then
	time $UKBDir/ukb_wsd --ppr -K $UKBDir/wn30.bin -D $UKBDir/wnet30_dict.txt $outputDir/UKBContext.txt > $outputDir/UKBOutput.txt 2>&1
fi

