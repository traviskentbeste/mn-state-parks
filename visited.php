<?php

// filename
$json_filename = '/var/www/traviskentbeste.com/public/mnstateparks/visited.json';
$js_filename = '/var/www/traviskentbeste.com/public/mnstateparks/visited.js';

// input
$id = $_POST['id'];	

// for testing
//$id = $_GET['id'];	

// response
$obj = new \stdClass();
$obj->status = "ok";
$obj->data = new \stdClass();
$obj->data->id = $id;

// load up the visited
$visited = file_get_contents($json_filename);

// empty file case
if ($visited == '') {

	$visited = array();
	array_push($visited, $id);
	$obj->data->visited = 1;
	$obj->data->visited_array = $visited;

} else {

	// exists, turn the string into a json object (array)	
	$visited = json_decode($visited);

	if (in_array($id, $visited)) {

		foreach ($visited as $key => $value) {
			if ($value==$id) unset($visited[$key]);
		}
		$obj->data->visited = 0;
		$obj->data->visited_array = $visited;

	} else {

		array_push($visited, $id);
		$obj->data->visited = 1;
		$obj->data->visited_array = $visited;

	}

}

// output the js
file_put_contents($js_filename, 'var visited = ' . json_encode($visited) . ';');

// save json
file_put_contents($json_filename, json_encode($visited));

// output the json
print json_encode($obj);

?>
