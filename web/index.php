<?php

	//		 				CONFIGURATON

	$root = "/home/luis/qtleap_pilot1";


?>
<!DOCTYPE HTML>
<html>
<head>
<title>Training status</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
</head>
<body>
<?php
foreach (scandir($root) as $d) {
	if ($d == "." || $d == ".." || !is_dir("$root/$d")) {
		continue;
	}
	echo "<h2>".htmlspecialchars($d)."</h2>\n";
	echo "<ol>\n";
	if (!is_file("$root/$d/corpus/parts.txt")) {
		echo "<li>Processing not started yet.</li>\n";
	} else {
		$num_parts = `wc -l $root/$d/corpus/parts.txt | cut -f 1 -d ' '`;
		echo "<li>Corpus was split into $num_parts parts with 200 sentences each.</li>\n";
	}
	if (!is_dir("$root/$d/atrees")) {
		echo "<li>Analysis to syntactic dependency level has not started yet.</li>\n";
	} else {
		$num_atrees = `ls $root/$d/atrees/ | grep -P '^part_[0-9]*.streex$' | wc -l`;
		$perc_atrees = sprintf("%.2f%%", $num_atrees / $num_parts * 100);
		echo "<li>Analysis to syntactic dependency level is $perc_atrees complete ($num_atrees/$num_parts parts).</li>\n";
	}
	if (!is_dir("$root/$d/ttrees")) {
		echo "<li>Analysis to tectogrammatical level has not started yet.</li>\n";
	} else {
		$num_ttrees = `ls $root/$d/ttrees/ | grep -P '^part_[0-9]*.streex$' | wc -l`;
		$perc_ttrees = sprintf("%.2f%%", $num_ttrees / $num_parts * 100);
		echo "<li>Analysis to tectogrammatical level is $perc_ttrees completed ($num_ttrees/$num_parts parts).</li>\n";
	}
	echo "</ol>\n";
}
?>
</body>
</html>