<!DOCTYPE html>
<html>
	<head>
		<title>Lab Pulse</title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0">

		<link href="/quality/assets/css/helix-2.css" rel="stylesheet" media="screen">
		
		<!--[if lt IE 9]>
		<script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
		<script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
		<![endif]-->	
		
		<style>
    .vote div { cursor:pointer }
    .stat { margin-bottom:30px }
		.container {
			width: 100%!Important;
		}
		body { margin-top: 20px!Important; }

  .focusedInput {
  border-color: #ccc;
  border-color: rgba(82,168,236,.8);
  outline: 0;
  outline: thin dotted \9;
  -moz-box-shadow: 0 0 8px rgba(82,168,236,.6);
  box-shadow: 0 0 8px rgba(82,168,236,.6);
  }

            .big h1,.big h3 { font-size: 150px; text-align:center; }
            .big .status { font-size: 25em; }
            .big { width: 100% }

		</style>
	</head>
	<body>

    <div class="container"> <!-- page header -->
        <div class="row view-header no-nav"> <!-- view header -->
            <div class="col col-md-8">
                <h2><i class="fa fa-signal"></i> Lab Pulse</h2>
            </div> <!-- col -->

            <div class="col col-md-4">
                <form id="mood_form" class="form-inline pull-right" onSubmit="return false;" role="form">
                    <div class="form-group">
                        <label class="sr-only" for="termSearch">enter a term</label>
                        <input type="text" class="form-control" id="termSearch" placeholder="what matters today?" maxlength="25" required>
                    </div>
                    <label>is</label>
                    <button name="mood" type="submit" class="btn btn-default" onclick="add(1);"><i class="fa fa-smile-o fa-lg text-success"></i></button>
                    <button name="mood" type="submit" class="btn btn-default" onclick="add(-1);"><i class="fa fa-frown-o fa-lg text-danger"></i></button>
                </form>
            </div> <!-- col -->
        </div> <!-- row view header -->
    </div> <!-- container page header -->

    <div class="container"> <!-- grid -->

        <div id="stats" class="row"> <!-- metrics grid -->
        </div> <!-- row metrics grid -->

    </div>

		<script src="/quality/assets/js/helix-2.js"></script>
		<script type="text/javascript" src="http://cdnjs.cloudflare.com/ajax/libs/jquery-cookie/1.4.0/jquery.cookie.min.js"></script>
	  <script type="text/javascript" src="http://www.parsecdn.com/js/parse-1.2.18.min.js"></script>
		
		<script>
$(document).ready( function() {
	start();

	reload_votes = setInterval(function(){
       end_cycle()
	   get_votes();
       if (big) { start_cycle() }
	}, 120000);

});

//var host = "http://10.107.64.114:9090";
//var url = "/cypher-services/trends/metrics";

var reload_votes = null
var cycle = null
var host = "."
var url = "/stats.json"
var user = "";

function start_cycle() {
    cycle = setInterval(rotate, 5000);
}

function end_cycle() {
    clearInterval(cycle)
}

function rotate() {
    $('.stat').first().slideUp(1000, function() { $(this).appendTo('#stats').show() })
}

function are_cookies_enabled()
{
    var cookieEnabled = (navigator.cookieEnabled) ? true : false;

    if (typeof navigator.cookieEnabled == "undefined" && !cookieEnabled)
    { 
        document.cookie="testcookie";
        cookieEnabled = (document.cookie.indexOf("testcookie") != -1) ? true : false;
    }
    return (cookieEnabled);
}

function start() {	
	Parse.initialize("oSUlar37AGFcQm2xnfWQS6YXOapT4WQwxMnnDi9m", "DikbxAnPabJjyCtVuluGPHdrUQR4ZXafHzwphPYR");

	user = $.cookie("user");
	console.log(user);
	
	if (! user) {
		user = Math.floor(Math.random()*10000000).toString();
		$.cookie("user", user);
	}
	
	console.log("USER: " + user);

	get_votes();
}

