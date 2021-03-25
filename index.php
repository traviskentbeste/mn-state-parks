<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no">
    <meta charset="utf-8">
    <title>MN State Parks</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
    <script src="/mn-state-parks/data/visited.js?_<?php echo time(); ?>"></script>
    <style>
      /* Always set the map height explicitly to define the size of the div
       * element that contains the map. */
      #map {
        height: 100%;
        width: 100%;
      }
      /* Optional: Makes the sample page fill the window. */
      html, body {
        height: 100%;
        margin: 0;
        padding: 0;
      }
    </style>
  </head>
  <body>
    <div id="map"></div>
    <script>
		var map;
		var markers = new Array();
		var openedInfoWindowForMarker;
		var home = {lat: 44.91592001001872, lng:-93.228188188915};

function markAsVisited(id, index) {
	//console.log( 'sending id of : ' + id + ' ' + markers[index].position.lat() + ' ' + markers[index].position.lng());

	var data = {
		'id' : id
	};
	//console.log(data);

	$.ajax({
		type: "POST",
		url: '/mn-state-parks/visited.php',
		data: data,
		success: function(response) {
			console.log(response);
			var marker = markers[index];
			if (response.status == 'ok') {
				if (response.data.visited == 1) {
					marker.setIcon("http://maps.google.com/mapfiles/ms/icons/green-dot.png");
				} else {
					marker.setIcon("http://maps.google.com/mapfiles/ms/icons/red-dot.png");
				}
			}
		},
		dataType: 'json'
	});
}

function initMap() {
	var myLatLng = {lat: 45.81560325923779, lng:-94.76468632373047};
	map = new google.maps.Map(document.getElementById('map'), {
		zoom: 7.0,
		center: myLatLng
	});

	// add a click event to show lat/lng
	google.maps.event.addListener(map,'click',function(event) {
		var latitude = event.latLng.lat();
		var longitude = event.latLng.lng();
		//console.log( latitude + ', ' + longitude );
	});

	// Create a <script> tag and set the URL as the source.
	var script = document.createElement('script');
	var time = new Date().getTime();
	script.src = '/mn-state-parks/data/data.js?_=' + time;
	document.getElementsByTagName('head')[0].appendChild(script);

	// add home marker
	var contentString = '<h1>Home</h1>';
	var infoWindow = new google.maps.InfoWindow({ content : contentString });
	var myLatLng = {lat: 44.0000, lng: -93.0000};

	var marker = new google.maps.Marker({
		position: home,
		map: map,
		draggable: true,
		title: 'Home',
		icon: {
			url: "http://maps.google.com/mapfiles/ms/icons/blue-dot.png"
		},
		animation: google.maps.Animation.DROP,
	});
	marker.addListener('click', function() {
		infoWindow.open(map, marker);
	});

	google.maps.event.addListener(marker,'dragend',function(event) {
		//document.getElementById('lat').value = this.position.lat();
		//document.getElementById('lng').value = this.position.lng();
		var lat = this.position.lat();
		var lng = this.position.lng();
		//console.log('Drag end : ' + lat + ' ' + lng);
		// reset the home coordinates
		home.lat = lat;
		home.lng = lng;
	});

}



