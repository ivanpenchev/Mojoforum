use Mojolicious::Lite;
use DateTime;
use Mojo::Util qw/sha1_sum/;

use DBI;

my $ver = 0.1;
my $dbfile = 'data/mojoforum.sqlite';
my $conn = DBI->connect("dbi:SQLite:dbname=$dbfile", '', '',{sqlite_unicode=>1});

helper db => sub {
	return $conn;
};

get '/' => sub {
	my $self = shift;
	if (-s $dbfile == 0) {
		$self->redirect_to('/install');
	} else {
		my $result = $self->db->selectall_arrayref( q{
				SELECT * FROM topics
			}, { Slice => {} } );
		$self->stash('topics', $result);
		$self -> render;
	}
} => 'index';

get '/install' => sub {
	my $self = shift;
	if (-s $dbfile != 0) {
		$self->redirect_to('/');
	}
	else
	{
		$self->db->do( q{
			CREATE TABLE IF NOT EXISTS topics (
				id integer primary key autoincrement not null,
				title varchar not null,
				author varchar not null,
				posts int default 0,
				published datetime not null
			)
		}) or die $self->db->errstr;
		$self->db->do( q{
			CREATE TABLE IF NOT EXISTS posts (
				id integer primary key autoincrement not null,
				title varchar not null,
				author varchar not null,
				content text not null,
				topic_id integer not null,
				published datetime not null
			)
		}) or die $self->db->errstr;
		$self->db->do( q{
			CREATE TABLE IF NOT EXISTS users (
				id integer primary key autoincrement not null,
				username varchar not null,
				email varchar,
				password varchar not null,
				name varchar,
				account_type int default 0 not null
			)
		});
		my $username = 'admin';
		my $password = sha1_sum 'admin';
		$self->db->do( qq{
			INSERT INTO users (username, password, account_type) VALUES ('$username', '$password', -1)
		});
		$self->render;
	}
} => 'installed';

get '/new/topic' => 'newtopic';

get '/new/post/:topic_id' => sub { 
	my $self = shift;
	my $topic_id = $self->param('topic_id');
	my $topic_details = $self->db->selectall_arrayref( qq{
			SELECT * FROM topics WHERE id='$topic_id'
		}, { Slice => {} } );
	$self->stash('topic' => $topic_details);
	$self->render;
} => 'newpost';

post '/new/post/:tid' => sub {
	my $self = shift;
	my $topic_id = $self->param('tid');
	my $post_title = $self->param('post_title');
	my $post_author = $self->param('user_name');
	my $post_content = $self->param('content');
	my $date_published  = DateTime->now;
	$self->db->do( qq{ 
		INSERT INTO posts (title, author, content, topic_id, published) VALUES ('$post_title', '$post_author',  '$post_content', '$topic_id', '$date_published')
	}) or die $self->db->errstr;
	$self->db->do( qq { UPDATE topics SET posts=posts+1 WHERE id=$topic_id } );
	$self->redirect_to("/topic/$topic_id");
};

post '/new/topic' => sub {
	my $self = shift;
	my $topic_title = $self->param('title');
	my $topic_author = $self->param('author');
	my $date_published = DateTime->now;
	$self->db-> do( qq{
		INSERT INTO topics (title, author, published) VALUES ('$topic_title', '$topic_author', '$date_published')
	}) or die $self->db->errstr;
	$self->redirect_to('/');
};

get '/topic/:id' => sub {
	my $self = shift;
	my $topic_id = $self->param('id');
	my $topic_details = $self->db->selectall_arrayref( qq{
			SELECT * FROM topics WHERE id='$topic_id'
		}, { Slice => {} } );
	my $posts = $self->db->selectall_arrayref( qq{
		SELECT * FROM posts WHERE topic_id='$topic_id'
	}, { Slice => {} } );
	$self->stash('topic' => $topic_details);
	$self->stash('posts' => $posts);
	$self->render;
} => 'viewtopic';

app->start;

__DATA__

@@ index.html.ep
% title 'Main Page';
% layout 'main';
% if(@$topics) {
	<table class="zebra-striped">
		<thead><tr><th class="header">Discussion</th> <th class="yellow">Posts</th> <th class="blue">Author</th> 
			<th class="green">Published</th></tr></thead>
		<tbody>
			% foreach my $topic (@$topics) {
				<tr> <td><a href="/topic/<%= $topic->{id} %>" title="<%= $topic->{title} %>"><%= $topic->{title} %> </a> <span class="label success">New!</span></td> <td><%= $topic->{posts} %></td> <td><%= $topic->{author} %></td> <td><%=$topic->{published} %></td>
			% }
		</tbody>
	</table>
% } else {
<p> There aren't any topics yet. Be the first to add one. </p>
% }

<div style="text-align: center">
	<a href="/new/topic" class="btn large success"> New Topic</a>
</div>

@@ viewtopic.html.ep
% title @$topic[0]->{title};
% layout 'main';
	% foreach my $post (@$posts) {
		<h3><%= $post->{title} %></h3>
		<h4><%= $post->{author} %></h4>
		<p>
			<%= $post->{content} %>
		</p>
		<hr />
	% }
	<div style="text-align: center">
		<a href="/new/topic" class="btn large success"> New Topic</a>
		<a href="/new/post/<%= @$topic[0]->{id} %>" class="btn large primary"> New Post </a>
	</div>

@@ installed.html.ep
% title 'Forum successfully installed';
% layout 'main';
<h2> Your forum was successfully installed </h2>
<a href="/">Go back to the home page</a>

@@ newpost.html.ep
% title 'New Post';
% layout 'main';
<h3>Add new post to <%= @$topic[0]->{title} %></h3>
<form method="post" action="">
	<input type="hidden" name="tid" value="<%= @$topic[0]->{id} %>">
	<div class="clearfix">
		<label>Your name:</label>
		<div class="input">
			<input type="text" name="user_name">
		</div>
	</div>
	<div class="clearfix">
		<label>Post Title:</label>
		<div class="input">
			<input type="text" name="post_title">
		</div>
	</div>
	<div class="clearfix">
		<label>Content:</label>
		<div class="input">
			<textarea style="width: 400px; height: 100px;" name="content"></textarea>
		</div>
	</div>
	<div class="actions">
		<input type="submit" class="btn success" name="submit" value="Post">
	</div>
</form>

@@ newtopic.html.ep
% title 'New Topic';
% layout 'main';
<h3>Create New Topic</h3>
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
		  
		  .hero-unit { padding: 10px; }

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
							<li class="active"> <a href="/">Home</a> </li>
							<li> <a href="/login">Login</a> </li>
							<li> <a href="/help">Help</a> </li>
						</ul>
						<hr />
						<%= content %>
					</div>
				</div>
			</div>
			<footer>
				<p> Powered by 
				<a href="http://mojolicio.us" title="Mojolicious"><img src="http://mojolicio.us/mojolicious-black.png" alt="Mojolicious"></a> and <a href="http://twitter.github.com/bootstrap/">Bootstrap</a></p>
			</footer>
		</div>
	</body>
</html>