function add(value) {
  var label = $('#termSearch').val();
  vote(label, value);
  $('#add').val('')
}

function vote(label, value) {
  console.log(label)
  if (! label || label.trim() == "") return;
  if (! are_cookies_enabled()) return;
	var Vote = Parse.Object.extend("Vote");

    var vote = new Vote();
	  vote.set("value", value);
	  vote.set("label", label);
	  vote.set("user_id", user);	
	  vote.save(null, {
  	  	success: function(vote) {
  console.log("vote saved");
  console.log(vote);
  var query = new Parse.Query(Vote);
  query.equalTo("user_id", user);
  query.equalTo("label", label);
  query.find({
      success: function(results) {
        console.log("results found " + results.length);
        console.log(results);
        for (var i = 0; i < results.length; i++) {
            var object = results[i];
            if (vote.id != object.id) {
              object.destroy({
                success: function(object) {
                  console.log(object)
                },
                error: function(object, error) {
                  console.log(error)
                }
             });
          }
        }
    }
  });
setTimeout(function(){get_votes()},1000);
  		  },
  		  error: function(vote, error) {
  		  }
	  });

}

function up_vote(label) {
  vote(label,1);
}

function down_vote(label) {
  vote(label,-1);
}

var user_votes = {}
function get_votes() {
  var yesterday = new Date(new Date().getTime() - (12 * 60 * 60 * 1000));
	var totals = {}
	var Vote = Parse.Object.extend("Vote");
	var query = new Parse.Query(Vote);
	query.exists("value");
	query.ascending("label")
  query.greaterThan("updatedAt", yesterday)
	query.find({
  		success: function(results) {
    		// Do something with the returned Parse.Object values
    		for (var i = 0; i < results.length; i++) { 
      			var object = results[i];
            if (object.get('user_id') == user) {
              user_votes[object.get('label')] = object;
            }
      			if (totals[object.get('label')]) {
      				totals[object.get('label')] += object.get('value');
      			} else {
      				totals[object.get('label')] = object.get('value');
      			}
    		}
    		console.log(totals);
        stats = [];
        for (i in totals) {
          if (totals[i] > 0) {
            light = "green";
          } else if (totals[i] < 0) {
            light = "red";
          } else {
            light = "muted";
          }

          stats.push({"name":i, "value":totals[i], "trend":totals[i], "light":light})
        }

        create_stats(stats)

  		},
  		error: function(error) {
  		}
	});
}

function get_stats() {
// 	$.get(host + url + "", {}, function(data) {
// 		console.log(data)
// 		stats = $.parseJSON(data);
// 		console.log(stats)
// 		create_stats(stats.stats);
// 	});
// var stats = [{"name":"conv", "value":"1234", "trend":"30", "light":"green"}, {"name":"visits", "value":"4", "trend":"-30", "light":"red"}, {"name":"pdp", "value":"400", "trend":"60", "light":"green"}, {"name":"addcart", "value":"200", "trend":"-50", "light":"red"}, {"name":"fiats", "value":"250", "trend":"10", "light":"green"}, {"name":"exitrate", "value":"70", "trend":"-10", "light":"red"}, {"name":"akamaierror", "value":"20", "trend":"15", "light":"green"}, {"name":"genericerror", "value":"30", "trend":"-30", "light":"red"}, {"name":"pdperror", "value":"60", "trend":"20", "light":"green"}, {"name":"pnferror", "value":"2", "trend":"5", "light":"green"}];				
// create_stats(stats);
var stats = [
	{name:"snacks", value:"M&Ms", trend:4, light:"green"},
	{name:"music", value:"rock", trend:"harder", light:"green"},
	{name:"weather", value:"rainy", trend:"wetter", light:"red"}
];
create_stats(stats);
}

