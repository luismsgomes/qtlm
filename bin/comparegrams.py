#! /usr/bin/env python3
"""
Extracts missing and extra n-grams of a reference and translated file

Arg1 Path to reference file
Arg2 Path to translated file
"""
import os
import sys
import operator

def main():
	input_files = get_input_files()
	count_ngrams(input_files)

def count_ngrams(input_files):

	case_sensitive = False
	n = 3

	dict_grams = []

	for gram in range(n):
		dict_grams.append({})

	ref_file,tst_file = input_files

	ref_txt = [line for line in open(ref_file,'r')]
	tst_txt = [line for line in open(tst_file,'r')]

	lines = len(ref_txt)

	#For each line
	for line_number in range(lines):

		ref_line = ref_txt[line_number - 1].split()
		tst_line = tst_txt[line_number - 1].split()

		#For each n of the n-grams
		for count_gram in range(n):

			#For both reference and translated files
			for idx,source in enumerate([tst_line,ref_line]):
				
				#gram_type (-1 = missing, 1 = extra)
				gram_type = idx if idx > 0 else -1

				#For each n-gram of the sentence
				for word_position in range(len(source) - 1):
					
					gram = source[word_position:word_position + count_gram + 1]
					key = ' '.join(gram) if case_sensitive else ' '.join(gram).lower()

					if key in dict_grams[count_gram]:
						dict_grams[count_gram][key] = dict_grams[count_gram][key] + gram_type
					else:
						dict_grams[count_gram][key] = gram_type

	calculate_statistics(dict_grams)
	

def calculate_statistics(dict_grams):

	number_items_show = 10

	for count_gram in range(len(dict_grams)):
		print("#" + str(count_gram + 1) + "-gram")

		sort_gram = sorted(dict_grams[count_gram].items(), key=operator.itemgetter(1))

		sort_gram_missing 	= sort_gram[-number_items_show:]
		sort_gram_extra 	= sort_gram[:number_items_show]

		print("Top missing\t\t\t\tTop extra")
		print('-'.join(str('-').ljust(35)))
	
		for item in range(number_items_show):
			missing_word,missing_count  = sort_gram_missing[number_items_show - item - 1]
			extra_word,extra_count  	= sort_gram_extra[item]

			print(	''.join(str(missing_word).ljust(25)) + 
					''.join(str(missing_count).ljust(15)) + 
					''.join(str(extra_word).ljust(25)) +
					''.join(str(extra_count)))
		
		print('-'.join(str('-').ljust(35)))
		print("\n")


def get_input_files():

	if(len(sys.argv)<3):
		print("Use: comparegrams.py ref_file tst_file")
		print("ref_file\t\t Path to reference file")
		print("tst_file\t\t Path to translated file")
		sys.exit(1)

	files_not_found = [arg for arg in sys.argv[1:] if not os.path.isfile(arg)]

	for files in files_not_found:
		print("File '" + files + "' not found")

	if files_not_found:
		sys.exit(1)
	
	return sys.argv[1:]

if __name__=="__main__":
    main()