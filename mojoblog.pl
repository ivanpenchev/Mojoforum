use Mojolicious::Lite;
use DateTime;

use DBI;

my $ver = 0.1;
my $dbfile = 'data/mojoblog.sqlite';
my $conn = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '');

helper db => sub {
	return $conn;
};

get '/' => sub {
	my $self = shift;
	$self -> render;
} => 'index';

get '/install' => sub {
	my $self = shift;
	$self->db->do( q{
		CREATE TABLE IF NOT exists topics (
			id integer primary key autoincrement not null,
			title varchar not null,
			author varchar not null,
			posts int default 0,
			published datetime not null
		)
	}, undef, 'DONE') or die $self->db->errstr;
	$self->render;
} => 'installed';

get '/new' => 'newpost';

post '/new' => sub {
	my $self = shift;
	my $post_title = $self->param('title');
	my $post_content = $self->param('text');
	my $post_author = $self->param('author');
	my $date_published = DateTime->now;
	$self->db-> do( qq{
		INSERT INTO posts (title, author, content, published) VALUES ('$post_title', '$post_author', '$post_content', '$date_published')
	}, undef, 'DONE') or die $self->db->errstr;
};

app->start;

__DATA__

@@ index.html.ep
% title 'Main Page';
% layout 'main';
<table class="zebra-striped">
	<thead><tr><th class="header">Discussion</th> <th class="yellow">Posts</th> <th class="blue">Author</th> 
		<th class="green">Published</th></tr></thead>
	<tbody>
		<tr> <td>All about the animals <span class="label success">New!</span></td> <td>33</td> <td>Ivan Penchev</td> <td>11/12/2011</td>
		<tr> <td>Android Phones <span class="label important">Closed</span></td> <td>10</td> <td>Georgi Kostadinov</td> <td>07/10/2011</td>
	</tbody>
</table>
<div style="text-align: center">
	<a href="#" class="btn large success"> New Topic</a>
</div>

@@ installed.html.ep
% title 'Forum successfully installed';
% layout 'main';
<h2> Your forum was successfully installed </h2>
<a href="/">Go back to the home page</a>

@@ newpost.html.ep
% title 'New Post';
% layout 'main';
<h3>Create New Post</h3>
<form method="post" action="">
	<div class="clearfix">
		<label>Post Title:</label>
		<div class="input">
			<input type="text" name="title">
		</div>
	</div>
	<div class="clearfix">
		<label>Your name:</label>
		<div class="input">
			<input type="text" name="author">
		</div>
	</div>
	<div class="clearfix">
		<label>Post content: </label>
		<div class="input">
			<textarea name="text"></textarea>
		</div>
	</div>
	<div class="actions">
		<input type="submit" class="btn primary" value="Save">
	</div>
</form>

@@ layouts/main.html.ep
<!DOCTYPE html>
<html>
	<head>
		<title>Forum App - Mojolicious::Lite - <%= title %></title>
		<link rel="stylesheet" href="http://twitter.github.com/bootstrap/1.4.0/bootstrap.min.css">
		<style>
		  /* Override some defaults */
		  html, body {
			background-color: #eee;
		  }
		  
		  body {
			padding-top: 0px; /* 40px to make the container go all the way to the bottom of the topbar */
		  }
		  .container > footer p {
			text-align: center; /* center align it with the container */
		  }
		  .container {
			width: 820px; /* downsize our container to make the content feel a bit tighter and more cohesive. NOTE: this removes two full columns from the grid, meaning you only go to 14 columns and not 16. */
		  }

		  /* The white background content wrapper */
		  .content {
			background-color: #fff;
			padding: 20px;
			margin: 0 -20px; /* negative indent the amount of the padding to maintain the grid system */
			-webkit-border-radius: 0 0 6px 6px;
			-moz-border-radius: 0 0 6px 6px;
			border-radius: 0 0 6px 6px;
			-webkit-box-shadow: 0 1px 2px rgba(0,0,0,.15);
		   -moz-box-shadow: 0 1px 2px rgba(0,0,0,.15);
			box-shadow: 0 1px 2px rgba(0,0,0,.15);
		  }

		  /* Page header tweaks */
		  .page-header {
			background-color: #f5f5f5;
			padding: 20px 20px 10px;
			margin: -20px -20px 20px;
		  }
		  
		  a.btn { text-align: center; margin: 0 auto; }
		  
		 table { margin-left: 15px; }
		  
		  footer { 
			border-top: none;
			margin-top: 7px;
			padding-top: 7px;
		}
		</style>
	</head>
	<body>
		<div class="container">
			<div class="content">
				<div class="page-header">
					<h1>Forum Name</h1>
					<small> Supporting text or slogan here...</small>
				</div>
				
				<div class="row">
					<div class="span14">
						<ul class="pills">
							<li class="active"> <a href="#">Home</a> </li>
							<li> <a href="#">Login</a> </li>
							<li> <a href="#">Help</a> </li>
						</ul>
						<hr />
						<%= content %>
					</div>
				</div>
			</div>
			<footer>
				<p> Powered by 
				<a href="http://mojolicio.us" title="Mojolicious"><img src="http://mojolicio.us/mojolicious-black.png" alt="Mojolicious"></a></p>
			</footer>
		</div>
	</body>
</html>