var big = false
function toggle() {
    if (big) {
        $('.stat').removeClass('big')
        end_cycle()
        big = false
    }   else {
        $('.stat').addClass('big')
        big = true
        start_cycle()
    }
}

function create_stats(stats) {
  $('#stats').html('')
	for (i in stats) {
		create_stat(stats[i]);
	}
}

function create_stat(stat) {
	
	var template = $('#stat_template').html();
	template = template.replace(/##name##/g, stat.name);
    template = template.replace(/##name_esc##/g, stat.name.replace("'","\\\'"));

	template = template.replace(/##value##/g, stat.value);
	template = template.replace(/##trend##/g, stat.trend);

  var new_stat = $(template);

  if (big) { new_stat.addClass('big'); }

  if (user_votes[stat.name]) {
    if (user_votes[stat.name].get('value') == "1") {
      new_stat.find('.smile').addClass('add-focus');
    } else {
      new_stat.find('.frown').addClass('add-focus');
    }
  }  

	
	switch (stat.light) {
		case "green":			
			new_stat.find('.status').addClass("text-success");
			new_stat.find('.status').addClass("fa-smile-o");
			break;
		case "red":		
			new_stat.find('.status').addClass("text-danger");
			new_stat.find('.status').addClass("fa-frown-o");
			break;
		default:		
			new_stat.find('.status').addClass("text-muted");

			new_stat.find('.status').addClass("fa-meh-o");
			break;		
	}
		
	$('#stats').append(new_stat);

}



</script>
    <hr>
    <button id="big_toggle" onclick="toggle()">big</button>
	</body>

<script type="text/html" id="stat_template">
    <div class="stat col-sm-6 col-sm-6 col-md-4 col-lg-3"> <!-- metric container -->
        <div class="thumbnail card">
            <h3 class="card-title">##name##</h3>
            <p class="text-center"><i class="fa fa-10x status"></i></p>

            <div class="caption">
                <h1 class="text-muted text-center margin-top-0">##value##</h1>


                <h5 class="text-muted text-center margin-top-30">your mood:</h5>
                <div class="row">
                    <div class="col col-md-6 col-sm-6 col-xs-12 text-center">
                        <button type="button" class="smile btn btn-default" onclick="up_vote('##name_esc##');"><i class="fa fa-smile-o fa-3x text-success"></i></button>
                    </div> <!-- col -->
                    <div class="col col-md-6 col-sm-6 col-xs-12 text-center">
                        <button type="button" class="frown btn btn-default" onclick="down_vote('##name_esc##');"><i class="fa fa-frown-o fa-3x text-danger"></i></button>
                    </div> <!-- col -->
                </div> <!-- row -->
            </div> <!-- caption -->
        </div> <!-- thumbnail -->
    </div> <!-- col metric container -->
</script>

<script type="text/html" id="stat_template_old">
<div class="stat col-sm-6 col-sm-6 col-md-4 col-lg-3"> <!-- metric container -->
<div class="thumbnail card">
<p class="text-center"><i class="status fa fa-10x"></i></p>
<div class="caption">
<h1 class="text-center margin-top-0">##name##</h1>
<h2 class="text-muted margin-top-0 text-center">##value##</h2>
<h5 class="text-muted text-center margin-top-30">your mood:</h5>
<div class="row">
<div class="col col-md-6 col-sm-6 col-xs-12 text-center">
<button type="button" class="smile btn btn-default" onclick='up_vote("##name##");' data-name="##name##"><i class="fa fa-smile-o fa-3x text-success"></i></button>
</div> <!-- col -->
<div class="col col-md-6 col-sm-6 col-xs-12 text-center">
<button type="button" class="frown btn btn-default" data-name="##name##" onclick='down_vote("##name##");'><i class="fa fa-frown-o fa-3x text-danger"></i></button>
</div> <!-- col -->
</div> <!-- row -->
</div> <!-- caption -->
</div> <!-- thumbnail -->
</div> <!-- col metric container -->
</script>
</html>