// Loop through the results array and place a marker for each
// set of coordinates.
window.data_callback = function(results) {
	//console.log(results.length);

	var infoWindow = new google.maps.InfoWindow();

	//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	//:::                                                                         :::
	//:::  This routine calculates the distance between two points (given the     :::
	//:::  latitude/longitude of those points). It is being used to calculate     :::
	//:::  the distance between two locations using GeoDataSource (TM) prodducts  :::
	//:::                                                                         :::
	//:::  Definitions:                                                           :::
	//:::    South latitudes are negative, east longitudes are positive           :::
	//:::                                                                         :::
	//:::  Passed to function:                                                    :::
	//:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
	//:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
	//:::    unit = the unit you desire for results                               :::
	//:::           where: 'M' is statute miles (default)                         :::
	//:::                  'K' is kilometers                                      :::
	//:::                  'N' is nautical miles                                  :::
	//:::                                                                         :::
	//:::  Worldwide cities and other features databases with latitude longitude  :::
	//:::  are available at https://www.geodatasource.com                         :::
	//:::                                                                         :::
	//:::  For enquiries, please contact sales@geodatasource.com                  :::
	//:::                                                                         :::
	//:::  Official Web site: https://www.geodatasource.com                       :::
	//:::                                                                         :::
	//:::               GeoDataSource.com (C) All Rights Reserved 2018            :::
	//:::                                                                         :::
	//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	function distance(lat1, lon1, lat2, lon2, unit) {
		if ((lat1 == lat2) && (lon1 == lon2)) {
			return 0;
		}
		else {
			var radlat1 = Math.PI * lat1/180;
			var radlat2 = Math.PI * lat2/180;
			var theta = lon1-lon2;
			var radtheta = Math.PI * theta/180;
			var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
			if (dist > 1) {
				dist = 1;
			}
			dist = Math.acos(dist);
			dist = dist * 180/Math.PI;
			dist = dist * 60 * 1.1515;
			if (unit=="K") { dist = dist * 1.609344 }
			if (unit=="N") { dist = dist * 0.8684 }
			return dist;
		}
	}

	function isInfoWindowOpen(infoWindow){
		var map = infoWindow.getMap();
		return (map !== null && typeof map !== "undefined");
	}

	function bindInfoWindow(marker, map, infoWindow, content) {
		google.maps.event.addListener(marker, 'click', function() {

			if (isInfoWindowOpen(infoWindow)) {
				//console.log('isinfowindowopen');
				var equal = 0;

				if (openedInfoWindowForMarker != marker) {
					//console.log('not equal');
					infoWindow.close(map, marker);
				} else {
					//console.log('equal');
					infoWindow.close(map, marker);
					equal++;
				}

			}

			if (! equal) {
				c = content;
				var d = distance( marker.position.lat(), marker.position.lng(), home.lat, home.lng, 'M' );
				c    += '<tr>';
				c    += '<td>';
				c    += 'Distance';
				c    += '</td>';
				c    += '<td>';
				c    +=  parseFloat(d).toFixed(2) + ' miles';
				c    += '</td>';
				c    += '</tr>';

				c    += '</table>';

				infoWindow.setContent(c);

				infoWindow.open(map, marker);
			}

			openedInfoWindowForMarker = marker;
		});
	}

	for (var i = 0; i < results.length; i++) {

		var latLng = new google.maps.LatLng(
			results[i].latitude,
			results[i].longitude
		);

		var content = '<table cellspacing="5" cellpadding="5">';

		content    += '<tr>';
		content    += '<td>Name</td>';
		content    += '<td><a target="_blank" href="https://www.dnr.state.mn.us/state_parks/park.html?id=' + results[i].id + '#homepage">' + results[i].name  + '</a></td>';
		content    += '</tr>';

		content    += '<tr>';
		content    += '<td>Phone</td>';
		content    += '<td><a href="tel:' + results[i] + '">' + results[i].phone  + '</a></td>';
		content    += '</tr>';

		content    += '<tr>';
		content    += '<td valign="top">Address</td>';
		content    += '<td><a href="http://maps.apple.com?dirflag=d&t=m&q=' + results[i].latitude + ',' + results[i].longitude + '">' + results[i].address + '</a></td>';
		content    += '</tr>';

		content    += '<tr>';
		content    += '<td>&nbsp;</td>';
		content    += '<td><button onClick="markAsVisited(\'' + results[i].id + '\', ' + i + ');">mark as visited</button></td>';
		content    += '</tr>';

		var iconUrl = "http://maps.google.com/mapfiles/ms/icons/red-dot.png";
		if (typeof visited !== 'undefined') {
			//console.log(visited);
			var found = 0;
			for (var j = 0; j < visited.length; j++) {
				if (visited[j] == results[i].id) {
					found++;
				}
			}
			if (found == 1) {
				iconUrl = "http://maps.google.com/mapfiles/ms/icons/green-dot.png";
			}
		} else {
			//console.log('no visited yet');
		}

		var marker = new google.maps.Marker({
			position: latLng,
			map: map,
			title: results[i].name,
			icon: {
				url: iconUrl
			}
		});

		bindInfoWindow(marker, map, infoWindow, content);

		markers[i] = marker;

	}

}
    </script>
    <script async defer
    src="https://maps.googleapis.com/maps/api/js?key=AIzaSyB4v140a65f7TJIwp7FOISDAc2pRrWE1-U&callback=initMap">
    </script>
  </body>
</html>
