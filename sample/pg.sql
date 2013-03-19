CREATE TABLE users (
  id  SERIAL PRIMARY KEY NOT NULL,
  username VARCHAR(255) NOT NULL,
  name VARCHAR(255),
  email VARCHAR(255),
  password VARCHAR(255)
);

CREATE UNIQUE INDEX index_users_username ON users(username);

CREATE TABLE articles (
 id  SERIAL PRIMARY KEY NOT NULL,
 message_id VARCHAR(255) NOT NULL,
 created_at VARCHAR(255) NOT NULL,
 overview VARCHAR(255) NOT NULL,
 newsgroup_names VARCHAR(255) NOT NULL
);

CREATE UNIQUE INDEX index_article_message_id ON articles(message_id);

CREATE TABLE newsgroups (
 id  SERIAL PRIMARY KEY NOT NULL,
 name VARCHAR(255) NOT NULL,
 created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
 description TEXT,
 min_pos INTEGER NOT NULL DEFAULT 0,
 max_pos INTEGER NOT NULL DEFAULT 0,
 articles_count INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX index_newsgroups_name ON newsgroups(name);

CREATE TABLE articles_newsgroups(
 id  SERIAL PRIMARY KEY NOT NULL,
 article_id INTEGER NOT NULL,
 newsgroup_id INTEGER NOT NULL,
 pos INTEGER NOT NULL
);

CREATE UNIQUE INDEX index_articles_newsgroups_ids ON articles_newsgroups(article_id,newsgroup_id);
CREATE UNIQUE INDEX index_articles_newsgroups_pos ON articles_newsgroups(newsgroup_id,pos);

